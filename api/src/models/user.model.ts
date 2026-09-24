import { pool } from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';
import { UserRole } from '../types';

export interface User extends RowDataPacket {
  id: number;
  uuid: string;
  full_name: string;
  email: string | null;
  phone: string | null;
  password_hash: string;
  role: UserRole;
  avatar_url: string | null;
  is_active: number;
  is_verified: number;
  created_at: string;
}

export const UserModel = {
  async create(data: {
    uuid: string; full_name: string; email?: string; phone?: string;
    password_hash: string; role: UserRole;
  }) {
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO users (uuid, full_name, email, phone, password_hash, role)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [data.uuid, data.full_name, data.email || null, data.phone || null, data.password_hash, data.role]
    );
    return result.insertId;
  },

  async findById(id: number) {
    const [rows] = await pool.query<User[]>('SELECT * FROM users WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async findByEmail(email: string) {
    const [rows] = await pool.query<User[]>('SELECT * FROM users WHERE email = ?', [email]);
    return rows[0] || null;
  },

  async findByPhone(phone: string) {
    const [rows] = await pool.query<User[]>('SELECT * FROM users WHERE phone = ?', [phone]);
    return rows[0] || null;
  },

  async findByEmailOrPhone(identifier: string) {
    const [rows] = await pool.query<User[]>(
      'SELECT * FROM users WHERE email = ? OR phone = ? LIMIT 1',
      [identifier, identifier]
    );
    return rows[0] || null;
  },

  async updateProfile(id: number, data: Partial<{ full_name: string; avatar_url: string }>) {
    const fields = Object.keys(data);
    if (!fields.length) return;
    const setClause = fields.map((f) => `${f} = ?`).join(', ');
    await pool.query(`UPDATE users SET ${setClause} WHERE id = ?`, [...Object.values(data), id]);
  },

  // super_admin: every account (any role / status), searchable + paged.
  // "Suspended" == users.is_active = 0 (login is blocked in AuthService.login / refresh).
  async listAdmin(f: { search?: string; role?: string; status?: string; limit?: number; offset?: number }) {
    const limit = Math.min(Math.max(Number(f.limit) || 20, 1), 100);
    const offset = Math.max(Number(f.offset) || 0, 0);

    const where: string[] = [];
    const params: unknown[] = [];
    if (f.search) {
      const like = `%${f.search}%`;
      where.push('(u.full_name LIKE ? OR u.email LIKE ? OR u.phone LIKE ?)');
      params.push(like, like, like);
    }
    if (f.role && ['customer', 'business_owner', 'staff', 'rider', 'super_admin'].includes(f.role)) {
      where.push('u.role = ?');
      params.push(f.role);
    }
    if (f.status === 'suspended') where.push('u.is_active = 0');
    if (f.status === 'active') where.push('u.is_active = 1');
    const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT u.id, u.uuid, u.full_name, u.email, u.phone, u.role, u.is_active, u.created_at,
              IF(u.is_active = 1, 'active', 'suspended') AS status
       FROM users u ${whereSql}
       ORDER BY u.created_at DESC, u.id DESC
       LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );
    const [[{ total }]] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) AS total FROM users u ${whereSql}`,
      params
    );
    return { rows, total: Number(total), limit, offset };
  },

  async setActive(id: number, active: boolean) {
    await pool.query('UPDATE users SET is_active = ? WHERE id = ?', [active ? 1 : 0, id]);
  },

  async remove(id: number) {
    await pool.query('DELETE FROM users WHERE id = ?', [id]);
  },
};
