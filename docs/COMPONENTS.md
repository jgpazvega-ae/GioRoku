# GioRoku — Component Reference

## 1. Backend Components

### 1.1 Provider Layer

```
backend/providers/
│
├── base.py
│   BaseProvider (abstract class)
│   ├── Attributes: id, name, type, priority, is_enabled
│   ├── get_channels() → AsyncIterator[RawChannel]
│   ├── get_categories() → list[str]
│   ├── refresh() → RefreshResult
│   ├── is_healthy() → bool
│   └── _get_options() → dict
│
├── m3u_provider.py
│   M3UProvider(BaseProvider)
│   ├── _download_playlist() → str
│   ├── _parse_m3u(content: str) → list[RawChannel]
│   ├── _parse_extinf(line: str) → dict[str, str]
│   └── _detect_encoding(bytes) → str
│
├── xtream_provider.py
│   XtreamProvider(BaseProvider)
│   ├── _authenticate() → XtreamSession
│   ├── _get_live_streams() → list[dict]
│   ├── _get_categories() → list[dict]
│   └── _map_to_raw_channel(stream: dict) → RawChannel
│
└── custom_api_provider.py
    CustomAPIProvider(BaseProvider)
    ├── _fetch_endpoint() → dict
    ├── _apply_mapping(data: dict) → RawChannel
    └── _resolve_jsonpath(data: dict, path: str) → Any
```

### 1.2 Service Layer

```
backend/services/
│
├── aggregator.py
│   Aggregator
│   ├── run() → AggregationResult
│   ├── _load_sources() → list[BaseProvider]
│   ├── _fetch_all() → list[RawChannel]
│   └── _merge_results() → list[RawChannel]
│
├── validator.py
│   StreamValidator
│   ├── validate_all(channels: list[Channel]) → list[ValidationResult]
│   ├── validate_one(channel: Channel) → ValidationResult
│   ├── _head_request(url: str) → Response | None
│   ├── _range_request(url: str) → Response | None
│   └── _classify_content_type(ct: str) → StreamType
│
│   ValidationResult { channel_id, is_online, response_ms, http_status, error }
│   StreamType enum { HLS, MPEG_TS, RADIO, ERROR_PAGE, UNKNOWN }
│
├── deduplicator.py
│   Deduplicator
│   ├── deduplicate(channels: list[RawChannel]) → list[Channel]
│   ├── _exact_key_group(channels) → dict[str, list[RawChannel]]
│   ├── _fuzzy_name_group(channels) → dict[str, list[RawChannel]]
│   └── _normalize_name(name: str) → str
│
├── country_detector.py
│   CountryDetector
│   ├── detect(channel: RawChannel) → str  (ISO code)
│   ├── _check_tvg_id_prefix(tvg_id: str) → str | None
│   ├── _check_group_title(group: str) → str | None
│   ├── _check_name_keywords(name: str) → str | None
│   ├── _check_stream_domain(url: str) → str | None
│   └── _load_country_config() → dict
│
├── logo_resolver.py
│   LogoResolver
│   ├── resolve(channel: Channel) → str  (URL)
│   ├── _check_override(channel_id: str) → str | None
│   ├── _check_cache(original_url: str) → str | None
│   ├── _verify_url(url: str) → bool
│   ├── _lookup_internal_db(name: str, tvg_id: str) → str | None
│   ├── _fetch_clearart(name: str) → str | None
│   └── _generate_svg_fallback(channel: Channel) → str
│
└── epg_manager.py
    EPGManager
    ├── get_current_program(epg_id: str) → Program | None
    ├── get_next_program(epg_id: str) → Program | None
    ├── get_schedule(epg_id: str, hours: int) → list[Program]
    ├── refresh_all() → None
    └── _mock_program(channel: Channel) → Program
```

### 1.3 API Generator

```
backend/api/generator.py
  APIGenerator
  ├── write_all(channels, categories, countries) → None
  ├── write_status(stats: Stats) → None
  ├── write_paginated_channels(channels, page_size=100) → None
  ├── write_by_country(channels, countries) → None
  ├── write_by_category(channels, categories) → None
  ├── write_categories(categories) → None
  ├── write_countries(countries) → None
  └── write_epg(programs) → None
```

