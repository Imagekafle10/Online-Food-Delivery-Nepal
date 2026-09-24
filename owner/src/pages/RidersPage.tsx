import { useEffect, useMemo, useState } from 'react'
import { Bike, Plus, Search, Ban, CheckCircle2, Trash2 } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import { fetchRiders, clearDeliveryMessages, Rider } from '../features/delivery/deliverySlice'
import { setUserStatus, deleteUser } from '../features/users/usersSlice'
import AddRiderModal from '../components/ui/AddRiderModal'

const riderStatusBadge: Record<string, string> = {
  available: 'badge-success',
  busy: 'badge-warning',
  offline: 'badge-muted',
}

/** super_admin: rider management - onboard riders, see who is available / busy / offline. */
export default function RidersPage() {
  const dispatch = useAppDispatch()
  const { riders, ridersLoading, error, success } = useAppSelector((s) => s.delivery)
  const updatingId = useAppSelector((s) => s.users.updatingId)
  const usersError = useAppSelector((s) => s.users.error)

  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [showAdd, setShowAdd] = useState(false)

  useEffect(() => {
    dispatch(fetchRiders())
  }, [dispatch])

  useEffect(() => {
    if (!error && !success) return
    const t = setTimeout(() => dispatch(clearDeliveryMessages()), 3500)
    return () => clearTimeout(t)
  }, [error, success, dispatch])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return riders.filter((r) => {
      if (status && r.status !== status) return false
      if (!q) return true
      return [r.full_name, r.phone, r.email, r.vehicle_number]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q))
    })
  }, [riders, search, status])

  const changeAccount = async (r: Rider, action: 'suspend' | 'activate') => {
    if (action === 'suspend' && !window.confirm(`Suspend ${r.full_name}? They will be blocked from logging in and set offline.`)) {
      return
    }
    const res = await dispatch(setUserStatus({ id: r.user_id, action }))
    if (setUserStatus.fulfilled.match(res)) dispatch(fetchRiders())
  }

  const removeRider = async (r: Rider) => {
    if (!window.confirm(`Permanently delete ${r.full_name}? This cannot be undone.`)) return
    const res = await dispatch(deleteUser(r.user_id))
    if (deleteUser.fulfilled.match(res)) dispatch(fetchRiders())
  }

  const count = (s: string) => riders.filter((r) => r.status === s).length

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Riders</h1>
          <p>
            {riders.length} total · {count('available')} available · {count('busy')} busy ·{' '}
            {count('offline')} offline
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-ghost btn-sm" onClick={() => dispatch(fetchRiders())}>
            Refresh
          </button>
          <button className="btn btn-primary btn-sm" onClick={() => setShowAdd(true)}>
            <Plus size={16} /> Add rider
          </button>
        </div>
      </div>

      {(error || usersError) && <div className="alert alert-error">{error || usersError}</div>}
      {success && <div className="alert alert-info">{success}</div>}

      <div className="filters-bar">
        <div style={{ position: 'relative', width: 320, maxWidth: '100%' }}>
          <Search
            size={15}
            style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }}
          />
          <input
            className="input"
            style={{ paddingLeft: 34, maxWidth: 'none' }}
            placeholder="Search name, phone, vehicle no…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select className="input select" value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">All statuses</option>
          <option value="available">Available</option>
          <option value="busy">Busy</option>
          <option value="offline">Offline</option>
        </select>
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Rider</th>
                <th>Contact</th>
                <th>Vehicle</th>
                <th>Status</th>
                <th>Deliveries</th>
                <th>Rating</th>
                <th>Account</th>
              </tr>
            </thead>
            <tbody>
              {ridersLoading && riders.length === 0 && (
                <tr>
                  <td colSpan={7} className="loading-row">
                    Loading…
                  </td>
                </tr>
              )}
              {filtered.map((r) => (
                <tr key={r.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div className="rider-avatar">
                        <Bike size={16} />
                      </div>
                      <strong>{r.full_name}</strong>
                    </div>
                  </td>
                  <td className="muted">{r.phone || r.email || '—'}</td>
                  <td className="muted">
                    {r.vehicle_type}
                    {r.vehicle_number ? ` · ${r.vehicle_number}` : ''}
                  </td>
                  <td>
                    {r.is_active === 0 ? (
                      <span className="badge badge-danger">suspended</span>
                    ) : (
                      <span className={`badge ${riderStatusBadge[r.status] || 'badge-muted'}`}>
                        {r.status}
                      </span>
                    )}
                  </td>
                  <td>{r.total_deliveries ?? 0}</td>
                  <td className="muted">{r.rating != null ? Number(r.rating).toFixed(1) : '—'}</td>
                  <td>
                    {r.is_active === 0 ? (
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button
                          className="btn btn-ghost btn-sm"
                          disabled={updatingId === r.user_id}
                          onClick={() => changeAccount(r, 'activate')}
                        >
                          <CheckCircle2 size={14} /> Reactivate
                        </button>
                        <button
                          className="btn btn-danger btn-sm"
                          disabled={updatingId === r.user_id}
                          onClick={() => removeRider(r)}
                        >
                          <Trash2 size={14} /> Delete
                        </button>
                      </div>
                    ) : (
                      <button
                        className="btn btn-danger btn-sm"
                        disabled={updatingId === r.user_id}
                        onClick={() => changeAccount(r, 'suspend')}
                      >
                        <Ban size={14} /> Suspend
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {!ridersLoading && filtered.length === 0 && (
                <tr>
                  <td colSpan={7} className="loading-row">
                    {riders.length === 0 ? 'No riders onboarded yet.' : 'No riders match your filters.'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showAdd && <AddRiderModal onClose={() => setShowAdd(false)} />}
    </div>
  )
}
