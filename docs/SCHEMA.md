# GioRoku — Data Schema Design

## 1. Channel (master record)

The canonical representation of a single channel after deduplication and enrichment.

```json
{
  "id": "mx_televisa_canal_de_las_estrellas",
  "name": "Canal de las Estrellas",
  "logo": "https://cdn.example.com/logos/televisa-estrellas.png",
  "category": "entertainment",
  "categoryLabel": "Entretenimiento",
  "country": "MX",
  "countryLabel": "México",
  "language": "es",
  "streamUrl": "https://live.provider.net/hls/mx_televisa.m3u8",
  "backupUrls": [],
  "quality": "HD",
  "isOnline": true,
  "isEnabled": true,
  "isFeatured": false,
  "epgId": "mx_televisa_estrellas",
  "tags": ["novelas", "noticias", "entretenimiento"],
  "offlineCount": 0,
  "lastCheck": "2024-01-15T06:00:00Z",
  "lastOnline": "2024-01-15T06:00:00Z",
  "responseMs": 312,
  "sourceId": "iptvplayer_stream",
  "sourcePriority": 1,
  "currentProgram": {
    "title": "Hoy",
    "start": "2024-01-15T14:00:00Z",
    "end": "2024-01-15T15:30:00Z",
    "description": "Programa de entretenimiento y noticias del espectáculo",
    "category": "Entertainment",
    "rating": "TV-G"
  },
  "nextProgram": {
    "title": "La Rosa de Guadalupe",
    "start": "2024-01-15T15:30:00Z",
    "end": "2024-01-15T16:30:00Z",
    "description": "",
    "category": "Drama",
    "rating": "TV-PG"
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Stable slug, never changes between pipeline runs |
| `name` | string | yes | Display name, may be operator-overridden |
| `logo` | string | yes | Absolute HTTPS URL to logo image |
| `category` | string | yes | Slug matching categories.json |
| `categoryLabel` | string | yes | Human-readable category name |
| `country` | string | yes | ISO 3166-1 alpha-2 or custom code (CA, US_ES, INTL) |
| `countryLabel` | string | yes | Human-readable country name |
| `language` | string | yes | BCP 47 language tag (es, en, pt, ...) |
| `streamUrl` | string | yes | Primary HLS stream URL |
| `backupUrls` | string[] | no | Alternate stream URLs, tried in order |
| `quality` | string | yes | SD / HD / FHD / 4K |
| `isOnline` | boolean | yes | Result of last validation check |
| `isEnabled` | boolean | yes | Operator override; false = hidden from all clients |
| `isFeatured` | boolean | yes | Shown in Featured row on Roku home screen |
| `epgId` | string | no | Matches EPG program records |
| `tags` | string[] | no | Free-form tags for search |
| `offlineCount` | integer | yes | Consecutive validation failures |
| `lastCheck` | ISO 8601 | yes | Timestamp of last validation attempt |
| `lastOnline` | ISO 8601 | no | Timestamp of last successful check |
| `responseMs` | integer | no | Stream response time in milliseconds |
| `sourceId` | string | yes | Originating provider ID |
| `sourcePriority` | integer | yes | Lower = higher priority (1 is best) |
| `currentProgram` | Program | no | Current EPG entry (null if unavailable) |
| `nextProgram` | Program | no | Next EPG entry (null if unavailable) |

---

## 2. Program (EPG entry)

```json
{
  "title": "Hoy",
  "start": "2024-01-15T14:00:00Z",
  "end": "2024-01-15T15:30:00Z",
  "description": "Programa de entretenimiento y noticias del espectáculo",
  "category": "Entertainment",
  "rating": "TV-G",
  "episodeTitle": null,
  "season": null,
  "episode": null,
  "isLive": true,
  "posterUrl": null
}
```

---

## 3. Source (provider configuration)

Stored in `backend/config/sources.json`. Operator-editable.

```json
{
  "id": "iptvplayer_stream",
  "name": "IPTV Player Stream",
  "type": "m3u",
  "url": "https://iptvplayer.stream/public-iptv-playlist",
  "priority": 1,
  "isEnabled": true,
  "refreshIntervalHours": 24,
  "lastRefresh": "2024-01-15T00:00:00Z",
  "lastChannelCount": 8423,
  "options": {
    "timeoutSeconds": 30,
    "encoding": "utf-8",
    "userAgent": "GioRoku/1.0"
  }
}
```

### Source Types

```json
{ "type": "m3u",    "url": "https://..." }

