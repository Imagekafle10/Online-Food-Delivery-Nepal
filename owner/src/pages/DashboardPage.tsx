import { useEffect } from 'react'
import { Building2, ShoppingBag, UtensilsCrossed, BedDouble } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import { fetchBusinessOrders, fetchAdminOrders } from '../features/orders/ordersSlice'
import { fetchMenu } from '../features/menus/menusSlice'
import { fetchRoomsAndTables } from '../features/rooms/roomsSlice'
import './dashboard.css'

export default function DashboardPage() {
  const dispatch = useAppDispatch()
  const user = useAppSelector((s) => s.auth.user)
  const { list: businesses, selectedId, selectedMeta } = useAppSelector((s) => s.business)
  const isAdmin = user?.role === 'super_admin'
  const {
    list: ownerOrders,
    loading: ownerOrdersLoading,
    error: ownerOrdersError,
    adminOrders,
    adminTotal,
    adminLoading,
    adminError,
  } = useAppSelector((s) => s.orders)
  // super_admin sees platform-wide numbers; owners see their own restaurant
  const orders = isAdmin ? adminOrders : ownerOrders
  const ordersLoading = isAdmin ? adminLoading : ownerOrdersLoading
  const ordersError = isAdmin ? adminError : ownerOrdersError
  const orderCount = isAdmin ? adminTotal : ownerOrders.length
  const { categories } = useAppSelector((s) => s.menus)
  const { rooms, tables } = useAppSelector((s) => s.rooms)

  const selected =
    businesses.find((b) => b.id === selectedId) ??
    (selectedMeta && selectedMeta.id === selectedId ? selectedMeta : undefined)

  useEffect(() => {
    if (isAdmin) {
      dispatch(fetchAdminOrders({ limit: 8 }))
      return
    }
    if (!selectedId) return
    dispatch(fetchBusinessOrders({ businessId: selectedId }))
    dispatch(fetchMenu(selectedId))
    dispatch(fetchRoomsAndTables(selectedId))
  }, [selectedId, isAdmin, dispatch])

  const menuItemCount = categories.reduce((n, c) => n + (c.items?.length || 0), 0)

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p>
            Welcome, {user?.full_name}.{' '}
            {isAdmin ? (
              'Platform overview across all restaurants.'
            ) : selected ? (
              <>
                Viewing <strong className="gold-text">{selected.name}</strong>
              </>
            ) : (
              'Select your business from the top bar.'
            )}
          </p>
        </div>
      </div>

      {ordersError && (
        <div className="alert alert-error">
          Orders: {ordersError}
          {ordersError.toLowerCase().includes('permission') ||
          ordersError.toLowerCase().includes('ownership') ||
          ordersError.toLowerCase().includes('not have')
            ? ' — Log in as the business owner (owner@foodie.test) to manage orders.'
            : ''}
        </div>
      )}

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon">
            <Building2 size={22} />
          </div>
          <div>
            <div className="stat-label">Businesses</div>
            <div className="stat-value">{businesses.length}</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon">
            <ShoppingBag size={22} />
          </div>
          <div>
            <div className="stat-label">{isAdmin ? 'Orders (all restaurants)' : 'Orders'}</div>
            <div className="stat-value">{ordersLoading ? '…' : orderCount}</div>
          </div>
        </div>
        {!isAdmin && (
          <>
        <div className="stat-card">
          <div className="stat-icon">
            <UtensilsCrossed size={22} />
          </div>
          <div>
            <div className="stat-label">Menu items</div>
            <div className="stat-value">{menuItemCount}</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon">
            <BedDouble size={22} />
          </div>
          <div>
            <div className="stat-label">Rooms / Tables</div>
            <div className="stat-value">
              {rooms.length} / {tables.length}
            </div>
          </div>
        </div>
          </>
        )}
      </div>

      <div className="card">
        <h3 className="card-title">Recent orders</h3>
        <p className="muted" style={{ fontSize: 12.5, marginTop: -10, marginBottom: 14 }}>
          {isAdmin
            ? 'Latest orders across all restaurants — open All orders for filters and details.'
            : 'What’s come in for your restaurant. Order status and payment are managed by super admin — see Order history for the full item breakdown.'}
        </p>
        {ordersLoading ? (
          <p className="loading-row">Loading…</p>
        ) : orders.length === 0 ? (
          <p className="muted" style={{ fontSize: 14 }}>
            {isAdmin ? 'No orders yet.' : 'No orders for this business (or you lack access).'}
          </p>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID / Number</th>
                  {isAdmin && <th>Restaurant</th>}
                  <th>Items</th>
                  <th>Total</th>
                  <th>Placed</th>
                </tr>
              </thead>
              <tbody>
                {orders.slice(0, 8).map((o) => (
                  <tr key={o.id}>
                    <td>
                      <strong className="gold-text">
                        {(o.order_number as string) || `#${o.id}`}
                      </strong>
                    </td>
                    {isAdmin && (
                      <td className="muted">{(o as { business_name?: string }).business_name || '—'}</td>
                    )}
                    <td className="muted">
                      {(() => {
                        const n = o.items?.length ?? (o as { item_count?: number }).item_count ?? 0
                        return n ? `${n} item${n === 1 ? '' : 's'}` : '—'
                      })()}
                    </td>
                    <td>
                      Rs. {Number(o.total ?? o.total_amount ?? 0).toFixed(2)}
                    </td>
                    <td className="muted" style={{ fontSize: 13 }}>
                      {(() => {
                        const t = o.created_at ?? (o as { placed_at?: string }).placed_at
                        return t ? String(t).slice(0, 16) : '—'
                      })()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
