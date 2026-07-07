"""
PremiumClassifier — autonomous pay-TV (canales de paga) filter.

Tags every channel with a `tier`:
    - "premium": belongs to a pay-TV network (ESPN, HBO, Discovery, TUDN, …)
    - "free":    free-to-air / open TV (Las Estrellas, Canal 5, Once, Univision, …)
    - "unknown": no confident match either way

When `keep_only_premium` is enabled in premium_networks.json, every channel
that is NOT premium is disabled (is_enabled=0) so it never reaches the JSON
API — but it stays in the database so the admin portal can still report how
many were filtered out. It also upgrades a channel's category when a premium
brand implies one (e.g. an ESPN feed grouped as "general" becomes "sports").
"""
from __future__ import annotations
import json
import re
import sqlite3
import time
import unicodedata
import urllib.request
from pathlib import Path
from rich.console import Console

console = Console()

# Which premium bucket maps to which app category.
BUCKET_CATEGORY = {
    "sports": "sports",
    "movies": "movies",
    "series_entertainment": "entertainment",
    "kids": "kids",
    "documentary": "documentary",
    "music": "music",
}

# iptv-org channel registry (id → network/owners/categories). Cross-referencing
# by tvg-id lets us recognise pay-TV feeds whose stream name is generic but
# whose canonical network is a premium brand.
REGISTRY_URL = "https://iptv-org.github.io/api/channels.json"
REGISTRY_MAX_AGE_S = 7 * 24 * 3600

# iptv-org category slug → our app category.
IPTVORG_CATEGORY = {
    "sports": "sports", "movies": "movies", "series": "entertainment",
    "comedy": "entertainment", "entertainment": "entertainment",
    "kids": "kids", "animation": "kids", "family": "kids",
    "documentary": "documentary", "science": "documentary", "culture": "documentary",
    "music": "music", "news": "news", "business": "news",
    "religious": "religious", "shop": "shopping",
}


def _n(s: str) -> str:
    s = unicodedata.normalize("NFD", s or "")
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", s).strip().lower()


