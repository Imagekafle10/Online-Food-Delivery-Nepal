import { useEffect } from 'react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import { fetchBusinesses, selectBusiness } from '../features/business/businessSlice'
import AdminBusinessesPage from './AdminBusinessesPage'

export default function BusinessesPage() {
  const role = useAppSelector((s) => s.auth.user?.role)
  return role === 'super_admin' ? <AdminBusinessesPage /> : <OwnerBusinessesPage />
}

function OwnerBusinessesPage() {
  const dispatch = useAppDispatch()
  const { list, loading, error, selectedId } = useAppSelector((s) => s.business)

  useEffect(() => {
    dispatch(fetchBusinesses())
  }, [dispatch])

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Businesses</h1>
          <p>{list.length} businesses from API</p>
        </div>
        <button className="btn btn-ghost btn-sm" onClick={() => dispatch(fetchBusinesses())}>
          Refresh
        </button>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>City</th>
                <th>Status</th>
                <th>Open</th>
                <th>Features</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={7} className="loading-row">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading &&
                list.map((b) => (
                  <tr key={b.id} style={selectedId === b.id ? { background: 'var(--gold-muted)' } : undefined}>
                    <td>
                      <strong>{b.name}</strong>
                      <div className="muted" style={{ fontSize: 12 }}>
                        {b.slug}
                      </div>
                    </td>
                    <td>
                      <span className="badge badge-gold">{b.type}</span>
                    </td>
                    <td className="muted">{b.city || '—'}</td>
                    <td>
                      <span
                        className={`badge ${
                          b.status === 'approved'
                            ? 'badge-success'
                            : b.status === 'pending'
                              ? 'badge-warning'
                              : 'badge-danger'
                        }`}
                      >
                        {b.status}
                      </span>
                    </td>
                    <td>{b.is_open ? 'Yes' : 'No'}</td>
                    <td className="muted" style={{ fontSize: 12 }}>
                      {[
                        b.has_food_ordering && 'Food',
                        b.has_table_booking && 'Tables',
                        b.has_room_booking && 'Rooms',
                      ]
                        .filter(Boolean)
                        .join(' · ') || '—'}
                    </td>
                    <td>
                      <button
                        className="btn btn-primary btn-sm"
                        onClick={() => dispatch(selectBusiness(b.id))}
                      >
                        {selectedId === b.id ? 'Selected' : 'Select'}
                      </button>
                    </td>
                  </tr>
                ))}
              {!loading && list.length === 0 && (
                <tr>
                  <td colSpan={7} className="loading-row">
                    No businesses found. Load seed_dummy_data.sql into MySQL.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
