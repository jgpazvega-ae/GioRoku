import { useCategories } from '@/hooks/useCategories'

export default function Categories() {
  const { data: categories = [], isLoading } = useCategories()

  if (isLoading) return <div className="text-white/40 text-sm">Cargando...</div>

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-white">Categorías</h1>
        <p className="text-white/40 text-sm">{categories.length} categorías</p>
      </div>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {categories.map(cat => (
          <div key={cat.id} className="bg-bg-surface rounded-xl p-4 border border-white/5 flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg flex items-center justify-center text-lg font-bold text-white"
              style={{ backgroundColor: `${cat.color}33` }}>
              <span style={{ color: cat.color }}>
                {cat.icon?.charAt(0).toUpperCase() ?? cat.label.charAt(0)}
              </span>
            </div>
            <div>
              <p className="text-white text-sm font-medium">{cat.label}</p>
              <p className="text-white/40 text-xs">{cat.channelCount?.toLocaleString() ?? 0} canales</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
