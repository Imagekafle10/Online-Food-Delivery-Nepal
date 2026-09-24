import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Eye, Trash2, X, Store, User, MapPin, Bike, Phone, Mail, Check, Ban, ListChecks, CreditCard, History } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import {
  fetchAdminOrders,
  fetchAdminOrderDetail,
  deleteAdminOrder,
  updateAdminOrderStatus,
  closeAdminOrderDetail,
  clearAdminOrdersError,
  AdminOrder,
} from '../features/orders/ordersSlice'
import { assignRider, fetchRiders, clearDeliveryMessages } from '../features/delivery/deliverySlice'
import './orderView.css'
import Pagination from '../components/ui/Pagination'
import {
  OrderStatus,
  adminStatuses,
  statusBadge,
  statusLabel,
} from '../features/orders/orderStatus'

const PAGE_SIZE = 20
/** Fetch a big batch, then split active vs finished orders on the client. */
const FETCH_LIMIT = 500

export type AdminOrdersMode = 'active' | 'history'

const ACTIVE_STATUSES: OrderStatus[] = ['placed', 'accepted', 'cooking', 'on_the_way']
const HISTORY_STATUSES: OrderStatus[] = ['delivered', 'cancelled']

const ORDER_TYPES = ['delivery', 'pickup', 'dine_in']
const PAYMENT_STATUSES = ['unpaid', 'pending', 'paid', 'failed', 'refunded']

const pretty = (v?: string | null) => (v ? v.replace(/_/g, ' ') : '—')
const money = (v: unknown) => `Rs. ${Number(v ?? 0).toFixed(2)}`
const when = (v?: string | null) => (v ? String(v).replace('T', ' ').slice(0, 16) : '—')

function paymentBadge(status?: string) {
  if (status === 'paid') return 'badge-success'
  if (status === 'failed') return 'badge-danger'
  if (status === 'refunded') return 'badge-muted'
  return 'badge-warning'
}

/**
 * super_admin: every order across every restaurant - search, filter, view, delete.
 * mode 'active' = All orders (in progress); mode 'history' = delivered / cancelled only.
 */
