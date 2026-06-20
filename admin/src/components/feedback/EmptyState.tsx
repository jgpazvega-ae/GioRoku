import type { ReactNode } from 'react'
import type { LucideIcon } from 'lucide-react'

interface Props {
  icon: LucideIcon
  title: string
  description?: string
  action?: ReactNode
}

export function EmptyState({ icon: Icon, title, description, action }: Props) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <Icon size={40} className="text-white/20 mb-4" />
      <h3 className="text-white/70 font-medium mb-1">{title}</h3>
      {description && <p className="text-white/40 text-sm mb-4">{description}</p>}
      {action}
    </div>
  )
}
