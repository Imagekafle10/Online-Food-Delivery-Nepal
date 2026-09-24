import { pool } from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

export const AddressModel = {
  async create(data: { user_id: number; label?: string; address_line: string; city?: string; latitude?: number; longitude?: number; is_default?: boolean }) {
    if (data.is_default) {
      await pool.query('UPDATE user_addresses SET is_default = 0 WHERE user_id = ?', [data.user_id]);
    }
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO user_addresses (user_id, label, address_line, city, latitude, longitude, is_default)
       VALUES (?,?,?,?,?,?,?)`,
      [data.user_id, data.label || 'Home', data.address_line, data.city || null, data.latitude ?? null, data.longitude ?? null, data.is_default ?? false]
    );
    return result.insertId;
  },

  async listByUser(userId: number) {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT * FROM user_addresses WHERE user_id = ? ORDER BY is_default DESC', [userId]);
    return rows;
  },

  async findById(id: number) {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT * FROM user_addresses WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async remove(id: number, userId: number) {
    await pool.query('DELETE FROM user_addresses WHERE id = ? AND user_id = ?', [id, userId]);
  },
};
