import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { apiClient } from '../../api/client'

export interface AuthUser {
  id: number
  uuid: string
  full_name: string
  email: string | null
  phone: string | null
  role: string
  avatar_url?: string | null
  is_active?: number
}

interface AuthState {
  isAuthenticated: boolean
  user: AuthUser | null
  accessToken: string | null
  refreshToken: string | null
  loading: boolean
  error: string | null
}

const storedToken = localStorage.getItem('accessToken')
const storedRefresh = localStorage.getItem('refreshToken')
const storedUser = localStorage.getItem('user')

const initialState: AuthState = {
  isAuthenticated: !!storedToken,
  user: storedUser ? JSON.parse(storedUser) : null,
  accessToken: storedToken,
  refreshToken: storedRefresh,
  loading: false,
  error: null,
}

export const login = createAsyncThunk(
  'auth/login',
  async (
    { identifier, password }: { identifier: string; password: string },
    { rejectWithValue }
  ) => {
    try {
      const data = await apiClient.post<{
        user: AuthUser
        accessToken: string
        refreshToken: string
      }>('/auth/login', { identifier, password })
      return data
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Login failed'
      return rejectWithValue(msg)
    }
  }
)

export const fetchMe = createAsyncThunk('auth/me', async (_, { rejectWithValue }) => {
  try {
    return await apiClient.get<AuthUser>('/auth/me')
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : 'Failed to load profile'
    return rejectWithValue(msg)
  }
})

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    logout: (state) => {
      state.isAuthenticated = false
      state.user = null
      state.accessToken = null
      state.refreshToken = null
      state.error = null
      localStorage.removeItem('accessToken')
      localStorage.removeItem('refreshToken')
      localStorage.removeItem('user')
    },
    clearError: (state) => {
      state.error = null
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(login.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false
        state.isAuthenticated = true
        state.user = action.payload.user
        state.accessToken = action.payload.accessToken
        state.refreshToken = action.payload.refreshToken
        localStorage.setItem('accessToken', action.payload.accessToken)
        localStorage.setItem('refreshToken', action.payload.refreshToken)
        localStorage.setItem('user', JSON.stringify(action.payload.user))
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false
        state.error = (action.payload as string) || 'Login failed'
      })
      .addCase(fetchMe.fulfilled, (state, action) => {
        state.user = action.payload as AuthUser
        localStorage.setItem('user', JSON.stringify(action.payload))
      })
  },
})

export const { logout, clearError } = authSlice.actions
export default authSlice.reducer
