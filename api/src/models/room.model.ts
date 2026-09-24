import { pool } from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

export const RoomModel = {
  async createRoom(data: {
    business_id: number; room_number: string; room_type: string; description?: string;
    price_per_night: number; capacity?: number; image_url?: string; amenities?: string;
  }) {
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO rooms (business_id, room_number, room_type, description, price_per_night, capacity, image_url, amenities)
       VALUES (?,?,?,?,?,?,?,?)`,
      [data.business_id, data.room_number, data.room_type, data.description || null,
        data.price_per_night, data.capacity ?? 2, data.image_url || null, data.amenities || null]
    );
    return result.insertId;
  },

  async listByBusiness(businessId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      "SELECT * FROM rooms WHERE business_id = ? AND status != 'inactive' ORDER BY price_per_night", [businessId]
    );
    return rows;
  },

  async findById(id: number) {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT * FROM rooms WHERE id = ?', [id]);
    return rows[0] || null;
  },

  // A room is available for [checkIn, checkOut) if it has no overlapping CONFIRMED/PENDING booking
  async isAvailable(roomId: number, checkIn: string, checkOut: string) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) AS cnt FROM room_bookings
       WHERE room_id = ? AND status IN ('pending','confirmed','checked_in')
       AND NOT (check_out <= ? OR check_in >= ?)`,
      [roomId, checkIn, checkOut]
    );
    return rows[0].cnt === 0;
  },

  async listAvailableRooms(businessId: number, checkIn: string, checkOut: string, guests?: number) {
    const guestFilter = guests ? 'AND capacity >= ?' : '';
    const params = guests ? [businessId, guests] : [businessId];
    const [rooms] = await pool.query<RowDataPacket[]>(
      `SELECT * FROM rooms WHERE business_id = ? AND status = 'available' ${guestFilter}`,
      params
    );
    const available = [];
    for (const room of rooms) {
      const free = await RoomModel.isAvailable(room.id, checkIn, checkOut);
      if (free) available.push(room);
    }
    return available;
  },

  async createBooking(data: {
    uuid: string; business_id: number; room_id: number; user_id: number; guest_name: string;
    guest_phone: string; check_in: string; check_out: string; num_guests: number; nights: number;
    price_per_night: number; total_amount: number; payment_method: string;
  }) {
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO room_bookings
        (uuid, business_id, room_id, user_id, guest_name, guest_phone, check_in, check_out, num_guests, nights, price_per_night, total_amount, payment_method)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [data.uuid, data.business_id, data.room_id, data.user_id, data.guest_name, data.guest_phone,
        data.check_in, data.check_out, data.num_guests, data.nights, data.price_per_night, data.total_amount, data.payment_method]
    );
    return result.insertId;
  },

  async findBookingById(id: number) {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT * FROM room_bookings WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async listBookingsByUser(userId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT * FROM room_bookings WHERE user_id = ? ORDER BY check_in DESC', [userId]
    );
    return rows;
  },

  async listBookingsByBusiness(businessId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT * FROM room_bookings WHERE business_id = ? ORDER BY check_in DESC', [businessId]
    );
    return rows;
  },

  async updateBookingStatus(id: number, status: string) {
    await pool.query('UPDATE room_bookings SET status = ? WHERE id = ?', [status, id]);
  },

  async setPaymentStatus(id: number, status: string) {
    await pool.query('UPDATE room_bookings SET payment_status = ? WHERE id = ?', [status, id]);
  },
};
