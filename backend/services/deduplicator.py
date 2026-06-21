from __future__ import annotations
import json
import re
import sqlite3
import unicodedata
from pathlib import Path
from Levenshtein import ratio
from rich.console import Console
from models.source import Source

console = Console()

QUALITY_RE = re.compile(r'\s*[|\-–]\s*(4k|uhd|fhd|1080p?|720p?|hd|sd)\s*$', re.I)

CREATE_CHANNELS = """
CREATE TABLE IF NOT EXISTS channels (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    logo TEXT,
    category TEXT DEFAULT 'entertainment',
    country TEXT DEFAULT 'INTL',
    language TEXT DEFAULT 'es',
    stream_url TEXT NOT NULL,
    backup_urls TEXT DEFAULT '[]',
    quality TEXT DEFAULT 'SD',
    is_online INTEGER DEFAULT 1,
    is_enabled INTEGER DEFAULT 1,
    is_featured INTEGER DEFAULT 0,
    is_trusted INTEGER DEFAULT 0,
    epg_id TEXT,
    tags TEXT DEFAULT '[]',
    offline_count INTEGER DEFAULT 0,
    last_check TEXT,
    last_online TEXT,
    response_ms INTEGER,
    source_id TEXT,
    source_priority INTEGER DEFAULT 10,
    override_name TEXT,
    override_logo TEXT,
    override_category TEXT,
    override_country TEXT,
    override_enabled INTEGER
);
"""


class Deduplicator:
    def __init__(self, base_dir: Path):
        self.db_path = base_dir / "db" / "iptv.db"
        self.config_dir = base_dir / "config"
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript(CREATE_CHANNELS)
            # Migrate: add is_trusted column if missing (safe on existing DBs)
            cols = {r[1] for r in conn.execute("PRAGMA table_info(channels)").fetchall()}
            if "is_trusted" not in cols:
                conn.execute("ALTER TABLE channels ADD COLUMN is_trusted INTEGER DEFAULT 0")

    def _source_flags(self) -> tuple[set[str], set[str]]:
        """Returns (trusted_ids, cable_ids)."""
        path = self.config_dir / "sources.json"
        if not path.exists():
            return set(), set()
        import json as _json
        data = _json.loads(path.read_text())
        enabled = [s for s in data if s.get("is_enabled", True)]
        trusted = {s["id"] for s in enabled if s.get("trusted")}
        cable   = {s["id"] for s in enabled if s.get("cable")}
        return trusted, cable

    def run(self) -> int:
        raw = self._load_raw()
        console.print(f"Deduplicating {len(raw)} raw channels...")

        # Pass 1: exact tvg_id grouping
        id_groups: dict[str, list[dict]] = {}
        no_id: list[dict] = []
        for ch in raw:
            key = _norm(ch.get("tvg_id") or "")
            if key:
                id_groups.setdefault(key, []).append(ch)
            else:
                no_id.append(ch)

        # Pass 2: fuzzy name grouping for channels without tvg_id
        used: set[int] = set()
        name_groups: list[list[dict]] = []
        for i, a in enumerate(no_id):
            if i in used:
                continue
            group = [a]
            used.add(i)
            na = _norm(a.get("tvg_name") or "")
            for j in range(i + 1, len(no_id)):
                if j in used:
                    continue
                nb = _norm(no_id[j].get("tvg_name") or "")
                if na and nb and ratio(na, nb) >= 0.85:
                    group.append(no_id[j])
                    used.add(j)
            name_groups.append(group)

        all_groups = list(id_groups.values()) + name_groups
        channels = [self._best(g) for g in all_groups]
        self._save(channels)
        console.print(f"[green]{len(channels)} unique channels[/green]")
        return len(channels)

    def _best(self, group: list[dict]) -> dict:
        sorted_g = sorted(group, key=lambda c: c.get("source_priority", 99))
        best = dict(sorted_g[0])
        backups = [c["stream_url"] for c in sorted_g[1:] if c["stream_url"] != best["stream_url"]][:3]
        best["backup_urls"] = json.dumps(backups)
        best["id"] = _make_id(best)
        return best

    def _make_id(self, ch: dict) -> str:
        key = ch.get("tvg_id") or _norm(ch.get("tvg_name") or ch.get("stream_url", ""))
        return re.sub(r'[^a-z0-9_]', '_', key.lower())[:80].strip("_")

    def _load_raw(self) -> list[dict]:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute("SELECT * FROM raw_channels").fetchall()]

    def _save(self, channels: list[dict]):
        trusted, cable = self._source_flags()
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM channels")
            for ch in channels:
                src = ch.get("source_id")
                is_trusted  = 1 if src in trusted else 0
                is_featured = 1 if src in cable   else 0
                conn.execute(
                    """INSERT OR REPLACE INTO channels
                       (id,name,logo,stream_url,backup_urls,epg_id,language,
                        source_id,source_priority,is_trusted,is_featured,is_online)
                       VALUES(?,?,?,?,?,?,?,?,?,?,?,?)""",
                    (
                        ch["id"],
                        ch.get("tvg_name") or ch.get("id", "Unknown"),
                        ch.get("tvg_logo"),
                        ch["stream_url"],
                        ch.get("backup_urls", "[]"),
                        ch.get("tvg_id"),
                        ch.get("language", "es"),
                        src,
                        ch.get("source_priority", 10),
                        is_trusted,
                        is_featured,
                        1,
                    ),
                )


def _norm(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = QUALITY_RE.sub("", s)
    return re.sub(r'\s+', ' ', s).strip().lower()

# expose for reuse in Deduplicator._make_id
def _make_id(ch: dict) -> str:
    key = ch.get("tvg_id") or _norm(ch.get("tvg_name") or ch.get("stream_url", ""))
    return re.sub(r'[^a-z0-9_]', '_', key.lower())[:80].strip("_")
