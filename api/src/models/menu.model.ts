import { pool } from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

export interface MenuItem extends RowDataPacket {
  id: number;
  business_id: number;
  category_id: number | null;
  name: string;
  description: string | null;
  price: number;
  discount_percent: number | null;
  image_url: string | null;
  is_veg: number;
  is_available: number;
  prep_time_mins: number;
  tags: string | null;
}

// Columns that may be changed through update() - column names are interpolated into SQL,
// so never pass request-body keys straight through.
const ITEM_EDITABLE = [
  'category_id', 'name', 'description', 'price', 'discount_percent', 'image_url',
  'is_veg', 'is_available', 'prep_time_mins', 'tags',
];
const CATEGORY_EDITABLE = ['name', 'sort_order', 'is_active'];

function pick(data: Record<string, any>, allowed: string[]) {
  const out: Record<string, any> = {};
  for (const key of allowed) if (data && data[key] !== undefined) out[key] = data[key];
  return out;
}

export const MenuModel = {
  async createCategory(businessId: number, name: string, sortOrder = 0) {
    const [result] = await pool.query<ResultSetHeader>(
      'INSERT INTO menu_categories (business_id, name, sort_order) VALUES (?, ?, ?)',
      [businessId, name, sortOrder]
    );
    return result.insertId;
  },

  async listCategories(businessId: number, onlyActive = true) {
    const [rows] = await pool.query<RowDataPacket[]>(
      onlyActive
        ? 'SELECT * FROM menu_categories WHERE business_id = ? AND is_active = 1 ORDER BY sort_order ASC'
        : 'SELECT * FROM menu_categories WHERE business_id = ? ORDER BY sort_order ASC',
      [businessId]
    );
    return rows;
  },

  async findCategoryById(id: number) {
    const [rows] = await pool.query<RowDataPacket[]>('SELECT * FROM menu_categories WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async updateCategory(id: number, data: Record<string, any>) {
    const clean = pick(data, CATEGORY_EDITABLE);
    const fields = Object.keys(clean);
    if (!fields.length) return false;
    const setClause = fields.map((f) => `${f} = ?`).join(', ');
    await pool.query(`UPDATE menu_categories SET ${setClause} WHERE id = ?`, [...Object.values(clean), id]);
    return true;
  },

  // Items in the category are kept (category_id -> NULL via FK ON DELETE SET NULL).
  async removeCategory(id: number) {
    await pool.query('DELETE FROM menu_categories WHERE id = ?', [id]);
  },

  async countOrderReferences(itemId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT COUNT(*) AS cnt FROM order_items WHERE menu_item_id = ?',
      [itemId]
    );
    return Number(rows[0]?.cnt ?? 0);
  },

  async createItem(data: {
    business_id: number; category_id?: number; name: string; description?: string;
    price: number; discount_percent?: number; image_url?: string; is_veg?: boolean;
    prep_time_mins?: number; tags?: string;
  }) {
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO menu_items
        (business_id, category_id, name, description, price, discount_percent, image_url, is_veg, prep_time_mins, tags)
       VALUES (?,?,?,?,?,?,?,?,?,?)`,
      [
        data.business_id, data.category_id || null, data.name, data.description || null,
        data.price, data.discount_percent ?? null, data.image_url || null,
        data.is_veg ?? true, data.prep_time_mins ?? 15, data.tags || null,
      ]
    );
    return result.insertId;
  },

  async findById(id: number) {
    const [rows] = await pool.query<MenuItem[]>('SELECT * FROM menu_items WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async listByBusiness(businessId: number, onlyAvailable = true) {
    const query = onlyAvailable
      ? 'SELECT * FROM menu_items WHERE business_id = ? AND is_available = 1 ORDER BY category_id, name'
      : 'SELECT * FROM menu_items WHERE business_id = ? ORDER BY category_id, name';
    const [rows] = await pool.query<MenuItem[]>(query, [businessId]);
    return rows;
  },

  async update(id: number, data: Record<string, any>) {
    const clean = pick(data, ITEM_EDITABLE);
    const fields = Object.keys(clean);
    if (!fields.length) return false;
    const setClause = fields.map((f) => `${f} = ?`).join(', ');
    await pool.query(`UPDATE menu_items SET ${setClause} WHERE id = ?`, [...Object.values(clean), id]);
    return true;
  },

  async setAvailability(id: number, isAvailable: boolean) {
    await pool.query('UPDATE menu_items SET is_available = ? WHERE id = ?', [isAvailable, id]);
  },

  async remove(id: number) {
    await pool.query('DELETE FROM menu_items WHERE id = ?', [id]);
  },

  async search(query: string, limit = 20) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT mi.*, b.name AS business_name, b.city, b.type
       FROM menu_items mi JOIN businesses b ON b.id = mi.business_id
       WHERE mi.is_available = 1 AND b.status = 'approved' AND (mi.name LIKE ? OR mi.tags LIKE ?)
       LIMIT ?`,
      [`%${query}%`, `%${query}%`, limit]
    );
    return rows;
  },
};
