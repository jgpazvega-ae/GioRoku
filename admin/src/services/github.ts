import { config } from './config'

const GH_API = 'https://api.github.com'

function token(): string {
  return localStorage.getItem('github_pat') ?? ''
}

function headers() {
  return {
    Authorization: `Bearer ${token()}`,
    Accept: 'application/vnd.github.v3+json',
    'Content-Type': 'application/json',
  }
}

async function getFileSha(path: string): Promise<string | null> {
  const res = await fetch(
    `${GH_API}/repos/${config.githubOwner}/${config.githubRepo}/contents/${path}?ref=${config.githubBranch}`,
    { headers: headers() }
  )
  if (!res.ok) return null
  const data = await res.json()
  return (data as { sha: string }).sha
}

export async function readConfig(path: string): Promise<unknown> {
  const res = await fetch(
    `${GH_API}/repos/${config.githubOwner}/${config.githubRepo}/contents/${path}?ref=${config.githubBranch}`,
    { headers: headers() }
  )
  if (!res.ok) throw new Error(`Cannot read ${path}`)
  const data = await res.json() as { content: string }
  return JSON.parse(atob(data.content))
}

export async function writeConfig(path: string, content: unknown, message: string): Promise<void> {
  const sha = await getFileSha(path)
  const body: Record<string, unknown> = {
    message,
    content: btoa(JSON.stringify(content, null, 2)),
    branch: config.githubBranch,
  }
  if (sha) body.sha = sha

  const res = await fetch(
    `${GH_API}/repos/${config.githubOwner}/${config.githubRepo}/contents/${path}`,
    { method: 'PUT', headers: headers(), body: JSON.stringify(body) }
  )
  if (!res.ok) throw new Error(`Cannot write ${path}: ${res.status}`)
}

export function hasToken(): boolean {
  return !!localStorage.getItem('github_pat')
}

export function setToken(pat: string): void {
  localStorage.setItem('github_pat', pat)
}
