import { useEffect, useState } from 'react'
import { Search, Ban, CheckCircle2, Trash2, Plus } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import {
  fetchUsers,
  setUserStatus,
  deleteUser,
  clearUserMessages,
  PlatformUser,
} from '../features/users/usersSlice'
import Pagination from '../components/ui/Pagination'
import AddUserModal from '../components/ui/AddUserModal'

const PAGE_SIZE = 20

const statusBadge = (s: string) =>
  s === 'active' ? 'badge-success' : s === 'suspended' ? 'badge-danger' : 'badge-muted'

const roleLabel: Record<string, string> = {
  customer: 'Customer',
  business_owner: 'Owner',
  rider: 'Rider',
  super_admin: 'Admin',
}

/** super_admin: monitor suspended accounts, suspend a user, or lift a suspension. */
export default function UsersPage() {
  const dispatch = useAppDispatch()
  const { page, loading, updatingId, error, notice } = useAppSelector((s) => s.users)
  const currentUserId = useAppSelector((s) => s.auth.user?.id)

  const [search, setSearch] = useState('')
  const [debounced, setDebounced] = useState('')
  const [status, setStatus] = useState('suspended')
  const [role, setRole] = useState('')
  const [offset, setOffset] = useState(0)
  const [showAddUser, setShowAddUser] = useState(false)

  useEffect(() => {
    const t = setTimeout(() => {
      setDebounced(search.trim())
      setOffset(0)
    }, 300)
    return () => clearTimeout(t)
  }, [search])

  const load = () =>
    dispatch(
      fetchUsers({
        search: debounced || undefined,
        status: status || undefined,
        role: role || undefined,
        limit: PAGE_SIZE,
        offset,
      })
    )

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debounced, status, role, offset])

  useEffect(() => {
    if (!error && !notice) return
    const t = setTimeout(() => dispatch(clearUserMessages()), 3500)
    return () => clearTimeout(t)
  }, [error, notice, dispatch])

  const users = page?.users ?? []

  const change = async (u: PlatformUser, action: 'suspend' | 'activate') => {
    if (action === 'suspend' && !window.confirm(`Suspend ${u.full_name}? They will be signed out of new sessions and blocked from logging in.`)) {
      return
    }
    const res = await dispatch(setUserStatus({ id: u.id, action }))
    // Row no longer matches the current filter (e.g. reactivated while viewing "Suspended")
    if (setUserStatus.fulfilled.match(res) && status) load()
  }

  const remove = async (u: PlatformUser) => {
    if (!window.confirm(`Permanently delete ${u.full_name}? This cannot be undone.`)) return
    await dispatch(deleteUser(u.id))
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>User monitoring</h1>
          <p>
            {page ? `${page.total} ${status || 'total'} user${page.total === 1 ? '' : 's'}` : 'Loading…'}{' '}
            · track suspended accounts, suspend or reactivate users
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-primary btn-sm" onClick={() => setShowAddUser(true)}>
            <Plus size={14} /> Add user
          </button>
          <button className="btn btn-ghost btn-sm" onClick={load}>
            Refresh
          </button>
        </div>
      </div>

      {showAddUser && <AddUserModal onClose={() => setShowAddUser(false)} />}

      {error && <div className="alert alert-error">{error}</div>}
      {notice && <div className="alert alert-info">{notice}</div>}

      <div className="filters-bar">
        <div style={{ position: 'relative', width: 320, maxWidth: '100%' }}>
          <Search
            size={15}
            style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }}
          />
          <input
            className="input"
            style={{ paddingLeft: 34, maxWidth: 'none' }}
            placeholder="Search name, email, phone…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select
          className="input select"
          value={status}
          onChange={(e) => {
            setStatus(e.target.value)
            setOffset(0)
          }}
        >
          <option value="suspended">Suspended</option>
          <option value="active">Active</option>
          <option value="">All statuses</option>
        </select>
        <select
          className="input select"
          value={role}
          onChange={(e) => {
            setRole(e.target.value)
            setOffset(0)
          }}
        >
          <option value="">All roles</option>
          <option value="customer">Customers</option>
          <option value="business_owner">Owners</option>
          <option value="rider">Riders</option>
        </select>
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Contact</th>
                <th>Role</th>
                <th>Status</th>
                <th>Joined</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={6} className="loading-row">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading &&
                users.map((u) => (
                  <tr key={u.id}>
                    <td>
                      <strong>{u.full_name}</strong>
                      {u.status === 'suspended' && u.suspend_reason && (
                        <div className="muted" style={{ fontSize: 12 }}>
                          Reason: {u.suspend_reason}
                        </div>
                      )}
                    </td>
                    <td className="muted">{u.email || u.phone || '—'}</td>
                    <td>
                      <span className="badge badge-gold">{roleLabel[u.role] || u.role}</span>
                    </td>
                    <td>
                      <span className={`badge ${statusBadge(u.status)}`}>{u.status}</span>
                    </td>
                    <td className="muted" style={{ fontSize: 13 }}>
                      {u.created_at ? String(u.created_at).slice(0, 10) : '—'}
                    </td>
                    <td>
                      {u.role === 'super_admin' || u.id === currentUserId ? (
                        <span className="muted">—</span>
                      ) : u.status === 'suspended' ? (
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button
                            className="btn btn-ghost btn-sm"
                            disabled={updatingId === u.id}
                            onClick={() => change(u, 'activate')}
                          >
                            <CheckCircle2 size={14} /> Reactivate
                          </button>
                          <button
                            className="btn btn-danger btn-sm"
                            disabled={updatingId === u.id}
                            onClick={() => remove(u)}
                          >
                            <Trash2 size={14} /> Delete
                          </button>
                        </div>
                      ) : (
                        <button
                          className="btn btn-danger btn-sm"
                          disabled={updatingId === u.id}
                          onClick={() => change(u, 'suspend')}
                        >
                          <Ban size={14} /> Suspend
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              {!loading && users.length === 0 && (
                <tr>
                  <td colSpan={6} className="loading-row">
                    {status === 'suspended' ? 'No suspended users' : 'No users match your filters.'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        {page && (
          <Pagination total={page.total} limit={page.limit} offset={page.offset} onChange={setOffset} />
        )}
      </div>
    </div>
  )
}