---

## 2. Admin Portal Components

### 2.1 Pages

```
admin/src/pages/
│
├── Dashboard.tsx
│   Shows: total channels, online %, offline %, last update time,
│           source health cards, recent activity feed
│   Hooks: useStatus(), useSources()
│   Refreshes every 60 seconds
│
├── Sources.tsx
│   Shows: source list table with status badges
│   Actions: Add Source modal, Edit Source modal,
│             Enable/Disable toggle, Delete with confirm
│   Supports: M3U, Xtream, Custom API source types
│
├── Channels.tsx
│   Shows: searchable/filterable channel table
│   Filters: country, category, status (online/offline/disabled)
│   Actions per row:
│     Enable/Disable, Set Featured, Override Name,
│     Override Category, Override Country, Replace Logo
│   Bulk actions: Enable All, Disable All Selected
│
├── Categories.tsx
│   Shows: category list with channel counts
│   Actions: Reorder (drag), Edit label, Edit keywords, Change color
│
├── Logos.tsx
│   Shows: channels with logo thumbnails
│   Filter: missing logos, placeholder logos, broken logos
│   Actions: Upload logo, Set URL, Auto-resolve selected
│
└── Health.tsx
    Shows: channel validation status dashboard
    Timeline chart: online % over 7 days
    Table: offline channels sorted by offline_count desc
    Actions: Trigger manual validation run
```

### 2.2 Shared Components

```
admin/src/components/
│
├── layout/
│   ├── Sidebar.tsx          Left nav: icons + labels for each page
│   ├── TopBar.tsx           Status bar: last updated, refresh button
│   └── Layout.tsx           Shell wrapper
│
├── data-display/
│   ├── StatCard.tsx         Single metric card (count + label + trend)
│   ├── StatusBadge.tsx      Online/Offline/Disabled colored pill
│   ├── CountryFlag.tsx      Flag emoji + country name
│   ├── ChannelCard.tsx      Logo + name + status for grid view
│   └── UptimeChart.tsx      Recharts line chart for 7-day uptime
│
├── forms/
│   ├── SourceForm.tsx       Add/edit source (type-adaptive fields)
│   ├── ChannelOverrideForm.tsx  Override name/category/country
│   └── LogoInput.tsx        URL field + drag-drop upload + preview
│
└── feedback/
    ├── ConfirmDialog.tsx    Destructive action confirmation
    ├── Toast.tsx            Success/error notifications
    └── EmptyState.tsx       No results placeholder
```

### 2.3 Hooks

```
admin/src/hooks/
│
├── useStatus.ts       GET /api/v1/status.json, refresh 60s
├── useChannels.ts     Paginated channel list, filter/sort client-side
├── useSources.ts      Source list from backend/config/sources.json
├── useCategories.ts   Categories from /api/v1/categories.json
├── useCountries.ts    Countries from /api/v1/countries.json
├── useHealth.ts       Recent channel_checks from /api/v1/status.json
└── useGitHub.ts       GitHub API wrapper for config file writes
```

### 2.4 Services

```
admin/src/services/
│
├── api.ts             Fetch wrapper for /api/v1/* endpoints
├── github.ts          GitHub Contents API: read/write config files
└── config.ts          App configuration (base URL, GitHub repo, etc.)
```

---

## 3. Roku Application Components

### 3.1 Screens (full-screen SceneGraph scenes)

