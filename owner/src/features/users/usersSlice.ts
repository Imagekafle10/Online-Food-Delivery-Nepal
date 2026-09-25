import { createSlice, createAsyncThunk } from '@reduxjs/toolkit'
import { apiClient, qs } from '../../api/client'

export interface PlatformUser {
  id: number
  full_name: string
  email: string | null
  phone: string | null
  role: string // customer | business_owner | rider | super_admin
  status: string // active | suspended | ...
  created_at?: string
  suspended_at?: string | null
  suspend_reason?: string | null
}

export interface UserQuery {
  search?: string
  role?: string
  status?: string
  limit?: number
  offset?: number
}

export interface UsersPage {
  users: PlatformUser[]
  total: number
  limit: number
  offset: number
}

interface UsersState {
  page: UsersPage | null
  loading: boolean
  updatingId: number | null
  creating: boolean
  error: string | null
  notice: string | null
}

const initialState: UsersState = {
  page: null,
  loading: false,
  updatingId: null,
  creating: false,
  error: null,
  notice: null,
}

/* Backend: routes/user.routes.ts (super_admin only). Suspended == users.is_active = 0. */
export const fetchUsers = createAsyncThunk(
  'users/fetch',
  async (params: UserQuery, { rejectWithValue }) => {
    try {
      return await apiClient.get<UsersPage>(`/users/admin/all${qs({ ...params })}`)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load users')
    }
  }
)

/** super_admin: onboard any account (customer, business_owner, staff, rider, super_admin) from the panel. */
export const createUser = createAsyncThunk(
  'users/create',
  async (
    payload: {
      full_name: string
      email?: string
      phone?: string
      password: string
      role: string
    },
    { rejectWithValue }
  ) => {
    try {
      return await apiClient.post<PlatformUser>('/users/admin', payload)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to create user')
    }
  }
)

export const setUserStatus = createAsyncThunk(
  'users/setStatus',
  async (
    { id, action, reason }: { id: number; action: 'suspend' | 'activate'; reason?: string },
    { rejectWithValue }
  ) => {
    try {
      await apiClient.patch(`/users/${id}/${action}`, action === 'suspend' ? { reason } : undefined)
      return { id, status: action === 'suspend' ? 'suspended' : 'active', reason }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to update user')
    }
  }
)

export const deleteUser = createAsyncThunk(
  'users/delete',
  async (id: number, { rejectWithValue }) => {
    try {
      await apiClient.delete(`/users/${id}`)
      return id
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to delete user')
    }
  }
)

const usersSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {
    clearUserMessages: (state) => {
      state.error = null
      state.notice = null
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchUsers.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchUsers.fulfilled, (state, action) => {
        state.loading = false
        state.page = action.payload
      })
      .addCase(fetchUsers.rejected, (state, action) => {
        state.loading = false
        state.error = (action.payload as string) || 'Error'
      })
      .addCase(createUser.pending, (state) => {
        state.creating = true
        state.error = null
      })
      .addCase(createUser.fulfilled, (state) => {
        state.creating = false
        state.notice = 'User created'
      })
      .addCase(createUser.rejected, (state, action) => {
        state.creating = false
        state.error = (action.payload as string) || 'Failed to create user'
      })
      .addCase(setUserStatus.pending, (state, action) => {
        state.updatingId = action.meta.arg.id
        state.error = null
      })
      .addCase(setUserStatus.fulfilled, (state, action) => {
        state.updatingId = null
        const { id, status, reason } = action.payload
        state.notice = status === 'suspended' ? 'User suspended' : 'User reactivated'
        const row = state.page?.users.find((u) => u.id === id)
        if (row) {
          row.status = status
          row.suspend_reason = status === 'suspended' ? reason ?? null : null
        }
      })
      .addCase(deleteUser.pending, (state, action) => {
        state.updatingId = action.meta.arg
        state.error = null
      })
      .addCase(deleteUser.fulfilled, (state, action) => {
        state.updatingId = null
        state.notice = 'User deleted'
        if (state.page) {
          state.page.users = state.page.users.filter((u) => u.id !== action.payload)
          state.page.total = Math.max(0, state.page.total - 1)
        }
      })
      .addCase(deleteUser.rejected, (state, action) => {
        state.updatingId = null
        state.error = (action.payload as string) || 'Error'
      })
      .addCase(setUserStatus.rejected, (state, action) => {
        state.updatingId = null
        state.error = (action.payload as string) || 'Error'
      })
  },
})

export const { clearUserMessages } = usersSlice.actions
export default usersSlice.reducer
