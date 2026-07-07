import { Wifi, WifiOff, Globe, Clock, Crown, Filter } from 'lucide-react'
import { useStatus } from '@/hooks/useStatus'
import { StatCard } from '@/components/data-display/StatCard'
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'

const MOCK_UPTIME = Array.from({ length: 7 }, (_, i) => ({
  day: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Hoy'][i],
  pct: 85 + Math.random() * 12,
}))

export default function Dashboard() {
  const { data, isLoading } = useStatus()

  if (isLoading) return <div className="text-white/40 text-sm">Cargando...</div>
  if (!data) return <div className="text-offline text-sm">No se pudo conectar a la API.</div>

  const { stats } = data
  const uptimePct = stats.totalChannels > 0
    ? ((stats.onlineChannels / stats.totalChannels) * 100).toFixed(1)
    : '—'

  const premium = stats.premiumChannels ?? stats.totalChannels
  const free = stats.filteredFreeChannels ?? 0
  const unknown = stats.filteredUnknownChannels ?? 0
  const nonLatino = stats.filteredNonLatinoChannels ?? 0
  const evaluated = premium + free + unknown + nonLatino
  const filteredOut = free + unknown + nonLatino
  const pct = (n: number) => (evaluated > 0 ? (n / evaluated) * 100 : 0)

  const composition = [
    { label: 'De paga · español latino (publicados)', value: premium, color: '#E50914' },
    { label: 'TV abierta (excluidos)', value: free, color: '#3498DB' },
    { label: 'No latino: España/inglés (excluidos)', value: nonLatino, color: '#F39C12' },
    { label: 'Sin clasificar (excluidos)', value: unknown, color: '#5A5A5A' },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Dashboard</h1>
        <p className="text-white/40 text-sm mt-0.5">Estado del sistema en tiempo real</p>
      </div>

      {/* Premium filter hero */}
      <div className="relative overflow-hidden rounded-xl border border-brand/30 bg-gradient-to-br from-brand/15 via-bg-surface to-bg-surface p-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="p-3 rounded-xl bg-brand/20">
              <Crown size={28} className="text-brand" />
            </div>
            <div>
              <p className="text-white/50 text-xs uppercase tracking-widest">Filtro autónomo</p>
              <h2 className="text-xl font-bold text-white">Solo canales de paga · español latino</h2>
              <p className="text-white/40 text-sm mt-0.5">
                {filteredOut.toLocaleString()} canales de TV abierta, de España/inglés o sin clasificar
                se descartan automáticamente en cada corrida del pipeline.
              </p>
            </div>
          </div>
          <div className="text-right">
            <p className="text-5xl font-bold text-brand leading-none">{premium.toLocaleString()}</p>
            <p className="text-white/50 text-xs uppercase tracking-wide mt-1">canales premium</p>
          </div>
        </div>

        {/* Composition bar */}
        <div className="mt-6">
          <div className="flex h-3 w-full overflow-hidden rounded-full bg-white/5">
            {composition.map((c) => (
              <div
                key={c.label}
                style={{ width: `${pct(c.value)}%`, backgroundColor: c.color }}
                title={`${c.label}: ${c.value.toLocaleString()}`}
              />
            ))}
          </div>
          <div className="mt-3 flex flex-wrap gap-x-6 gap-y-1">
            {composition.map((c) => (
              <div key={c.label} className="flex items-center gap-2 text-xs">
                <span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ backgroundColor: c.color }} />
                <span className="text-white/70">{c.label}</span>
                <span className="text-white/40">{c.value.toLocaleString()} ({pct(c.value).toFixed(0)}%)</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        <StatCard label="Canales de paga" value={premium}              icon={Crown}      color="#E50914" />
        <StatCard label="En línea"        value={stats.onlineChannels}  icon={Wifi}       color="#00C851" />
        <StatCard label="Sin señal"       value={stats.offlineChannels} icon={WifiOff}    color="#FF4444" />
        <StatCard label="Descartados"     value={filteredOut}           icon={Filter}     color="#3498DB" />
        <StatCard label="Países"          value={stats.totalCountries}  icon={Globe}      color="#8E44AD" />
        <StatCard label="Disponibilidad"  value={`${uptimePct}%`}       icon={Clock}      color="#F39C12" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-bg-surface rounded-xl p-5 border border-white/5">
          <h2 className="text-white/80 text-sm font-medium mb-4">Disponibilidad (7 días)</h2>
          <ResponsiveContainer width="100%" height={180}>
            <LineChart data={MOCK_UPTIME}>
              <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" />
              <XAxis dataKey="day" stroke="#ffffff40" tick={{ fontSize: 11 }} />
              <YAxis domain={[80, 100]} stroke="#ffffff40" tick={{ fontSize: 11 }} unit="%" />
              <Tooltip
                contentStyle={{ background: '#1A1A1A', border: '1px solid #ffffff20', borderRadius: 8 }}
                labelStyle={{ color: '#ffffff80' }}
                itemStyle={{ color: '#E50000' }}
              />
              <Line type="monotone" dataKey="pct" stroke="#E50000" strokeWidth={2} dot={{ r: 3 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-bg-surface rounded-xl p-5 border border-white/5">
          <h2 className="text-white/80 text-sm font-medium mb-4">Información del sistema</h2>
          <dl className="space-y-3">
            {[
              ['Versión pipeline', data.pipelineVersion],
              ['Total evaluados', evaluated.toLocaleString()],
              ['Categorías activas', String(stats.totalCategories)],
              ['Generado', new Date(data.generatedAt).toLocaleString('es-MX')],
              ['Última validación', stats.lastValidationRun
                ? new Date(stats.lastValidationRun).toLocaleString('es-MX')
                : '—'],
            ].map(([label, value]) => (
              <div key={label} className="flex justify-between text-sm">
                <dt className="text-white/40">{label}</dt>
                <dd className="text-white/80">{value}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>
    </div>
  )
}
