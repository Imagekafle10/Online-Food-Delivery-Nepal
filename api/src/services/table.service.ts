import { v4 as uuidv4 } from 'uuid';
import { TableModel } from '../models/table.model';
import { BusinessModel } from '../models/business.model';
import { AppError } from '../utils/AppError';
import { emitToBusiness } from '../utils/socket';

export const TableService = {
  async addTable(businessId: number, tableNumber: string, capacity: number, locationNote?: string) {
    const id = await TableModel.createTable(businessId, tableNumber, capacity, locationNote);
    return { id };
  },

  async listTables(businessId: number) {
    return TableModel.listByBusiness(businessId);
  },

  async book(userId: number, data: {
    business_id: number; guest_name: string; guest_phone: string; party_size: number;
    booking_date: string; booking_time: string; special_request?: string;
  }) {
    const business = await BusinessModel.findById(data.business_id);
    if (!business) throw new AppError('Business not found', 404);
    if (!business.has_table_booking) throw new AppError('This business does not accept table bookings', 400);

    // Try to auto-assign an available table matching party size; booking still succeeds
    // as "pending" even if none is free right now (staff can reassign manually).
    const table = await TableModel.findAvailable(data.business_id, data.party_size);

    const bookingId = await TableModel.createBooking({
      uuid: uuidv4(),
      business_id: data.business_id,
      table_id: table?.id,
      user_id: userId,
      guest_name: data.guest_name,
      guest_phone: data.guest_phone,
      party_size: data.party_size,
      booking_date: data.booking_date,
      booking_time: data.booking_time,
      special_request: data.special_request,
    });

    if (table) await TableModel.setStatus(table.id, 'reserved');

    const booking = await TableModel.findBookingById(bookingId);
    emitToBusiness(data.business_id, 'booking:new_table', booking);
    return booking;
  },

  async listForBusiness(businessId: number, date?: string) {
    return TableModel.listBookingsByBusiness(businessId, date);
  },

  async listForUser(userId: number) {
    return TableModel.listBookingsByUser(userId);
  },

  async updateStatus(bookingId: number, status: string) {
    const booking = await TableModel.findBookingById(bookingId);
    if (!booking) throw new AppError('Booking not found', 404);
    await TableModel.updateBookingStatus(bookingId, status);
    if (booking.table_id && ['completed', 'cancelled', 'no_show'].includes(status)) {
      await TableModel.setStatus(booking.table_id, 'available');
    }
    if (booking.table_id && status === 'seated') {
      await TableModel.setStatus(booking.table_id, 'occupied');
    }
    emitToBusiness(booking.business_id, 'booking:table_status', { bookingId, status });
    return TableModel.findBookingById(bookingId);
  },
};
