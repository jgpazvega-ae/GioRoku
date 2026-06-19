import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Layout } from '@/components/layout/Layout'
import Dashboard from '@/pages/Dashboard'
import Sources from '@/pages/Sources'
import Channels from '@/pages/Channels'
import Categories from '@/pages/Categories'
import Logos from '@/pages/Logos'
import Health from '@/pages/Health'

const qc = new QueryClient({
  defaultOptions: { queries: { retry: 2, refetchOnWindowFocus: false } },
})

export default function App() {
  return (
    <QueryClientProvider client={qc}>
      <BrowserRouter basename="/GioRoku/admin">
        <Routes>
          <Route path="/" element={<Layout />}>
            <Route index element={<Dashboard />} />
            <Route path="sources" element={<Sources />} />
            <Route path="channels" element={<Channels />} />
            <Route path="categories" element={<Categories />} />
            <Route path="logos" element={<Logos />} />
            <Route path="health" element={<Health />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}
