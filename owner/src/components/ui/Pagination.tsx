interface PaginationProps {
  total: number
  limit: number
  offset: number
  onChange: (offset: number) => void
}

/** Simple prev / next pager for server-side paged lists. */
export default function Pagination({ total, limit, offset, onChange }: PaginationProps) {
  if (total <= 0) return null
  const from = offset + 1
  const to = Math.min(offset + limit, total)
  return (
    <div className="pager">
      <span className="muted">
        Showing {from}–{to} of {total}
      </span>
      <div style={{ display: 'flex', gap: 8 }}>
        <button
          className="btn btn-ghost btn-sm"
          disabled={offset <= 0}
          onClick={() => onChange(Math.max(0, offset - limit))}
        >
          Previous
        </button>
        <button
          className="btn btn-ghost btn-sm"
          disabled={offset + limit >= total}
          onClick={() => onChange(offset + limit)}
        >
          Next
        </button>
      </div>
    </div>
  )
}
