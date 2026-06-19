export interface Program {
  title: string
  description: string
  start: string
  end: string
  category: string
  rating: string | null
  durationMinutes?: number
  progressPercent?: number
  isLive?: boolean
}

export interface Channel {
  id: string
  name: string
  logo: string
  category: string
  categoryLabel: string
  country: string
  countryLabel: string
  language: string
  streamUrl: string
  backupUrls: string[]
  quality: 'SD' | 'HD' | 'FHD' | '4K'
  isOnline: boolean
  isEnabled: boolean
  isFeatured: boolean
  epgId: string | null
  tags: string[]
  offlineCount: number
  lastCheck: string | null
  lastOnline: string | null
  responseMs: number | null
  sourceId: string | null
  sourcePriority: number
  currentProgram?: Program | null
  nextProgram?: Program | null
}

export interface Category {
  id: string
  label: string
  labelEn: string
  icon: string
  color: string
  sortOrder: number
  channelCount: number
  keywords: string[]
}

export interface Country {
  code: string
  name: string
  nameEn: string
  flag: string
  sortOrder: number
  channelCount: number
  keywords: string[]
}

export interface Source {
  id: string
  name: string
  type: 'm3u' | 'xtream' | 'custom_api'
  url: string
  username?: string
  password?: string
  priority: number
  is_enabled: boolean
  refresh_interval_hours: number
  last_refresh: string | null
  last_channel_count: number
  options: {
    timeout_seconds: number
    encoding: string
    user_agent: string
    verify_ssl: boolean
    headers: Record<string, string>
  }
}

export interface PipelineStats {
  totalChannels: number
  onlineChannels: number
  offlineChannels: number
  disabledChannels?: number
  totalSources?: number
  totalCountries: number
  totalCategories: number
  lastValidationRun: string
  nextScheduledRun?: string
}

export interface StatusResponse {
  generatedAt: string
  pipelineVersion: string
  stats: PipelineStats
}

export interface ChannelsPage {
  page: number
  pageSize: number
  totalPages: number
  totalChannels: number
  channels: Channel[]
}
