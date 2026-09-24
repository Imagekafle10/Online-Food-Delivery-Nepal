import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { apiClient } from '../../api/client'

export interface MenuItem {
  id: number
  business_id: number
  category_id: number | null
  name: string
  description?: string | null
  price: number
  discount_percent?: number | null
  is_available: number | boolean
  is_veg?: number | boolean
  prep_time_mins?: number
  image_url?: string | null
  [key: string]: unknown
}

export interface MenuCategory {
  id: number | null
  name: string
  items: MenuItem[]
  is_active?: number
  sort_order?: number
}

export interface MenuItemInput {
  name: string
  description?: string
  price: number
  discount_percent?: number | null
  category_id?: number | null
  is_veg?: boolean
  prep_time_mins?: number
  image_url?: string
}

export interface MenuCategoryInput {
  name: string
}

export const MIN_DISCOUNT_PERCENT = 5
export const MAX_DISCOUNT_PERCENT = 90

// Builds a multipart form when an image file is attached (so it can be uploaded
// together with the item fields); otherwise callers just send plain JSON.
function toFormData(data: MenuItemInput, image?: File | null): FormData {
  const fd = new FormData()
  Object.entries(data).forEach(([key, value]) => {
    if (value === undefined || value === null) return
    fd.append(key, String(value))
  })
  if (image) fd.append('image', image)
  return fd
}

interface MenusState {
  categories: MenuCategory[]
  search: string
  loading: boolean
  saving: boolean
  error: string | null
  /** Informational message (e.g. an item was hidden instead of deleted). */
  notice: string | null
}

const initialState: MenusState = {
  categories: [],
  search: '',
  loading: false,
  saving: false,
  error: null,
  notice: null,
}

export const fetchMenu = createAsyncThunk(
  'menus/fetch',
  async (businessId: number, { rejectWithValue }) => {
    try {
      // /manage also returns unavailable items + inactive categories, so nothing disappears
      // from the admin/owner view when an item is switched off.
      return await apiClient.get<MenuCategory[]>(`/menu/${businessId}/manage`)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to load menu')
    }
  }
)

export const createMenuItem = createAsyncThunk(
  'menus/create',
  async (
    { businessId, data, image }: { businessId: number; data: MenuItemInput; image?: File | null },
    { rejectWithValue }
  ) => {
    try {
      if (image) {
        return await apiClient.postForm<MenuItem>(
          `/menu/${businessId}/items`,
          toFormData(data, image)
        )
      }
      return await apiClient.post<MenuItem>(`/menu/${businessId}/items`, data)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to create item')
    }
  }
)

export const updateMenuItem = createAsyncThunk(
  'menus/update',
  async (
    {
      businessId,
      itemId,
      data,
      image,
    }: { businessId: number; itemId: number; data: Partial<MenuItemInput>; image?: File | null },
    { rejectWithValue }
  ) => {
    try {
      if (image) {
        return await apiClient.patchForm<MenuItem>(
          `/menu/${businessId}/items/${itemId}`,
          toFormData(data as MenuItemInput, image)
        )
      }
      return await apiClient.patch<MenuItem>(`/menu/${businessId}/items/${itemId}`, data)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to update item')
    }
  }
)

export const createMenuCategory = createAsyncThunk(
  'menus/createCategory',
  async (
    { businessId, data }: { businessId: number; data: MenuCategoryInput },
    { rejectWithValue }
  ) => {
    try {
      return await apiClient.post<MenuCategory>(`/menu/${businessId}/categories`, data)
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to create category')
    }
  }
)

export const setItemAvailability = createAsyncThunk(
  'menus/setAvailability',
  async (
    {
      businessId,
      itemId,
      is_available,
    }: { businessId: number; itemId: number; is_available: boolean },
    { rejectWithValue }
  ) => {
    try {
      await apiClient.patch(`/menu/${businessId}/items/${itemId}/availability`, {
        is_available,
      })
      return { itemId, is_available }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to update availability')
    }
  }
)

export const updateMenuCategory = createAsyncThunk(
  'menus/updateCategory',
  async (
    {
      businessId,
      categoryId,
      data,
    }: { businessId: number; categoryId: number; data: { name?: string; sort_order?: number } },
    { rejectWithValue }
  ) => {
    try {
      return await apiClient.patch<MenuCategory>(
        `/menu/${businessId}/categories/${categoryId}`,
        data
      )
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to update category')
    }
  }
)

