import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  Building2,
  ShoppingBag,
  History,
  UtensilsCrossed,
  Users,
  UserCog,
  Settings,
  LogOut,
} from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../../hooks/redux'
import { logout } from '../../features/auth/authSlice'

export default function Sidebar() {
  const dispatch = useAppDispatch()
  const role = useAppSelector((s) => s.auth.user?.role)

  const isAdmin = role === 'super_admin'

  const navItems = [
    { to: '/', icon: LayoutDashboard, label: 'Dashboard', end: true },
    { to: '/menus', icon: UtensilsCrossed, label: isAdmin ? 'Menus' : 'My Menu' },
    { to: '/orders', icon: ShoppingBag, label: isAdmin ? 'All orders' : 'Order history' },
    ...(isAdmin
      ? [
          { to: '/history', icon: History, label: 'Order history', end: false },
          { to: '/users', icon: Users, label: 'User accounts', end: false },
          { to: '/riders', icon: UserCog, label: 'Rider accounts', end: false },
        ]
      : []),
    { to: '/businesses', icon: Building2, label: isAdmin ? 'Restaurants' : 'My business' },
    { to: '/settings', icon: Settings, label: 'Settings' },
  ]

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <img className="logo-icon" src="/logo.png" alt="Bhansa" />
        <div>
          <h2>Bhansa</h2>
          <span>{role === 'super_admin' ? 'Super Admin' : 'Owner panel'}</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        <div className="nav-section-label">
          {role === 'business_owner' ? 'Your restaurant' : 'Main'}
        </div>
        {navItems.map(({ to, icon: Icon, label, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
          >
            <Icon size={18} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <button className="nav-link" style={{ width: '100%' }} onClick={() => dispatch(logout())}>
          <LogOut size={18} />
          <span>Sign out</span>
        </button>
      </div>
    </aside>
  )
}
