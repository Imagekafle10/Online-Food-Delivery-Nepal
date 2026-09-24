import { useEffect } from 'react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import { fetchRoomsAndTables } from '../features/rooms/roomsSlice'
import './rooms.css'

export default function RoomsPage() {
  const dispatch = useAppDispatch()
  const selectedId = useAppSelector((s) => s.business.selectedId)
  const { rooms, tables, loading, error } = useAppSelector((s) => s.rooms)

  useEffect(() => {
    if (selectedId) dispatch(fetchRoomsAndTables(selectedId))
  }, [selectedId, dispatch])

  if (!selectedId) {
    return (
      <div>
        <div className="page-header">
          <h1>Rooms & Tables</h1>
        </div>
        <div className="alert alert-info">Select a business from the top bar first.</div>
      </div>
    )
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Rooms & Tables</h1>
          <p>
            {rooms.length} rooms · {tables.length} tables · business #{selectedId}
          </p>
        </div>
        <button
          className="btn btn-ghost btn-sm"
          onClick={() => dispatch(fetchRoomsAndTables(selectedId))}
        >
          Refresh
        </button>
      </div>

      {error && <div className="alert alert-error">{error}</div>}
      {loading && <p className="loading-row">Loading…</p>}

      <div className="section-title">Rooms</div>
      {rooms.length === 0 && !loading ? (
        <p className="muted" style={{ marginBottom: 24 }}>
          No rooms for this business.
        </p>
      ) : (
        <div className="rooms-grid" style={{ marginBottom: 24 }}>
          {rooms.map((r) => (
            <div key={r.id} className="room-card">
              <div className="room-card-header">
                <strong className="room-number">
                  {String(r.room_number || r.name || `#${r.id}`)}
                </strong>
                <span className="badge badge-gold">{String(r.type || 'room')}</span>
              </div>
              <div className="room-meta">
                {r.capacity != null && <span>Cap. {r.capacity}</span>}
                {(r.price_per_night != null || r.base_price != null) && (
                  <span className="gold-text">
                    Rs. {Number(r.price_per_night ?? r.base_price).toFixed(0)}/night
                  </span>
                )}
                {r.status && <span className="badge badge-muted">{String(r.status)}</span>}
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="section-title">Tables</div>
      {tables.length === 0 && !loading ? (
        <p className="muted">No tables for this business.</p>
      ) : (
        <div className="rooms-grid">
          {tables.map((t) => (
            <div key={t.id} className="room-card">
              <div className="room-card-header">
                <strong className="room-number">
                  {String(t.table_number || `T-${t.id}`)}
                </strong>
                <span className="badge badge-info">table</span>
              </div>
              <div className="room-meta">
                {t.capacity != null && <span>Cap. {t.capacity}</span>}
                {t.location_note && <span>{String(t.location_note)}</span>}
                {t.is_available != null && (
                  <span className={`badge ${t.is_available ? 'badge-success' : 'badge-warning'}`}>
                    {t.is_available ? 'available' : 'busy'}
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
