import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { apiClient, ApiError, qs } from '../../api/client'

import { assignRider } from '../delivery/deliverySlice'
import type { OrderStatus } from './orderStatus'
export type { OrderStatus } from './orderStatus'

/** A single food item within an order — this is what owners need to see to prep the order. */
export interface OrderItem {
  id?: number
  menu_item_id?: number
  name?: string
  item_name?: string
  quantity: number
  unit_price?: number
  price?: number
  subtotal?: number
  notes?: string
  special_instructions?: string
  [key: string]: unknown
}

export interface Order {
  id: number
  order_number?: string
  business_id: number
  user_id?: number
  order_type?: string
  /** Internal only — not shown to owners; status is managed by super admin. */
  status: OrderStatus
  total?: number
  total_amount?: number
  special_instructions?: string
  created_at?: string
  customer_name?: string
  full_name?: string
  guest_name?: string
  items?: OrderItem[]
  [key: string]: unknown
}

/** Row from GET /orders/admin/all (super_admin) - order + business/customer/rider names. */
export interface AdminOrder extends Order {
  business_name?: string
  business_city?: string
  business_type?: string
  customer_phone?: string | null
  rider_id?: number | null
  rider_name?: string | null
  item_count?: number
  payment_method?: string
  payment_status?: string
  placed_at?: string
}

export interface AdminOrderDetail {
  order: AdminOrder & {
    subtotal?: number | string
    delivery_fee?: number | string
    tax_amount?: number | string
    discount_amount?: number | string
    total_amount?: number | string
    business_phone?: string | null
    business_address?: string | null
    customer_email?: string | null
    rider_phone?: string | null
    rider_vehicle_type?: string | null
    rider_vehicle_number?: string | null
    delivery_address_label?: string | null
    delivery_address_line?: string | null
    delivery_city?: string | null
    cancelled_reason?: string | null
  }
  items: OrderItem[]
  statusLog: { id: number; status: string; note: string | null; created_at: string }[]
  payments: {
    id: number
    amount: number | string
    method: string
    status: string
    gateway_txn_id: string | null
    created_at: string
  }[]
}

export interface AdminOrderFilters {
  search?: string
  status?: string
  business_id?: number
  order_type?: string
  payment_status?: string
  from?: string
  to?: string
  limit?: number
  offset?: number
}

interface AdminOrdersPage {
  orders: AdminOrder[]
  total: number
  limit: number
  offset: number
}

interface OrdersState {
  list: Order[]
  search: string
  loading: boolean
  error: string | null
  /** Order id currently expanded to show its items in the table. */
  expandedOrderId: number | null
  itemsByOrderId: Record<number, OrderItem[]>
  itemsLoadingId: number | null
  // ---- super_admin ----
  adminOrders: AdminOrder[]
  adminTotal: number
  adminLimit: number
  adminOffset: number
  adminLoading: boolean
  adminError: string | null
  adminDetail: AdminOrderDetail | null
  adminDetailLoading: boolean
  adminDeletingId: number | null
  adminStatusUpdatingId: number | null
}

const initialState: OrdersState = {
  list: [],
  search: '',
  loading: false,
  error: null,
  expandedOrderId: null,
  itemsByOrderId: {},
  itemsLoadingId: null,
  adminOrders: [],
  adminTotal: 0,
  adminLimit: 20,
  adminOffset: 0,
  adminLoading: false,
  adminError: null,
  adminDetail: null,
  adminDetailLoading: false,
  adminDeletingId: null,
  adminStatusUpdatingId: null,
}

export const fetchBusinessOrders = createAsyncThunk(
  'orders/fetchBusiness',
  async ({ businessId }: { businessId: number }, { rejectWithValue }) => {
    try {
      return await apiClient.get<Order[]>(`/orders/business/${businessId}`)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load orders')
    }
  }
)

/** Fetches the food items that were part of a single order, so the owner can see what to prepare. */
export const fetchOrderItems = createAsyncThunk(
  'orders/fetchItems',
  async (orderId: number, { rejectWithValue }) => {
    try {
      const detail = await apiClient.get<Order & { order_items?: OrderItem[] }>(`/orders/${orderId}`)
      const items = detail.items || detail.order_items || []
      return { orderId, items }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load order items')
    }
  }
)

/** super_admin: every order on the platform, filterable + paged. */
export const fetchAdminOrders = createAsyncThunk(
  'orders/fetchAdmin',
  async (filters: AdminOrderFilters, { rejectWithValue }) => {
    try {
      return await apiClient.get<AdminOrdersPage>(`/orders/admin/all${qs({ ...filters })}`)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load orders')
    }
  }
)

/** super_admin: the "view" button - full order with customer, rider, items, log, payments. */
export const fetchAdminOrderDetail = createAsyncThunk(
  'orders/fetchAdminDetail',
  async (orderId: number, { rejectWithValue }) => {
    try {
      return await apiClient.get<AdminOrderDetail>(`/orders/admin/${orderId}`)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load order')
    }
  }
)

/**
 * super_admin: move an order along placed -> accepted -> cooking -> on_the_way -> delivered,
 * or cancel it (note = the reason). The API rejects illegal jumps.
 */
export const updateAdminOrderStatus = createAsyncThunk(
  'orders/updateAdminStatus',
  async (
    { id, status, note }: { id: number; status: OrderStatus; note?: string },
    { rejectWithValue }
  ) => {
    try {
      await apiClient.patch(`/orders/${id}/status`, { status, note })
      return { id, status }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to update status')
    }
  }
)

