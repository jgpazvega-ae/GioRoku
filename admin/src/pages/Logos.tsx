import { useState } from 'react'
import { Image } from 'lucide-react'
import { useAllChannels } from '@/hooks/useChannels'
import { EmptyState } from '@/components/feedback/EmptyState'
import type { Channel } from '@/types'

export default function Logos() {
  const { data: channels = [], isLoading } = useAllChannels()
  const [filter, setFilter] = useState<'all' | 'svg' | 'missing'>('all')

  const filtered = channels.filter(ch => {
    if (filter === 'svg') return ch.logo?.startsWith('data:image/svg')
    if (filter === 'missing') return !ch.logo
    return true
  })

  if (isLoading) return <div className="text-white/40 text-sm">Cargando...</div>

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Gestión de Logos</h1>
          <p className="text-white/40 text-sm">{filtered.length.toLocaleString()} canales</p>
        </div>
        <div className="flex rounded-lg overflow-hidden border border-white/10">
          {([['all','Todos'],['svg','SVG (auto)'],['missing','Sin logo']] as const).map(([v,l]) => (
            <button key={v} onClick={() => setFilter(v)}
              className={`px-3 py-2 text-sm transition-colors ${filter === v ? 'bg-accent-primary text-white' : 'bg-bg-surface text-white/50 hover:text-white'}`}>
              {l}
            </button>
          ))}
        </div>
      </div>
      {filtered.length === 0 ? (
        <EmptyState icon={Image} title="Sin resultados" />
      ) : (
        <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 xl:grid-cols-10 gap-3">
          {filtered.slice(0, 200).map(ch => <LogoCard key={ch.id} channel={ch} />)}
        </div>
      )}
    </div>
  )
}

function LogoCard({ channel: ch }: { channel: Channel }) {
  const isSvg = ch.logo?.startsWith('data:image/svg')
  return (
    <div className="bg-bg-surface rounded-lg p-2 border border-white/5 group cursor-pointer hover:border-accent-primary/40 transition-colors">
      <div className="aspect-video bg-black/30 rounded flex items-center justify-center overflow-hidden mb-2">
        {ch.logo ? (
          <img src={ch.logo} alt={ch.name} className="w-full h-full object-contain" />
        ) : (
          <span className="text-white/20 text-xs">Sin logo</span>
        )}
      </div>
      <p className="text-white/60 text-[10px] truncate">{ch.name}</p>
      {isSvg && <span className="text-pending text-[9px]">SVG auto</span>}
    </div>
  )
}
