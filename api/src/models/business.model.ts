import { pool } from "../config/db";
import { RowDataPacket, ResultSetHeader } from "mysql2";
import { BusinessType } from "../types";

export interface Business extends RowDataPacket {
  id: number;
  uuid: string;
  owner_id: number;
  name: string;
  slug: string;
  type: BusinessType;
  description: string | null;
  logo_url: string | null;
  cover_image_url: string | null;
  phone: string | null;
  email: string | null;
  address: string | null;
  city: string | null;
  latitude: number | null;
  longitude: number | null;
  has_food_ordering: number;
  has_table_booking: number;
  has_room_booking: number;
  delivery_radius_km: number;
  base_delivery_fee: number;
  min_order_amount: number;
  avg_prep_time_mins: number;
  commission_percent: number;
  status: "pending" | "approved" | "suspended" | "rejected";
  is_open: number;
  opens_at: string;
  closes_at: string;
}

export const BusinessModel = {
  async create(data: {
    uuid: string;
    owner_id: number;
    name: string;
    slug: string;
    type: BusinessType;
    description?: string;
    phone?: string;
    email?: string;
    address?: string;
    city?: string;
    latitude?: number;
    longitude?: number;
    logo_url?: string;
    has_food_ordering?: boolean;
    has_table_booking?: boolean;
    has_room_booking?: boolean;
  }) {
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO businesses
        (uuid, owner_id, name, slug, type, description, phone, email, address, city, latitude, longitude, logo_url,
         has_food_ordering, has_table_booking, has_room_booking)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [
        data.uuid,
        data.owner_id,
        data.name,
        data.slug,
        data.type,
        data.description || null,
        data.phone || null,
        data.email || null,
        data.address || null,
        data.city || null,
        data.latitude ?? null,
        data.longitude ?? null,
        data.logo_url || null,
        data.has_food_ordering ?? true,
        data.has_table_booking ?? true,
        data.has_room_booking ?? false,
      ],
    );
    return result.insertId;
  },

  async findById(id: number) {
    const [rows] = await pool.query<Business[]>(
      "SELECT * FROM businesses WHERE id = ?",
      [id],
    );
    return rows[0] || null;
  },

  async findBySlug(slug: string) {
    const [rows] = await pool.query<Business[]>(
      "SELECT * FROM businesses WHERE slug = ?",
      [slug],
    );
    return rows[0] || null;
  },

  /** Used to enforce: 1 owner → 1 business only */
  async countByOwner(ownerId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      "SELECT COUNT(*) AS cnt FROM businesses WHERE owner_id = ?",
      [ownerId],
    );
    return Number(rows[0]?.cnt ?? 0);
  },

  async isOwner(businessId: number, userId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT 1 FROM businesses WHERE id = ? AND owner_id = ?
       UNION SELECT 1 FROM business_staff WHERE business_id = ? AND user_id = ?`,
      [businessId, userId, businessId, userId],
    );
    return rows.length > 0;
  },

  async list(filters: {
    type?: BusinessType;
    city?: string;
    status?: string;
    search?: string;
    limit?: number;
    offset?: number;
  }) {
    const conditions: string[] = [];
    const params: any[] = [];
    if (filters.type) {
      conditions.push("type = ?");
      params.push(filters.type);
    }
    if (filters.city) {
      conditions.push("city = ?");
      params.push(filters.city);
    }
    conditions.push("status = ?");
    params.push(filters.status || "approved");
    if (filters.search) {
      conditions.push("(name LIKE ? OR description LIKE ?)");
      params.push(`%${filters.search}%`, `%${filters.search}%`);
    }

    const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
    const limit = filters.limit ?? 20;
    const offset = filters.offset ?? 0;
    const [rows] = await pool.query<Business[]>(
      `SELECT * FROM businesses ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    );
    return rows;
  },

  /**
   * super_admin listing: ALL statuses (pending/suspended/rejected too), searchable by
   * business name, city, address, phone, email or owner name. Returns paging info.
   */
  async listAdmin(filters: {
    search?: string;
    status?: string;
    type?: string;
    city?: string;
    limit?: number;
    offset?: number;
  }) {
    const conditions: string[] = [];
    const params: any[] = [];
    if (filters.status) { conditions.push("b.status = ?"); params.push(filters.status); }
    if (filters.type) { conditions.push("b.type = ?"); params.push(filters.type); }
    if (filters.city) { conditions.push("b.city = ?"); params.push(filters.city); }
    if (filters.search) {
      const like = `%${filters.search}%`;
      conditions.push(
        "(b.name LIKE ? OR b.city LIKE ? OR b.address LIKE ? OR b.phone LIKE ? OR b.email LIKE ? OR u.full_name LIKE ?)",
      );
      params.push(like, like, like, like, like, like);
    }
    const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
    const limit = Math.min(Math.max(filters.limit ?? 20, 1), 100);
    const offset = Math.max(filters.offset ?? 0, 0);
    const from = `FROM businesses b JOIN users u ON u.id = b.owner_id ${where}`;

    const [countRows] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) AS total ${from}`,
      params,
    );
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT b.*, u.full_name AS owner_name, u.email AS owner_email, u.phone AS owner_phone,
              (SELECT COUNT(*) FROM menu_items mi WHERE mi.business_id = b.id) AS menu_items_count,
              (SELECT COUNT(*) FROM orders o WHERE o.business_id = b.id) AS orders_count
       ${from}
       ORDER BY b.created_at DESC
       LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    );
    return { rows, total: Number(countRows[0]?.total ?? 0), limit, offset };
  },

  async updateStatus(id: number, status: string) {
    await pool.query("UPDATE businesses SET status = ? WHERE id = ?", [
      status,
      id,
    ]);
  },

  async update(id: number, data: Record<string, any>) {
    const fields = Object.keys(data);
    if (!fields.length) return;
    const setClause = fields.map((f) => `${f} = ?`).join(", ");
    await pool.query(`UPDATE businesses SET ${setClause} WHERE id = ?`, [
      ...Object.values(data),
      id,
    ]);
  },

  async toggleOpen(id: number, isOpen: boolean) {
    await pool.query("UPDATE businesses SET is_open = ? WHERE id = ?", [
      isOpen,
      id,
    ]);
  },

  async remove(id: number) {
    await pool.query("DELETE FROM businesses WHERE id = ?", [id]);
  },
};
