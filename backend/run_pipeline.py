"""
GioRoku IPTV Pipeline

Usage:
    python run_pipeline.py                     # all stages
    python run_pipeline.py --stage fetch
    python run_pipeline.py --stage validate --country MX
    python run_pipeline.py --stage generate --dry-run
"""
from __future__ import annotations
import asyncio
import sys
from pathlib import Path

import click
from rich.console import Console

sys.path.insert(0, str(Path(__file__).parent))

from services.aggregator import Aggregator
from services.validator import StreamValidator
from services.deduplicator import Deduplicator
from services.country_detector import CountryDetector
from services.logo_resolver import LogoResolver
from services.epg_manager import EPGManager
from api.generator import APIGenerator

console = Console()
STAGES = ["fetch", "validate", "deduplicate", "classify", "enrich", "generate"]


@click.command()
@click.option("--stage", default="all", help=f"Stage(s): all | {' | '.join(STAGES)}")
@click.option("--country", default=None, help="Filter by country code (validate only)")
@click.option("--dry-run", is_flag=True, help="Skip writing output files")
def main(stage: str, country: str | None, dry_run: bool):
    """GioRoku IPTV aggregation pipeline."""
    console.rule("[bold blue]GioRoku Pipeline[/bold blue]")
    stages = STAGES if stage == "all" else [s.strip() for s in stage.split(",")]
    for s in stages:
        if s not in STAGES:
            console.print(f"[red]Unknown stage: {s}[/red]")
            sys.exit(1)
    asyncio.run(_run(stages, country, dry_run))


async def _run(stages: list[str], country: str | None, dry_run: bool):
    base = Path(__file__).parent

    if "fetch" in stages:
        console.rule("1 — Fetch")
        raw = await Aggregator(base).run()
        console.print(f"[green]{len(raw)} raw channels fetched[/green]")

    if "validate" in stages:
        console.rule("2 — Validate")
        results = await StreamValidator(base).validate_all(country)
        online = sum(1 for r in results if r.is_online)
        console.print(f"[green]{online}/{len(results)} online[/green]")

    if "deduplicate" in stages:
        console.rule("3 — Deduplicate")
        n = Deduplicator(base).run()
        console.print(f"[green]{n} unique channels[/green]")

    if "classify" in stages:
        console.rule("4 — Classify")
        n = CountryDetector(base).classify_all()
        console.print(f"[green]{n} channels classified[/green]")

    if "enrich" in stages:
        console.rule("5 — Enrich")
        await LogoResolver(base).resolve_all()
        await EPGManager(base).refresh_all()

    if "generate" in stages:
        console.rule("6 — Generate API")
        stats = APIGenerator(base, dry_run=dry_run).write_all()
        console.print(f"[green]{stats['total_files']} files written[/green]")

    console.rule("[bold green]Done[/bold green]")


if __name__ == "__main__":
    main()
