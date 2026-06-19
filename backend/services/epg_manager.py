from __future__ import annotations
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from rich.console import Console
from models.epg import Program

console = Console()

CREATE_EPG = """
CREATE TABLE IF NOT EXISTS epg_programs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    epg_id TEXT NOT NULL,
    title TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    description TEXT DEFAULT '',
    category TEXT DEFAULT '',
    rating TEXT
);
"""

SCHEDULES: dict[str, list[tuple[str, int]]] = {
    "news": [
        ("Noticiero Matutino",60),("Análisis Político",30),("Noticias del Mediodía",60),
        ("Edición Especial",30),("Noticiero Estelar",90),("Resumen del Día",30),
        ("Noticias de la Noche",60),("Últimas Noticias",60),
    ],
    "sports": [
        ("SportsCenter",60),("Fútbol en Vivo",120),("Análisis Deportivo",30),
        ("Box en Vivo",90),("Béisbol en Vivo",180),("Baloncesto",120),
        ("Deportes Total",60),("Resumen Deportivo",30),
    ],
    "movies": [
        ("Cine de Acción",120),("Clásico del Cine",120),("Cine de Comedia",110),
        ("Película Especial",130),("Cine Estelar",120),("Maratón de Cine",120),
    ],
    "kids": [
        ("Cartoon Time",30),("Mundo Animal Jr",30),("Aventuras Animadas",30),
        ("Club Infantil",60),("Dibujos Animados",30),("Series Infantiles",30),
        ("Cuentos y Colores",30),("Aprendiendo con TV",30),
    ],
    "music": [
        ("Top 40 Latinoamérica",60),("Rock Clásico",60),("Reggaeton Mix",60),
        ("Baladas Románticas",60),("Cumbia Hits",60),("Videos Musicales",120),
    ],
}
DEFAULT_SCHED = [
    ("En Vivo",60),("Programa Especial",60),("Entretenimiento",60),
    ("Variedad TV",90),("Magazin",60),("Show Estelar",90),
    ("Noche de Gala",60),("Programa Nocturno",60),
]


class EPGManager:
    def __init__(self, base_dir: Path):
        self.db_path = base_dir / "db" / "iptv.db"
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript(CREATE_EPG)

    async def refresh_all(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            channels = conn.execute(
                "SELECT id,name,category,epg_id FROM channels WHERE is_enabled=1"
            ).fetchall()

        now = datetime.utcnow().replace(minute=0, second=0, microsecond=0)
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM epg_programs")
            for ch in channels:
                epg_id = ch["epg_id"] or ch["id"]
                for p in self._mock(epg_id, ch["name"], ch["category"] or "entertainment", now):
                    conn.execute(
                        "INSERT INTO epg_programs(epg_id,title,start_time,end_time,description,category,rating) VALUES(?,?,?,?,?,?,?)",
                        (epg_id, p.title, p.start.isoformat(), p.end.isoformat(), p.description, p.category, p.rating),
                    )

        console.print(f"[green]EPG generated for {len(channels)} channels[/green]")

    def get_current(self, epg_id: str) -> Program | None:
        now = datetime.utcnow().isoformat()
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                "SELECT * FROM epg_programs WHERE epg_id=? AND start_time<=? AND end_time>? ORDER BY start_time DESC LIMIT 1",
                (epg_id, now, now),
            ).fetchone()
        return self._row(row) if row else None

    def get_next(self, epg_id: str) -> Program | None:
        now = datetime.utcnow().isoformat()
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                "SELECT * FROM epg_programs WHERE epg_id=? AND start_time>? ORDER BY start_time ASC LIMIT 1",
                (epg_id, now),
            ).fetchone()
        return self._row(row) if row else None

    def _row(self, row) -> Program:
        return Program(
            title=row["title"], description=row["description"] or "",
            start=datetime.fromisoformat(row["start_time"]),
            end=datetime.fromisoformat(row["end_time"]),
            category=row["category"] or "", rating=row["rating"], is_live=True,
        )

    def _mock(self, epg_id: str, name: str, cat: str, base: datetime) -> list[Program]:
        sched = SCHEDULES.get(cat, DEFAULT_SCHED)
        programs: list[Program] = []
        t = base - timedelta(hours=2)
        for title, mins in sched * 3:
            end = t + timedelta(minutes=mins)
            programs.append(Program(
                title=title, description=f"Transmisión en vivo de {name}",
                start=t, end=end, category=cat, rating="TV-G", is_live=True,
            ))
            t = end
            if t > base + timedelta(hours=12):
                break
        return programs
