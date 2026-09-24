import { useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAppDispatch, useAppSelector } from './hooks/redux'
import { fetchMe } from './features/auth/authSlice'
import { fetchBusinesses } from './features/business/businessSlice'
import AdminLayout from './components/layout/AdminLayout'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import BusinessesPage from './pages/BusinessesPage'
import OrdersPage, { OrderHistoryPage } from './pages/OrdersPage'
import MenusPage from './pages/MenusPage'
import RoomsPage from './pages/RoomsPage'
import SettingsPage from './pages/SettingsPage'
import RidersPage from './pages/RidersPage'
import UsersPage from './pages/UsersPage'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAppSelector((s) => s.auth.isAuthenticated)
  if (!isAuthenticated) return <Navigate to="/login" replace />
  return <>{children}</>
}

function Bootstrap() {
  const dispatch = useAppDispatch()
  const isAuthenticated = useAppSelector((s) => s.auth.isAuthenticated)

  useEffect(() => {
    if (isAuthenticated) {
      dispatch(fetchMe())
      dispatch(fetchBusinesses())
    }
  }, [isAuthenticated, dispatch])

  return null
}

export default function App() {
  return (
    <>
      <Bootstrap />
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <AdminLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<DashboardPage />} />
          <Route path="businesses" element={<BusinessesPage />} />
          <Route path="orders" element={<OrdersPage />} />
          <Route path="history" element={<OrderHistoryPage />} />
          <Route path="menus" element={<MenusPage />} />
          <Route path="rooms" element={<RoomsPage />} />
          <Route path="delivery" element={<Navigate to="/orders" replace />} />
          <Route path="riders" element={<RidersPage />} />
          <Route path="users" element={<UsersPage />} />
          <Route path="settings" element={<SettingsPage />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </>
  )
}
