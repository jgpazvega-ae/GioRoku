import { Activity } from 'lucide-react'
import { useAllChannels } from '@/hooks/useChannels'
import { StatusBadge } from '@/components/data-display/StatusBadge'
import { EmptyState } from '@/components/feedback/EmptyState'

export default function Health() {
  const { data: channels = [], isLoading } = useAllChannels()

  const offline = channels
    .filter(ch => !ch.isOnline && ch.isEnabled)
    .sort((a, b) => b.offlineCount - a.offlineCount)

  if (isLoading) return <div className="text-white/40 text-sm">Cargando...</div>

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-white">Salud de Canales</h1>
        <p className="text-white/40 text-sm">{offline.length} canales sin señal actualmente</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'En línea', value: channels.filter(c => c.isOnline).length, color: 'text-online' },
          { label: 'Sin señal', value: channels.filter(c => !c.isOnline && c.isEnabled).length, color: 'text-offline' },
          { label: 'Deshabilitados', value: channels.filter(c => !c.isEnabled).length, color: 'text-white/40' },
        ].map(({ label, value, color }) => (
          <div key={label} className="bg-bg-surface rounded-xl p-4 border border-white/5 text-center">
            <p className={`text-3xl font-bold ${color}`}>{value.toLocaleString()}</p>
            <p className="text-white/40 text-xs mt-1">{label}</p>
          </div>
        ))}
      </div>

      <div className="bg-bg-surface rounded-xl border border-white/5 overflow-hidden">
        <div className="px-4 py-3 border-b border-white/10">
          <h2 className="text-white/80 text-sm font-medium">Canales con problemas (ordenados por días caído)</h2>
        </div>
        {offline.length === 0 ? (
          <EmptyState icon={Activity} title="Todos los canales están en línea" />
        ) : (
          <table className="w-full text-sm">
            <thead className="border-b border-white/10">
              <tr className="text-white/40 text-xs uppercase">
                <th className="text-left px-4 py-3">Canal</th>
                <th className="text-left px-4 py-3">País</th>
                <th className="text-left px-4 py-3">Estado</th>
                <th className="text-right px-4 py-3">Días caído</th>
                <th className="text-right px-4 py-3">Último OK</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {offline.slice(0, 100).map(ch => (
                <tr key={ch.id} className="hover:bg-white/5">
                  <td className="px-4 py-2.5 text-white">{ch.name}</td>
                  <td className="px-4 py-2.5 text-white/50">{ch.country}</td>
                  <td className="px-4 py-2.5"><StatusBadge status="offline" /></td>
                  <td className="px-4 py-2.5 text-right text-offline font-mono">{ch.offlineCount}</td>
                  <td className="px-4 py-2.5 text-right text-white/30 text-xs">
                    {ch.lastOnline ? new Date(ch.lastOnline).toLocaleDateString('es-MX') : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
