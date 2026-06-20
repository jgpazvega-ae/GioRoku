from __future__ import annotations
import asyncio
import json
import sqlite3
from pathlib import Path
from rich.console import Console
from models.channel import RawChannel
from models.source import Source
from providers import create_provider

console = Console()

CREATE_RAW = """
CREATE TABLE IF NOT EXISTS raw_channels (
    id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL,
    tvg_id TEXT,
    tvg_name TEXT,
    tvg_logo TEXT,
    group_title TEXT,
    language TEXT,
    stream_url TEXT NOT NULL,
    fetched_at TEXT NOT NULL
);
"""


class Aggregator:
    def __init__(self, base_dir: Path):
        self.db_path = base_dir / "db" / "iptv.db"
        self.config_dir = base_dir / "config"
        self._init_db()

    def _init_db(self):
        self.db_path.parent.mkdir(exist_ok=True)
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript(CREATE_RAW)

    def _load_sources(self) -> list[Source]:
        path = self.config_dir / "sources.json"
        if not path.exists():
            return []
        with open(path) as f:
            data = json.load(f)
        sources = [Source(**s) for s in data if s.get("is_enabled", True)]
        console.print(f"Loaded {len(sources)} source(s)")
        return sources

    async def run(self) -> list[RawChannel]:
        sources = self._load_sources()
        if not sources:
            console.print("[yellow]No sources configured.[/yellow]")
            return []

        tasks = [create_provider(s).get_channels() for s in sources]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        all_channels: list[RawChannel] = []
        for source, result in zip(sources, results):
            if isinstance(result, Exception):
                console.print(f"[red]{source.name}: {result}[/red]")
                continue
            console.print(f"[green]{source.name}: {len(result)} channels[/green]")
            all_channels.extend(result)

        self._save(all_channels)
        return all_channels

    def _save(self, channels: list[RawChannel]):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM raw_channels")
            conn.executemany(
                """INSERT OR REPLACE INTO raw_channels
                   (id,source_id,tvg_id,tvg_name,tvg_logo,group_title,language,stream_url,fetched_at)
                   VALUES (?,?,?,?,?,?,?,?,?)""",
                [
                    (c.id, c.source_id, c.tvg_id, c.tvg_name,
                     c.tvg_logo, c.group_title, c.language,
                     c.stream_url, c.fetched_at.isoformat())
                    for c in channels
                ],
            )
