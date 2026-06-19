# GioRoku — Data Flow Diagrams

## 1. Nightly Pipeline (GitHub Actions)

```
00:00 UTC — GitHub Actions cron trigger
│
▼
┌────────────────────────────────────────────────────────────────┐
│  STAGE 1: FETCH                                                │
│                                                                │
│  For each source in sources.json:                              │
│                                                                │
│  M3UProvider ──────────────────────────────────────────────┐  │
│    GET https://iptvplayer.stream/public-iptv-playlist       │  │
│    Parse #EXTINF attributes                                 │  │
│    Yield RawChannel per entry                               │  │
│                                                             │  │
│  XtreamProvider ────────────────────────────────────────┐   │  │
│    POST /player_api.php?action=get_live_streams          │   │  │
│    Map Xtream fields → RawChannel                        │   │  │
│                                                          │   │  │
│  CustomAPIProvider ──────────────────────────────────┐   │   │  │
│    GET configured endpoint                           │   │   │  │
│    Apply JSONPath mapping                            │   │   │  │
│                                                      │   │   │  │
│                                                      ▼   ▼   ▼  │
│                                              RawChannel[]       │
│                                                      │          │
│                                              Write to SQLite     │
│                                              (raw_channels)      │
└────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────┐
│  STAGE 2: VALIDATE                                             │
│                                                                │
│  Load all channels where last_check < now - 24h               │
│  (typically all channels on first run; changed ones after)     │
│                                                                │
│  asyncio.gather with semaphore(50):                            │
│    For each channel:                                           │
│      HTTP HEAD stream_url (5s timeout)                         │
│      If HEAD fails → HTTP GET bytes=0-1023                     │
│      Parse Content-Type                                        │
│      Record: is_online, response_ms, http_status              │
│                                                                │
│  Update SQLite:                                                │
│    is_online = result                                          │
│    offline_count = 0 if online else offline_count + 1         │
│    is_enabled = false if offline_count >= 7                    │
│    Append to channel_checks                                    │
└────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────┐
│  STAGE 3: DEDUPLICATE                                          │
│                                                                │
│  Pass 1 — Exact tvg_id match                                   │
│    Group raw_channels by normalize(tvg_id)                     │
│    Keep record from source with lowest priority number         │
│    Merge backup_urls from discarded duplicates                 │
│                                                                │
│  Pass 2 — Fuzzy name match                                     │
│    Normalize names: lowercase, strip diacritics, strip quality │
│    Levenshtein(a, b) / max(len(a),len(b)) < 0.15 → duplicate  │
│    Same source-priority winner rule applies                    │
│                                                                │
│  Output: deduplicated Channel[] written to channels table      │
└────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────┐
│  STAGE 4: CLASSIFY                                             │
│                                                                │
│  CountryDetector.detect(channel):                              │
│    Check tvg_id prefix → country dict                          │
│    Check group_title → country keyword dict                    │
│    Check channel name → country keyword dict                   │
│    Check domain of stream_url → ccTLD map                      │
│    Default → INTL                                              │
│                                                                │
│  CategoryDetector.detect(channel):                             │
│    Check group_title → category keyword dict                   │
│    Check channel name → category keyword dict                  │
│    Default → entertainment                                     │
│                                                                │
│  Apply operator overrides from channel_overrides.json          │
│  Update channels table: country, category                      │
└────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────┐
│  STAGE 5: ENRICH                                               │
│                                                                │
│  LogoResolver.resolve(channel):                                │
│    Check logo_overrides.json (operator) → use if found        │
│    Check logos cache (SQLite) → use if fresh                   │
│    Use tvg_logo as-is if it's a valid HTTPS URL                │
│    Look up internal logo DB (logos/*.json shipped with repo)   │
│    Query Clearart/Fanart.tv by name (rate-limited)             │
│    Generate SVG placeholder (category color + initials)        │
│    Update logos cache                                          │
│                                                                │
│  EPGManager.get_programs(channel):                             │
│    Check epg_programs table for epg_id                         │
│    If found → return current + next program                    │
│    If not found → return mock program (generic "Live TV")      │
│                                                                │
│  Update channels table: logo, current_program, next_program    │
└────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────┐
│  STAGE 6: GENERATE JSON API                                    │
│                                                                │
│  APIGenerator.write_all():                                     │
│                                                                │
│  SELECT all enabled channels → serialize → write:              │
│    api/v1/channels/page/1.json  (channels 1-100)               │
│    api/v1/channels/page/2.json  (channels 101-200)             │
│    ...                                                         │
│    api/v1/channels/country/MX.json                             │
│    api/v1/channels/country/AR.json                             │
│    ...                                                         │
│    api/v1/channels/category/entertainment.json                 │
│    ...                                                         │
│    api/v1/categories.json                                      │
│    api/v1/countries.json                                       │
│    api/v1/epg.json                                             │
│    api/v1/status.json                                          │
└────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────┐
│  STAGE 7: DEPLOY                                               │
│                                                                │
│  git add api/                                                  │
│  git commit -m "chore: api update $(date -u)"                  │
│  git push origin main                                          │
│                                                                │
│  GitHub Pages auto-publishes from main branch /api/ directory  │
│  CDN propagation: ~60 seconds                                  │
└────────────────────────────────────────────────────────────────┘
│
▼
Available at:
https://{user}.github.io/GioRoku/api/v1/status.json
```

