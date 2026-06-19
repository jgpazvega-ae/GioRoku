from __future__ import annotations
import json
import re
import sqlite3
import unicodedata
from pathlib import Path
from rich.console import Console

console = Console()

COUNTRY_KEYWORDS: dict[str, list[str]] = {
    "MX": ["mexico","mexicana","mexicano","azteca","televisa","multimedios","imagen",
           "canal 5","canal 7","canal 9","canal 11","cadenatres","tv azteca","once tv",
           "efekto","excelsior","milenio","foro tv","telemax","cablemás","megacable",
           "totalplay","tdmax","tlnovelas mx","galavision mx","unitv"],
    "AR": ["argentina","argentino","canal 13 ar","canal 7 ar","telefe","elnueve",
           "canal 26","a24","tn noticias","cronica tv","canal america","metro ar",
           "c5n","infobae tv","canal rural","disney channel ar","espn ar"],
    "CO": ["colombia","colombiana","colombiano","caracol tv","rcn","canal uno",
           "señal colombia","telecaribe","telepacifico","telecafe","teleantioquia",
           "telemedellín","city tv","canal institucional","teleislas","noticias rcn"],
    "CL": ["chile","chilena","chileno","canal 13 cl","mega chile","chv","chilevision",
           "t13","tvn","telecanal","uctv","biobiotv","24horas cl","la red","cooperativa tv"],
    "PE": ["peru","perú","peruana","peruano","america tv pe","andina television",
           "rpptv","latina tv","global tv pe","panamericana","canal n","tv peru","willax"],
    "UY": ["uruguay","uruguaya","uruguayo","canal 10 uy","canal 12 uy","monte carlo tv",
           "teledoce","tnu uy","tv libre uy"],
    "PY": ["paraguay","paraguaya","paraguayo","canal 13 py","rpc py","telefuturo",
           "c9n py","canal 2 py","tigo sports py"],
    "EC": ["ecuador","ecuatoriana","ecuatoriano","teleamazonas","ecuavisa","rts ecuador",
           "tc television","canal uno ec","gama tv","televistazo"],
    "BO": ["bolivia","boliviana","boliviano","unitel","red tv bo","canal 36 bo",
           "atb bo","red uno bo","gigavision bo"],
    "VE": ["venezuela","venezolana","venezolano","televen","venevision","globovision",
           "viv venezuela","tves ve","trc ve","vale tv ve"],
    "CA": ["centroamerica","costa rica","guatemala","honduras","el salvador","nicaragua",
           "panama","teletica","repretel","canal 7 cr","tcs salvadoreño"],
    "US_ES": ["univision","telemundo","entravision","estrella tv","hitn","latv",
              "america teve","tv azteca us","mexicana tv us"],
}

TVG_PREFIXES: dict[str, str] = {
    "mx_":"MX","ar_":"AR","co_":"CO","cl_":"CL","pe_":"PE",
    "uy_":"UY","py_":"PY","ec_":"EC","bo_":"BO","ve_":"VE","us_":"US_ES",
}

CCTLD: dict[str, str] = {
    ".mx":"MX",".com.mx":"MX",".ar":"AR",".com.ar":"AR",".co":"CO",".com.co":"CO",
    ".cl":"CL",".pe":"PE",".com.pe":"PE",".uy":"UY",".com.uy":"UY",
    ".py":"PY",".ec":"EC",".com.ec":"EC",".bo":"BO",".ve":"VE",".com.ve":"VE",
    ".cr":"CA",".gt":"CA",".hn":"CA",".sv":"CA",".ni":"CA",".pa":"CA",
}


def _n(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r'\s+', ' ', s).strip().lower()


class CountryDetector:
    def __init__(self, base_dir: Path):
        self.db_path = base_dir / "db" / "iptv.db"
        self.config_dir = base_dir / "config"
        self._kw = self._load_config()

    def _load_config(self) -> dict[str, list[str]]:
        path = self.config_dir / "countries.json"
        merged = dict(COUNTRY_KEYWORDS)
        if path.exists():
            with open(path) as f:
                for item in json.load(f):
                    code = item.get("code", "")
                    if code and item.get("keywords"):
                        merged.setdefault(code, []).extend(item["keywords"])
        return merged

    def detect(self, tvg_id: str | None, name: str | None, group: str | None, url: str | None) -> str:
        tid = (tvg_id or "").lower()
        n = _n(name or "")
        g = _n(group or "")

        for prefix, code in TVG_PREFIXES.items():
            if tid.startswith(prefix):
                return code

        for code, kws in self._kw.items():
            for kw in kws:
                if _n(kw) in g:
                    return code

        for code, kws in self._kw.items():
            for kw in kws:
                if _n(kw) in n:
                    return code

        if url:
            clean = url.split("?")[0]
            for tld, code in CCTLD.items():
                if clean.endswith(tld) or f"{tld}/" in clean:
                    return code

        return "INTL"

    def classify_all(self) -> int:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            channels = conn.execute(
                "SELECT id,name,epg_id,stream_url FROM channels WHERE override_country IS NULL"
            ).fetchall()
            for ch in channels:
                raw = conn.execute(
                    "SELECT group_title FROM raw_channels WHERE stream_url=?", (ch["stream_url"],)
                ).fetchone()
                country = self.detect(
                    tvg_id=ch["epg_id"],
                    name=ch["name"],
                    group=raw["group_title"] if raw else None,
                    url=ch["stream_url"],
                )
                conn.execute("UPDATE channels SET country=? WHERE id=?", (country, ch["id"]))
            return conn.execute("SELECT COUNT(*) FROM channels").fetchone()[0]
