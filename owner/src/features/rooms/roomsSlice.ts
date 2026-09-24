import { createSlice, createAsyncThunk } from '@reduxjs/toolkit'
import { apiClient } from '../../api/client'

export interface Room {
  id: number
  business_id: number
  room_number?: string
  name?: string
  type?: string
  capacity?: number
  base_price?: number
  price_per_night?: number
  status?: string
  is_available?: number
  floor?: number
  [key: string]: unknown
}

export interface Table {
  id: number
  business_id: number
  table_number?: string
  capacity?: number
  location_note?: string
  is_available?: number
  status?: string
  [key: string]: unknown
}

interface RoomsState {
  rooms: Room[]
  tables: Table[]
  loading: boolean
  error: string | null
}

const initialState: RoomsState = {
  rooms: [],
  tables: [],
  loading: false,
  error: null,
}

export const fetchRoomsAndTables = createAsyncThunk(
  'rooms/fetchAll',
  async (businessId: number, { rejectWithValue }) => {
    try {
      const [rooms, tables] = await Promise.all([
        apiClient.get<Room[]>(`/rooms/${businessId}/rooms`).catch(() => [] as Room[]),
        apiClient.get<Table[]>(`/tables/${businessId}/tables`).catch(() => [] as Table[]),
      ])
      return {
        rooms: Array.isArray(rooms) ? rooms : [],
        tables: Array.isArray(tables) ? tables : [],
      }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load rooms/tables')
    }
  }
)

const roomsSlice = createSlice({
  name: 'rooms',
  initialState,
  reducers: {
    clearRooms: (state) => {
      state.rooms = []
      state.tables = []
      state.error = null
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchRoomsAndTables.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchRoomsAndTables.fulfilled, (state, action) => {
        state.loading = false
        state.rooms = action.payload.rooms
        state.tables = action.payload.tables
      })
      .addCase(fetchRoomsAndTables.rejected, (state, action) => {
        state.loading = false
        state.error = (action.payload as string) || 'Error'
      })
  },
})

export const { clearRooms } = roomsSlice.actions
export default roomsSlice.reducer
