import { useEffect, useRef, useState } from 'react'
import { Search } from 'lucide-react'
import { searchAdminBusinesses, Business } from '../../features/business/businessSlice'

const statusBadge: Record<string, string> = {
  approved: 'badge-success',
  pending: 'badge-warning',
}

interface Props {
  value: string
  onChange: (value: string) => void
  /** Called when the admin picks a restaurant from the dropdown. */
  onPick: (b: Business) => void
  placeholder?: string
}

/**
 * Search box with a live dropdown. Typing filters the page (via onChange) and also lists
 * matching restaurants / hotels / cafes (any status) so the admin can jump straight into one.
 * Keyboard: ↑ ↓ to move, Enter to open, Esc to close.
 */
export default function RestaurantSearch({ value, onChange, onPick, placeholder }: Props) {
  const [open, setOpen] = useState(false)
  const [results, setResults] = useState<Business[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [highlight, setHighlight] = useState(-1)
  const wrapRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const onDown = (e: MouseEvent) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onDown)
    return () => document.removeEventListener('mousedown', onDown)
  }, [])

  // Debounced lookup while the dropdown is open
  useEffect(() => {
    if (!open) return
    let cancelled = false
    const timer = setTimeout(async () => {
      setLoading(true)
      setError(null)
      try {
        const page = await searchAdminBusinesses({ search: value.trim() || undefined, limit: 8 })
        if (!cancelled) {
          setResults(page.businesses || [])
          setHighlight(-1)
        }
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
  }, [value, open])

  const pick = (b: Business) => {
    setOpen(false)
    onPick(b)
  }

  const onKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Escape') {
      setOpen(false)
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      setOpen(true)
      setHighlight((h) => Math.min(h + 1, results.length - 1))
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setHighlight((h) => Math.max(h - 1, 0))
    } else if (e.key === 'Enter' && open && highlight >= 0 && results[highlight]) {
      e.preventDefault()
      pick(results[highlight])
    }
  }

  return (
    <div className="biz-search" ref={wrapRef}>
      <Search size={15} className="biz-search-icon" />
      <input
        className="input biz-search-input"
        placeholder={placeholder ?? 'Search name, city, phone, owner…'}
        value={value}
        onChange={(e) => {
          onChange(e.target.value)
          setOpen(true)
        }}
        onFocus={() => setOpen(true)}
        onKeyDown={onKeyDown}
        autoComplete="off"
      />

      {open && (
        <div className="biz-search-panel">
          <ul className="biz-search-list">
            {loading && <li className="biz-search-empty">Searching…</li>}
            {!loading && error && <li className="biz-search-empty">{error}</li>}
            {!loading && !error && results.length === 0 && (
              <li className="biz-search-empty">No restaurants found</li>
            )}
            {!loading &&
              !error &&
              results.map((b, i) => (
                <li key={b.id}>
                  <button
                    type="button"
                    className={`biz-search-item${i === highlight ? ' active' : ''}`}
                    onMouseEnter={() => setHighlight(i)}
                    onClick={() => pick(b)}
                  >
                    <span className="biz-search-name">{b.name}</span>
                    <span className="muted biz-search-sub">
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
