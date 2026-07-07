from __future__ import annotations
import hashlib
import re
from datetime import datetime
import httpx
from models.channel import RawChannel
from models.source import Source
from .base import BaseProvider

ATTR_RE = re.compile(r'(?P<key>[\w-]+)="(?P<value>[^"]*)"')


def _split_extinf(line: str) -> tuple[str, str]:
    """Split an #EXTINF line into (attrs_blob, display_name).

    The name is whatever follows the first comma that is OUTSIDE quotes — a
    naive split on the first comma breaks on attributes whose value contains
    one, e.g. user-agent="...AppleWebKit (KHTML, like Gecko)...".
    """
    in_quote = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_quote = not in_quote
        elif ch == "," and not in_quote:
            return line[:i], line[i + 1:].strip()
    return line, ""


class M3UProvider(BaseProvider):
    def __init__(self, source: Source):
        super().__init__(source)

    async def get_channels(self) -> list[RawChannel]:
        content = await self._download()
        return self._filter(self._parse(content))

    def _filter(self, channels: list[RawChannel]) -> list[RawChannel]:
        langs = {l.lower() for l in self.source.options.filter_languages}
        groups = [g.lower() for g in self.source.options.filter_groups]
        if not langs and not groups:
            return channels
        kept = []
        for ch in channels:
            if langs:
                # tvg-language may hold several values ("Spanish;English") or be absent
                ch_langs = {p.strip().lower() for p in (ch.language or "").replace(";", ",").split(",") if p.strip()}
                if not ch_langs & langs:
                    continue
            if groups:
                g = (ch.group_title or "").lower()
                if not any(sub in g for sub in groups):
                    continue
            kept.append(ch)
        return kept

    async def get_categories(self) -> list[str]:
        channels = await self.get_channels()
        return sorted({c.group_title for c in channels if c.group_title})

    async def _download(self) -> str:
        headers = {"User-Agent": self.source.options.user_agent, **self.source.options.headers}
        async with httpx.AsyncClient(
            timeout=self.source.options.timeout_seconds,
            follow_redirects=True,
            verify=self.source.options.verify_ssl,
        ) as client:
            resp = await client.get(self.source.url, headers=headers)
            resp.raise_for_status()
            return resp.content.decode(self.source.options.encoding, errors="replace")

    def _parse(self, content: str) -> list[RawChannel]:
        channels: list[RawChannel] = []
        lines = content.splitlines()
        attrs: dict = {}
        name = ""
        for line in lines:
            line = line.strip()
            if line.startswith("#EXTINF:"):
                attrs, name = {}, ""
                attrs_blob, name = _split_extinf(line)
                for am in ATTR_RE.finditer(attrs_blob):
                    attrs[am.group("key").lower()] = am.group("value")
            elif line and not line.startswith("#"):
                try:
                    channels.append(RawChannel(
                        id=_uid(self.id, line),
                        source_id=self.id,
                        tvg_id=attrs.get("tvg-id") or None,
                        tvg_name=attrs.get("tvg-name") or name or None,
                        tvg_logo=attrs.get("tvg-logo") or None,
                        group_title=attrs.get("group-title") or None,
                        language=attrs.get("tvg-language") or attrs.get("tvg-lang") or None,
                        stream_url=line,
                        fetched_at=datetime.utcnow(),
                    ))
                except Exception:
                    pass
                attrs, name = {}, ""
        return channels


def _uid(source_id: str, url: str) -> str:
    return hashlib.md5(f"{source_id}::{url}".encode()).hexdigest()
