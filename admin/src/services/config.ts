export const config = {
  apiBase: import.meta.env.VITE_API_BASE ?? 'https://jgpazvega-ae.github.io/GioRoku/api/v1',
  githubOwner: import.meta.env.VITE_GITHUB_OWNER ?? 'jgpazvega-ae',
  githubRepo: import.meta.env.VITE_GITHUB_REPO ?? 'GioRoku',
  githubBranch: import.meta.env.VITE_GITHUB_BRANCH ?? 'main',
} as const
