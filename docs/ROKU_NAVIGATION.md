# GioRoku — Roku Navigation Map

## 1. Screen Tree

```
Launch
│
▼
SplashScreen
  Loads: status.json, categories.json, countries.json, channels/page/1.json
  │
  └─ Data ready ──────────────────────────────────────────────────────────────┐
                                                                              ▼
                                                                       HomeScreen
                                                                     ┌──── NavBar ────┐
                                                    ┌────────────────┤  Home  (focus) ├────────────────────────────────┐
                                                    │                └────────────────┘                                │
                                                    │                                                                   │
                                     ┌──────────────┼──────────────┬──────────────┬──────────────┬──────────────┐     │
                                     ▼              ▼              ▼              ▼              ▼              ▼     │
                                  Live TV         Guide        Favorites        Search        Settings       (Home)   │
                                     │              │              │              │              │                     │
                                     ▼              ▼              ▼              ▼              ▼                     │
                               LiveTVScreen    GuideScreen  FavoritesScreen SearchScreen  SettingsScreen              │
                                                                                                                      │
         ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
         │  Home screen rows:
         │
         ├── [Continue Watching]
         │     ChannelRow (from roRegistry — recent channels)
         │     Channel select → PlayerScreen
         │
         ├── [Favorites]
         │     ChannelRow (from roRegistry — favorited channels)
         │     Channel select → PlayerScreen
         │     Empty state → "No favorites yet. Press * on any channel."
         │
         ├── [Featured]
         │     ChannelRow (channels where isFeatured=true)
         │     Channel select → PlayerScreen
         │
         ├── [By Category]  ← one row per category, horizontally scrollable sections
         │     Entretenimiento  ──→ ChannelRow → Channel select → PlayerScreen
         │     Noticias         ──→ ChannelRow → Channel select → PlayerScreen
         │     Deportes         ──→ ChannelRow → Channel select → PlayerScreen
         │     … (all categories)
         │
         └── [By Country]  ← one row per country
               🇲🇽 México   ──→ ChannelRow → Channel select → PlayerScreen
               🇦🇷 Argentina ──→ ChannelRow → Channel select → PlayerScreen
               … (all countries)
```

---

## 2. LiveTV Screen Navigation

```
LiveTVScreen
│
├── Filter tabs (top row)
│     [All]  [By Country ▼]  [By Category ▼]
│     D-pad left/right moves between tabs
│     OK on dropdown tab → opens picker overlay
│
└── ChannelGrid (main area)
      5-column grid of ChannelCards
      D-pad up/down/left/right navigates cards
      │
      ├── OK → PlayerScreen (channel)
      ├── * (options) → ContextMenu
      │     [Add to Favorites]
      │     [Hide Channel]
      │     [Channel Info]
      └── Back → HomeScreen
```

---

## 3. Guide Screen Navigation

```
GuideScreen
│
├── Channel column (left, fixed width 280px)
│     24 channels visible
│     D-pad up/down scrolls channels
│     D-pad right → moves focus into program grid
│
├── Time header (top, scrollable)
│     Current time highlighted with vertical red bar
│     D-pad left/right scrolls timeline (30 min per press)
│     Rewind button (<<): jump -1 hour
│
└── Program grid (main area)
      Program cells sized proportional to duration
      Current program: bright highlight + progress bar
      Future program: normal appearance
      Past program: dimmed
      │
      ├── OK → Program Detail overlay
      │     Shows: title, description, start-end, rating
      │     Actions: [Watch Now] [Set Reminder*]
      │     * Reminder is future feature
      │
      ├── D-pad left → return focus to channel column
      ├── Page Up / Page Down → scroll 6 channels
      └── Back → HomeScreen
```

---

## 4. Player Screen Navigation

```
PlayerScreen
│
├── Full-screen video
│
├── Info overlay (auto-appears, auto-hides after 5s)
│     Top-left: channel logo + name + country flag
│     Bottom: current program title + progress bar
│             next program: "Up next: [title] at [time]"
│
├── Controls overlay (press OK to show)
│     Left arrow: previous channel (from history)
│     Right arrow: next channel (same category)
│     Up arrow: channel +1 (by list order)
│     Down arrow: channel -1 (by list order)
│     Heart icon: toggle Favorite
│     Info icon: show program detail
│
├── Key bindings
│     OK          → toggle controls overlay
│     Back        → return to previous screen
│     Up          → channel up (same category)
│     Down        → channel down (same category)
│     * (options) → options menu
│     Replay      → restart stream (re-connect)
│
└── Options menu (* button)
      [Add to / Remove from Favorites]
      [Channel Info]
      [Copy Stream URL*]  (* debug only)
      [Report Issue]      → opens GitHub issue URL on phone via deep link
      [Close]
```

