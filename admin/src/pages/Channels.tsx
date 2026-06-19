import { useState, useMemo } from 'react'
import { Search, Star, EyeOff, Eye } from 'lucide-react'
import { useAllChannels } from '@/hooks/useChannels'
import { useCategories } from '@/hooks/useCategories'
import { useCountries } from '@/hooks/useCountries'
import { StatusBadge } from '@/components/data-display/StatusBadge'
import { EmptyState } from '@/components/feedback/EmptyState'
import type { Channel } from '@/types'

export default function Channels() {
  const { data: channels = [], isLoading } = useAllChannels()
  const { data: categories = [] } = useCategories()
  const { data: countries = [] } = useCountries()

  const [query, setQuery] = useState('')
  const [country, setCountry] = useState('')
  const [category, setCategory] = useState('')
  const [statusFilter, setStatusFilter] = useState<'all' | 'online' | 'offline'>('all')

  const filtered = useMemo(() => {
    const q = query.toLowerCase()
    return channels.filter(ch => {
      if (q && !ch.name.toLowerCase().includes(q)) return false
      if (country && ch.country !== country) return false
      if (category && ch.category !== category) return false
      if (statusFilter === 'online' && !ch.isOnline) return false
      if (statusFilter === 'offline' && ch.isOnline) return false
      return true
    })
  }, [channels, query, country, category, statusFilter])

  if (isLoading) return <div className="text-white/40 text-sm">Cargando canales...</div>

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Canales</h1>
          <p className="text-white/40 text-sm">{filtered.length.toLocaleString()} de {channels.length.toLocaleString()}</p>
        </div>
      </div>

      <div className="flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-48">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
          <input
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Buscar canal..."
            className="w-full pl-9 pr-3 py-2 bg-bg-surface border border-white/10 rounded-lg text-sm text-white placeholder-white/30 focus:outline-none focus:border-accent-primary"
          />
        </div>
        <select value={country} onChange={e => setCountry(e.target.value)}
          className="px-3 py-2 bg-bg-surface border border-white/10 rounded-lg text-sm text-white/80 focus:outline-none">
          <option value="">Todos los países</option>
          {countries.map(c => <option key={c.code} value={c.code}>{c.flag} {c.name}</option>)}
        </select>
        <select value={category} onChange={e => setCategory(e.target.value)}
          className="px-3 py-2 bg-bg-surface border border-white/10 rounded-lg text-sm text-white/80 focus:outline-none">
          <option value="">Todas las categorías</option>
          {categories.map(c => <option key={c.id} value={c.id}>{c.label}</option>)}
        </select>
        <div className="flex rounded-lg overflow-hidden border border-white/10">
          {(['all', 'online', 'offline'] as const).map(s => (
            <button key={s} onClick={() => setStatusFilter(s)}
              className={`px-3 py-2 text-sm transition-colors ${statusFilter === s ? 'bg-accent-primary text-white' : 'bg-bg-surface text-white/50 hover:text-white'}`}>
              {s === 'all' ? 'Todos' : s === 'online' ? 'En línea' : 'Sin señal'}
            </button>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <EmptyState icon={Search} title="Sin resultados" description="Intenta con otros filtros." />
      ) : (
        <div className="bg-bg-surface rounded-xl border border-white/5 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="border-b border-white/10">
              <tr className="text-white/40 text-xs uppercase">
                <th className="text-left px-4 py-3">Canal</th>
                <th className="text-left px-4 py-3 hidden lg:table-cell">País</th>
                <th className="text-left px-4 py-3 hidden md:table-cell">Categoría</th>
                <th className="text-left px-4 py-3">Estado</th>
                <th className="text-left px-4 py-3 hidden xl:table-cell">ms</th>
                <th className="text-right px-4 py-3">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filtered.slice(0, 200).map(ch => <ChannelRow key={ch.id} channel={ch} />)}
            </tbody>
          </table>
          {filtered.length > 200 && (
            <p className="text-white/30 text-xs text-center py-3">Mostrando 200 de {filtered.length}. Refina la búsqueda para ver más.</p>
          )}
        </div>
      )}
    </div>
  )
}

function ChannelRow({ channel: ch }: { channel: Channel }) {
  const status = !ch.isEnabled ? 'disabled' : ch.isOnline ? 'online' : 'offline'
  return (
    <tr className="hover:bg-white/5 transition-colors">
      <td className="px-4 py-3">
        <div className="flex items-center gap-3">
          {ch.logo && !ch.logo.startsWith('data:') ? (
            <img src={ch.logo} alt="" className="w-9 h-5 object-contain rounded bg-black/30" />
          ) : (
            <div className="w-9 h-5 rounded bg-white/10 flex items-center justify-center text-[9px] text-white/40 font-bold">
              {ch.name.slice(0, 2).toUpperCase()}
            </div>
          )}
          <span className="text-white font-medium">{ch.name}</span>
          {ch.isFeatured && <Star size={12} className="text-yellow-400 fill-yellow-400" />}
        </div>
      </td>
      <td className="px-4 py-3 hidden lg:table-cell text-white/50">{ch.country}</td>
      <td className="px-4 py-3 hidden md:table-cell text-white/50">{ch.categoryLabel}</td>
      <td className="px-4 py-3"><StatusBadge status={status} /></td>
      <td className="px-4 py-3 hidden xl:table-cell text-white/40">{ch.responseMs ?? '—'}</td>
      <td className="px-4 py-3 text-right">
        <button className="p-1.5 hover:bg-white/10 rounded-md text-white/40 hover:text-white transition-colors" title={ch.isEnabled ? 'Deshabilitar' : 'Habilitar'}>
          {ch.isEnabled ? <Eye size={14} /> : <EyeOff size={14} />}
        </button>
      </td>
    </tr>
  )
}