/**
 * super_admin: delete an order. Finished orders delete directly; in-progress ones are
 * rejected with 409 unless force = true.
 */
export const deleteAdminOrder = createAsyncThunk(
  'orders/deleteAdmin',
  async ({ id, force }: { id: number; force?: boolean }, { rejectWithValue }) => {
    try {
      await apiClient.delete(`/orders/admin/${id}${force ? '?force=true' : ''}`)
      return id
    } catch (e: unknown) {
      return rejectWithValue({
        message: e instanceof Error ? e.message : 'Failed to delete order',
        status: e instanceof ApiError ? e.status : 0,
      })
    }
  }
)

const ordersSlice = createSlice({
  name: 'orders',
  initialState,
  reducers: {
    setSearch: (state, action: PayloadAction<string>) => {
      state.search = action.payload
    },
    clearOrders: (state) => {
      state.list = []
      state.error = null
    },
    /** Toggles the item breakdown open/closed for one order; closes any other open row. */
    toggleOrderExpanded: (state, action: PayloadAction<number>) => {
      state.expandedOrderId = state.expandedOrderId === action.payload ? null : action.payload
    },
    closeAdminOrderDetail: (state) => {
      state.adminDetail = null
      state.adminDetailLoading = false
    },
    clearAdminOrdersError: (state) => {
      state.adminError = null
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchBusinessOrders.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchBusinessOrders.fulfilled, (state, action) => {
        state.loading = false
        state.list = Array.isArray(action.payload) ? action.payload : []
      })
      .addCase(fetchBusinessOrders.rejected, (state, action) => {
        state.loading = false
        state.error = (action.payload as string) || 'Error'
        state.list = []
      })
      .addCase(fetchOrderItems.pending, (state, action) => {
        state.itemsLoadingId = action.meta.arg
      })
      .addCase(fetchOrderItems.fulfilled, (state, action) => {
        state.itemsLoadingId = null
        state.itemsByOrderId[action.payload.orderId] = action.payload.items
      })
      .addCase(fetchOrderItems.rejected, (state, action) => {
        state.itemsLoadingId = null
        state.error = (action.payload as string) || 'Failed to load items'
      })
      .addCase(fetchAdminOrders.pending, (state) => {
        state.adminLoading = true
        state.adminError = null
      })
      .addCase(fetchAdminOrders.fulfilled, (state, action) => {
        state.adminLoading = false
        state.adminOrders = action.payload.orders || []
        state.adminTotal = action.payload.total || 0
        state.adminLimit = action.payload.limit || 20
        state.adminOffset = action.payload.offset || 0
      })
      .addCase(fetchAdminOrders.rejected, (state, action) => {
        state.adminLoading = false
        state.adminError = (action.payload as string) || 'Error'
        state.adminOrders = []
        state.adminTotal = 0
      })
      .addCase(fetchAdminOrderDetail.pending, (state) => {
        state.adminDetailLoading = true
        state.adminDetail = null
      })
      .addCase(fetchAdminOrderDetail.fulfilled, (state, action) => {
        state.adminDetailLoading = false
        state.adminDetail = action.payload
      })
      .addCase(fetchAdminOrderDetail.rejected, (state, action) => {
        state.adminDetailLoading = false
        state.adminError = (action.payload as string) || 'Failed to load order'
      })
      .addCase(updateAdminOrderStatus.pending, (state, action) => {
        state.adminStatusUpdatingId = action.meta.arg.id
        state.adminError = null
      })
      .addCase(updateAdminOrderStatus.fulfilled, (state, action) => {
        state.adminStatusUpdatingId = null
        const { id, status } = action.payload
        const row = state.adminOrders.find((o) => o.id === id)
        if (row) row.status = status
        if (state.adminDetail && state.adminDetail.order.id === id) {
          state.adminDetail.order.status = status
        }
      })
      .addCase(updateAdminOrderStatus.rejected, (state, action) => {
        state.adminStatusUpdatingId = null
        state.adminError = (action.payload as string) || 'Failed to update status'
      })
      .addCase(assignRider.fulfilled, (state, action) => {
        const { orderId, riderId, riderName } = action.payload
        const row = state.adminOrders.find((o) => o.id === orderId)
        if (row) {
          row.rider_id = riderId
          row.rider_name = riderName ?? row.rider_name
        }
      })
      .addCase(deleteAdminOrder.pending, (state, action) => {
        state.adminDeletingId = action.meta.arg.id
        state.adminError = null
      })
      .addCase(deleteAdminOrder.fulfilled, (state, action) => {
        state.adminDeletingId = null
        state.adminOrders = state.adminOrders.filter((o) => o.id !== action.payload)
        state.adminTotal = Math.max(0, state.adminTotal - 1)
      })
      .addCase(deleteAdminOrder.rejected, (state, action) => {
        state.adminDeletingId = null
        // 409 = order still in progress; the page asks the admin whether to force-delete,
        // so don't show it as an error banner.
        const payload = action.payload as { message: string; status: number } | undefined
        if (payload?.status !== 409) state.adminError = payload?.message || 'Failed to delete order'
      })
  },
})

export const {
  setSearch,
  clearOrders,
  toggleOrderExpanded,
  closeAdminOrderDetail,
  clearAdminOrdersError,
} = ordersSlice.actions
export default ordersSlice.reducer
