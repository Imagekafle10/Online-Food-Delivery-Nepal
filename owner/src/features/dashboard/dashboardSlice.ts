import { createSlice, PayloadAction } from '@reduxjs/toolkit'

export interface StatCard {
  id: string
  label: string
  value: string | number
  change: number
  icon: string
}

export interface RevenuePoint {
  name: string
  revenue: number
  orders: number
}

interface DashboardState {
  stats: StatCard[]
  revenueData: RevenuePoint[]
  recentActivity: { id: string; text: string; time: string; type: string }[]
  loading: boolean
}

const initialState: DashboardState = {
  stats: [
    { id: '1', label: 'Total Revenue', value: '$48,250', change: 12.5, icon: 'dollar' },
    { id: '2', label: 'Orders Today', value: 186, change: 8.2, icon: 'orders' },
    { id: '3', label: 'Active Users', value: 1240, change: -2.1, icon: 'users' },
    { id: '4', label: 'Occupancy Rate', value: '78%', change: 5.4, icon: 'rooms' },
  ],
  revenueData: [
    { name: 'Mon', revenue: 4200, orders: 42 },
    { name: 'Tue', revenue: 5100, orders: 55 },
    { name: 'Wed', revenue: 4800, orders: 48 },
    { name: 'Thu', revenue: 6200, orders: 67 },
    { name: 'Fri', revenue: 7800, orders: 89 },
    { name: 'Sat', revenue: 9200, orders: 112 },
    { name: 'Sun', revenue: 8500, orders: 98 },
  ],
  recentActivity: [
    { id: '1', text: 'New order #ORD-2841 from Table 12', time: '2 min ago', type: 'order' },
    { id: '2', text: 'Room 305 checked in — John Doe', time: '15 min ago', type: 'room' },
    { id: '3', text: 'Order #ORD-2841 items updated', time: '28 min ago', type: 'order' },
    { id: '4', text: 'Menu item "Truffle Pasta" updated', time: '1 hr ago', type: 'menu' },
    { id: '5', text: 'New user registered: sarah@email.com', time: '2 hr ago', type: 'user' },
  ],
  loading: false,
}

const dashboardSlice = createSlice({
  name: 'dashboard',
  initialState,
  reducers: {
    setStats: (state, action: PayloadAction<StatCard[]>) => {
      state.stats = action.payload
    },
    setRevenueData: (state, action: PayloadAction<RevenuePoint[]>) => {
      state.revenueData = action.payload
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload
    },
    addActivity: (state, action: PayloadAction<DashboardState['recentActivity'][0]>) => {
      state.recentActivity.unshift(action.payload)
      if (state.recentActivity.length > 10) state.recentActivity.pop()
    },
  },
})

export const { setStats, setRevenueData, setLoading, addActivity } = dashboardSlice.actions
export default dashboardSlice.reducer
