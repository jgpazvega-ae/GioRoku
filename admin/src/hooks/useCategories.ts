import { useQuery } from '@tanstack/react-query'
import { api } from '@/services/api'

export function useCategories() {
  return useQuery({
    queryKey: ['categories'],
    queryFn: async () => {
      const res = await api.categories()
      return res.categories
    },
    staleTime: 10 * 60_000,
  })
}
