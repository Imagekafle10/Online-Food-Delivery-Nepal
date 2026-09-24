import { useEffect, useRef, useState } from 'react'
import { ChevronDown, Search } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../../hooks/redux'
import {
  searchAdminBusinesses,
  selectBusinessWithMeta,
  Business,
} from '../../features/business/businessSlice'

const statusBadge: Record<string, string> = {
  approved: 'badge-success',
  pending: 'badge-warning',
}

/**
 * super_admin: search ANY restaurant / hotel / cafe (all statuses) by name, city, phone
 * or owner, and switch to it. Menus, Orders and Dashboard follow the selection.
 */
export default function BusinessPicker() {
  const dispatch = useAppDispatch()
  const { selectedId, selectedMeta, list } = useAppSelector((s) => s.business)

  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<Business[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const wrapRef = useRef<HTMLDivElement>(null)

  const currentName =
    selectedMeta && selectedMeta.id === selectedId
      ? selectedMeta.name
      : list.find((b) => b.id === selectedId)?.name

  useEffect(() => {
    const onDown = (e: MouseEvent) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onDown)
    return () => document.removeEventListener('mousedown', onDown)
  }, [])

  // Debounced search while the panel is open
  useEffect(() => {
    if (!open) return
    let cancelled = false
    const timer = setTimeout(async () => {
      setLoading(true)
      setError(null)
      try {
        const page = await searchAdminBusinesses({ search: query.trim() || undefined, limit: 8 })
        if (!cancelled) setResults(page.businesses || [])
      } catch (e: unknown) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'Search failed')
      } finally {
        if (!cancelled) setLoading(false)
      }
    }, 250)
    return () => {
      cancelled = true
      clearTimeout(timer)
    }
  }, [query, open])

  const pick = (b: Business) => {
    dispatch(selectBusinessWithMeta({ id: b.id, name: b.name, type: b.type }))
    setOpen(false)
    setQuery('')
  }

  return (
    <div className="biz-picker" ref={wrapRef}>
      <button
        type="button"
        className="input biz-picker-btn"
        onClick={() => setOpen((o) => !o)}
        title="Search restaurants"
      >
        <Search size={15} />
        <span className="biz-picker-label">{currentName ?? 'Search restaurants…'}</span>
        <ChevronDown size={14} />
      </button>

      {open && (
        <div className="biz-picker-panel">
          <input
            className="input"
            autoFocus
            placeholder="Name, city, owner, phone…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          <ul className="biz-picker-list">
            {loading && <li className="biz-picker-empty">Searching…</li>}
            {!loading && error && <li className="biz-picker-empty">{error}</li>}
            {!loading && !error && results.length === 0 && (
              <li className="biz-picker-empty">No restaurants found</li>
            )}
            {!loading &&
              !error &&
              results.map((b) => (
                <li key={b.id}>
                  <button
                    type="button"
                    className={`biz-picker-item${b.id === selectedId ? ' active' : ''}`}
                    onClick={() => pick(b)}
                  >
                    <span className="biz-picker-name">{b.name}</span>
                    <span className="muted biz-picker-sub">
                      {b.type}
                      {b.city ? ` · ${b.city}` : ''}
                    </span>
                    <span className={`badge ${statusBadge[b.status] || 'badge-danger'}`}>
                      {b.status}
                    </span>
                  </button>
                </li>
              ))}
          </ul>
        </div>
      )}
    </div>
  )
}
