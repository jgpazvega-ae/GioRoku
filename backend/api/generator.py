from __future__ import annotations
import json
import re
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
        self.out.mkdir(parents=True, exist_ok=True)
        channels = self._channels()
        categories = self._categories()
        countries = self._countries()
        epg = self._epg()

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
        self._write("categories.json", {"generatedAt": now, "categories": categories})
        self._write("countries.json", {"generatedAt": now, "countries": countries})
        self._write("epg.json", {"generatedAt": now, "programs": epg})
        self._write("status.json", {
            "generatedAt": now,
            "pipelineVersion": "1.0.0",
            "stats": {
                "totalChannels": len(channels),
                "onlineChannels": sum(1 for c in channels if c.get("isOnline")),
                "offlineChannels": sum(1 for c in channels if not c.get("isOnline")),
                "totalCountries": len(countries),
                "totalCategories": len(categories),
                "lastValidationRun": now,
            },
        })

        total = len(pages) + len(country_map) + len(cat_map) + 4
        console.print(f"[green]API: {total} files, {len(channels)} channels[/green]")
        return {"total_files": total, "total_channels": len(channels)}

    def write_bundled_roku(self) -> int:
        """Write roku-app/data/channels.json with the top 3000 channels.

        Limit to 3000 so the Roku can parse the bundled JSON in ~1s instead of ~5s.
        Cable/pay-TV channels are first (is_featured DESC), so they are always included.
        The background LoadTask fetches the full API and upgrades the list at runtime
        if more channels are available.
        """
        channels = self._channels()
        online = [ch for ch in channels if ch.get("isOnline")][:3000]
        for ch in online:
            ch["name"] = _clean_ch_name(ch["name"])
        roku_path = self.out.parent.parent.parent / "roku-app" / "data" / "channels.json"
        if not self.dry_run:
            roku_path.parent.mkdir(parents=True, exist_ok=True)
            roku_path.write_text(
                json.dumps({"channels": online}, ensure_ascii=False, indent=1),
                encoding="utf-8",
            )
            console.print(f"[green]Roku bundle: {len(online)} online channels → {roku_path}[/green]")
        else:
            console.print(f"[dim]DRY Roku bundle: {len(online)} online channels[/dim]")
        return len(online)

    def _write(self, rel: str, data):
        path = self.out / rel
        if self.dry_run:
            console.print(f"[dim]DRY {path}[/dim]")
            return
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    # Countries considered "Latino" — only these appear in API and Roku bundle.
    LATAM_COUNTRIES = (
        "MX","AR","CO","CL","VE","PE","UY","PY","EC","BO",
        "US_ES","SV","GT","HN","NI","CR","PA","DO","CU","PR"
    )
    # Tier 1 — Spanish Latin American CABLE channels (ESPN, Discovery, History,
    # HBO, TNT, Fox Sports, CNN en Español…).  Included regardless of country tag.
    CABLE_SOURCES = (
        "dmelendez11_especial",  # 49 ch: ESPN 1-6, Discovery HD, History, HBO, TNT, FX…
        "dmelendez11_m3u",       # 80 ch: CNN en Español, Cinecanal, ESPN 2-6, Fox Sports…
    )
    # Tier 2 — Mexico / LATAM curated lists.  Country filter applied (INTL excluded).
    CURATED_SOURCES = (
        "achoapps_mexico3",      # MX/AR/CL/PE channels: Azteca, Canal 5, Multimedios, Milenio…
    )
    # Tier 3 — Official iptv-org country playlists — only LATAM-country channels.
    OFFICIAL_SOURCES = (
        "iptvorg_mx","iptvorg_ar","iptvorg_co","iptvorg_cl",
        "iptvorg_pe","iptvorg_ve","m3u_iptvcat_mx",
    )
    # Tier 3b — achoapps_acho: include only LATAM-tagged channels.
    COUNTRY_FILTERED_SOURCES = (
        "achoapps_acho",
    )
    # Non-Spanish channels mixed into cable sources (Russian, Turkish, Asian, radio).
    BLOCKED_NAMES = (
        # Russian cable (dmelendez11_m3u)
        "NTV Hit","NTV Pravo","NTV Ruso","NTV Serial HD","NTV Style HD",
        "Sochi Live HD","RT Noticias","Страна FM","Canal Ruso",
        # Asian / Turkish
        "BigAsia HD","Kanal D Drama",
        # Spain-only (not LATAM)
        "La 2",
        # Radio stations
        "1Mus","City Radio",
        # Non-Spanish from dmelendez11_especial (German, Swiss, English)
        "018. DW ✅ ✅",            # Deutsche Welle (German)
        "065. 127_Eurosport HD ✅ ✅",  # Eurosport (English/French)
        "106. MyTime Movie Network ✅ ✅",  # English movies
        "118. RTS ✅ ✅",           # Radio-Télévision Suisse (Swiss/French)
        "099. 1 ✅ ✅",             # Unnamed/unknown channel
        # Radio & numbered garbage
        "025. BigR - Golden Oldielive ✅ ✅",
        "113. NTV ✅ ✅",
    )

    def _channels(self) -> list[dict]:
        countries_sql = ",".join(f"'{c}'" for c in self.LATAM_COUNTRIES)
        cable_sql    = ",".join(f"'{s}'" for s in self.CABLE_SOURCES)
        curated_sql  = ",".join(f"'{s}'" for s in self.CURATED_SOURCES)
        official_sql = ",".join(f"'{s}'" for s in self.OFFICIAL_SOURCES)
        cfilt_sql    = ",".join(f"'{s}'" for s in self.COUNTRY_FILTERED_SOURCES)
        blocked_sql  = ",".join(f"'{n}'" for n in self.BLOCKED_NAMES)
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(f"""
                SELECT id,
                    COALESCE(override_name,name) AS name,
                    COALESCE(override_logo,logo) AS logo,
                    COALESCE(override_category,category) AS category,
                    COALESCE(override_country,country) AS country,
                    language, stream_url, backup_urls, quality,
                    is_online, COALESCE(override_enabled,is_enabled) AS is_enabled,
                    is_featured, is_trusted, epg_id, tags, offline_count,
                    last_check, last_online, response_ms, source_id, source_priority
                FROM channels
                WHERE COALESCE(override_enabled,is_enabled)=1
                  AND (
                    source_id IN ({cable_sql})
                    OR (source_id IN ({curated_sql}) AND COALESCE(override_country,country) IN ({countries_sql}))
                    OR (source_id IN ({official_sql}) AND COALESCE(override_country,country) IN ({countries_sql}))
                    OR (source_id IN ({cfilt_sql})    AND COALESCE(override_country,country) IN ({countries_sql}))
                  )
                  -- Block non-Spanish channels mixed into cable sources
                  AND COALESCE(override_name,name) NOT IN ({blocked_sql})
                  -- Block corrupt/garbage entries (M3U directives used as channel names)
                  AND COALESCE(override_name,name) NOT LIKE 'tvg-logo=%'
                  AND COALESCE(override_name,name) NOT LIKE 'http%'
                  AND COALESCE(override_name,name) NOT LIKE '--- %'
                  AND COALESCE(override_name,name) NOT LIKE '%Chrome/%'
                  AND COALESCE(override_name,name) NOT LIKE '%Safari/%'
                  AND COALESCE(override_name,name) NOT LIKE '%Gecko)%'
                  -- Block radio-only channels from achoapps_acho (music streams, FM stations)
                  AND NOT (source_id = 'achoapps_acho' AND (
                      COALESCE(override_name,name) LIKE 'MUSICA:%'
                      OR COALESCE(override_name,name) LIKE 'NIU %'
                      OR COALESCE(override_name,name) LIKE 'RADIO %'
                      OR COALESCE(override_name,name) = 'RADIO LA SALADA'
                      OR COALESCE(override_name,name) LIKE 'RADIOTV:%'
                      OR COALESCE(override_name,name) LIKE 'WORLD NEWS:%'
                      OR COALESCE(override_name,name) LIKE 'Chileiptv:INT%'
                  ))
                ORDER BY
                    CASE WHEN source_id IN ({cable_sql})   THEN 0
                         WHEN source_id IN ({curated_sql}) THEN 1
                         ELSE 2 END,
                    is_featured DESC,
                    CASE WHEN COALESCE(override_country,country) = 'MX' THEN 0
                         WHEN COALESCE(override_country,country) IN ('AR','CO','CL','VE','PE','UY','PY','EC','BO','US_ES','DO','PR','CU','GT','HN','SV','NI','CR','PA') THEN 1
                         ELSE 2 END,
                    is_online DESC, response_ms ASC NULLS LAST, name
            """).fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["backupUrls"] = json.loads(d.pop("backup_urls") or "[]")
            d["isOnline"] = bool(d.pop("is_online"))
            d["isEnabled"] = bool(d.pop("is_enabled"))
            d["isFeatured"] = bool(d.pop("is_featured"))
            d["isTrusted"] = bool(d.pop("is_trusted"))
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
            tables = {r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()}
            if "epg_programs" not in tables:
                return {}
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


def _clean_ch_name(name: str) -> str:
    """Strip M3U numbering noise so names are human-readable on Roku."""
    n = name
    n = re.sub(r'^\d{2,3}\.\s*', '', n)   # "020. " → ""
    n = re.sub(r'^[A-Z]{2,3}:\s*', '', n)  # "CO: " → ""
    n = re.sub(r'^\d{1,2}\.\d+', '', n)    # "09.1", "03.4" → ""
    n = re.sub(r'^\d+_', '', n)             # "143_", "127_" → ""
    n = re.sub(r'^\d+[a-zA-Z]+\s+', '', n) # "70w " → ""
    n = n.replace('✅', '').replace('⭐', '')
    n = re.sub(r'\s+', ' ', n).strip()
    return n if n else name


def _prog(row) -> dict:
    return {"title": row["title"], "description": row["description"] or "",
            "start": row["start_time"], "end": row["end_time"],
            "category": row["category"] or "", "rating": row["rating"]}


def _now() -> str:
    return datetime.utcnow().isoformat() + "Z"
