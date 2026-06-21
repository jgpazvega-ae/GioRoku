from __future__ import annotations
import asyncio
import sqlite3
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional
import httpx
from rich.console import Console
from rich.progress import Progress, BarColumn, TaskProgressColumn, TextColumn

console = Console()

VALID_CT = {
    "video/mp2t", "video/mpeg", "application/x-mpegurl",
    "application/vnd.apple.mpegurl", "video/mp4", "video/webm",
    "audio/mpeg", "audio/aac",
}

CREATE_CHECKS = """
CREATE TABLE IF NOT EXISTS channel_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    channel_id TEXT NOT NULL,
    checked_at TEXT NOT NULL,
    is_online INTEGER NOT NULL,
    response_ms INTEGER,
    http_status INTEGER,
    error TEXT
);
"""


@dataclass
class ValidationResult:
    channel_id: str
    is_online: bool
    response_ms: Optional[int] = None
    http_status: Optional[int] = None
    error: Optional[str] = None


class StreamValidator:
    def __init__(self, base_dir: Path, concurrency: int = 50):
        self.db_path = base_dir / "db" / "iptv.db"
        self.concurrency = concurrency
        self._ensure_tables()

    def _ensure_tables(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript(CREATE_CHECKS)

    async def validate_all(self, country_filter: str | None = None) -> list[ValidationResult]:
        channels = self._load(country_filter)
        if not channels:
            return []
        console.print(f"Validating {len(channels)} channels (concurrency={self.concurrency})")
        sem = asyncio.Semaphore(self.concurrency)
        results: list[ValidationResult] = []

        with Progress(TextColumn("{task.description}"), BarColumn(), TaskProgressColumn(), console=console) as prog:
            task = prog.add_task("Checking...", total=len(channels))

            async def check_one(ch):
                async with sem:
                    r = await self._check(ch["id"], ch["stream_url"])
                    results.append(r)
                    prog.advance(task)

            await asyncio.gather(*[check_one(ch) for ch in channels])

        self._save(results)
        return results

    async def _check(self, cid: str, url: str) -> ValidationResult:
        loop = asyncio.get_event_loop()
        t0 = loop.time()
        try:
            async with httpx.AsyncClient(
                timeout=httpx.Timeout(connect=5, read=5, write=5, pool=5),
                follow_redirects=True,
                max_redirects=3,
            ) as client:
                try:
                    resp = await client.head(url)
                except Exception:
                    resp = await client.get(url, headers={"Range": "bytes=0-1023"})

                ms = int((loop.time() - t0) * 1000)
                ct = resp.headers.get("content-type", "").split(";")[0].strip().lower()
                ok = resp.status_code < 400 and (
                    any(ct.startswith(v) for v in VALID_CT) or resp.status_code in (200, 206)
                )
                return ValidationResult(channel_id=cid, is_online=ok, response_ms=ms, http_status=resp.status_code)
        except Exception as e:
            return ValidationResult(channel_id=cid, is_online=False, error=str(e)[:200])

    def _load(self, country: str | None) -> list[dict]:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            if country:
                rows = conn.execute(
                    "SELECT id,stream_url FROM channels WHERE country=? AND is_enabled=1 AND is_trusted=0", (country,)
                ).fetchall()
            else:
                rows = conn.execute(
                    "SELECT id,stream_url FROM channels WHERE is_enabled=1 AND is_trusted=0"
                ).fetchall()
        return [dict(r) for r in rows]

    def _save(self, results: list[ValidationResult]):
        now = datetime.utcnow().isoformat()
        with sqlite3.connect(self.db_path) as conn:
            for r in results:
                # Trusted channels: only update response_ms/last_check, never toggle is_online
                conn.execute(
                    """UPDATE channels SET
                       is_online=CASE WHEN is_trusted THEN 1 ELSE ? END,
                       response_ms=?, last_check=?,
                       last_online=CASE WHEN is_trusted OR ? THEN ? ELSE last_online END,
                       offline_count=CASE WHEN is_trusted OR ? THEN 0 ELSE offline_count+1 END,
                       is_enabled=CASE WHEN NOT is_trusted AND offline_count>=6 AND NOT ? THEN 0 ELSE is_enabled END
                       WHERE id=?""",
                    (r.is_online, r.response_ms, now,
                     r.is_online, now, r.is_online, r.is_online, r.channel_id),
                )
                conn.execute(
                    "INSERT INTO channel_checks(channel_id,checked_at,is_online,response_ms,http_status,error) VALUES(?,?,?,?,?,?)",
                    (r.channel_id, now, r.is_online, r.response_ms, r.http_status, r.error),
                )
