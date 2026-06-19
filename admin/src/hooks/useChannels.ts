import { useQuery } from '@tanstack/react-query'
import { api } from '@/services/api'
import { useStatus } from './useStatus'

export function useChannelsPage(page: number) {
  return useQuery({
    queryKey: ['channels', page],
    queryFn: () => api.channelsPage(page),
    staleTime: 5 * 60_000,
  })
}

export function useAllChannels() {
  const { data: status } = useStatus()
  const totalPages = status ? Math.ceil(status.stats.totalChannels / 100) : 1

  return useQuery({
    queryKey: ['channels', 'all', totalPages],
    queryFn: () => api.allChannels(totalPages),
    enabled: !!status,
    staleTime: 5 * 60_000,
  })
}
