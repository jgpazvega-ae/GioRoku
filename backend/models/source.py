from __future__ import annotations
from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel


class SourceType(str, Enum):
    M3U = "m3u"
    XTREAM = "xtream"
    CUSTOM_API = "custom_api"


class SourceOptions(BaseModel):
    timeout_seconds: int = 30
    encoding: str = "utf-8"
    user_agent: str = "GioRoku/1.0"
    verify_ssl: bool = True
    headers: dict[str, str] = {}


class Source(BaseModel):
    id: str
    name: str
    type: SourceType
    url: str
    username: Optional[str] = None
    password: Optional[str] = None
    priority: int = 10
    is_enabled: bool = True
    refresh_interval_hours: int = 24
    last_refresh: Optional[datetime] = None
    last_channel_count: int = 0
    options: SourceOptions = SourceOptions()
    channels_path: Optional[str] = None
    mapping: Optional[dict[str, str]] = None


class RefreshResult(BaseModel):
    source_id: str
    success: bool
    channel_count: int = 0
    error: Optional[str] = None
    duration_seconds: float = 0.0