```
roku/source/screens/
│
├── SplashScreen.xml + .brs
│   Shows: GioRoku logo, loading bar
│   Transitions: fade to HomeScreen on data ready
│
├── HomeScreen.xml + .brs
│   Top nav bar: Home | Live TV | Guide | Favorites | Search | Settings
│   Content rows: Continue Watching, Favorites, Featured,
│                 Categories, Countries, Trending
│   Handles: row selection → drill-down screen
│
├── LiveTVScreen.xml + .brs
│   Filter row: All | By Country | By Category
│   Main grid: ChannelGrid component
│   Handles: channel select → PlayerScreen
│
├── GuideScreen.xml + .brs
│   Left column: channel list with logos (24 visible)
│   Top row: time slots (30-min blocks, 3 hours visible)
│   Grid: program cells spanning time blocks
│   Current time: vertical red line indicator
│   Handles: program select → PlayerScreen
│             channel focus → scroll program grid
│             left/right fast scroll: 30 min per press
│             up/down Page: 6 channels per page
│
├── PlayerScreen.xml + .brs
│   Full-screen video via roVideoPlayer
│   Overlay (auto-hide 5s):
│     Top-left: channel logo + name
│     Bottom: progress bar, program title, next program
│   Controls overlay (OK to show):
│     Channel Up/Down arrows
│     Favorite toggle heart
│     Info button → program detail
│   Handles: * button → options menu
│             back → return to previous screen
│
├── SearchScreen.xml + .brs
│   Keyboard: SceneGraph Keyboard component
│   Results: ChannelGrid filtered in real time
│   No network requests — searches in-memory channel list
│
├── FavoritesScreen.xml + .brs
│   ChannelGrid with favorites only
│   Long-press OK → Remove from Favorites / Reorder
│
└── SettingsScreen.xml + .brs
    Sections: Display, Country Preference, Parental Controls,
              Data & Cache, About
    Handles: Theme toggle (Dark/Light)
             Country preference → filter home screen
             Clear cache → wipe roRegistrySection
             Force refresh → trigger API reload
```

### 3.2 Reusable Components (SceneGraph Nodes)

```
roku/source/components/
│
├── ChannelGrid.xml + .brs
│   Wraps SceneGraph RowList or PosterGrid
│   Inputs: channels (array), columns (integer)
│   Handles D-pad navigation, focus management
│   Lazy loads more channels on last-item focus
│
├── ChannelCard.xml + .brs
│   Logo image (Poster node)
│   Channel name (Label, 2-line max)
│   Country flag + category badge
│   Online status indicator dot (green/red/grey)
│   Focused state: scale 1.05, glow border
│
├── NavBar.xml + .brs
│   Horizontal tab list across top of screen
│   Active tab: accent color underline
│   Handles left/right D-pad between tabs
│   Fires: tabChange event
│
├── OverlayPanel.xml + .brs
│   Semi-transparent dark panel
│   Animates in/out with Translation animation
│   Used by PlayerScreen for controls overlay
│
├── ProgramCell.xml + .brs
│   Used in GuideScreen grid
│   Width proportional to program duration
│   Shows: title, start time, progress bar if current
│   Focused: highlight border + show description tooltip
│
├── ChannelRow.xml + .brs
│   Horizontal scrolling row for HomeScreen sections
│   Title label above row
│   Contains ChannelCard nodes
│
├── LoadingSpinner.xml + .brs
│   Animated rotating ring
│   Centered overlay while data loads
│
└── ErrorDialog.xml + .brs
    Modal dialog with message + action buttons
    Types: network_error, stream_error, no_results
```

### 3.3 Services (BrightScript)

```
roku/source/services/
│
├── APIService.brs
│   BASE_URL constant
│   fetchStatus() → roAssociativeArray
│   fetchPage(page: int) → roAssociativeArray
│   fetchByCountry(code: str) → roAssociativeArray
│   fetchByCategory(slug: str) → roAssociativeArray
│   fetchEPG() → roAssociativeArray
│   fetchCategories() → roAssociativeArray
│   fetchCountries() → roAssociativeArray
│   _get(url: str) → roAssociativeArray | invalid
│   _parseJSON(response: str) → roAssociativeArray
│
├── StorageService.brs
│   Registry section: "GioRoku"
│   getFavorites() → roArray
│   addFavorite(channelId: str) → void
│   removeFavorite(channelId: str) → void
│   getRecentChannels() → roArray
│   addRecentChannel(channelId: str) → void
│   getSettings() → roAssociativeArray
│   setSetting(key: str, value: dynamic) → void
│   clearAll() → void
│
├── ChannelService.brs
│   In-memory channel cache
│   allChannels (roArray, up to 5000 entries)
│   loadedPages (roArray of ints)
│   getChannel(id: str) → roAssociativeArray | invalid
│   searchChannels(query: str) → roArray
│   filterByCountry(code: str) → roArray
│   filterByCategory(slug: str) → roArray
│   getFeatured() → roArray
│   ensurePageLoaded(page: int) → void (async)
│
└── PlayerService.brs
    currentChannel (roAssociativeArray)
    channelHistory (roArray, max 20)
    createContent(channel: roAssociativeArray) → roSGNode
    playChannel(channel: roAssociativeArray) → void
    playNext() → void
    playPrevious() → void
    tryBackupUrl(channel: roAssociativeArray, index: int) → void
```

