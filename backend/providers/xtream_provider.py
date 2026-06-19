from __future__ import annotations
import hashlib
from datetime import datetime
import httpx
from ..models.channel import RawChannel
from ..models.source import Source
from .base import BaseProvider


class XtreamProvider(BaseProvider):
    def __init__(self, source: Source):
        super().__init__(source)
        self._base = source.url.rstrip("/")
        self._user = source.username or ""
        self._pass = source.password or ""

    async def get_channels(self) -> list[RawChannel]:
        streams = await self._api("get_live_streams")
        categories = await self._api("get_live_categories")
        cat_map = {c["category_id"]: c["category_name"] for c in categories}
        channels: list[RawChannel] = []
        for s in streams:
            try:
                url = f"{self._base}/live/{self._user}/{self._pass}/{s['stream_id']}.m3u8"
                channels.append(RawChannel(
                    id=hashlib.md5(url.encode()).hexdigest(),
                    source_id=self.id,
                    tvg_id=s.get("epg_channel_id") or str(s.get("stream_id", "")),
                    tvg_name=s.get("name"),
                    tvg_logo=s.get("stream_icon"),
                    group_title=cat_map.get(s.get("category_id", ""), ""),
                    stream_url=url,
                    fetched_at=datetime.utcnow(),
                ))
            except Exception:
                continue
        return channels

    async def get_categories(self) -> list[str]:
        cats = await self._api("get_live_categories")
        return [c["category_name"] for c in cats]

    async def _api(self, action: str) -> list[dict]:
        url = f"{self._base}/player_api.php"
        params = {"username": self._user, "password": self._pass, "action": action}
        async with httpx.AsyncClient(timeout=30, follow_redirects=True) as client:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            return resp.json()
