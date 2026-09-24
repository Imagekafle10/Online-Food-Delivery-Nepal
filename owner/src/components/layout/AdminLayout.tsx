import { useEffect } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { useAppDispatch, useAppSelector } from '../../hooks/redux'
import { clearSelection } from '../../features/business/businessSlice'
import Sidebar from './Sidebar'
import Topbar from './Topbar'
import './layout.css'

// Pages where a super_admin works on ONE restaurant (chosen via search).
const RESTAURANT_SCOPED = ['/menus', '/rooms']

export default function AdminLayout() {
  const dispatch = useAppDispatch()
  const { pathname } = useLocation()
  const role = useAppSelector((s) => s.auth.user?.role)

  // super_admin: the picked restaurant only applies to the Menu page. Leaving it forgets the
  // choice, so no other page (Dashboard, Orders, Delivery...) silently follows an old selection.
  useEffect(() => {
    if (role === 'super_admin' && !RESTAURANT_SCOPED.some((p) => pathname.startsWith(p))) {
      dispatch(clearSelection())
    }
  }, [pathname, role, dispatch])

  return (
    <div className="admin-shell">
      <Sidebar />
      <div className="admin-main">
        <Topbar />
        <main className="admin-content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
