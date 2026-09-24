import { pool } from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

export interface Rider extends RowDataPacket {
  id: number;
  user_id: number;
  vehicle_type: string;
  vehicle_number: string | null;
  status: 'offline' | 'available' | 'busy';
  current_latitude: number | null;
  current_longitude: number | null;
  rating: number;
  total_deliveries: number;
}

export const RiderModel = {
  async create(userId: number, vehicleType = 'bike', vehicleNumber?: string) {
    const [result] = await pool.query<ResultSetHeader>(
      'INSERT INTO riders (user_id, vehicle_type, vehicle_number) VALUES (?, ?, ?)',
      [userId, vehicleType, vehicleNumber || null]
    );
    return result.insertId;
  },

  async findByUserId(userId: number) {
    const [rows] = await pool.query<Rider[]>('SELECT * FROM riders WHERE user_id = ?', [userId]);
    return rows[0] || null;
  },

  async findById(id: number) {
    const [rows] = await pool.query<Rider[]>('SELECT * FROM riders WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async setStatus(riderId: number, status: 'offline' | 'available' | 'busy') {
    await pool.query('UPDATE riders SET status = ? WHERE id = ?', [status, riderId]);
  },

  async updateLocation(riderId: number, lat: number, lng: number, orderId?: number) {
    await pool.query('UPDATE riders SET current_latitude = ?, current_longitude = ? WHERE id = ?', [lat, lng, riderId]);
    await pool.query(
      'INSERT INTO rider_location_pings (rider_id, order_id, latitude, longitude) VALUES (?, ?, ?, ?)',
      [riderId, orderId || null, lat, lng]
    );
  },

  // Naive nearest-available-rider using Haversine distance (fine for moderate rider counts;
  // swap for a geospatial index / dedicated matching service at scale).
  async findNearestAvailable(lat: number, lng: number, limit = 5) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT *,
        (6371 * acos(
          cos(radians(?)) * cos(radians(current_latitude)) *
          cos(radians(current_longitude) - radians(?)) +
          sin(radians(?)) * sin(radians(current_latitude))
        )) AS distance_km
       FROM riders
       WHERE status = 'available' AND current_latitude IS NOT NULL
       ORDER BY distance_km ASC
       LIMIT ?`,
      [lat, lng, lat, limit]
    );
    return rows;
  },

  async incrementDeliveries(riderId: number) {
    await pool.query('UPDATE riders SET total_deliveries = total_deliveries + 1 WHERE id = ?', [riderId]);
  },

  // Full roster for the admin panel: joins the user row so the UI has a name/phone to show,
  // and rider_location_pings isn't touched here since we only need the last known lat/lng.
  async listAll() {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT r.*, u.full_name, u.phone, u.email, u.is_active
       FROM riders r
       JOIN users u ON u.id = r.user_id
       ORDER BY (r.status = 'available') DESC, r.status ASC, u.full_name ASC`
    );
    return rows;
  },

  async updateVehicle(riderId: number, vehicleType?: string, vehicleNumber?: string) {
    const fields: string[] = [];
    const values: unknown[] = [];
    if (vehicleType) { fields.push('vehicle_type = ?'); values.push(vehicleType); }
    if (vehicleNumber) { fields.push('vehicle_number = ?'); values.push(vehicleNumber); }
    if (!fields.length) return;
    values.push(riderId);
    await pool.query(`UPDATE riders SET ${fields.join(', ')} WHERE id = ?`, values);
  },

  async listAvailable() {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT r.*, u.full_name, u.phone
       FROM riders r
       JOIN users u ON u.id = r.user_id
       WHERE r.status = 'available'
       ORDER BY u.full_name ASC`
    );
    return rows;
  },

  async countOrders(riderId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT COUNT(*) AS cnt FROM orders WHERE rider_id = ?',
      [riderId]
    );
    return Number(rows[0]?.cnt ?? 0);
  },
};
