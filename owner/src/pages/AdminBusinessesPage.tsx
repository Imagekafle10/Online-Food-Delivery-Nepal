import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { UtensilsCrossed, ShoppingBag, CheckCircle2, Ban, Trash2, Plus } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import {
  fetchAdminBusinesses,
  selectBusinessWithMeta,
  setBusinessStatus,
  deleteBusiness,
  Business,
} from '../features/business/businessSlice'
import Pagination from '../components/ui/Pagination'
import RestaurantSearch from '../components/ui/RestaurantSearch'
import AddRestaurantModal from '../components/ui/AddRestaurantModal'

const PAGE_SIZE = 20

const statusBadge: Record<string, string> = {
  approved: 'badge-success',
  pending: 'badge-warning',
}

/** super_admin: find any restaurant / hotel / cafe and jump straight into its menu or orders. */
export default function AdminBusinessesPage() {
  const dispatch = useAppDispatch()
  const navigate = useNavigate()
  const { adminPage, adminLoading, error, selectedId, statusUpdatingId } = useAppSelector(
    (s) => s.business
  )

  const [search, setSearch] = useState('')
  const [debounced, setDebounced] = useState('')
  const [status, setStatus] = useState('')
  const [type, setType] = useState('')
  const [offset, setOffset] = useState(0)
  const [showAddRestaurant, setShowAddRestaurant] = useState(false)

  useEffect(() => {
    const t = setTimeout(() => {
      setDebounced(search.trim())
      setOffset(0)
    }, 300)
    return () => clearTimeout(t)
  }, [search])

  useEffect(() => {
    dispatch(
      fetchAdminBusinesses({
        search: debounced || undefined,
        status: status || undefined,
        type: type || undefined,
        limit: PAGE_SIZE,
        offset,
      })
    )
  }, [debounced, status, type, offset, dispatch])

  const reload = () =>
    dispatch(
      fetchAdminBusinesses({
        search: debounced || undefined,
        status: status || undefined,
        type: type || undefined,
        limit: PAGE_SIZE,
        offset,
      })
    )

  const businesses = adminPage?.businesses ?? []

  const openMenu = (b: Business) => {
    dispatch(selectBusinessWithMeta({ id: b.id, name: b.name, type: b.type }))
    navigate('/menus')
  }

  const openOrders = (b: Business) => {
    dispatch(selectBusinessWithMeta({ id: b.id, name: b.name, type: b.type }))
    navigate(`/orders?business=${b.id}`)
  }

  const changeStatus = (b: Business, action: 'approve' | 'suspend') => {
    if (action === 'suspend' && !confirm(`Suspend "${b.name}"? Customers will no longer see it.`)) {
      return
    }
    dispatch(setBusinessStatus({ id: b.id, action }))
  }

  const removeBusiness = (b: Business) => {
    if (
      !confirm(
        `Permanently delete "${b.name}"? Its menu, tables and rooms will be removed. This cannot be undone.`
      )
    ) {
      return
    }
    dispatch(deleteBusiness(b.id))
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Restaurants</h1>
          <p>
            {adminPage ? `${adminPage.total} businesses` : 'Loading…'} · search, manage menus, view
            orders
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-primary btn-sm" onClick={() => setShowAddRestaurant(true)}>
            <Plus size={14} /> Add restaurant
          </button>
          <button className="btn btn-ghost btn-sm" onClick={reload}>
            Refresh
          </button>
        </div>
      </div>

      {showAddRestaurant && <AddRestaurantModal onClose={() => setShowAddRestaurant(false)} />}

      {error && <div className="alert alert-error">{error}</div>}

      <div className="filters-bar">
        <RestaurantSearch value={search} onChange={setSearch} onPick={openMenu} />
        <select
          className="input select"
          value={status}
          onChange={(e) => {
            setStatus(e.target.value)
            setOffset(0)
          }}
        >
          <option value="">All statuses</option>
          <option value="approved">Approved</option>
          <option value="pending">Pending</option>
          <option value="suspended">Suspended</option>
          <option value="rejected">Rejected</option>
        </select>
        <select
          className="input select"
          value={type}
          onChange={(e) => {
            setType(e.target.value)
            setOffset(0)
          }}
        >
          <option value="">All types</option>
          <option value="restaurant">Restaurant</option>
          <option value="cafe">Cafe</option>
          <option value="hotel">Hotel</option>
          <option value="guest_house">Guest house</option>
        </select>
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Restaurant</th>
                <th>Owner</th>
                <th>Type</th>
                <th>City</th>
                <th>Status</th>
                <th>Menu</th>
                <th>Orders</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {adminLoading && (
                <tr>
                  <td colSpan={8} className="loading-row">
                    Loading…
                  </td>
                </tr>
              )}
              {!adminLoading &&
                businesses.map((b) => (
                  <tr
                    key={b.id}
                    style={selectedId === b.id ? { background: 'var(--gold-muted)' } : undefined}
                  >
                    <td>
                      <strong>{b.name}</strong>
                      <div className="muted" style={{ fontSize: 12 }}>
                        {b.phone || b.slug}
                      </div>
                    </td>
                    <td>
                      {b.owner_name || '—'}
                      <div className="muted" style={{ fontSize: 12 }}>
                        {b.owner_email || b.owner_phone || ''}
                      </div>
                    </td>
                    <td>
                      <span className="badge badge-gold">{b.type}</span>
                    </td>
                    <td className="muted">{b.city || '—'}</td>
                    <td>
                      <span className={`badge ${statusBadge[b.status] || 'badge-danger'}`}>
                        {b.status}
                      </span>
                    </td>
                    <td>{b.menu_items_count ?? 0} items</td>
                    <td>{b.orders_count ?? 0}</td>
                    <td>
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                        <button className="btn btn-primary btn-sm" onClick={() => openMenu(b)}>
                          <UtensilsCrossed size={14} /> Menu
                        </button>
                        <button className="btn btn-ghost btn-sm" onClick={() => openOrders(b)}>
                          <ShoppingBag size={14} /> Orders
                        </button>
                        {b.status !== 'approved' && (
                          <button
                            className="btn btn-ghost btn-sm"
                            disabled={statusUpdatingId === b.id}
                            onClick={() => changeStatus(b, 'approve')}
                          >
                            <CheckCircle2 size={14} /> Approve
                          </button>
                        )}
                        {b.status === 'suspended' && (
                          <button
                            className="btn btn-danger btn-sm"
                            disabled={statusUpdatingId === b.id}
                            onClick={() => removeBusiness(b)}
                          >
                            <Trash2 size={14} /> Delete
                          </button>
                        )}
                        {b.status === 'approved' && (
                          <button
                            className="btn btn-danger btn-sm"
                            disabled={statusUpdatingId === b.id}
                            onClick={() => changeStatus(b, 'suspend')}
                          >
                            <Ban size={14} /> Suspend
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              {!adminLoading && businesses.length === 0 && (
                <tr>
                  <td colSpan={8} className="loading-row">
                    No businesses match your search.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        {adminPage && (
          <Pagination
            total={adminPage.total}
            limit={adminPage.limit}
            offset={adminPage.offset}
            onChange={setOffset}
          />
        )}
      </div>
    </div>
  )
}
