import { pool } from '../config/db';
import { RowDataPacket } from 'mysql2';

export const DeviceModel = {
  // A token belongs to exactly one user: if the same phone logs into another
  // account, the row is re-assigned instead of duplicated.
  async upsert(userId: number, token: string, platform: string) {
    await pool.query(
      `INSERT INTO device_tokens (user_id, token, platform) VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), platform = VALUES(platform)`,
      [userId, token, platform],
    );
  },

  async remove(token: string, userId?: number) {
    if (userId) await pool.query('DELETE FROM device_tokens WHERE token = ? AND user_id = ?', [token, userId]);
    else await pool.query('DELETE FROM device_tokens WHERE token = ?', [token]);
  },

  async removeMany(tokens: string[]) {
    if (!tokens.length) return;
    await pool.query('DELETE FROM device_tokens WHERE token IN (?)', [tokens]);
  },

  async tokensForUsers(userIds: number[]): Promise<string[]> {
    if (!userIds.length) return [];
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT token FROM device_tokens WHERE user_id IN (?)',
      [userIds],
    );
    return rows.map((r) => r.token as string);
  },

  // Owner + staff of a business (they all get new-order alerts).
  async businessUserIds(businessId: number): Promise<number[]> {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT owner_id AS uid FROM businesses WHERE id = ?
       UNION SELECT user_id AS uid FROM business_staff WHERE business_id = ?`,
      [businessId, businessId],
    );
    return rows.map((r) => r.uid as number);
  },

  async riderUserId(riderId: number): Promise<number | null> {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT user_id FROM riders WHERE id = ?', [riderId]);
    return rows[0]?.user_id ?? null;
  },
};
