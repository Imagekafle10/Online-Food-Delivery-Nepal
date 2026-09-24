import { pool } from "../config/db";
import { RowDataPacket, ResultSetHeader } from "mysql2";
import { PaymentMethod, GatewayPaymentStatus } from "../types";

export const PaymentModel = {
  async create(data: {
    uuid: string;
    reference_type: "order" | "room_booking";
    reference_id: number;
    user_id: number;
    amount: number;
    method: PaymentMethod;
  }) {
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO payments (uuid, reference_type, reference_id, user_id, amount, method, status)
       VALUES (?,?,?,?,?,?, 'initiated')`,
      [
        data.uuid,
        data.reference_type,
        data.reference_id,
        data.user_id,
        data.amount,
        data.method,
      ],
    );
    return result.insertId;
  },

  async findByUuid(uuid: string) {
    const [rows] = await pool.query<RowDataPacket[]>(
      "SELECT * FROM payments WHERE uuid = ?",
      [uuid],
    );
    return rows[0] || null;
  },

  async markStatus(
    uuid: string,
    status: GatewayPaymentStatus,
    gatewayTxnId?: string,
    gatewayRefId?: string,
    rawResponse?: any,
  ) {
    await pool.query(
      `UPDATE payments SET status = ?, gateway_txn_id = ?, gateway_ref_id = ?, raw_response = ? WHERE uuid = ?`,
      [
        status,
        gatewayTxnId || null,
        gatewayRefId || null,
        rawResponse ? JSON.stringify(rawResponse) : null,
        uuid,
      ],
    );
  },

  async listForUser(userId: number) {
    const [rows] = await pool.query<RowDataPacket[]>(
      "SELECT * FROM payments WHERE user_id = ? ORDER BY created_at DESC",
      [userId],
    );
    return rows;
  },
};
