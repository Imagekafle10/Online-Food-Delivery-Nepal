import { pool } from '../config/db';
import { RowDataPacket, ResultSetHeader, PoolConnection } from 'mysql2/promise';
import { OrderStatus, PaymentMethod, PaymentStatus } from '../types';

export interface Order extends RowDataPacket {
  id: number;
  uuid: string;
  order_number: string;
  business_id: number;
  user_id: number;
  order_type: 'delivery' | 'pickup' | 'dine_in';
  status: OrderStatus;
  subtotal: number;
  delivery_fee: number;
  tax_amount: number;
  discount_amount: number;
  total_amount: number;
  payment_method: PaymentMethod;
  payment_status: PaymentStatus;
  delivery_address_id: number | null;
  delivery_latitude: number | null;
  delivery_longitude: number | null;
  rider_id: number | null;
  created_at: string;
}

export interface OrderItemInput {
  menu_item_id: number;
  item_name: string;
  unit_price: number;
  quantity: number;
  addons_json?: any;
  item_subtotal: number;
  notes?: string;
}

export const OrderModel = {
  async createWithItems(order: {
    uuid: string; order_number: string; business_id: number; user_id: number;
    order_type: string; subtotal: number; delivery_fee: number; tax_amount: number;
    discount_amount: number; total_amount: number; payment_method: PaymentMethod;
    delivery_address_id?: number; delivery_latitude?: number; delivery_longitude?: number;
    delivery_instructions?: string; table_id?: number; special_instructions?: string;
  }, items: OrderItemInput[]) {
    const conn: PoolConnection = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const [result] = await conn.query<ResultSetHeader>(
        `INSERT INTO orders
          (uuid, order_number, business_id, user_id, order_type, subtotal, delivery_fee, tax_amount,
           discount_amount, total_amount, payment_method, delivery_address_id, delivery_latitude,
           delivery_longitude, delivery_instructions, table_id, special_instructions,
           status)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, 'placed')`,
        [
          order.uuid, order.order_number, order.business_id, order.user_id, order.order_type,
          order.subtotal, order.delivery_fee, order.tax_amount, order.discount_amount, order.total_amount,
          order.payment_method, order.delivery_address_id || null, order.delivery_latitude ?? null,
          order.delivery_longitude ?? null, order.delivery_instructions || null, order.table_id || null,
          order.special_instructions || null,
        ]
      );
      const orderId = result.insertId;

      for (const item of items) {
        await conn.query(
          `INSERT INTO order_items (order_id, menu_item_id, item_name, unit_price, quantity, addons_json, item_subtotal, notes)
           VALUES (?,?,?,?,?,?,?,?)`,
          [orderId, item.menu_item_id, item.item_name, item.unit_price, item.quantity,
            item.addons_json ? JSON.stringify(item.addons_json) : null, item.item_subtotal, item.notes || null]
        );
      }

      await conn.query(
        'INSERT INTO order_status_log (order_id, status, note) VALUES (?, ?, ?)',
        [orderId, 'placed', 'Order placed — waiting for kitchen']
      );

      await conn.commit();
      return orderId;
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  },

  async findById(id: number) {
    const [rows] = await pool.query<Order[]>('SELECT * FROM orders WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async findByUuid(uuid: string) {
    const [rows] = await pool.query<Order[]>('SELECT * FROM orders WHERE uuid = ?', [uuid]);
    return rows[0] || null;
  },

  async getItems(orderId: number) {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT * FROM order_items WHERE order_id = ?', [orderId]);
    return rows;
  },

  async getStatusLog(orderId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT * FROM order_status_log WHERE order_id = ? ORDER BY created_at ASC', [orderId]
    );
    return rows;
  },

  async listByUser(userId: number, limit = 20, offset = 0) {
    const [rows] = await pool.query<Order[]>(
      'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [userId, limit, offset]
    );
    return rows;
  },

  async listByBusiness(businessId: number, status?: OrderStatus, limit = 50, offset = 0) {
    if (status) {
      const [rows] = await pool.query<Order[]>(
        'SELECT * FROM orders WHERE business_id = ? AND status = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
        [businessId, status, limit, offset]
      );
      return rows;
    }
    const [rows] = await pool.query<Order[]>(
      'SELECT * FROM orders WHERE business_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [businessId, limit, offset]
    );
    return rows;
  },

  async listActiveForRider(riderId: number) {
    const [rows] = await pool.query<Order[]>(
      `SELECT * FROM orders WHERE rider_id = ? AND status IN ('accepted','cooking','on_the_way')
       ORDER BY created_at ASC`,
      [riderId]
    );
    return rows;
  },

  // Delivery orders that still need a rider (accepted / cooking, no rider yet).
  // Joins business name + customer name so the admin "assign rider" screen doesn't
  // need N extra lookups per row.
  async listUnassignedReady(businessId?: number) {
    const base = `
      SELECT o.*, b.name AS business_name, b.city AS business_city, u.full_name AS customer_name
      FROM orders o
      JOIN businesses b ON b.id = o.business_id
      JOIN users u ON u.id = o.user_id
      WHERE o.status IN ('accepted','cooking') AND o.order_type = 'delivery' AND o.rider_id IS NULL`;
    if (businessId) {
      const [rows] = await pool.query<Order[]>(`${base} AND o.business_id = ? ORDER BY o.placed_at ASC`, [businessId]);
      return rows;
    }
    const [rows] = await pool.query<Order[]>(`${base} ORDER BY o.placed_at ASC`);
    return rows;
  },

  // Every delivery-type order (any status), with business/customer/rider names joined in —
  // used by the admin "Delivery" screen so admin can see the full picture, not just
  // the ones still waiting for a rider.
  async listAllDeliveryOrders(businessId?: number, status?: OrderStatus) {
    const conditions: string[] = [`o.order_type = 'delivery'`];
    const params: unknown[] = [];
    if (businessId) { conditions.push('o.business_id = ?'); params.push(businessId); }
    if (status) { conditions.push('o.status = ?'); params.push(status); }

    const [rows] = await pool.query<Order[]>(
      `SELECT o.*, b.name AS business_name, b.city AS business_city,
              u.full_name AS customer_name, ru.full_name AS rider_name
       FROM orders o
       JOIN businesses b ON b.id = o.business_id
       JOIN users u ON u.id = o.user_id
       LEFT JOIN riders r ON r.id = o.rider_id
       LEFT JOIN users ru ON ru.id = r.user_id
       WHERE ${conditions.join(' AND ')}
       ORDER BY o.placed_at DESC
       LIMIT 200`,
      params
    );
    return rows;
  },

  // super_admin: every order on the platform, filterable + searchable, with paging.
  async listAdmin(filters: {
    search?: string; status?: string; businessId?: number; orderType?: string;
    paymentStatus?: string; from?: string; to?: string; limit?: number; offset?: number;
  }) {
    const conditions: string[] = [];
    const params: any[] = [];
    if (filters.businessId) { conditions.push('o.business_id = ?'); params.push(filters.businessId); }
    if (filters.status) { conditions.push('o.status = ?'); params.push(filters.status); }
    if (filters.orderType) { conditions.push('o.order_type = ?'); params.push(filters.orderType); }
    if (filters.paymentStatus) { conditions.push('o.payment_status = ?'); params.push(filters.paymentStatus); }
    if (filters.from) { conditions.push('o.placed_at >= ?'); params.push(filters.from); }
    if (filters.to) { conditions.push('o.placed_at < DATE_ADD(?, INTERVAL 1 DAY)'); params.push(filters.to); }
    if (filters.search) {
      const like = `%${filters.search}%`;
      conditions.push('(o.order_number LIKE ? OR u.full_name LIKE ? OR u.phone LIKE ? OR b.name LIKE ?)');
      params.push(like, like, like, like);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = Math.min(Math.max(filters.limit ?? 20, 1), 100);
    const offset = Math.max(filters.offset ?? 0, 0);
    const from = `FROM orders o
       JOIN businesses b ON b.id = o.business_id
       JOIN users u ON u.id = o.user_id
       LEFT JOIN riders r ON r.id = o.rider_id
       LEFT JOIN users ru ON ru.id = r.user_id
       ${where}`;

    const [countRows] = await pool.query<RowDataPacket[]>(`SELECT COUNT(*) AS total ${from}`, params);
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT o.*, b.name AS business_name, b.city AS business_city, b.type AS business_type,
              u.full_name AS customer_name, u.phone AS customer_phone,
              ru.full_name AS rider_name,
              (SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.id) AS item_count
       ${from}
       ORDER BY o.placed_at DESC
       LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );
    return { rows, total: Number(countRows[0]?.total ?? 0), limit, offset };
  },

  // Full detail for the admin "view order" screen.
  async findAdminDetail(orderId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT o.*,
              b.name AS business_name, b.type AS business_type, b.phone AS business_phone,
              b.address AS business_address, b.city AS business_city,
              u.full_name AS customer_name, u.phone AS customer_phone, u.email AS customer_email,
              ru.full_name AS rider_name, ru.phone AS rider_phone,
              r.vehicle_type AS rider_vehicle_type, r.vehicle_number AS rider_vehicle_number,
              a.label AS delivery_address_label, a.address_line AS delivery_address_line,
              a.city AS delivery_city
       FROM orders o
       JOIN businesses b ON b.id = o.business_id
       JOIN users u ON u.id = o.user_id
       LEFT JOIN riders r ON r.id = o.rider_id
       LEFT JOIN users ru ON ru.id = r.user_id
       LEFT JOIN user_addresses a ON a.id = o.delivery_address_id
       WHERE o.id = ?`,
      [orderId]
    );
    return rows[0] || null;
  },

  async getPayments(orderId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT id, uuid, amount, method, status, gateway_txn_id, gateway_ref_id, created_at
       FROM payments WHERE reference_type = 'order' AND reference_id = ? ORDER BY created_at ASC`,
      [orderId]
    );
    return rows;
  },

  // order_items + order_status_log go with it (ON DELETE CASCADE). Payment rows are
  // intentionally left alone so the money trail is never lost.
  async remove(orderId: number) {
    await pool.query('DELETE FROM orders WHERE id = ?', [orderId]);
  },

  async updateStatus(orderId: number, status: OrderStatus, note?: string) {
    // on_the_way = the rider has picked the food up
    const timestampField: Record<string, string | null> = {
      accepted: 'accepted_at',
      cooking: 'ready_at', // kitchen started prep (reuse ready_at as prep-started marker)
      on_the_way: 'picked_up_at',
      delivered: 'delivered_at',
    };
    const extraSet = timestampField[status] ? `, ${timestampField[status]} = NOW()` : '';
    await pool.query(`UPDATE orders SET status = ? ${extraSet} WHERE id = ?`, [status, orderId]);
    await pool.query('INSERT INTO order_status_log (order_id, status, note) VALUES (?, ?, ?)', [orderId, status, note || null]);
  },

  async assignRider(orderId: number, riderId: number) {
    // Assigning a rider no longer changes the order status - it just links the rider.
    await pool.query('UPDATE orders SET rider_id = ? WHERE id = ?', [riderId, orderId]);
    await pool.query(
      'INSERT INTO order_status_log (order_id, status, note) SELECT id, status, ? FROM orders WHERE id = ?',
      [`Rider #${riderId} assigned`, orderId]
    );
  },

  async setPaymentStatus(orderId: number, status: PaymentStatus) {
    await pool.query('UPDATE orders SET payment_status = ? WHERE id = ?', [status, orderId]);
  },

  async cancel(orderId: number, reason: string) {
    await pool.query(`UPDATE orders SET status = 'cancelled', cancelled_reason = ? WHERE id = ?`, [reason, orderId]);
    await pool.query('INSERT INTO order_status_log (order_id, status, note) VALUES (?, ?, ?)', [orderId, 'cancelled', reason]);
  },
};