export const removeMenuCategory = createAsyncThunk(
  'menus/removeCategory',
  async (
    { businessId, categoryId }: { businessId: number; categoryId: number },
    { rejectWithValue }
  ) => {
    try {
      await apiClient.delete(`/menu/${businessId}/categories/${categoryId}`)
      return categoryId
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to delete category')
    }
  }
)

export const removeMenuItem = createAsyncThunk(
  'menus/remove',
  async (
    { businessId, itemId }: { businessId: number; itemId: number },
    { rejectWithValue }
  ) => {
    try {
      // Items that appear in past orders can't be deleted - the server hides them instead.
      const result = await apiClient.delete<{ deleted?: boolean; archived?: boolean } | null>(
        `/menu/${businessId}/items/${itemId}`
      )
      return { itemId, archived: !!result?.archived }
    } catch (e: unknown) {
      return rejectWithValue(e instanceof Error ? e.message : 'Failed to delete item')
    }
  }
)

const menusSlice = createSlice({
  name: 'menus',
  initialState,
  reducers: {
    setSearch: (state, action: PayloadAction<string>) => {
      state.search = action.payload
    },
    clearMenuError: (state) => {
      state.error = null
      state.notice = null
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchMenu.pending, (state) => {
        state.loading = true
        state.error = null
        state.notice = null
      })
      .addCase(fetchMenu.fulfilled, (state, action) => {
        state.loading = false
        state.categories = Array.isArray(action.payload) ? action.payload : []
      })
      .addCase(fetchMenu.rejected, (state, action) => {
        state.loading = false
        state.error = (action.payload as string) || 'Error'
      })
      .addCase(createMenuItem.pending, (state) => {
        state.saving = true
        state.error = null
      })
      .addCase(createMenuItem.fulfilled, (state) => {
        state.saving = false
      })
      .addCase(createMenuItem.rejected, (state, action) => {
        state.saving = false
        state.error = (action.payload as string) || 'Create failed'
      })
      .addCase(updateMenuItem.pending, (state) => {
        state.saving = true
        state.error = null
      })
      .addCase(updateMenuItem.fulfilled, (state) => {
        state.saving = false
      })
      .addCase(updateMenuItem.rejected, (state, action) => {
        state.saving = false
        state.error = (action.payload as string) || 'Update failed'
      })
      .addCase(setItemAvailability.fulfilled, (state, action) => {
        const { itemId, is_available } = action.payload
        for (const cat of state.categories) {
          const item = cat.items?.find((i) => i.id === itemId)
          if (item) item.is_available = is_available ? 1 : 0
        }
      })
      .addCase(removeMenuItem.fulfilled, (state, action) => {
        const { itemId, archived } = action.payload
        if (archived) {
          for (const cat of state.categories) {
            const item = cat.items?.find((i) => i.id === itemId)
            if (item) item.is_available = 0
          }
          state.notice =
            'This item is part of past orders, so it was hidden from customers instead of deleted.'
          return
        }
        for (const cat of state.categories) {
          cat.items = (cat.items || []).filter((i) => i.id !== itemId)
        }
      })
      .addCase(removeMenuItem.rejected, (state, action) => {
        state.error = (action.payload as string) || 'Failed to delete item'
      })
      .addCase(updateMenuCategory.pending, (state) => {
        state.saving = true
        state.error = null
      })
      .addCase(updateMenuCategory.fulfilled, (state, action) => {
        state.saving = false
        const cat = state.categories.find((c) => c.id === action.payload.id)
        if (cat) cat.name = action.payload.name
      })
      .addCase(updateMenuCategory.rejected, (state, action) => {
        state.saving = false
        state.error = (action.payload as string) || 'Failed to update category'
      })
      .addCase(removeMenuCategory.fulfilled, (state, action) => {
        state.categories = state.categories.filter((c) => c.id !== action.payload)
      })
      .addCase(removeMenuCategory.rejected, (state, action) => {
        state.error = (action.payload as string) || 'Failed to delete category'
      })
      .addCase(createMenuCategory.pending, (state) => {
        state.saving = true
        state.error = null
      })
      .addCase(createMenuCategory.fulfilled, (state, action) => {
        state.saving = false
        const exists = state.categories.some((c) => c.id === action.payload.id)
        if (!exists) state.categories.push({ ...action.payload, items: action.payload.items || [] })
      })
      .addCase(createMenuCategory.rejected, (state, action) => {
        state.saving = false
        state.error = (action.payload as string) || 'Failed to create category'
      })
  },
})

export const { setSearch, clearMenuError } = menusSlice.actions
export default menusSlice.reducer
