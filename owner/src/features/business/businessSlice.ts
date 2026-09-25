import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { apiClient, qs } from '../../api/client'
import type { RootState } from '../../app/store'

export interface Business {
  id: number
  uuid: string
  owner_id: number
  name: string
  slug: string
  type: string
  description: string | null
  phone: string | null
  email: string | null
  address: string | null
  city: string | null
  status: string
  is_open: number
  has_food_ordering: number
  has_table_booking: number
  has_room_booking: number
  opens_at?: string
  closes_at?: string
  // Extra fields only returned by GET /businesses/admin/all (super_admin)
  owner_name?: string
  owner_email?: string | null
  owner_phone?: string | null
  menu_items_count?: number
  orders_count?: number
}

/** Minimal info about the business currently being worked on (shown in the top bar). */
export interface SelectedMeta {
  id: number
  name: string
  type: string
}

export interface AdminBusinessQuery {
  search?: string
  status?: string
  type?: string
  limit?: number
  offset?: number
}

export interface AdminBusinessPage {
  businesses: Business[]
  total: number
  limit: number
  offset: number
}

/** super_admin: search every business (any status), paged. */
export function searchAdminBusinesses(params: AdminBusinessQuery) {
  return apiClient.get<AdminBusinessPage>(
    `/businesses/admin/all${qs({ ...params })}`
  )
}

interface BusinessState {
  list: Business[]
  selectedId: number | null
  selectedMeta: SelectedMeta | null
  loading: boolean
  error: string | null
  // super_admin "all restaurants" screen
  adminPage: AdminBusinessPage | null
  adminLoading: boolean
  statusUpdatingId: number | null
  creating: boolean
}

// The selected business is NOT remembered between visits (old saved selections are dropped).
localStorage.removeItem('selectedBusinessId')
localStorage.removeItem('selectedBusinessMeta')

const initialState: BusinessState = {
  list: [],
  selectedId: null,
  selectedMeta: null,
  loading: false,
  error: null,
  adminPage: null,
  adminLoading: false,
  statusUpdatingId: null,
  creating: false,
}

/**
 * Owners only see businesses they own.
 * super_admin loads up to 100 businesses of ANY status; use the top-bar search or the
 * Restaurants page to reach the rest.
 */
export const fetchBusinesses = createAsyncThunk(
  'business/fetchAll',
  async (_, { getState, rejectWithValue }) => {
    try {
      const user = (getState() as RootState).auth.user
      if (user?.role === 'super_admin') {
        const page = await searchAdminBusinesses({ limit: 100 })
        return { list: page.businesses || [], isAdmin: true }
      }
      const data = await apiClient.get<Business[]>('/businesses')
      const list = Array.isArray(data) ? data : []
      if (user?.role === 'business_owner') {
        return { list: list.filter((b) => b.owner_id === user.id), isAdmin: false }
      }
      return { list, isAdmin: false }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load businesses')
    }
  }
)

export const fetchAdminBusinesses = createAsyncThunk(
  'business/fetchAdmin',
  async (params: AdminBusinessQuery, { rejectWithValue }) => {
    try {
      return await searchAdminBusinesses(params)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to search businesses')
    }
  }
)

/** super_admin: onboard a restaurant/hotel/cafe + its owner account in one step. Goes live immediately. */
export const createBusiness = createAsyncThunk(
  'business/create',
  async (
    payload: {
      name: string
      type: string
      description?: string
      phone?: string
      email?: string
      address?: string
      city?: string
      owner_full_name: string
      owner_email?: string
      owner_phone?: string
      owner_password: string
    },
    { rejectWithValue }
  ) => {
    try {
      return await apiClient.post<Business>('/businesses/admin', payload)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to create restaurant')
    }
  }
)

export const setBusinessStatus = createAsyncThunk(
  'business/setStatus',
  async (
    { id, action }: { id: number; action: 'approve' | 'suspend' },
    { rejectWithValue }
  ) => {
    try {
      await apiClient.patch(`/businesses/${id}/${action}`)
      return { id, status: action === 'approve' ? 'approved' : 'suspended' }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to update business')
    }
  }
)

export const deleteBusiness = createAsyncThunk(
  'business/delete',
  async (id: number, { rejectWithValue }) => {
    try {
      await apiClient.delete(`/businesses/${id}`)
      return id
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to delete business')
    }
  }
)

