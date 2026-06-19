import { NavLink } from 'react-router-dom'
import { LayoutDashboard, Radio, FolderOpen, Globe, Image, Activity } from 'lucide-react'
import clsx from 'clsx'

const nav = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/sources', icon: Radio, label: 'Fuentes' },
  { to: '/channels', icon: FolderOpen, label: 'Canales' },
  { to: '/categories', icon: Globe, label: 'Categorías' },
  { to: '/logos', icon: Image, label: 'Logos' },
  { to: '/health', icon: Activity, label: 'Salud' },
]

export function Sidebar() {
  return (
    <aside className="w-56 bg-bg-surface border-r border-white/10 flex flex-col">
      <div className="px-6 py-5 border-b border-white/10">
        <span className="text-accent-primary font-bold text-xl tracking-tight">GioRoku</span>
        <span className="text-white/40 text-xs ml-1">Admin</span>
      </div>
      <nav className="flex-1 py-4 space-y-0.5 px-2">
        {nav.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              clsx(
                'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors',
                isActive
                  ? 'bg-accent-primary/20 text-accent-primary font-medium'
                  : 'text-white/60 hover:bg-white/5 hover:text-white'
              )
            }
          >
            <Icon size={17} />
            {label}
          </NavLink>
        ))}
      </nav>
    </aside>
  )
}
