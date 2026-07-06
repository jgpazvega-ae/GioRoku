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
import unicodedata
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
        self._ensure_column()

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

    def classify(self, name: str, group: str | None) -> tuple[str, str | None]:
        """Return (tier, implied_category)."""
        hay = _n(name) + " " + _n(group or "")
        for needle in self._free:
            if self._matches(needle, hay):
                return "free", None
        for needle, bucket in self._premium:
            if self._matches(needle, hay):
                return "premium", BUCKET_CATEGORY.get(bucket)
        return "unknown", None

    def run(self) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            rows = conn.execute("SELECT id,name,category FROM channels").fetchall()

            counts = {"premium": 0, "free": 0, "unknown": 0}
            for ch in rows:
                raw = conn.execute(
                    "SELECT group_title FROM raw_channels WHERE stream_url=("
                    "SELECT stream_url FROM channels WHERE id=?) LIMIT 1",
                    (ch["id"],),
                ).fetchone()
                group = raw["group_title"] if raw else None
                tier, implied = self.classify(ch["name"], group)
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
