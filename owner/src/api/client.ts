const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api'

/** Builds "?a=1&b=2" from a params object, skipping empty values. */
export function qs(params: Record<string, string | number | undefined | null>): string {
  const q = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => {
    if (value === undefined || value === null || value === '') return
    q.set(key, String(value))
  })
  const str = q.toString()
  return str ? `?${str}` : ''
}

/** Turns a stored image path like "/uploads/x.jpg" into a full URL the browser can load. */
export function assetUrl(path?: string | null): string | null {
  if (!path) return null
  if (/^(https?:|blob:|data:)/i.test(path)) return path
  const origin = API_URL.replace(/\/api\/?$/, '')
  return `${origin}${path.startsWith('/') ? '' : '/'}${path}`
}

export class ApiError extends Error {
  status: number
  errors?: unknown
  constructor(message: string, status: number, errors?: unknown) {
    super(message)
    this.status = status
    this.errors = errors
  }
}

function getToken(): string | null {
  return localStorage.getItem('accessToken')
}

export async function api<T = unknown>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const isFormData = typeof FormData !== 'undefined' && options.body instanceof FormData

  const headers: Record<string, string> = {
    ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
    ...(options.headers as Record<string, string> | undefined),
  }

  const token = getToken()
  if (token) headers.Authorization = `Bearer ${token}`

  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
  })

  let body: { success?: boolean; message?: string; data?: T; errors?: unknown } = {}
  try {
    body = await res.json()
  } catch {
    // non-json
  }

  if (!res.ok || body.success === false) {
    throw new ApiError(body.message || res.statusText || 'Request failed', res.status, body.errors)
  }

  return (body.data !== undefined ? body.data : body) as T
}

export const apiClient = {
  get: <T>(path: string) => api<T>(path),
  post: <T>(path: string, body?: unknown) =>
    api<T>(path, { method: 'POST', body: body ? JSON.stringify(body) : undefined }),
  patch: <T>(path: string, body?: unknown) =>
    api<T>(path, { method: 'PATCH', body: body ? JSON.stringify(body) : undefined }),
  delete: <T>(path: string) => api<T>(path, { method: 'DELETE' }),
  postForm: <T>(path: string, form: FormData) => api<T>(path, { method: 'POST', body: form }),
  patchForm: <T>(path: string, form: FormData) => api<T>(path, { method: 'PATCH', body: form }),
}
