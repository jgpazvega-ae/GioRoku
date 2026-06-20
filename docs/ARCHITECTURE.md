# GioRoku — Technical Architecture

## 1. Design Principles

| Principle | Implementation |
|---|---|
| Roku receives zero raw M3U | All playlist work happens server-side; device only fetches JSON |
| Static-first API | GitHub Pages hosts pre-generated JSON — no running server, no cost |
| Fail gracefully | Every offline stream is caught before it reaches the device |
| Incremental updates | JSON files are diff-friendly; unchanged channels keep their IDs |
| Operator control | Admin portal lets a human override any automated decision |
| Latin America first | Country classifier is tuned for MX/AR/CO/CL/PE and 8 more |

---

## 2. Technology Decisions

### Backend Engine
- **Python 3.11** — mature async support, excellent HTTP/M3U parsing libraries
- **Pydantic v2** — typed data models, automatic validation, JSON serialization
- **httpx + asyncio** — concurrent stream validation (hundreds in parallel)
- **SQLite** — lightweight persistence for channel state between pipeline runs
- **No web framework** — the "API" is static JSON files, not a running server

### Administration Portal
- **React 18 + TypeScript** — component model fits the dashboard UI
- **Vite** — fast build, good GitHub Pages compatibility
- **TanStack Query** — server state, polling, background refresh
- **Tailwind CSS** — utility-first, consistent dark theme
- **Recharts** — health monitoring graphs, uptime charts

### Roku Application
- **SceneGraph XML** — all UI components declared as XML nodes
- **BrightScript** — business logic, API calls, state management
- **roSGNode Task** — background threads for API fetching and stream validation
- **roChannelStore / roRegistrySection** — favorites and settings persistence

### Hosting & Automation
- **GitHub Pages** — free, globally CDN-backed static hosting for the JSON API
- **GitHub Actions** — nightly cron pipeline, no external CI cost
- **GitHub repository** — sources.json is the single source of truth for provider config

---

## 3. Core Architecture

### 3.1 Provider Abstraction Layer

Every IPTV source implements the `BaseProvider` interface. Adding a new source type requires only a new adapter — no changes to the pipeline.

```
BaseProvider (abstract)
│
├── M3UProvider          reads remote or local .m3u/.m3u8 files
├── XtreamProvider       speaks Xtream Codes API protocol
├── CustomAPIProvider    configurable REST adapter
└── [Future]            Stalker Portal, TVAPI, etc.
```

**Interface contract:**

```
BaseProvider
  .id          → str
  .name        → str
  .source_type → SourceType enum
  .get_channels()    → AsyncIterator[RawChannel]
  .get_categories()  → list[str]
  .refresh()         → RefreshResult
  .is_healthy()      → bool
```

### 3.2 Pipeline Stages

The nightly GitHub Actions workflow runs these stages sequentially. Each stage reads from and writes to the SQLite database. The final stage writes the static JSON files.

```
Stage 1 — FETCH
  For each enabled source:
    provider.get_channels() → RawChannel[]
    Store raw records with source_id foreign key

Stage 2 — VALIDATE
  For each channel where last_check > 24h ago:
    HEAD request to stream URL (5s timeout)
    Update: is_online, response_ms, last_check, offline_count
    Mark disabled if offline_count >= 7

Stage 3 — DEDUPLICATE
  Group by tvg_id (exact match)
  Group by name similarity (Levenshtein ≥ 85%)
  Group by logo hash similarity
  Within each group: keep highest-priority source

Stage 4 — CLASSIFY
  For each channel:
    country_detector.detect(name, group, language, tvg_id)
    → CountryCode or "INTL"

Stage 5 — ENRICH
  For each channel:
    logo_resolver.resolve(tvg_logo, name, tvg_id)
    epg_manager.get_current_program(tvg_id)

Stage 6 — GENERATE
  api_generator.write_all()
    → /api/v1/channels.json
    → /api/v1/channels/page/{n}.json
    → /api/v1/channels/country/{code}.json
    → /api/v1/categories.json
    → /api/v1/countries.json
    → /api/v1/epg.json
    → /api/v1/status.json

Stage 7 — DEPLOY
  git add api/
  git commit
  GitHub Pages auto-publishes
```

### 3.3 Country Classifier

Uses a layered scoring system. The first layer to produce a confident match wins.

```
Layer 1: tvg-id prefix match
  e.g.  "mx_televisa" → MX

Layer 2: group-title keyword match
  e.g.  "Mexico | Entertainment" → MX
  e.g.  "Señal Colombia" → CO

Layer 3: name keyword match
  Dictionaries per country (500+ patterns)
  e.g.  "Azteca", "Multimedios", "Canal 5" → MX
  e.g.  "Canal 13", "Mega", "CHV" → CL

Layer 4: language + stream host heuristics
  e.g.  language=es + host in .mx domain → MX

Layer 5: Fallback → INTL
```

**Supported countries:**

| Code | Country |
|---|---|
| MX | Mexico |
| AR | Argentina |
| CO | Colombia |
| CL | Chile |
| PE | Peru |
| UY | Uruguay |
| PY | Paraguay |
| EC | Ecuador |
| BO | Bolivia |
| VE | Venezuela |
| CA | Central America (composite) |
| US_ES | United States (Spanish) |
| INTL | International / Unclassified |

### 3.4 Logo Resolver

