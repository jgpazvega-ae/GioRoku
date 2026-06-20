import { RefreshCw } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { useStatus } from '@/hooks/useStatus'

export function TopBar() {
  const { data, isFetching } = useStatus()
  const qc = useQueryClient()

  const lastUpdate = data?.generatedAt
    ? new Date(data.generatedAt).toLocaleString('es-MX', { dateStyle: 'short', timeStyle: 'short' })
    : '—'

  return (
    <header className="h-14 bg-bg-surface border-b border-white/10 flex items-center justify-between px-6">
      <span className="text-white/40 text-sm">
        Última actualización: <span className="text-white/70">{lastUpdate}</span>
      </span>
      <button
        onClick={() => qc.invalidateQueries()}
        disabled={isFetching}
        className="flex items-center gap-2 px-3 py-1.5 rounded-md bg-white/5 hover:bg-white/10 text-white/70 hover:text-white text-sm transition-colors disabled:opacity-40"
      >
        <RefreshCw size={14} className={isFetching ? 'animate-spin' : ''} />
        Actualizar
      </button>
    </header>
  )
}
