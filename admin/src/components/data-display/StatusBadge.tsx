import clsx from 'clsx'

type Status = 'online' | 'offline' | 'disabled' | 'unknown'

interface Props { status: Status }

const MAP: Record<Status, { label: string; dot: string; text: string }> = {
  online:   { label: 'En línea',    dot: 'bg-online',  text: 'text-online' },
  offline:  { label: 'Sin señal',   dot: 'bg-offline', text: 'text-offline' },
  disabled: { label: 'Deshabilitado', dot: 'bg-white/30', text: 'text-white/40' },
  unknown:  { label: 'Desconocido', dot: 'bg-pending', text: 'text-pending' },
}

export function StatusBadge({ status }: Props) {
  const { label, dot, text } = MAP[status] ?? MAP.unknown
  return (
    <span className={clsx('inline-flex items-center gap-1.5 text-xs font-medium', text)}>
      <span className={clsx('w-1.5 h-1.5 rounded-full', dot)} />
      {label}
    </span>
  )
}
