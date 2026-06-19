from __future__ import annotations
import abc
import time
from ..models.channel import RawChannel
from ..models.source import Source, RefreshResult


class BaseProvider(abc.ABC):
    def __init__(self, source: Source):
        self.source = source

    @property
    def id(self) -> str:
        return self.source.id

    @property
    def name(self) -> str:
        return self.source.name

    @abc.abstractmethod
    async def get_channels(self) -> list[RawChannel]: ...

    @abc.abstractmethod
    async def get_categories(self) -> list[str]: ...

    async def refresh(self) -> RefreshResult:
        start = time.monotonic()
        try:
            channels = await self.get_channels()
            return RefreshResult(
                source_id=self.id,
                success=True,
                channel_count=len(channels),
                duration_seconds=time.monotonic() - start,
            )
        except Exception as e:
            return RefreshResult(
                source_id=self.id,
                success=False,
                error=str(e),
                duration_seconds=time.monotonic() - start,
            )

    async def is_healthy(self) -> bool:
        try:
            result = await self.refresh()
            return result.success and result.channel_count > 0
        except Exception:
            return False
