import { useEffect, useMemo, useState } from 'react'
import { Bike, Plus } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import {
  fetchDeliveryOrders,
  fetchRiders,
  assignRider,
  clearDeliveryMessages,
  setStatusFilter,
  DeliveryOrderStatus,
} from '../features/delivery/deliverySlice'
import { ORDER_STATUSES, ORDER_STATUS_LABEL, isActiveStatus, statusBadge, statusLabel } from '../features/orders/orderStatus'
import AddRiderModal from '../components/ui/AddRiderModal'
import './delivery.css'

const riderStatusBadge: Record<string, string> = {
  available: 'badge-success',
  busy: 'badge-warning',
  offline: 'badge-muted',
}

const STATUS_OPTIONS: { value: DeliveryOrderStatus | 'all'; label: string }[] = [
  { value: 'all', label: 'All statuses' },
  ...ORDER_STATUSES.map((value) => ({ value, label: ORDER_STATUS_LABEL[value] })),
]

export default function DeliveryPage() {
  const dispatch = useAppDispatch()
  const role = useAppSelector((s) => s.auth.user?.role)
  const selectedBusinessId = useAppSelector((s) => s.business.selectedId)
  const isSuperAdmin = role === 'super_admin'

  const {
    orders,
    statusFilter,
    riders,
    loading,
    ridersLoading,
    assigningOrderId,
    error,
    success,
  } = useAppSelector((s) => s.delivery)

  const [pickedRider, setPickedRider] = useState<Record<number, string>>({})
  const [showAddRider, setShowAddRider] = useState(false)

  const businessFilter = isSuperAdmin ? undefined : selectedBusinessId ?? undefined

  const load = () => {
    dispatch(fetchDeliveryOrders({ businessId: businessFilter, status: statusFilter }))
    dispatch(fetchRiders())
  }

  useEffect(() => {
    if (!isSuperAdmin && !selectedBusinessId) return
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [businessFilter, statusFilter, isSuperAdmin, selectedBusinessId])

  useEffect(() => {
    if (!error && !success) return
    const t = setTimeout(() => dispatch(clearDeliveryMessages()), 3500)
    return () => clearTimeout(t)
  }, [error, success, dispatch])

  const availableRiders = useMemo(() => riders.filter((r) => r.status === 'available'), [riders])
  const awaitingCount = useMemo(
    () =>
      orders.filter((o) => {
        if (o.rider_id) return false
        // Superadmin can assign on any unassigned order (incl. placed)
        if (isSuperAdmin) return true
        return o.status === 'accepted' || o.status === 'cooking' || o.status === 'on_the_way'
      }).length,
    [orders, isSuperAdmin]
  )

  /** Superadmin may assign a rider to any order that has none; others only after kitchen accepts. */
  const canAssignRider = (order: { rider_id?: number | null; status: string }) => {
    if (order.rider_id) return false
    if (isSuperAdmin) return true
    return isActiveStatus(order.status)
  }

  const handleAssign = (orderId: number) => {
    const riderId = Number(pickedRider[orderId])
    if (!riderId) return
    dispatch(assignRider({ orderId, riderId }))
  }

  if (!isSuperAdmin && !selectedBusinessId) {
    return (
      <div>
        <div className="page-header">
          <h1>Delivery</h1>
        </div>
        <div className="alert alert-info">Select your business from the top bar.</div>
      </div>
    )
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Delivery</h1>
          <p>
            {orders.length} order{orders.length === 1 ? '' : 's'} · {awaitingCount} awaiting a rider ·{' '}
            {availableRiders.length} rider{availableRiders.length === 1 ? '' : 's'} available
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          {isSuperAdmin && (
            <button className="btn btn-primary btn-sm" onClick={() => setShowAddRider(true)}>
              <Plus size={16} /> Add rider
            </button>
          )}
          <button className="btn btn-ghost btn-sm" onClick={load}>
            Refresh
          </button>
        </div>
      </div>

      {error && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-info">{success}</div>}

      <div className="filters-bar">
        <select
          className="input select"
          value={statusFilter}
          onChange={(e) => dispatch(setStatusFilter(e.target.value as DeliveryOrderStatus | 'all'))}
        >
          {STATUS_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>

      <div className="card" style={{ padding: 0, marginBottom: 28 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order</th>
                {isSuperAdmin && <th>Business</th>}
                <th>Customer</th>
                <th>Status</th>
                <th>Total</th>
                <th>Placed</th>
                <th>Rider</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={isSuperAdmin ? 7 : 6} className="loading-row">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading &&
                orders.map((order) => (
                  <tr key={order.id}>
                    <td>
                      <strong className="gold-text">{(order.order_number as string) || `#${order.id}`}</strong>
                    </td>
                    {isSuperAdmin && (
                      <td className="muted">
                        {(order.business_name as string) || `#${order.business_id}`}
                      </td>
                    )}
                    <td className="muted">{(order.customer_name as string) || '—'}</td>
                    <td>
                      <span className={`badge ${statusBadge(order.status)}`}>
                        {statusLabel(order.status)}
                      </span>
                    </td>
                    <td>
                      <strong>Rs. {Number(order.total_amount ?? 0).toFixed(2)}</strong>
                    </td>
                    <td className="muted" style={{ fontSize: 13 }}>
                      {order.placed_at ? String(order.placed_at).slice(0, 16) : order.created_at ? String(order.created_at).slice(0, 16) : '—'}
                    </td>
                    <td>
                      {order.rider_id ? (
                        <span className="muted">{order.rider_name || `Rider #${order.rider_id}`}</span>
                      ) : canAssignRider(order) ? (
                        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                          <select
                            className="input select"
                            style={{ minWidth: 160 }}
                            value={pickedRider[order.id] || ''}
                            onChange={(e) => setPickedRider((p) => ({ ...p, [order.id]: e.target.value }))}
                          >
                            <option value="">Select rider…</option>
                            {availableRiders.map((r) => (
                              <option key={r.id} value={r.id}>
                                {r.full_name} · {r.vehicle_type}
                              </option>
                            ))}
                          </select>
                          <button
                            className="btn btn-primary btn-sm"
                            disabled={!pickedRider[order.id] || assigningOrderId === order.id}
                            onClick={() => handleAssign(order.id)}
                          >
                            {assigningOrderId === order.id ? 'Assigning…' : 'Assign'}
                          </button>
                        </div>
                      ) : (
                        <span className="muted">—</span>
                      )}
                    </td>
                  </tr>
                ))}
              {!loading && orders.length === 0 && (
                <tr>
                  <td colSpan={isSuperAdmin ? 7 : 6} className="loading-row">
                    No orders found for this filter
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="section-title">Riders</div>
      {ridersLoading && riders.length === 0 ? (
        <p className="muted">Loading riders…</p>
      ) : riders.length === 0 ? (
        <p className="muted">No riders onboarded yet.</p>
      ) : (
        <div className="riders-grid">
          {riders.map((r) => (
            <div key={r.id} className="rider-card">
              <div className="rider-card-header">
                <div className="rider-avatar">
                  <Bike size={16} />
                </div>
                <div style={{ flex: 1 }}>
                  <strong>{r.full_name}</strong>
                  <div className="muted" style={{ fontSize: 12.5 }}>
                    {r.phone || r.email || '—'}
                  </div>
                </div>
                <span className={`badge ${riderStatusBadge[r.status] || 'badge-muted'}`}>{r.status}</span>
              </div>
              <div className="rider-meta">
                <span>
                  {r.vehicle_type}
                  {r.vehicle_number ? ` · ${r.vehicle_number}` : ''}
                </span>
                <span className="gold-text">{r.total_deliveries ?? 0} deliveries</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {showAddRider && <AddRiderModal onClose={() => setShowAddRider(false)} />}
    </div>
  )
}