{ "type": "xtream",
  "url": "http://provider.example.com",
  "username": "user",
  "password": "pass" }

{ "type": "custom_api",
  "url": "https://api.provider.com/channels",
  "headers": { "X-API-Key": "..." },
  "channelsPath": "$.data.channels",
  "mapping": {
    "name":     "channel_name",
    "streamUrl": "stream.hls",
    "logo":     "thumbnail_url",
    "group":    "category"
  }
}
```

---

## 4. Category

Stored in `backend/config/categories.json`.

```json
{
  "id": "entertainment",
  "label": "Entretenimiento",
  "labelEn": "Entertainment",
  "icon": "star",
  "color": "#E74C3C",
  "sortOrder": 1,
  "channelCount": 234,
  "keywords": ["entertainment", "entretenimiento", "general", "variedades"]
}
```

### Standard Categories

| ID | Label | Description |
|---|---|---|
| `entertainment` | Entretenimiento | General entertainment |
| `news` | Noticias | News and current affairs |
| `sports` | Deportes | Sports and athletics |
| `movies` | Películas | Movies and cinema |
| `kids` | Infantil | Children's programming |
| `music` | Música | Music channels |
| `documentary` | Documentales | Documentaries and nature |
| `religious` | Religioso | Religious programming |
| `shopping` | Compras | Shopping channels |
| `local` | Local | Local and community TV |
| `international` | Internacional | International channels |
| `radio` | Radio | Audio/radio streams |

---

## 5. Country

Stored in `backend/config/countries.json`.

```json
{
  "code": "MX",
  "name": "México",
  "nameEn": "Mexico",
  "flag": "🇲🇽",
  "sortOrder": 1,
  "channelCount": 312,
  "keywords": [
    "mexico", "méxico", "mx", "azteca", "televisa",
    "multimedios", "imagen", "canal 5", "tv azteca",
    "once tv", "cadenatres", "efekto", "excelsior"
  ]
}
```

### Country Registry

| Code | Country | Sort |
|---|---|---|
| MX | México | 1 |
| AR | Argentina | 2 |
| CO | Colombia | 3 |
| CL | Chile | 4 |
| PE | Perú | 5 |
| UY | Uruguay | 6 |
| PY | Paraguay | 7 |
| EC | Ecuador | 8 |
| BO | Bolivia | 9 |
| VE | Venezuela | 10 |
| CA | Centroamérica | 11 |
| US_ES | EE.UU. (Español) | 12 |
| INTL | Internacional | 99 |

---

## 6. API Response Envelopes

### /api/v1/status.json

```json
{
  "generatedAt": "2024-01-15T06:30:00Z",
  "pipelineVersion": "1.0.0",
  "stats": {
    "totalChannels": 8423,
    "onlineChannels": 7891,
    "offlineChannels": 412,
    "disabledChannels": 120,
    "totalSources": 3,
    "activeSources": 3,
    "totalCountries": 13,
    "totalCategories": 12,
    "lastValidationRun": "2024-01-15T05:45:00Z",
    "nextScheduledRun": "2024-01-16T00:00:00Z"
  },
  "sources": [
    {
      "id": "iptvplayer_stream",
      "name": "IPTV Player Stream",
      "channelCount": 8423,
      "lastRefresh": "2024-01-15T00:00:00Z",
      "isHealthy": true
    }
  ]
}
```

### /api/v1/channels/page/{n}.json

```json
{
  "page": 1,
  "pageSize": 100,
  "totalPages": 85,
  "totalChannels": 8423,
  "channels": [ /* Channel[] */ ]
}
```

### /api/v1/categories.json

```json
{
  "generatedAt": "2024-01-15T06:30:00Z",
  "categories": [ /* Category[] */ ]
}
```

### /api/v1/countries.json

```json
{
  "generatedAt": "2024-01-15T06:30:00Z",
  "countries": [ /* Country[] */ ]
}
```

### /api/v1/epg.json

```json
{
  "generatedAt": "2024-01-15T06:30:00Z",
  "programs": {
    "mx_televisa_estrellas": {
      "current": { /* Program */ },
      "next": { /* Program */ }
    }
  }
}
```

---

## 7. SQLite Schema

```sql
CREATE TABLE sources (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    type            TEXT NOT NULL,
    url             TEXT NOT NULL,
    priority        INTEGER DEFAULT 10,
    is_enabled      INTEGER DEFAULT 1,
    options_json    TEXT,
    last_refresh    TEXT,
    channel_count   INTEGER DEFAULT 0
);

