import { config } from './config'
import type { StatusResponse, ChannelsPage, Channel, Category, Country } from '@/types'

async function get<T>(path: string): Promise<T> {
  const res = await fetch(`${config.apiBase}/${path}`)
  if (!res.ok) throw new Error(`API ${path}: ${res.status}`)
  return res.json() as Promise<T>
}

export const api = {
  status: () => get<StatusResponse>('status.json'),
  channelsPage: (page: number) => get<ChannelsPage>(`channels/page/${page}.json`),
  channelsByCountry: (code: string) => get<{ country: string; channels: Channel[] }>(`channels/country/${code}.json`),
  channelsByCategory: (cat: string) => get<{ category: string; channels: Channel[] }>(`channels/category/${cat}.json`),
  categories: () => get<{ generatedAt: string; categories: Category[] }>('categories.json'),
  countries: () => get<{ generatedAt: string; countries: Country[] }>('countries.json'),
  epg: () => get<{ generatedAt: string; programs: Record<string, { current?: unknown; next?: unknown }> }>('epg.json'),

  async allChannels(totalPages: number): Promise<Channel[]> {
    const pages = await Promise.all(
      Array.from({ length: totalPages }, (_, i) => this.channelsPage(i + 1))
    )
    return pages.flatMap(p => p.channels)
  },
}