const businessSlice = createSlice({
  name: 'business',
  initialState,
  reducers: {
    /** Select by id (owner top-bar dropdown). Name is looked up from data already loaded. */
    selectBusiness: (state, action: PayloadAction<number>) => {
      const id = action.payload
      const found =
        state.list.find((b) => b.id === id) ||
        state.adminPage?.businesses.find((b) => b.id === id)
      state.selectedId = id
      state.selectedMeta = found
        ? { id: found.id, name: found.name, type: found.type }
        : state.selectedMeta?.id === id
          ? state.selectedMeta
          : null
    },
    /** Select a business together with its name (super_admin search / restaurants page). */
    /** super_admin: forget the working restaurant (called when leaving the pages that use it). */
    clearSelection: (state) => {
      state.selectedId = null
      state.selectedMeta = null
    },
    selectBusinessWithMeta: (state, action: PayloadAction<SelectedMeta>) => {
      state.selectedId = action.payload.id
      state.selectedMeta = action.payload
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchBusinesses.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchBusinesses.fulfilled, (state, action) => {
        const { list, isAdmin } = action.payload
        state.loading = false
        state.list = list
        if (isAdmin) return // super_admin picks a restaurant explicitly (search) - never auto-select
        if (list.length === 0) {
          state.selectedId = null
          state.selectedMeta = null
          return
        }
        const current = list.find((b) => b.id === state.selectedId)
        const target = current ?? list[0]
        state.selectedId = target.id
        state.selectedMeta = { id: target.id, name: target.name, type: target.type }
      })
      .addCase(fetchBusinesses.rejected, (state, action) => {
        state.loading = false
        state.error = (action.payload as string) || 'Error'
      })
      .addCase(fetchAdminBusinesses.pending, (state) => {
        state.adminLoading = true
        state.error = null
      })
      .addCase(fetchAdminBusinesses.fulfilled, (state, action) => {
        state.adminLoading = false
        state.adminPage = action.payload
      })
      .addCase(fetchAdminBusinesses.rejected, (state, action) => {
        state.adminLoading = false
        state.error = (action.payload as string) || 'Error'
      })
      .addCase(createBusiness.pending, (state) => {
        state.creating = true
        state.error = null
      })
      .addCase(createBusiness.fulfilled, (state, action) => {
        state.creating = false
        if (state.adminPage) {
          state.adminPage.businesses = [action.payload, ...state.adminPage.businesses]
          state.adminPage.total += 1
        }
      })
      .addCase(createBusiness.rejected, (state, action) => {
        state.creating = false
        state.error = (action.payload as string) || 'Failed to create restaurant'
      })
      .addCase(setBusinessStatus.pending, (state, action) => {
        state.statusUpdatingId = action.meta.arg.id
        state.error = null
      })
      .addCase(setBusinessStatus.fulfilled, (state, action) => {
        state.statusUpdatingId = null
        const { id, status } = action.payload
        const row = state.adminPage?.businesses.find((b) => b.id === id)
        if (row) row.status = status
        const inList = state.list.find((b) => b.id === id)
        if (inList) inList.status = status
      })
      .addCase(deleteBusiness.pending, (state, action) => {
        state.statusUpdatingId = action.meta.arg
        state.error = null
      })
      .addCase(deleteBusiness.fulfilled, (state, action) => {
        const id = action.payload
        state.statusUpdatingId = null
        state.list = state.list.filter((b) => b.id !== id)
        if (state.adminPage) {
          state.adminPage.businesses = state.adminPage.businesses.filter((b) => b.id !== id)
          state.adminPage.total = Math.max(0, state.adminPage.total - 1)
        }
        if (state.selectedId === id) {
          state.selectedId = null
          state.selectedMeta = null
        }
      })
      .addCase(deleteBusiness.rejected, (state, action) => {
        state.statusUpdatingId = null
        state.error = (action.payload as string) || 'Error'
      })
      .addCase(setBusinessStatus.rejected, (state, action) => {
        state.statusUpdatingId = null
        state.error = (action.payload as string) || 'Error'
      })
  },
})

export const { selectBusiness, selectBusinessWithMeta, clearSelection } = businessSlice.actions
export default businessSlice.reducer