CREATE TABLE raw_channels (
    id              TEXT PRIMARY KEY,   -- hash(source_id + stream_url)
    source_id       TEXT NOT NULL,
    tvg_id          TEXT,
    tvg_name        TEXT,
    tvg_logo        TEXT,
    group_title     TEXT,
    language        TEXT,
    stream_url      TEXT NOT NULL,
    fetched_at      TEXT NOT NULL,
    FOREIGN KEY (source_id) REFERENCES sources(id)
);

CREATE TABLE channels (
    id              TEXT PRIMARY KEY,   -- stable slug
    name            TEXT NOT NULL,
    logo            TEXT,
    category        TEXT,
    country         TEXT,
    language        TEXT,
    stream_url      TEXT NOT NULL,
    backup_urls     TEXT,              -- JSON array
    quality         TEXT DEFAULT 'SD',
    is_online       INTEGER DEFAULT 1,
    is_enabled      INTEGER DEFAULT 1,
    is_featured     INTEGER DEFAULT 0,
    epg_id          TEXT,
    tags            TEXT,              -- JSON array
    offline_count   INTEGER DEFAULT 0,
    last_check      TEXT,
    last_online     TEXT,
    response_ms     INTEGER,
    source_id       TEXT,
    source_priority INTEGER,
    -- operator overrides (survive pipeline runs)
    override_name   TEXT,
    override_logo   TEXT,
    override_category TEXT,
    override_country  TEXT,
    override_enabled  INTEGER,
    FOREIGN KEY (source_id) REFERENCES sources(id)
);

CREATE TABLE channel_checks (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    channel_id      TEXT NOT NULL,
    checked_at      TEXT NOT NULL,
    is_online       INTEGER NOT NULL,
    response_ms     INTEGER,
    http_status     INTEGER,
    error           TEXT,
    FOREIGN KEY (channel_id) REFERENCES channels(id)
);

CREATE TABLE logos (
    url             TEXT PRIMARY KEY,  -- original tvg-logo URL
    resolved_url    TEXT NOT NULL,     -- final cached URL
    phash           TEXT,              -- perceptual hash
    resolved_at     TEXT NOT NULL,
    source          TEXT               -- 'tvg_logo'|'internal'|'clearart'|'fallback'
);

CREATE TABLE epg_programs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    epg_id          TEXT NOT NULL,
    title           TEXT NOT NULL,
    start_time      TEXT NOT NULL,
    end_time        TEXT NOT NULL,
    description     TEXT,
    category        TEXT,
    rating          TEXT
);

CREATE INDEX idx_channels_country    ON channels(country);
CREATE INDEX idx_channels_category   ON channels(category);
CREATE INDEX idx_channels_is_online  ON channels(is_online);
CREATE INDEX idx_channel_checks_time ON channel_checks(checked_at);
CREATE INDEX idx_epg_id_time         ON epg_programs(epg_id, start_time);
```

---

## 8. Admin Portal Configuration Files

These JSON files in `backend/config/` are the operator's control plane. The pipeline reads them on every run.

### sources.json

Array of `Source` objects (see §3 above).

### categories.json

Array of `Category` objects (see §4 above). Edit to reorder categories on the Roku home screen.

### countries.json

Array of `Country` objects (see §5 above). Edit keywords to improve auto-detection accuracy.

### logo_overrides.json

```json
{
  "mx_televisa_canal_de_las_estrellas": {
    "logo": "https://my-cdn.com/logos/televisa-estrellas-hd.png",
    "setAt": "2024-01-10T12:00:00Z",
    "setBy": "operator"
  }
}
```

### channel_overrides.json

Operator-set field overrides that survive pipeline rebuilds.

```json
{
  "mx_televisa_canal_de_las_estrellas": {
    "name": "Canal de las Estrellas",
    "category": "entertainment",
    "country": "MX",
    "isEnabled": true,
    "isFeatured": true
  }
}
```
