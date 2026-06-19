# GioRoku — Premium IPTV Ecosystem for Roku

A complete IPTV platform engineered for daily household use. Aggregates, validates, and serves thousands of channels through a static JSON API consumed by a premium Roku application — no direct M3U consumption on the device.

---

## System Overview

```
IPTV Sources (M3U / Xtream / REST)
          │
          ▼
  ┌───────────────────┐
  │  Aggregation      │  Python backend, runs via GitHub Actions
  │  Engine           │
  └───────┬───────────┘
          │  validates · deduplicates · classifies · enriches
          ▼
  ┌───────────────────┐
  │  JSON API         │  Static files hosted on GitHub Pages
  │  (GitHub Pages)   │
  └───────┬───────────┘
          │
    ┌─────┴──────┐
    │            │
    ▼            ▼
  Roku App    Admin Portal
 (BrightScript) (React + TypeScript)
```

---

## Repository Structure

```
GioRoku/
├── .github/
│   └── workflows/
│       ├── daily-refresh.yml        # Nightly pipeline: fetch → validate → deploy
│       ├── validate-streams.yml     # On-demand stream health check
│       └── deploy-admin.yml         # Admin portal CI/CD
│
├── backend/                         # Python aggregation engine
│   ├── providers/                   # Provider adapter layer
│   │   ├── base.py
│   │   ├── m3u_provider.py
│   │   ├── xtream_provider.py
│   │   └── custom_api_provider.py
│   ├── services/                    # Core processing services
│   │   ├── aggregator.py
│   │   ├── validator.py
│   │   ├── deduplicator.py
│   │   ├── country_detector.py
│   │   ├── logo_resolver.py
│   │   └── epg_manager.py
│   ├── models/                      # Pydantic data models
│   │   ├── channel.py
│   │   ├── source.py
│   │   └── epg.py
│   ├── api/                         # JSON API generators
│   │   └── generator.py
│   ├── config/                      # Editable configuration
│   │   ├── sources.json
│   │   ├── categories.json
│   │   ├── countries.json
│   │   └── logo_overrides.json
│   └── requirements.txt
│
├── admin/                           # React administration portal
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Sources.tsx
│   │   │   ├── Channels.tsx
│   │   │   ├── Categories.tsx
│   │   │   ├── Logos.tsx
│   │   │   └── Health.tsx
│   │   ├── hooks/
│   │   └── services/
│   ├── package.json
│   └── vite.config.ts
│
├── roku/                            # BrightScript / SceneGraph application
│   ├── manifest
│   └── source/
│       ├── main.brs
│       ├── components/              # Reusable SceneGraph components
│       ├── screens/                 # Full-screen views
│       ├── models/                  # Data model helpers
│       └── services/               # API, storage, player services
│
├── api/                             # Generated — do not edit manually
│   └── v1/
│       ├── channels.json
│       ├── channels/
│       │   ├── page/
│       │   └── country/
│       ├── categories.json
│       ├── countries.json
│       ├── epg.json
│       └── status.json
│
└── docs/
    ├── ARCHITECTURE.md
    ├── SCHEMA.md
    ├── DATA_FLOW.md
    ├── COMPONENTS.md
    └── ROKU_NAVIGATION.md
```

---

## Documentation Index

| Document | Contents |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Full system design, principles, technology decisions |
| [SCHEMA.md](docs/SCHEMA.md) | All data models and JSON schemas |
| [DATA_FLOW.md](docs/DATA_FLOW.md) | Step-by-step data flow diagrams |
| [COMPONENTS.md](docs/COMPONENTS.md) | Component breakdown for all three subsystems |
| [ROKU_NAVIGATION.md](docs/ROKU_NAVIGATION.md) | Screen map and UX navigation tree |

---

## Development Phases

| Phase | Scope | Status |
|---|---|---|
| 1 | Architecture & Design | ✅ Complete |
| 2 | Backend Engine | Pending |
| 3 | Administration Portal | Pending |
| 4 | Roku Application | Pending |
| 5 | Deployment Configuration | Pending |
| 6 | GitHub Actions Automation | Pending |
| 7 | Testing Strategy | Pending |
