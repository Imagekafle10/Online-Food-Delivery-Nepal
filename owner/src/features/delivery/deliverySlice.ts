import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { apiClient } from '../../api/client'
import type { OrderStatus } from '../orders/orderStatus'

export type DeliveryOrderStatus = OrderStatus

export interface DeliveryOrder {
  id: number
  order_number?: string
  business_id: number
  business_name?: string
  business_city?: string
  customer_name?: string
  rider_id?: number | null
  rider_name?: string | null
  status: DeliveryOrderStatus
  total_amount?: number
  placed_at?: string
  created_at?: string
  [key: string]: unknown
}

export interface Rider {
  id: number
  user_id: number
  full_name: string
  phone: string | null
  email: string | null
  vehicle_type: 'bike' | 'scooter' | 'bicycle' | 'car'
  vehicle_number: string | null
  status: 'offline' | 'available' | 'busy'
  is_active?: number // 0 = account suspended
  rating?: number
  total_deliveries?: number
}

interface DeliveryState {
  orders: DeliveryOrder[]
  statusFilter: DeliveryOrderStatus | 'all'
  riders: Rider[]
  loading: boolean
  ridersLoading: boolean
  assigningOrderId: number | null
  creatingRider: boolean
  error: string | null
  success: string | null
}

const initialState: DeliveryState = {
  orders: [],
  statusFilter: 'all',
  riders: [],
  loading: false,
  ridersLoading: false,
  assigningOrderId: null,
  creatingRider: false,
  error: null,
  success: null,
}

/** All delivery-type orders (any status), optionally scoped to one business and/or status. */
export const fetchDeliveryOrders = createAsyncThunk(
  'delivery/fetchOrders',
  async (
    { businessId, status }: { businessId?: number; status?: string },
    { rejectWithValue }
  ) => {
    try {
      const params = new URLSearchParams()
      if (businessId) params.set('businessId', String(businessId))
      if (status && status !== 'all') params.set('status', status)
      const qs = params.toString()
      return await apiClient.get<DeliveryOrder[]>(`/delivery/orders${qs ? `?${qs}` : ''}`)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load orders')
    }
  }
)

export const fetchRiders = createAsyncThunk(
  'delivery/fetchRiders',
  async (_, { rejectWithValue }) => {
    try {
      return await apiClient.get<Rider[]>('/riders')
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load riders')
    }
  }
)

export const assignRider = createAsyncThunk(
  'delivery/assignRider',
  async (
    { orderId, riderId, riderName }: { orderId: number; riderId: number; riderName?: string },
    { rejectWithValue }
  ) => {
    try {
      await apiClient.post(`/delivery/${orderId}/assign`, { rider_id: riderId })
      return { orderId, riderId, riderName }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to assign rider')
    }
  }
)

export const createRider = createAsyncThunk(
  'delivery/createRider',
  async (
    payload: {
      full_name: string
      phone?: string
      email?: string
      password: string
      vehicle_type: string
      vehicle_number?: string
    },
    { rejectWithValue }
  ) => {
    try {
      await apiClient.post('/riders', payload)
      return true
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to create rider')
    }
  }
)

const deliverySlice = createSlice({
  name: 'delivery',
  initialState,
  reducers: {
    clearDeliveryMessages: (state) => {
      state.error = null
      state.success = null
    },
    setStatusFilter: (state, action: PayloadAction<DeliveryOrderStatus | 'all'>) => {
      state.statusFilter = action.payload
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchDeliveryOrders.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchDeliveryOrders.fulfilled, (state, action) => {
        state.loading = false
        state.orders = Array.isArray(action.payload) ? action.payload : []
      })
      .addCase(fetchDeliveryOrders.rejected, (state, action) => {
        state.loading = false
        state.error = (action.payload as string) || 'Error'
        state.orders = []
      })
      .addCase(fetchRiders.pending, (state) => {
        state.ridersLoading = true
      })
      .addCase(fetchRiders.fulfilled, (state, action) => {
        state.ridersLoading = false
        state.riders = Array.isArray(action.payload) ? action.payload : []
      })
      .addCase(fetchRiders.rejected, (state, action) => {
        state.ridersLoading = false
        state.error = (action.payload as string) || 'Failed to load riders'
      })
      .addCase(assignRider.pending, (state, action) => {
        state.assigningOrderId = action.meta.arg.orderId
        state.error = null
      })
      .addCase(assignRider.fulfilled, (state, action) => {
        state.assigningOrderId = null
        state.success = 'Rider updated'
        const order = state.orders.find((o) => o.id === action.payload.orderId)
        if (order) {
          order.rider_id = action.payload.riderId
          const rider = state.riders.find((r) => r.id === action.payload.riderId)
          if (rider) order.rider_name = rider.full_name
        }
        const rider = state.riders.find((r) => r.id === action.payload.riderId)
        if (rider) rider.status = 'busy'
      })
      .addCase(assignRider.rejected, (state, action) => {
        state.assigningOrderId = null
        state.error = (action.payload as string) || 'Failed to assign rider'
      })
      .addCase(createRider.pending, (state) => {
        state.creatingRider = true
        state.error = null
      })
      .addCase(createRider.fulfilled, (state) => {
        state.creatingRider = false
        state.success = 'Rider account created'
      })
      .addCase(createRider.rejected, (state, action) => {
        state.creatingRider = false
        state.error = (action.payload as string) || 'Failed to create rider'
      })
  },
})

export const { clearDeliveryMessages, setStatusFilter } = deliverySlice.actions
export default deliverySlice.reducer
