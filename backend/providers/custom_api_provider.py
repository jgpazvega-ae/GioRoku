from __future__ import annotations
import hashlib
from datetime import datetime
import httpx
from models.channel import RawChannel
from models.source import Source
from .base import BaseProvider


class CustomAPIProvider(BaseProvider):
    def __init__(self, source: Source):
        super().__init__(source)
        self._mapping = source.mapping or {}
        self._channels_path = source.channels_path or "$.data"

    async def get_channels(self) -> list[RawChannel]:
        data = await self._fetch()
        items = self._extract(data, self._channels_path)
        channels: list[RawChannel] = []
        for item in items:
            try:
                stream_url = self._field(item, "streamUrl") or ""
                if not stream_url:
                    continue
                channels.append(RawChannel(
                    id=hashlib.md5(f"{self.id}::{stream_url}".encode()).hexdigest(),
                    source_id=self.id,
                    tvg_id=self._field(item, "tvgId"),
                    tvg_name=self._field(item, "name"),
                    tvg_logo=self._field(item, "logo"),
                    group_title=self._field(item, "group"),
                    language=self._field(item, "language"),
                    stream_url=stream_url,
                    fetched_at=datetime.utcnow(),
                ))
            except Exception:
                continue
        return channels

    async def get_categories(self) -> list[str]:
        channels = await self.get_channels()
        return sorted({c.group_title for c in channels if c.group_title})

    async def _fetch(self) -> dict:
        headers = {"User-Agent": self.source.options.user_agent, **self.source.options.headers}
        async with httpx.AsyncClient(timeout=self.source.options.timeout_seconds) as client:
            resp = await client.get(self.source.url, headers=headers)
            resp.raise_for_status()
            return resp.json()

    def _field(self, item: dict, logical: str) -> str | None:
        raw_key = self._mapping.get(logical)
        if not raw_key:
            return None
        val = item
        for part in raw_key.split("."):
            val = val.get(part) if isinstance(val, dict) else None
        return str(val) if val is not None else None

    def _extract(self, data, path: str) -> list:
        path = path.lstrip("$.")
        val = data
        for part in path.split("."):
            val = val.get(part, []) if isinstance(val, dict) else []
        return val if isinstance(val, list) else []
