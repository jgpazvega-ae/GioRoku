import { useQuery } from '@tanstack/react-query'
import { api } from '@/services/api'

export function useCountries() {
  return useQuery({
    queryKey: ['countries'],
    queryFn: async () => {
      const res = await api.countries()
      return res.countries
    },
    staleTime: 10 * 60_000,
  })
}
