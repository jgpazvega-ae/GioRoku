from __future__ import annotations
import asyncio
import base64
import json
import sqlite3
from datetime import datetime
from pathlib import Path
import httpx
from rich.console import Console

console = Console()

COLORS = {
    "entertainment":"#E74C3C","news":"#3498DB","sports":"#27AE60",
    "movies":"#9B59B6","kids":"#F39C12","music":"#E91E63",
    "documentary":"#16A085","religious":"#8E44AD","shopping":"#D35400",
    "local":"#2C3E50","international":"#7F8C8D","radio":"#1ABC9C",
}

CREATE_LOGOS = """
CREATE TABLE IF NOT EXISTS logos (
    url TEXT PRIMARY KEY,
    resolved_url TEXT NOT NULL,
    resolved_at TEXT NOT NULL,
    source TEXT
);
"""


class LogoResolver:
    def __init__(self, base_dir: Path):
        self.db_path = base_dir / "db" / "iptv.db"
        self.config_dir = base_dir / "config"
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript(CREATE_LOGOS)
        self._overrides = self._load_overrides()

    def _load_overrides(self) -> dict:
        p = self.config_dir / "logo_overrides.json"
        return json.loads(p.read_text()) if p.exists() else {}

    async def resolve_all(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            channels = conn.execute(
                "SELECT id,name,logo,category FROM channels"
            ).fetchall()

        sem = asyncio.Semaphore(20)

        async def one(ch):
            async with sem:
                logo = await self._resolve(ch["id"], ch["name"], ch["logo"], ch["category"] or "entertainment")
                with sqlite3.connect(self.db_path) as c:
                    c.execute("UPDATE channels SET logo=? WHERE id=?", (logo, ch["id"]))

        await asyncio.gather(*[one(ch) for ch in channels])
        console.print(f"[green]Logos resolved for {len(channels)} channels[/green]")

    async def _resolve(self, cid: str, name: str, tvg_logo: str | None, cat: str) -> str:
        if cid in self._overrides:
            return self._overrides[cid].get("logo", "")

        cached = self._cached(tvg_logo or "")
        if cached:
            return cached

        if tvg_logo and tvg_logo.startswith("https://"):
            if await self._verify(tvg_logo):
                self._cache(tvg_logo, tvg_logo, "tvg_logo")
                return tvg_logo

        return self._svg(name, cat)

    def _cached(self, url: str) -> str | None:
        if not url:
            return None
        with sqlite3.connect(self.db_path) as conn:
            row = conn.execute("SELECT resolved_url FROM logos WHERE url=?", (url,)).fetchone()
        return row[0] if row else None

    def _cache(self, original: str, resolved: str, source: str):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT OR REPLACE INTO logos(url,resolved_url,resolved_at,source) VALUES(?,?,?,?)",
                (original, resolved, datetime.utcnow().isoformat(), source),
            )

    async def _verify(self, url: str) -> bool:
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                resp = await client.head(url, follow_redirects=True)
                ct = resp.headers.get("content-type", "")
                return resp.status_code == 200 and ("image" in ct or "svg" in ct)
        except Exception:
            return False

    def _svg(self, name: str, cat: str) -> str:
        color = COLORS.get(cat, "#555555")
        initials = "".join(w[0].upper() for w in name.split()[:2]) or "TV"
        svg = (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="120" height="68" viewBox="0 0 120 68">'
            f'<rect width="120" height="68" rx="8" fill="{color}"/>'
            f'<text x="60" y="44" text-anchor="middle" font-family="Arial,sans-serif" '
            f'font-size="24" font-weight="bold" fill="white">{initials}</text></svg>'
        )
        enc = base64.b64encode(svg.encode()).decode()
        return f"data:image/svg+xml;base64,{enc}"
