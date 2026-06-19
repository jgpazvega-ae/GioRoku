from .base import BaseProvider
from .m3u_provider import M3UProvider
from .xtream_provider import XtreamProvider
from .custom_api_provider import CustomAPIProvider
from ..models.source import SourceType

PROVIDER_MAP = {
    SourceType.M3U: M3UProvider,
    SourceType.XTREAM: XtreamProvider,
    SourceType.CUSTOM_API: CustomAPIProvider,
}


def create_provider(source) -> BaseProvider:
    cls = PROVIDER_MAP.get(source.type)
    if cls is None:
        raise ValueError(f"Unknown source type: {source.type}")
    return cls(source)
