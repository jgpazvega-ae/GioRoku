import { useQuery } from '@tanstack/react-query'
import { api } from '@/services/api'

export function useStatus() {
  return useQuery({
    queryKey: ['status'],
    queryFn: () => api.status(),
    refetchInterval: 60_000,
    staleTime: 30_000,
  })
}
