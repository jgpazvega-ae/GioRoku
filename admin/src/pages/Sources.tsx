import { useState } from 'react'
import { Plus, Radio, CheckCircle, XCircle, Pencil } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { readConfig } from '@/services/github'
import type { Source } from '@/types'

function useSourcesConfig() {
  return useQuery({
    queryKey: ['config', 'sources'],
    queryFn: () => readConfig('backend/config/sources.json') as Promise<Source[]>,
    staleTime: 60_000,
  })
}

export default function Sources() {
  const { data: sources = [], isLoading, error } = useSourcesConfig()
  const [showAdd, setShowAdd] = useState(false)

  if (isLoading) return <div className="text-white/40 text-sm">Cargando fuentes...</div>
  if (error) return (
    <div className="bg-bg-surface rounded-xl p-6 border border-offline/30 text-offline text-sm">
      No se pudo leer la configuración. Verifica que hayas configurado tu GitHub PAT en Ajustes.
    </div>
  )

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Fuentes IPTV</h1>
          <p className="text-white/40 text-sm">{sources.length} fuentes configuradas</p>
        </div>
        <button
          onClick={() => setShowAdd(true)}
          className="flex items-center gap-2 px-4 py-2 bg-accent-primary hover:bg-accent-primary/80 text-white rounded-lg text-sm font-medium transition-colors"
        >
          <Plus size={16} /> Agregar fuente
        </button>
      </div>

      <div className="grid gap-4">
        {sources.map(source => (
          <div key={source.id} className="bg-bg-surface rounded-xl border border-white/5 p-5">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-accent-primary/10">
                  <Radio size={18} className="text-accent-primary" />
                </div>
                <div>
                  <h3 className="text-white font-medium">{source.name}</h3>
                  <p className="text-white/40 text-xs mt-0.5">{source.url}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                {source.is_enabled
                  ? <span className="flex items-center gap-1.5 text-xs text-online"><CheckCircle size={13} /> Activa</span>
                  : <span className="flex items-center gap-1.5 text-xs text-offline"><XCircle size={13} /> Inactiva</span>
                }
                <button className="p-1.5 hover:bg-white/10 rounded-md text-white/40 hover:text-white">
                  <Pencil size={14} />
                </button>
              </div>
            </div>
            <div className="flex gap-6 mt-4 text-xs text-white/40">
              <span>Tipo: <strong className="text-white/70">{source.type.toUpperCase()}</strong></span>
              <span>Prioridad: <strong className="text-white/70">{source.priority}</strong></span>
              <span>Canales: <strong className="text-white/70">{source.last_channel_count?.toLocaleString() ?? '—'}</strong></span>
              <span>Actualización: <strong className="text-white/70">Cada {source.refresh_interval_hours}h</strong></span>
            </div>
          </div>
        ))}
      </div>

      {showAdd && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
          <div className="bg-bg-elevated rounded-xl border border-white/10 p-6 max-w-md w-full mx-4">
            <h2 className="text-white font-semibold text-lg mb-4">Nueva fuente</h2>
            <p className="text-white/40 text-sm mb-6">
              Edita <code className="text-accent-secondary">backend/config/sources.json</code> directamente para agregar fuentes complejas (Xtream, Custom API).
            </p>
            <button onClick={() => setShowAdd(false)}
              className="w-full px-4 py-2 bg-white/5 hover:bg-white/10 text-white/70 rounded-lg text-sm">
              Cerrar
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
