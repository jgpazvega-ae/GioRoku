from __future__ import annotations
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class Program(BaseModel):
    title: str
    description: str = ""
    start: datetime
    end: datetime
    category: str = ""
    rating: Optional[str] = None
    episode_title: Optional[str] = None
    season: Optional[int] = None
    episode: Optional[int] = None
    is_live: bool = False
    poster_url: Optional[str] = None

    @property
    def duration_minutes(self) -> int:
        return int((self.end - self.start).total_seconds() / 60)

    @property
    def progress_percent(self) -> float:
        now = datetime.utcnow()
        if now < self.start:
            return 0.0
        if now > self.end:
            return 100.0
        elapsed = (now - self.start).total_seconds()
        total = (self.end - self.start).total_seconds()
        return round(elapsed / total * 100, 1)

    def to_api_dict(self) -> dict:
        return {
            "title": self.title,
            "description": self.description,
            "start": self.start.isoformat(),
            "end": self.end.isoformat(),
            "category": self.category,
            "rating": self.rating,
            "durationMinutes": self.duration_minutes,
            "progressPercent": self.progress_percent,
            "isLive": self.is_live,
            "posterUrl": self.poster_url,
        }


class EPGSchedule(BaseModel):
    epg_id: str
    current: Optional[Program] = None
    next: Optional[Program] = None
    programs: list[Program] = []