class PremiumClassifier:
    def __init__(self, base_dir: Path):
        self.db_path = base_dir / "db" / "iptv.db"
        self.config_dir = base_dir / "config"
        cfg = self._load()
        self.keep_only_premium: bool = bool(cfg.get("keep_only_premium", True))
        # Pre-normalize brand tables into (needle, bucket) and a free-to-air set.
        self._premium: list[tuple[str, str]] = []
        for bucket, brands in cfg.get("premium_brands", {}).items():
            for b in brands:
                nb = _n(b)
                if nb:
                    self._premium.append((nb, bucket))
        # Longer needles first so "espn deportes" wins over "espn".
        self._premium.sort(key=lambda x: len(x[0]), reverse=True)
        self._free = [_n(b) for b in cfg.get("free_to_air_brands", []) if _n(b)]
        self._by_id, self._by_name = self._load_registry(base_dir)
        self._ensure_column()

    def _load_registry(self, base_dir: Path) -> tuple[dict, dict]:
        """Return (id→record, normname→record) from the iptv-org channel DB.

        Cached on disk; re-downloaded when missing or older than a week. On any
        network failure we fall back to the stale cache, or to empty maps (the
        classifier still works on brand names alone)."""
        cache = base_dir / "db" / "iptv_org_channels.json"
        cache.parent.mkdir(parents=True, exist_ok=True)
        fresh = cache.exists() and (time.time() - cache.stat().st_mtime) < REGISTRY_MAX_AGE_S
        if not fresh:
            try:
                req = urllib.request.Request(REGISTRY_URL, headers={"User-Agent": "GioRoku/1.0"})
                with urllib.request.urlopen(req, timeout=30) as r:
                    cache.write_bytes(r.read())
            except Exception as e:
                console.print(f"[yellow]Registry download failed ({e}); using cache if present[/yellow]")
        if not cache.exists():
            return {}, {}
        try:
            data = json.loads(cache.read_text(encoding="utf-8"))
        except Exception:
            return {}, {}
        by_id, by_name = {}, {}
        for c in data:
            rec = {
                "network": c.get("network") or "",
                "owners": c.get("owners") or [],
                "categories": c.get("categories") or [],
                "name": c.get("name") or "",
                "alt_names": c.get("alt_names") or [],
            }
            if c.get("id"):
                by_id[c["id"].lower()] = rec
            nm = _n(rec["name"])
            if nm and nm not in by_name:
                by_name[nm] = rec
        console.print(f"Registry: {len(by_id)} channels indexed")
        return by_id, by_name

    def _registry_lookup(self, tvg_id: str | None, name: str) -> dict | None:
        if tvg_id and tvg_id.lower() in self._by_id:
            return self._by_id[tvg_id.lower()]
        return self._by_name.get(_n(name))

    def _load(self) -> dict:
        path = self.config_dir / "premium_networks.json"
        return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}

    def _ensure_column(self):
        with sqlite3.connect(self.db_path) as conn:
            cols = {r[1] for r in conn.execute("PRAGMA table_info(channels)").fetchall()}
            if "tier" not in cols:
                conn.execute("ALTER TABLE channels ADD COLUMN tier TEXT DEFAULT 'unknown'")

    @staticmethod
    def _matches(needle: str, hay: str) -> bool:
        # Boundary match that tolerates symbols (a+, a&e, i-sat): the needle
        # must not be flanked by another alphanumeric character, so bare
        # "max" hits "tv max" but never "eSports Max TV"'s neighbours.
        pat = r"(?<![a-z0-9])" + re.escape(needle) + r"(?![a-z0-9])"
        return re.search(pat, hay) is not None

    def classify(self, name: str, group: str | None, tvg_id: str | None = None) -> tuple[str, str | None]:
        """Return (tier, implied_category).

        The haystack is enriched with the channel's canonical name, network,
        owners and alt-names from the iptv-org registry (looked up by tvg-id,
        then by name), so a generically-named feed of a premium network is
        still recognised. The registry also supplies a fallback category."""
        rec = self._registry_lookup(tvg_id, name)
        hay = _n(name) + " " + _n(group or "")
        reg_category = None
        if rec:
            extra = [rec["name"], rec["network"]] + rec["owners"] + rec["alt_names"]
            hay = hay + " " + " ".join(_n(x) for x in extra if x)
            for cat in rec["categories"]:
                if cat in IPTVORG_CATEGORY:
                    reg_category = IPTVORG_CATEGORY[cat]
                    break

        for needle in self._free:
            if self._matches(needle, hay):
                return "free", None
        for needle, bucket in self._premium:
            if self._matches(needle, hay):
                return "premium", BUCKET_CATEGORY.get(bucket) or reg_category
        return "unknown", reg_category

    def run(self) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            rows = conn.execute("SELECT id,name,category,epg_id FROM channels").fetchall()

            counts = {"premium": 0, "free": 0, "unknown": 0}
            for ch in rows:
                raw = conn.execute(
                    "SELECT group_title FROM raw_channels WHERE stream_url=("
                    "SELECT stream_url FROM channels WHERE id=?) LIMIT 1",
                    (ch["id"],),
                ).fetchone()
                group = raw["group_title"] if raw else None
                tier, implied = self.classify(ch["name"], group, ch["epg_id"])
                counts[tier] += 1

                new_cat = implied or ch["category"]
                if self.keep_only_premium and tier != "premium":
                    conn.execute(
                        "UPDATE channels SET tier=?, category=?, is_enabled=0 WHERE id=?",
                        (tier, new_cat, ch["id"]),
                    )
                else:
                    conn.execute(
                        "UPDATE channels SET tier=?, category=? WHERE id=?",
                        (tier, new_cat, ch["id"]),
                    )

        mode = "keep-only-premium" if self.keep_only_premium else "tag-only"
        console.print(
            f"[green]Premium filter ({mode}): "
            f"{counts['premium']} premium · {counts['free']} free · {counts['unknown']} unknown[/green]"
        )
        return counts
