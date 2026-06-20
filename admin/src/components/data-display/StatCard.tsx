import clsx from 'clsx'
import type { LucideIcon } from 'lucide-react'

interface Props {
  label: string
  value: string | number
  icon: LucideIcon
  trend?: 'up' | 'down' | 'neutral'
  color?: string
}

export function StatCard({ label, value, icon: Icon, trend, color = '#E50000' }: Props) {
  return (
    <div className="bg-bg-surface rounded-xl p-5 border border-white/5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-white/50 text-xs uppercase tracking-wide mb-1">{label}</p>
          <p className="text-3xl font-bold text-white">{typeof value === 'number' ? value.toLocaleString() : value}</p>
        </div>
        <div className="p-2.5 rounded-lg" style={{ backgroundColor: `${color}22` }}>
          <Icon size={20} style={{ color }} />
        </div>
      </div>
      {trend && (
        <p className={clsx('text-xs mt-3', trend === 'up' ? 'text-online' : trend === 'down' ? 'text-offline' : 'text-white/40')}>
          {trend === 'up' ? '↑' : trend === 'down' ? '↓' : '→'} en relación al día anterior
        </p>
      )}
    </div>
  )
}
