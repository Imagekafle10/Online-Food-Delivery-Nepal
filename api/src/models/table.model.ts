import { pool } from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

export const TableModel = {
  async createTable(businessId: number, tableNumber: string, capacity: number, locationNote?: string) {
    const [result] = await pool.query<ResultSetHeader>(
      'INSERT INTO restaurant_tables (business_id, table_number, capacity, location_note) VALUES (?, ?, ?, ?)',
      [businessId, tableNumber, capacity, locationNote || null]
    );
    return result.insertId;
  },

  async listByBusiness(businessId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT * FROM restaurant_tables WHERE business_id = ? ORDER BY table_number', [businessId]
    );
    return rows;
  },

  async findAvailable(businessId: number, partySize: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT * FROM restaurant_tables WHERE business_id = ? AND status = 'available' AND capacity >= ?
       ORDER BY capacity ASC LIMIT 1`,
      [businessId, partySize]
    );
    return rows[0] || null;
  },

  async setStatus(tableId: number, status: string) {
    await pool.query('UPDATE restaurant_tables SET status = ? WHERE id = ?', [status, tableId]);
  },

  async createBooking(data: {
    uuid: string; business_id: number; table_id?: number; user_id: number; guest_name: string;
    guest_phone: string; party_size: number; booking_date: string; booking_time: string; special_request?: string;
  }) {
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO table_bookings (uuid, business_id, table_id, user_id, guest_name, guest_phone, party_size, booking_date, booking_time, special_request)
       VALUES (?,?,?,?,?,?,?,?,?,?)`,
      [data.uuid, data.business_id, data.table_id || null, data.user_id, data.guest_name, data.guest_phone,
        data.party_size, data.booking_date, data.booking_time, data.special_request || null]
    );
    return result.insertId;
  },

  async findBookingById(id: number) {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT * FROM table_bookings WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async listBookingsByBusiness(businessId: number, date?: string) {
    if (date) {
      const [rows] = await pool.query<RowDataPacket[]>(
        'SELECT * FROM table_bookings WHERE business_id = ? AND booking_date = ? ORDER BY booking_time', [businessId, date]
      );
      return rows;
    }
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT * FROM table_bookings WHERE business_id = ? ORDER BY booking_date DESC, booking_time DESC', [businessId]
    );
    return rows;
  },

  async listBookingsByUser(userId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT * FROM table_bookings WHERE user_id = ? ORDER BY booking_date DESC', [userId]
    );
    return rows;
  },

  async updateBookingStatus(id: number, status: string) {
    await pool.query('UPDATE table_bookings SET status = ? WHERE id = ?', [status, id]);
  },
};
