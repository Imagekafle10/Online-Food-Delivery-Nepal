import { RowDataPacket, ResultSetHeader } from 'mysql2';
import { pool } from '../config/db';
import { AppError } from '../utils/AppError';

export const ReviewService = {
  /** A customer can rate a restaurant once per delivered order. */
  async create(userId: number, body: { order_id?: number; rating?: number; comment?: string }) {
    const orderId = Number(body.order_id);
    const rating = Number(body.rating);
    if (!orderId) throw new AppError('order_id is required', 422);
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      throw new AppError('rating must be a whole number from 1 to 5', 422);
    }
    const comment = body.comment ? String(body.comment).trim().slice(0, 500) : null;

    const [orders] = await pool.query<RowDataPacket[]>(
      'SELECT id, business_id, user_id, status FROM orders WHERE id = ?',
      [orderId],
    );
    const order = orders[0];
    if (!order || order.user_id !== userId) throw new AppError('Order not found', 404);
    if (order.status !== 'delivered') throw new AppError('You can rate an order after it is delivered', 400);

    const [existing] = await pool.query<RowDataPacket[]>('SELECT id FROM reviews WHERE order_id = ?', [orderId]);
    if (existing.length) throw new AppError('You already rated this order', 409);

    const [r] = await pool.query<ResultSetHeader>(
      'INSERT INTO reviews (business_id, user_id, order_id, rating, comment) VALUES (?,?,?,?,?)',
      [order.business_id, userId, orderId, rating, comment],
    );
    return { id: r.insertId, business_id: order.business_id, order_id: orderId, rating, comment };
  },

  async listForBusiness(businessId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT r.id, r.rating, r.comment, r.created_at, u.full_name AS user_name
         FROM reviews r JOIN users u ON u.id = r.user_id
        WHERE r.business_id = ? ORDER BY r.created_at DESC LIMIT 50`,
      [businessId],
    );
    return rows;
  },

  async getForOrder(userId: number, orderId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT id, rating, comment FROM reviews WHERE order_id = ? AND user_id = ?',
      [orderId, userId],
    );
    return rows[0] ?? null;
  },
};