```
Resolution priority:

1. logo_overrides.json  (operator-curated, highest trust)
2. tvg-logo from M3U    (source-provided)
3. Internal logo DB     (curated logos shipped with repo)
4. Clearart / Fanart.tv public API (by channel name)
5. Generic placeholder  (category-colored SVG fallback)

All resolved logos are stored as absolute HTTPS URLs.
The Roku app never fetches logos at resolution time — they are pre-resolved.
```

### 3.5 EPG Manager

EPG is architecturally supported but uses mock data in Phase 2. The interface is stable so XMLTV integration can be added in a future phase without changing downstream consumers.

```
EPGManager
  .get_current_program(epg_id)  → Program | None
  .get_schedule(epg_id, hours)  → list[Program]
  .refresh_all()                → void

Program {
  title: str
  description: str
  start: datetime
  end: datetime
  category: str
  rating: str | None
}
```

### 3.6 Deduplication Engine

```
Input: list[RawChannel] from all sources

Step 1 — Exact key dedup
  Key = normalize(tvg_id)
  Within group: rank by source priority, keep first

Step 2 — Fuzzy name dedup
  Normalize names: lowercase, remove accents, strip "HD"/"FHD"/"4K"
  Levenshtein distance ≤ 15% of length → duplicate candidate
  Within group: keep highest source priority

Step 3 — Logo hash dedup (optional, expensive)
  Download logo, compute perceptual hash
  phash distance ≤ 10 → same channel
  Run only on unresolved duplicates from steps 1-2

Output: list[Channel] with duplicates collapsed, best source kept
```

### 3.7 Validation Engine

```
Concurrency: 50 simultaneous checks (configurable)

For each channel:
  1. DNS resolution check
  2. HTTP HEAD to stream URL
     timeout: 5 seconds
     follow redirects: yes (max 3)
  3. If HEAD fails: HTTP GET with Range: bytes=0-1023
  4. Parse Content-Type
     video/mp2t       → valid HLS/MPEG-TS
     application/x-mpegURL → valid HLS
     audio/*          → radio, flag separately
     text/html        → likely dead (error page)
  5. Record result

Offline threshold: 7 consecutive failures
  → channel.is_enabled = false
  → excluded from JSON API
  → still visible in admin portal with status=DISABLED
```

---

## 4. JSON API Specification

All files are UTF-8 JSON. Generated nightly, served from GitHub Pages.

### Base URL

```
https://{user}.github.io/GioRoku/api/v1/
```

### Endpoints

| Path | Description | Paginated |
|---|---|---|
| `/status.json` | Pipeline last run, counts | No |
| `/channels.json` | All enabled channels | No (summary only) |
| `/channels/page/{n}.json` | 100 channels per page | Yes |
| `/channels/country/{code}.json` | Channels filtered by country | No |
| `/channels/category/{slug}.json` | Channels filtered by category | No |
| `/categories.json` | All categories with counts | No |
| `/countries.json` | All countries with counts | No |
| `/epg.json` | Current+next program for all channels | No |
| `/epg/{epg_id}.json` | Schedule for one channel | No |

### Caching headers (served by GitHub Pages)

GitHub Pages serves with `Cache-Control: max-age=600`. The Roku app additionally caches in memory for the session duration.

---

## 5. Data Persistence

The pipeline uses SQLite at `backend/db/iptv.db`. This file is **not** committed to the repository — it is created fresh on first run and rebuilt incrementally by the GitHub Actions runner using the persistent cache.

```
Tables:
  sources        — provider configuration (mirrors sources.json)
  raw_channels   — every channel seen from any source
  channels       — deduplicated, validated, enriched master list
  channel_checks — time-series of validation results
  logos          — logo cache (url → resolved_url + hash)
  epg_programs   — EPG schedule data
```

State that must survive pipeline runs:
- `offline_count` per channel (counts consecutive failures)
- `is_enabled` overrides (set by operator via admin portal)
- Logo resolution cache (avoids re-fetching)

The admin portal writes to `backend/config/*.json` files, which are committed. The pipeline reads these on startup to apply operator overrides.

---

## 6. Security Considerations

- The JSON API is read-only and publicly accessible — contains no credentials
- Stream URLs in the API are third-party URLs; users understand they are public streams
- The admin portal does not have a backend — it writes changes as a git commit (operator must be authenticated via GitHub)
- No user credentials stored anywhere
- No server to compromise — attack surface is limited to GitHub Actions runners

---

## 7. Performance Targets

| Metric | Target |
|---|---|
| Channels supported | 10,000+ |
| Pipeline runtime | < 30 min |
| Validation concurrency | 50 simultaneous |
| API page size | 100 channels |
| Roku initial load | < 3 seconds |
| Roku channel grid scroll | 60 fps |
| Admin portal load | < 2 seconds |

---

## 8. Extensibility Points

| Extension | How to add |
|---|---|
| New IPTV source type | Implement `BaseProvider`, register in `sources.json` |
| New country | Add patterns to `countries.json`, no code change |
| XMLTV EPG | Implement `XMLTVEPGSource`, wire into `EPGManager` |
| Push notifications | Add GitHub Actions step to POST to Pushover/Ntfy |
| Multi-user favorites | Replace `roRegistrySection` with cloud sync service |
| DRM streams | Add Widevine/PlayReady key management layer |