### 3.4 Models (BrightScript helper functions)

```
roku/source/models/
│
├── Channel.brs
│   createChannel(data: roAssociativeArray) → Channel
│   isOnline(channel) → boolean
│   getDisplayName(channel) → string
│   getLogoUrl(channel) → string
│
├── Program.brs
│   getCurrentProgram(channel) → Program | invalid
│   getNextProgram(channel) → Program | invalid
│   formatTimeRange(program) → string  ("7:00 PM – 8:30 PM")
│   getProgressPercent(program) → float
│
└── Settings.brs
    DEFAULT_SETTINGS constant
    getTheme() → string  ("dark" | "light")
    getCountryPref() → string  (ISO code)
    isParentalEnabled() → boolean
```

---

## 4. GitHub Actions Workflows

```
.github/workflows/
│
├── daily-refresh.yml
│   Trigger: cron "0 0 * * *" (midnight UTC)
│   Jobs:
│     fetch:
│       python backend/run_pipeline.py --stage fetch
│     validate:
│       needs: [fetch]
│       python backend/run_pipeline.py --stage validate
│     process:
│       needs: [validate]
│       python backend/run_pipeline.py --stage deduplicate,classify,enrich
│     generate:
│       needs: [process]
│       python backend/run_pipeline.py --stage generate
│     deploy:
│       needs: [generate]
│       git commit + push api/ directory
│   Cache: SQLite database between jobs via actions/cache
│
├── validate-streams.yml
│   Trigger: workflow_dispatch (manual trigger)
│   Input: country (optional, filter)
│   Job: run validate stage for specified subset
│
└── deploy-admin.yml
    Trigger: push to main (paths: admin/**)
    Jobs:
      build:
        npm ci
        npm run build
        Upload dist/ as artifact
      deploy:
        actions/deploy-pages
        Publishes admin portal to GitHub Pages /admin/ path
```

---

## 5. Component Interaction Map

```
┌──────────────────────────────────────────────────────────────┐
│                      GitHub Actions                          │
│                                                              │
│  Aggregator → Validator → Deduplicator → CountryDetector     │
│       ↓              ↓           ↓              ↓            │
│  LogoResolver ─────────────────────────────────→ SQLite DB   │
│  EPGManager  ─────────────────────────────────→ SQLite DB    │
│                                                    ↓         │
│                                             APIGenerator     │
│                                                    ↓         │
│                                          api/v1/*.json        │
└──────────────────────────────────────────────────────────────┘
                             ↓ GitHub Pages CDN
         ┌───────────────────┴───────────────────┐
         │                                       │
┌────────┴─────────┐                   ┌─────────┴────────┐
│   Roku App       │                   │  Admin Portal    │
│                  │                   │                  │
│  APIService      │                   │  useStatus()     │
│  ChannelService  │                   │  useChannels()   │
│  StorageService  │                   │  useGitHub()     │
│  PlayerService   │                   │                  │
│       ↓          │                   │        ↓         │
│  HomeScreen      │                   │  Dashboard.tsx   │
│  LiveTVScreen    │                   │  Channels.tsx    │
│  GuideScreen     │                   │  Health.tsx      │
│  PlayerScreen    │                   │  Sources.tsx     │
└──────────────────┘                   └─────────┬────────┘
                                                 │ GitHub API
                                                 ↓
                                    backend/config/*.json
                                         (committed)
```
