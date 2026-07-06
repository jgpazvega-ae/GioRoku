from __future__ import annotations
import json
import shutil
import sqlite3
from datetime import datetime
from pathlib import Path
from rich.console import Console

console = Console()
PAGE_SIZE = 100


class APIGenerator:
    def __init__(self, base_dir: Path, dry_run: bool = False):
        self.db_path = base_dir / "db" / "iptv.db"
        self.out = base_dir.parent / "docs" / "api" / "v1"
        self.cfg = base_dir / "config"
        self.dry_run = dry_run

    def write_all(self) -> dict:
        # Drop stale channel files from previous runs (page counts and
        # country/category sets shrink as sources change)
        if not self.dry_run and (self.out / "channels").exists():
            shutil.rmtree(self.out / "channels")
        self.out.mkdir(parents=True, exist_ok=True)
        channels = self._channels()
        categories = self._categories()
        countries = self._countries()
        epg = self._epg()

        # Friendly labels for the UI (the DB stores codes/slugs only).
        cat_label = {c["id"]: c.get("label", c["id"]) for c in categories}
        cat_label_en = {c["id"]: c.get("labelEn", c["id"]) for c in categories}
        ctry_label = {c["code"]: c.get("name", c["code"]) for c in countries}
        ctry_flag = {c["code"]: c.get("flag", "") for c in countries}
        for ch in channels:
            ch["categoryLabel"] = cat_label.get(ch.get("category"), "")
            ch["categoryLabelEn"] = cat_label_en.get(ch.get("category"), "")
            ch["countryLabel"] = ctry_label.get(ch.get("country"), "")
            ch["countryFlag"] = ctry_flag.get(ch.get("country"), "")

        self._mark_featured(channels)

        for ch in channels:
            epg_id = ch.get("epgId") or ch["id"]
            ch["currentProgram"] = epg.get(epg_id, {}).get("current")
            ch["nextProgram"] = epg.get(epg_id, {}).get("next")

        pages = [channels[i:i + PAGE_SIZE] for i in range(0, max(len(channels), 1), PAGE_SIZE)]
        for n, page in enumerate(pages, 1):
            self._write(f"channels/page/{n}.json", {
                "page": n, "pageSize": PAGE_SIZE,
                "totalPages": len(pages), "totalChannels": len(channels),
                "channels": page,
            })

        country_map: dict[str, list] = {}
        cat_map: dict[str, list] = {}
        for ch in channels:
            country_map.setdefault(ch.get("country", "INTL"), []).append(ch)
            cat_map.setdefault(ch.get("category", "entertainment"), []).append(ch)

        for code, chs in country_map.items():
            self._write(f"channels/country/{code}.json", {"country": code, "channels": chs})
        for cat, chs in cat_map.items():
            self._write(f"channels/category/{cat}.json", {"category": cat, "channels": chs})

        for c in categories:
            c["channelCount"] = len(cat_map.get(c["id"], []))
        for c in countries:
            c["channelCount"] = len(country_map.get(c["code"], []))

        now = _now()
        tiers = self._tier_breakdown()
        self._write("categories.json", {"generatedAt": now, "categories": categories})
        self._write("countries.json", {"generatedAt": now, "countries": countries})
        self._write("epg.json", {"generatedAt": now, "programs": epg})
        self._write("status.json", {
            "generatedAt": now,
            "pipelineVersion": "1.1.0",
            "stats": {
                "totalChannels": len(channels),
                "onlineChannels": sum(1 for c in channels if c.get("isOnline")),
                "offlineChannels": sum(1 for c in channels if not c.get("isOnline")),
                "premiumChannels": tiers.get("premium", 0),
                "filteredFreeChannels": tiers.get("free", 0),
                "filteredUnknownChannels": tiers.get("unknown", 0),
                "totalCountries": len(country_map),
                "totalCategories": len(cat_map),
                "lastValidationRun": now,
            },
        })

        total = len(pages) + len(country_map) + len(cat_map) + 4
        console.print(f"[green]API: {total} files, {len(channels)} channels[/green]")
        return {"total_files": total, "total_channels": len(channels)}

    def _write(self, rel: str, data):
        path = self.out / rel
        if self.dry_run:
            console.print(f"[dim]DRY {path}[/dim]")
            return
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    def _channels(self) -> list[dict]:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cols = {r[1] for r in conn.execute("PRAGMA table_info(channels)").fetchall()}
            tier_sql = "tier" if "tier" in cols else "'premium' AS tier"
            rows = conn.execute(f"""
                SELECT id,
                    COALESCE(override_name,name) AS name,
                    COALESCE(override_logo,logo) AS logo,
                    COALESCE(override_category,category) AS category,
                    COALESCE(override_country,country) AS country,
                    language, stream_url, backup_urls, quality, {tier_sql},
                    is_online, COALESCE(override_enabled,is_enabled) AS is_enabled,
                    is_featured, epg_id, tags, offline_count,
                    last_check, last_online, response_ms, source_id, source_priority
                FROM channels
                WHERE COALESCE(override_enabled,is_enabled)=1
                ORDER BY source_priority, name
            """).fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["backupUrls"] = json.loads(d.pop("backup_urls") or "[]")
            d["isOnline"] = bool(d.pop("is_online"))
            d["isEnabled"] = bool(d.pop("is_enabled"))
            d["isFeatured"] = bool(d.pop("is_featured"))
            d["streamUrl"] = d.pop("stream_url")
            d["offlineCount"] = d.pop("offline_count")
            d["lastCheck"] = d.pop("last_check")
            d["lastOnline"] = d.pop("last_online")
            d["responseMs"] = d.pop("response_ms")
            d["sourceId"] = d.pop("source_id")
            d["sourcePriority"] = d.pop("source_priority")
            d["epgId"] = d.pop("epg_id")
            d["tags"] = json.loads(d.pop("tags") or "[]")
            result.append(d)
        return result

    def _mark_featured(self, channels: list[dict]) -> None:
        """Feature the best online channel of each category for the Home hero row."""
        def score(c: dict) -> tuple:
            return (
                1 if c.get("isOnline") else 0,
                -c.get("sourcePriority", 99),
                -(c.get("responseMs") or 9999),
            )
        by_cat: dict[str, list[dict]] = {}
        for ch in channels:
            ch["isFeatured"] = False
            by_cat.setdefault(ch.get("category", "entertainment"), []).append(ch)
        for chs in by_cat.values():
            best = max(chs, key=score)
            if best.get("isOnline"):
                best["isFeatured"] = True

    def _tier_breakdown(self) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            cols = {r[1] for r in conn.execute("PRAGMA table_info(channels)").fetchall()}
            if "tier" not in cols:
                return {}
            return {
                row[0]: row[1]
                for row in conn.execute("SELECT tier, COUNT(*) FROM channels GROUP BY tier")
            }

    def _categories(self) -> list[dict]:
        p = self.cfg / "categories.json"
        return json.loads(p.read_text()) if p.exists() else []

    def _countries(self) -> list[dict]:
        p = self.cfg / "countries.json"
        return json.loads(p.read_text()) if p.exists() else []

    def _epg(self) -> dict:
        now = datetime.utcnow().isoformat()
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            epg: dict = {}
            for row in conn.execute(
                "SELECT * FROM epg_programs WHERE start_time<=? AND end_time>?", (now, now)
            ).fetchall():
                epg.setdefault(row["epg_id"], {})["current"] = _prog(row)
            for row in conn.execute(
                "SELECT * FROM epg_programs WHERE start_time>? GROUP BY epg_id HAVING start_time=MIN(start_time)", (now,)
            ).fetchall():
                epg.setdefault(row["epg_id"], {})["next"] = _prog(row)
        return epg


def _prog(row) -> dict:
    return {"title": row["title"], "description": row["description"] or "",
            "start": row["start_time"], "end": row["end_time"],
            "category": row["category"] or "", "rating": row["rating"]}


def _now() -> str:
    return datetime.utcnow().isoformat() + "Z"
