import { configureStore } from '@reduxjs/toolkit'
import authReducer from '../features/auth/authSlice'
import businessReducer from '../features/business/businessSlice'
import ordersReducer from '../features/orders/ordersSlice'
import menusReducer from '../features/menus/menusSlice'
import roomsReducer from '../features/rooms/roomsSlice'
import deliveryReducer from '../features/delivery/deliverySlice'
import usersReducer from '../features/users/usersSlice'

export const store = configureStore({
  reducer: {
    auth: authReducer,
    business: businessReducer,
    orders: ordersReducer,
    menus: menusReducer,
    rooms: roomsReducer,
    delivery: deliveryReducer,
    users: usersReducer,
  },
})

export type RootState = ReturnType<typeof store.getState>
export type AppDispatch = typeof store.dispatch
