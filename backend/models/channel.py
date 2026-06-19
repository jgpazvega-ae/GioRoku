from __future__ import annotations
from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, field_validator


class StreamQuality(str, Enum):
    SD = "SD"
    HD = "HD"
    FHD = "FHD"
    UHD = "4K"


class ChannelStatus(str, Enum):
    ONLINE = "online"
    OFFLINE = "offline"
    DISABLED = "disabled"
    UNKNOWN = "unknown"


class RawChannel(BaseModel):
    """Channel record as parsed from a provider, before dedup/enrichment."""
    id: str
    source_id: str
    tvg_id: Optional[str] = None
    tvg_name: Optional[str] = None
    tvg_logo: Optional[str] = None
    group_title: Optional[str] = None
    language: Optional[str] = None
    stream_url: str
    fetched_at: datetime = datetime.utcnow()

    @field_validator("stream_url")
    @classmethod
    def validate_stream_url(cls, v: str) -> str:
        if not v.startswith(("http://", "https://", "rtmp://", "rtsp://")):
            raise ValueError(f"Invalid stream URL: {v}")
        return v


class Channel(BaseModel):
    """Deduplicated, enriched, production-ready channel record."""
    id: str
    name: str
    logo: Optional[str] = None
    category: str = "entertainment"
    category_label: str = "Entretenimiento"
    country: str = "INTL"
    country_label: str = "Internacional"
    language: str = "es"
    stream_url: str
    backup_urls: list[str] = []
    quality: StreamQuality = StreamQuality.SD
    is_online: bool = True
    is_enabled: bool = True
    is_featured: bool = False
    epg_id: Optional[str] = None
    tags: list[str] = []
    offline_count: int = 0
    last_check: Optional[datetime] = None
    last_online: Optional[datetime] = None
    response_ms: Optional[int] = None
    source_id: Optional[str] = None
    source_priority: int = 10
    override_name: Optional[str] = None
    override_logo: Optional[str] = None
    override_category: Optional[str] = None
    override_country: Optional[str] = None
    override_enabled: Optional[bool] = None

    @property
    def display_name(self) -> str:
        return self.override_name or self.name

    @property
    def effective_enabled(self) -> bool:
        if self.override_enabled is not None:
            return self.override_enabled
        return self.is_enabled

    @property
    def status(self) -> ChannelStatus:
        if not self.effective_enabled:
            return ChannelStatus.DISABLED
        return ChannelStatus.ONLINE if self.is_online else ChannelStatus.OFFLINE

    def to_api_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.display_name,
            "logo": self.override_logo or self.logo or "",
            "category": self.override_category or self.category,
            "categoryLabel": self.category_label,
            "country": self.override_country or self.country,
            "countryLabel": self.country_label,
            "language": self.language,
            "streamUrl": self.stream_url,
            "backupUrls": self.backup_urls,
            "quality": self.quality.value,
            "isOnline": self.is_online,
            "isEnabled": self.effective_enabled,
            "isFeatured": self.is_featured,
            "epgId": self.epg_id,
            "tags": self.tags,
            "offlineCount": self.offline_count,
            "lastCheck": self.last_check.isoformat() if self.last_check else None,
            "lastOnline": self.last_online.isoformat() if self.last_online else None,
            "responseMs": self.response_ms,
        }