export default function AdminOrdersPage({ mode = 'active' }: { mode?: AdminOrdersMode }) {
  const dispatch = useAppDispatch()
  const [params, setParams] = useSearchParams()
  const businessId = params.get('business') ? Number(params.get('business')) : undefined


  const {
    adminOrders: allFetched, adminLoading, adminError,
    adminDetail, adminDetailLoading, adminDeletingId, adminStatusUpdatingId,
  } = useAppSelector((s) => s.orders)

  const { riders, assigningOrderId, error: riderError, success: riderSuccess } = useAppSelector((s) => s.delivery)

  const isHistory = mode === 'history'
  const modeStatuses = isHistory ? HISTORY_STATUSES : ACTIVE_STATUSES

  const [search, setSearch] = useState('')
  const [debounced, setDebounced] = useState('')
  const [status, setStatus] = useState('')
  const [orderType, setOrderType] = useState('')
  const [paymentStatus, setPaymentStatus] = useState('')
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [offset, setOffset] = useState(0)
  const [viewingId, setViewingId] = useState<number | null>(null)

  useEffect(() => {
    const t = setTimeout(() => {
      setDebounced(search.trim())
      setOffset(0)
    }, 300)
    return () => clearTimeout(t)
  }, [search])

  const load = () =>
    dispatch(
      fetchAdminOrders({
        search: debounced || undefined,
        status: status || undefined,
        business_id: businessId,
        order_type: orderType || undefined,
        payment_status: paymentStatus || undefined,
        from: from || undefined,
        to: to || undefined,
        limit: FETCH_LIMIT,
        offset: 0,
      })
    )

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debounced, status, businessId, orderType, paymentStatus, from, to, mode])

  useEffect(() => {
    dispatch(fetchRiders())
  }, [dispatch])

  useEffect(() => {
    if (!riderError && !riderSuccess) return
    const t = setTimeout(() => dispatch(clearDeliveryMessages()), 3000)
    return () => clearTimeout(t)
  }, [riderError, riderSuccess, dispatch])

  const assignableRiders = riders.filter((r) => r.is_active !== 0)

  /** Rider currently on the order (rider_id if the API sends it, otherwise matched by name). */
  const currentRiderId = (o: AdminOrder): number | '' =>
    o.rider_id ?? riders.find((r) => r.full_name === o.rider_name)?.id ?? ''

  const handleRiderChange = (o: AdminOrder, value: string) => {
    const riderId = Number(value)
    if (!riderId || riderId === currentRiderId(o)) return
    const rider = riders.find((r) => r.id === riderId)
    dispatch(assignRider({ orderId: o.id, riderId, riderName: rider?.full_name }))
  }

  const adminOrders = useMemo(
    () => allFetched.filter((o) => modeStatuses.includes(o.status)),
    [allFetched, modeStatuses]
  )
  const adminTotal = adminOrders.length
  const pageOrders = adminOrders.slice(offset, offset + PAGE_SIZE)

  // Reset the filter + page when switching between All orders and Order history.
  useEffect(() => {
    setStatus('')
    setOffset(0)
  }, [mode])

  const resetOffset = () => setOffset(0)

  const openView = (order: AdminOrder) => {
    setViewingId(order.id)
    dispatch(fetchAdminOrderDetail(order.id))
  }

  const closeView = () => {
    setViewingId(null)
    dispatch(closeAdminOrderDetail())
  }

  /** Move an order to its next status; cancelling asks for the reason. */
  const handleStatusChange = async (order: AdminOrder, next: OrderStatus) => {
    const label = (order.order_number as string) || `#${order.id}`
    let note: string | undefined
    if (next === 'cancelled') {
      const reason = prompt(`Why is order ${label} being cancelled?`, 'Problem with the order')
      if (reason === null) return // admin backed out
      note = reason.trim() || 'Cancelled by admin'
    }
    const res = await dispatch(updateAdminOrderStatus({ id: order.id, status: next, note }))
    if (updateAdminOrderStatus.fulfilled.match(res) && viewingId === order.id) {
      dispatch(fetchAdminOrderDetail(order.id)) // refresh the status history in the open modal
    }
  }

  /** Returns true if the order was deleted. */
  const handleDelete = async (order: AdminOrder): Promise<boolean> => {
    const label = (order.order_number as string) || `#${order.id}`
    if (!confirm(`Delete order ${label}? This cannot be undone.`)) return false
    const res = await dispatch(deleteAdminOrder({ id: order.id }))
    if (deleteAdminOrder.fulfilled.match(res)) return true
    const payload = res.payload as { message: string; status: number } | undefined
    if (
      payload?.status === 409 &&
      confirm(`Order ${label} is still in progress ("${statusLabel(order.status)}").\n\nDelete it anyway?`)
    ) {
      const forced = await dispatch(deleteAdminOrder({ id: order.id, force: true }))
      return deleteAdminOrder.fulfilled.match(forced)
    }
    return false
  }

  const clearBusinessFilter = () => {
    const next = new URLSearchParams(params)
    next.delete('business')
    setParams(next)
    resetOffset()
  }

  const businessChipName =
    adminOrders.find((o) => o.business_id === businessId)?.business_name || `#${businessId}`

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>{isHistory ? 'Order history' : 'All orders'}</h1>
          <p>
            {adminTotal} {isHistory ? 'delivered or cancelled' : 'active'} orders across all restaurants
          </p>
        </div>
        <button className="btn btn-ghost btn-sm" onClick={load}>
          Refresh
        </button>
      </div>

      {adminError && (
        <div className="alert alert-error" onClick={() => dispatch(clearAdminOrdersError())}>
          {adminError}
        </div>
      )}

      {riderError && <div className="alert alert-error">{riderError}</div>}
      {riderSuccess && <div className="alert alert-info">{riderSuccess}</div>}

      <div className="filters-bar">
        <input
          className="input"
          placeholder="Search order #, customer, phone, restaurant…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select className="input select" value={status} onChange={(e) => { setStatus(e.target.value); resetOffset() }}>
          <option value="">All statuses</option>
          {modeStatuses.map((s) => (
            <option key={s} value={s}>{statusLabel(s)}</option>
          ))}
        </select>
        <select className="input select" value={orderType} onChange={(e) => { setOrderType(e.target.value); resetOffset() }}>
          <option value="">All types</option>
          {ORDER_TYPES.map((t) => (
            <option key={t} value={t}>{pretty(t)}</option>
          ))}
        </select>
        <select className="input select" value={paymentStatus} onChange={(e) => { setPaymentStatus(e.target.value); resetOffset() }}>
          <option value="">Any payment</option>
          {PAYMENT_STATUSES.map((p) => (
            <option key={p} value={p}>{pretty(p)}</option>
          ))}
        </select>
        <input className="input" type="date" title="From" style={{ maxWidth: 160 }} value={from} onChange={(e) => { setFrom(e.target.value); resetOffset() }} />
        <input className="input" type="date" title="To" style={{ maxWidth: 160 }} value={to} onChange={(e) => { setTo(e.target.value); resetOffset() }} />
        {businessId && (
          <span className="filter-chip">
            {businessChipName}
            <button onClick={clearBusinessFilter} title="Show all restaurants">
              <X size={14} />
            </button>
          </span>
        )}
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order</th>
                <th>Restaurant</th>
                <th>Customer</th>
                <th>Total</th>
                <th>Status</th>
                <th>Rider</th>
                <th>Placed</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {adminLoading && (
                <tr>
                  <td colSpan={8} className="loading-row">Loading…</td>
                </tr>
              )}
              {!adminLoading &&
                pageOrders.map((o) => {
                  const statusOptions = adminStatuses(o.status, o.order_type as string)
                  const isDelivery = !o.order_type || o.order_type === 'delivery'
                  return (
                    <tr key={o.id}>
                      <td>
                        <strong className="gold-text">{(o.order_number as string) || `#${o.id}`}</strong>
                        <div className="muted" style={{ fontSize: 12 }}>{pretty(o.order_type)}</div>
                      </td>
                      <td>{o.business_name || '—'}</td>
                      <td>{o.customer_name || '—'}</td>
                      <td><strong>{money(o.total_amount ?? o.total)}</strong></td>
                      <td>
                        <select
                          className="input select"
                          style={{ padding: '6px 28px 6px 10px', fontSize: 13, width: 'auto', minWidth: 120 }}
                          value={o.status}
                          disabled={adminStatusUpdatingId === o.id || statusOptions.length === 0}
                          onChange={(e) => handleStatusChange(o, e.target.value as OrderStatus)}
                        >
                          <option value={o.status}>{statusLabel(o.status)}</option>
                          {statusOptions.map((s) => (
                            <option key={s} value={s}>{statusLabel(s)}</option>
                          ))}
                        </select>
                      </td>
                      <td>
                        {isDelivery ? (
                          <select
                            className="input select"
                            style={{ padding: '6px 28px 6px 10px', fontSize: 13, width: 'auto', minWidth: 140 }}
                            value={currentRiderId(o)}
                            disabled={assigningOrderId === o.id}
                            onChange={(e) => handleRiderChange(o, e.target.value)}
                          >
                            {currentRiderId(o) === '' && (
                              <option value="">{o.rider_name || 'Assign rider…'}</option>
                            )}
                            {assignableRiders.map((r) => (
                              <option key={r.id} value={r.id}>{r.full_name}</option>
                            ))}
                          </select>
                        ) : (
                          <span className="muted">—</span>
                        )}
                      </td>
                      <td className="muted" style={{ fontSize: 13 }}>{when((o.placed_at || o.created_at) as string)}</td>
                      <td>
                        <div className="row-actions">
                          <button className="act-btn act-view" title="View order" onClick={() => openView(o)}>
                            <Eye size={15} /> View
                          </button>
                          <button
                            className="act-btn act-del icon"
                            title="Delete order"
                            disabled={adminDeletingId === o.id}
                            onClick={() => handleDelete(o)}
                          >
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              {!adminLoading && pageOrders.length === 0 && (
                <tr>
                  <td colSpan={8} className="loading-row">{isHistory ? 'No delivered or cancelled orders yet' : 'No active orders'}</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        <Pagination total={adminTotal} limit={PAGE_SIZE} offset={offset} onChange={setOffset} />
      </div>

      {viewingId !== null && (
        <div className="modal-overlay" onClick={closeView}>
          <div className="modal-card ov-card" onClick={(e) => e.stopPropagation()}>
            {adminDetailLoading && (
              <div className="ov-body"><p className="muted">Loading order…</p></div>
            )}
            {!adminDetailLoading && !adminDetail && (
              <div className="ov-body">
                <p className="muted">Could not load this order.</p>
                <button className="btn btn-ghost" onClick={closeView}>Close</button>
              </div>
            )}

            {adminDetail && (() => {
              const o = adminDetail.order
              const isDelivery = o.order_type === 'delivery'
              const steps: OrderStatus[] = isDelivery
                ? ['placed', 'accepted', 'cooking', 'on_the_way', 'delivered']
                : ['placed', 'accepted', 'cooking', 'delivered']
              const currentIdx = steps.indexOf(o.status)
              return (
                <>
                  <div className="ov-head">
                    <div>
                      <div className="ov-title">Order {o.order_number as string}</div>
                      <div className="ov-sub">
                        <span className={`badge ${statusBadge(o.status)}`}>{statusLabel(o.status)}</span>
                        <span className="badge badge-gold">{pretty(o.order_type)}</span>
                        <span className={`badge ${paymentBadge(o.payment_status)}`}>{o.payment_status || 'unpaid'}</span>
                        <span className="muted" style={{ fontSize: 12.5 }}>
                          {when((o.placed_at || o.created_at) as string)}
                        </span>
                      </div>
                    </div>
                    <button className="ov-close" onClick={closeView} title="Close"><X size={16} /></button>
                  </div>

                  <div className="ov-body">
                    {o.status === 'cancelled' ? (
                      <div className="ov-cancelled">
                        <Ban size={18} />
                        <span>Cancelled{o.cancelled_reason ? ` — ${o.cancelled_reason}` : ''}</span>
                      </div>
                    ) : (
                      <div className="ov-steps">
                        {steps.map((st, i) => (
                          <div
                            key={st}
                            className={`ov-step${i < currentIdx ? ' done' : ''}${i === currentIdx ? ' current' : ''}`}
                          >
                            <div className="ov-dot">{i < currentIdx ? <Check size={14} /> : i + 1}</div>
                            {statusLabel(st)}
                          </div>
                        ))}
                      </div>
                    )}

                    <div className="ov-grid">
                      <div className="ov-box">
                        <h4><Store size={14} /> Restaurant</h4>
                        <div className="ov-name">{o.business_name || '—'}</div>
                        {o.business_phone && <div className="ov-line"><Phone size={12} /> {o.business_phone}</div>}
                        <div className="ov-line">
                          {[o.business_address, o.business_city].filter(Boolean).join(', ') || ''}
                        </div>
                      </div>
                      <div className="ov-box">
                        <h4><User size={14} /> Customer</h4>
                        <div className="ov-name">{o.customer_name || '—'}</div>
                        {o.customer_phone && <div className="ov-line"><Phone size={12} /> {o.customer_phone}</div>}
                        {o.customer_email && <div className="ov-line"><Mail size={12} /> {o.customer_email}</div>}
                      </div>
                      {isDelivery && (
                        <>
                          <div className="ov-box">
                            <h4><MapPin size={14} /> Delivery address</h4>
                            {o.delivery_address_label && <div className="ov-name">{o.delivery_address_label}</div>}
                            <div className="ov-line">
                              {[o.delivery_address_line, o.delivery_city].filter(Boolean).join(', ') || '—'}
                            </div>
                          </div>
                          <div className="ov-box">
                            <h4><Bike size={14} /> Rider</h4>
                            {o.rider_name ? (
                              <>
                                <div className="ov-name">{o.rider_name}</div>
                                {o.rider_phone && <div className="ov-line"><Phone size={12} /> {o.rider_phone}</div>}
                                <div className="ov-line">
                                  {[o.rider_vehicle_type, o.rider_vehicle_number].filter(Boolean).join(' · ')}
                                </div>
                              </>
                            ) : (
                              <div className="ov-line">Not assigned yet</div>
                            )}
                          </div>
                        </>
                      )}
                    </div>

                    <div className="ov-box">
                      <h4><ListChecks size={14} /> Items ({adminDetail.items.length})</h4>
                      <ul className="ov-items">
                        {adminDetail.items.map((it, idx) => (
                          <li key={it.id ?? idx}>
                            <span className="ov-qty">{it.quantity}×</span>
                            <div>
                              <div>{it.name || it.item_name || 'Item'}</div>
                              {(it.notes || it.special_instructions) && (
                                <div className="ov-note">“{it.notes || it.special_instructions}”</div>
                              )}
                            </div>
                            <span className="ov-price">{money(it.item_subtotal ?? it.subtotal)}</span>
                          </li>
                        ))}
                      </ul>
                      {o.special_instructions && <div className="ov-instr">Note: {o.special_instructions}</div>}
                    </div>

                    <div className="ov-grid">
                      <div className="ov-box">
                        <h4><CreditCard size={14} /> Payment</h4>
                        <ul className="ov-totals">
                          <li><span>Subtotal</span><span>{money(o.subtotal)}</span></li>
                          <li><span>Delivery fee</span><span>{money(o.delivery_fee)}</span></li>
                          <li><span>Tax</span><span>{money(o.tax_amount)}</span></li>
                          {Number(o.discount_amount) > 0 && (
                            <li><span>Discount</span><span>- {money(o.discount_amount)}</span></li>
                          )}
                          <li className="grand"><span>Total</span><span>{money(o.total_amount)}</span></li>
                        </ul>
                        {adminDetail.payments.map((p) => (
                          <div key={p.id} className="ov-pay">
                            <span className={`badge ${paymentBadge(p.status === 'success' ? 'paid' : p.status)}`}>{p.status}</span>
                            <span style={{ textTransform: 'uppercase' }}>{p.method}</span>
                            <span>{money(p.amount)}</span>
                            {p.gateway_txn_id && <span className="id">{p.gateway_txn_id}</span>}
                          </div>
                        ))}
                      </div>
                      <div className="ov-box">
                        <h4><History size={14} /> Status history</h4>
                        <ul className="ov-timeline">
                          {adminDetail.statusLog.map((l) => (
                            <li key={l.id}>
                              <strong>{statusLabel(l.status)}</strong>
                              {l.note && <span className="muted"> — {l.note}</span>}
                              <span className="when">{when(l.created_at)}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </div>

                  <div className="ov-foot">
                    <button
                      className="act-btn act-del"
                      style={{ height: 36 }}
                      onClick={async () => {
                        const target = adminOrders.find((x) => x.id === o.id) ?? (o as AdminOrder)
                        if (await handleDelete(target)) closeView()
                      }}
                    >
                      <Trash2 size={15} /> Delete order
                    </button>
                    <div className="ov-foot-right">
                      {adminStatuses(o.status, o.order_type as string).map((st) => (
                        <button
                          key={st}
                          className={st === 'cancelled' ? 'btn btn-ghost btn-sm' : 'btn btn-primary btn-sm'}
                          disabled={adminStatusUpdatingId === o.id}
                          onClick={() => {
                            const target = adminOrders.find((x) => x.id === o.id)
                            handleStatusChange(target ?? (o as AdminOrder), st)
                          }}
                        >
                          {st === 'cancelled' ? 'Cancel order' : `Mark ${statusLabel(st).toLowerCase()}`}
                        </button>
                      ))}
                      <button className="btn btn-ghost btn-sm" onClick={closeView}>Close</button>
                    </div>
                  </div>
                </>
              )
            })()}
          </div>
        </div>
      )}
    </div>
  )
}