---

## 5. Search Screen Navigation

```
SearchScreen
│
├── On-screen keyboard (top half)
│     Standard SceneGraph Keyboard component
│     Input is instant-search (no submit required)
│
└── Results grid (bottom half)
      Updates in real time as user types
      Shows: channel logo + name + country + category
      │
      ├── 0 results → "No channels found for [query]"
      ├── OK on result → PlayerScreen
      └── Back → HomeScreen
```

---

## 6. Settings Screen Navigation

```
SettingsScreen
│
├── Display
│     Theme: [Dark ●] [Light]
│     Text size: [Normal] [Large]
│
├── Content Preferences
│     Default country: dropdown (MX, AR, CO, CL …)
│     Show adult content: [Off ●] [On]
│
├── Parental Controls
│     Enable PIN: toggle
│     Set PIN: numeric entry dialog
│     Rating limit: [TV-G] [TV-PG] [TV-14] [TV-MA]
│
├── Data & Cache
│     Last API update: [2024-01-15 06:30 UTC]
│     Force refresh now: button → triggers APITask reload
│     Clear cache: button → confirm dialog → roRegistrySection.delete()
│     Cache size: [~2.4 MB]
│
└── About
      Version: 1.0.0
      Data source: GioRoku API (GitHub Pages)
      Open source: [View on GitHub] → opens browser
```

---

## 7. Remote Control Map

```
Roku Remote Button → Screen → Action

D-pad Up          → All screens        → Move focus up / scroll up
D-pad Down        → All screens        → Move focus down / scroll down
D-pad Left        → All screens        → Move focus left / back panel
D-pad Right       → All screens        → Move focus right / enter panel
OK / Select       → All screens        → Activate focused element
Back              → All screens        → Navigate back (close screen)

Up                → PlayerScreen       → Channel up
Down              → PlayerScreen       → Channel down
* (Options)       → PlayerScreen       → Options menu
* (Options)       → LiveTVScreen       → Channel context menu
* (Options)       → FavoritesScreen    → Reorder / Remove menu

Replay            → PlayerScreen       → Restart stream
Play/Pause        → PlayerScreen       → Pause / Resume (if supported)
Fast Forward >>   → GuideScreen        → Advance timeline +1 hour
Rewind <<         → GuideScreen        → Rewind timeline -1 hour
Instant Replay    → PlayerScreen       → Reconnect stream

Home              → Any screen         → Exit to Roku home (system)
```

---

## 8. Deep Link Support

GioRoku supports Roku deep linking for discovery and voice search integration.

```
Channel launch parameters:

contentId = channel ID string
mediaType = "live"

Examples:
  contentId=mx_televisa_estrellas  → open PlayerScreen for that channel
  contentId=guide                  → open GuideScreen
  contentId=search&query=noticias  → open SearchScreen pre-filled
```

---

## 9. State Persistence (roRegistrySection)

All user state is persisted between sessions. No account required.

```
Section: "GioRoku"

Keys:
  favorites         JSON array of channel IDs, ordered
  recentChannels    JSON array of { id, watchedAt, durationSec }, max 20
  settings          JSON object (theme, country, parental, etc.)
  loadedPages       JSON array of page numbers fetched this session
  epgLastFetch      ISO timestamp of last EPG fetch
  apiLastFetch      ISO timestamp of last status.json fetch
```

---

## 10. UI Design Language

### Color Palette (Dark Theme, default)

```
Background (primary):    #0D0D0D  — near-black
Background (surface):    #1A1A1A  — card/panel background
Background (elevated):   #262626  — focused elements
Accent (primary):        #E50000  — action buttons, active tab
Accent (secondary):      #FF6B35  — highlights, badges
Text (primary):          #FFFFFF  — main labels
Text (secondary):        #A0A0A0  — metadata, timestamps
Online indicator:        #00C851  — green dot
Offline indicator:       #FF4444  — red dot
Pending indicator:       #FFBB33  — yellow dot
```

### Typography (Roku/SG)

```
Headline (channel name):     font size 28, weight bold
Subhead (category/country):  font size 20, weight regular
Body (program description):  font size 18, weight regular
Caption (timestamps):        font size 16, weight regular
```

### Animation Timings

```
Screen transition (fade):    300ms
Overlay show/hide:           200ms
Card focus scale:            150ms
Guide scroll:                80ms per step (smooth)
```

### Grid Layouts

```
HomeScreen rows:    horizontal scroll, 200×112px cards, 12px gap
LiveTV grid:        5 columns, 200×112px cards, 16px gap
Guide channel col:  280px wide, 72px row height
Guide time block:   180px per 30 minutes
Player overlay:     full-width, 160px tall from bottom
```
