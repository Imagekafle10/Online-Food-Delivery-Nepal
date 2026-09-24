import { v4 as uuidv4 } from 'uuid';
import { RoomModel } from '../models/room.model';
import { BusinessModel } from '../models/business.model';
import { AppError } from '../utils/AppError';
import { PaymentMethod } from '../types';
import { emitToBusiness } from '../utils/socket';

function nightsBetween(checkIn: string, checkOut: string) {
  const inDate = new Date(checkIn);
  const outDate = new Date(checkOut);
  const diffMs = outDate.getTime() - inDate.getTime();
  return Math.round(diffMs / (1000 * 60 * 60 * 24));
}

export const RoomService = {
  async addRoom(businessId: number, data: any) {
    const id = await RoomModel.createRoom({ ...data, business_id: businessId });
    return RoomModel.findById(id);
  },

  async listRooms(businessId: number) {
    return RoomModel.listByBusiness(businessId);
  },

  async searchAvailable(businessId: number, checkIn: string, checkOut: string, guests?: number) {
    if (nightsBetween(checkIn, checkOut) < 1) throw new AppError('check_out must be after check_in', 422);
    return RoomModel.listAvailableRooms(businessId, checkIn, checkOut, guests);
  },

  async book(userId: number, data: {
    business_id: number; room_id: number; guest_name: string; guest_phone: string;
    check_in: string; check_out: string; num_guests: number; payment_method: PaymentMethod;
  }) {
    const business = await BusinessModel.findById(data.business_id);
    if (!business) throw new AppError('Business not found', 404);
    if (!business.has_room_booking) throw new AppError('This business does not accept room bookings', 400);

    const room = await RoomModel.findById(data.room_id);
    if (!room || room.business_id !== data.business_id) throw new AppError('Room not found', 404);

    const nights = nightsBetween(data.check_in, data.check_out);
    if (nights < 1) throw new AppError('check_out must be after check_in', 422);

    const available = await RoomModel.isAvailable(data.room_id, data.check_in, data.check_out);
    if (!available) throw new AppError('Room is not available for the selected dates', 409);

    const totalAmount = Number((room.price_per_night * nights).toFixed(2));

    const bookingId = await RoomModel.createBooking({
      uuid: uuidv4(),
      business_id: data.business_id,
      room_id: data.room_id,
      user_id: userId,
      guest_name: data.guest_name,
      guest_phone: data.guest_phone,
      check_in: data.check_in,
      check_out: data.check_out,
      num_guests: data.num_guests,
      nights,
      price_per_night: room.price_per_night,
      total_amount: totalAmount,
      payment_method: data.payment_method,
    });

    const booking = await RoomModel.findBookingById(bookingId);
    emitToBusiness(data.business_id, 'booking:new_room', booking);
    return booking;
  },

  async listForBusiness(businessId: number) {
    return RoomModel.listBookingsByBusiness(businessId);
  },

  async listForUser(userId: number) {
    return RoomModel.listBookingsByUser(userId);
  },

  async updateStatus(bookingId: number, status: string) {
    const booking = await RoomModel.findBookingById(bookingId);
    if (!booking) throw new AppError('Booking not found', 404);
    await RoomModel.updateBookingStatus(bookingId, status);
    emitToBusiness(booking.business_id, 'booking:room_status', { bookingId, status });
    return RoomModel.findBookingById(bookingId);
  },
};
