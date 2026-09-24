import { useAppDispatch, useAppSelector } from '../../hooks/redux'
import { selectBusiness } from '../../features/business/businessSlice'

export default function Topbar() {
  const dispatch = useAppDispatch()
  const user = useAppSelector((s) => s.auth.user)
  const { list, selectedId } = useAppSelector((s) => s.business)

  return (
    <header className="topbar">
      <div className="topbar-biz">
        {user?.role !== 'super_admin' && list.length > 0 && (
          <select
            className="input select"
            value={selectedId ?? ''}
            onChange={(e) => dispatch(selectBusiness(Number(e.target.value)))}
          >
            {list.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name} ({b.type})
              </option>
            ))}
          </select>
        )}
      </div>

      <div className="topbar-actions">
        <div className="topbar-user">
          <div className="topbar-avatar">
            {(user?.full_name || 'A').charAt(0).toUpperCase()}
          </div>
          <div className="topbar-user-info">
            <div className="name">{user?.full_name ?? 'Admin'}</div>
            <div className="role">{user?.role ?? ''}</div>
          </div>
        </div>
      </div>
    </header>
  )
}
