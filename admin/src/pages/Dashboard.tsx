import { Tv, Wifi, WifiOff, Globe, FolderOpen, Clock } from 'lucide-react'
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

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Dashboard</h1>
        <p className="text-white/40 text-sm mt-0.5">Estado del sistema en tiempo real</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        <StatCard label="Total canales"    value={stats.totalChannels}   icon={Tv}       color="#E50000" />
        <StatCard label="En línea"         value={stats.onlineChannels}  icon={Wifi}     color="#00C851" />
        <StatCard label="Sin señal"        value={stats.offlineChannels} icon={WifiOff}  color="#FF4444" />
        <StatCard label="Países"           value={stats.totalCountries}  icon={Globe}    color="#3498DB" />
        <StatCard label="Categorías"       value={stats.totalCategories} icon={FolderOpen} color="#9B59B6" />
        <StatCard label="Disponibilidad"   value={`${uptimePct}%`}       icon={Clock}    color="#F39C12" />
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