---

## 2. Roku App Startup Flow

```
Device powers on / channel launched
│
▼
SplashScreen.brs
  Show logo + loading animation
  Start background Task: APITask
│
▼
APITask (roSGNode Task)
  GET /api/v1/status.json
  ├── Failure → show "No connection" dialog → retry or exit
  └── Success → extract generatedAt, stats
│
▼
  GET /api/v1/categories.json
  GET /api/v1/countries.json
  GET /api/v1/channels/page/1.json  ← first 100 channels only
│
▼
HomeScreen rendered with available data
  Continue Watching row: loaded from roRegistrySection
  Favorites row: loaded from roRegistrySection
  Categories row: from categories.json
  Countries row: from countries.json
  Featured row: channels where isFeatured=true
│
▼
User navigates → lazy load additional pages on demand
  GET /api/v1/channels/page/{n}.json  as user scrolls
  GET /api/v1/channels/country/{code}.json  on country select
  GET /api/v1/epg.json  when Guide screen opened
```

---

## 3. Channel Playback Flow

```
User presses OK on channel card
│
▼
PlayerScreen.brs launched
  channel object passed as params
│
▼
  roVideoPlayer.setContent(channel.streamUrl)
  roVideoPlayer.play()
│
├── Stream starts successfully
│     Show overlay: logo + name + currentProgram
│     Auto-hide overlay after 5 seconds
│     Record to recentChannels in roRegistrySection
│     Update Continue Watching row
│
└── Stream fails (timeout / HTTP error)
      Try channel.backupUrls[0]
      │
      ├── Backup succeeds → play backup, show warning badge
      └── All URLs fail → show error dialog
            Options: [Retry] [Remove from Favorites] [Back]
```

---

## 4. Admin Portal → Pipeline Flow

```
Operator opens admin portal (GitHub Pages)
│
▼
Portal reads:
  /api/v1/status.json   → dashboard stats
  /api/v1/channels/...  → channel list
  backend/config/*.json → editable config (via GitHub API)
│
▼
Operator makes change:
  Example: set channel X as Featured
│
▼
Portal writes to GitHub:
  PATCH /repos/{owner}/GioRoku/contents/backend/config/channel_overrides.json
  (uses GitHub API with operator's PAT stored in browser localStorage)
  Creates a commit directly to main branch
│
▼
Change triggers GitHub Actions workflow (push event)
  OR operator waits for next nightly run
│
▼
Pipeline reads channel_overrides.json on Stage 4 (CLASSIFY)
  is_featured override applied to channel
  JSON API regenerated and deployed
│
▼
Roku app fetches fresh /api/v1/channels/...
  Channel now appears in Featured row
```

---

## 5. Search Flow (Roku)

```
User navigates to Search screen
│
▼
SearchScreen.brs
  All channels already in memory (loaded pages 1..N)
  roSGNode TextEditBox for query input
│
▼
User types character
  OnTextChange handler fires
  Filter in-memory channel list:
    Levenshtein distance OR substring match on:
      channel.name
      channel.categoryLabel
      channel.countryLabel
      channel.tags[]
  Render filtered results in ChannelGrid component
  (no network request — fully client-side)
│
▼
User selects result → PlayerScreen
```

---

## 6. Logo Resolution Decision Tree

```
Input: channel with tvg_logo URL

logo_overrides.json has entry for this channel?
├── YES → use override URL (stop)
└── NO  ↓

logos cache (SQLite) has fresh entry?
├── YES → use cached resolved URL (stop)
└── NO  ↓

tvg_logo is valid HTTPS URL?
├── YES → HTTP HEAD to verify it loads (200 OK, Content-Type: image/*)
│         ├── OK  → use tvg_logo, cache it (stop)
│         └── BAD ↓
└── NO  ↓

Internal logo DB has entry for channel name/tvg_id?
├── YES → use internal URL, cache it (stop)
└── NO  ↓

Clearart/Fanart.tv has logo for channel name?
├── YES → use Clearart URL, cache it (stop)
└── NO  ↓

Generate SVG fallback:
  Category color + channel name initials
  Data URI embedded in JSON
  (stop — always succeeds)
```
