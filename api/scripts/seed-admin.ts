/**
 * One-off script to create (or promote) the platform super_admin account.
 * Run after `npm install` and after the schema has been applied:
 *
 *   npm run seed:admin
 *
 * Credentials are set below — change them before running, or override
 * via env vars ADMIN_EMAIL / ADMIN_PASSWORD / ADMIN_NAME.
 */
import { v4 as uuidv4 } from 'uuid';
import { pool } from '../src/config/db';
import { hashPassword } from '../src/utils/auth.util';

const ADMIN_NAME = process.env.ADMIN_NAME || 'Super Admin';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@bhansa.app';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Bhansa@Admin2026!';

async function main() {
  const password_hash = await hashPassword(ADMIN_PASSWORD);

  const [existingRows] = await pool.query('SELECT id FROM users WHERE email = ?', [ADMIN_EMAIL]);
  const existing = (existingRows as any[])[0];

  if (existing) {
    await pool.query(
      'UPDATE users SET full_name = ?, password_hash = ?, role = ?, is_active = 1, is_verified = 1 WHERE id = ?',
      [ADMIN_NAME, password_hash, 'super_admin', existing.id]
    );
    console.log(`[seed:admin] Updated existing user #${existing.id} (${ADMIN_EMAIL}) to super_admin.`);
  } else {
    const uuid = uuidv4();
    await pool.query(
      `INSERT INTO users (uuid, full_name, email, password_hash, role, is_active, is_verified)
       VALUES (?, ?, ?, ?, 'super_admin', 1, 1)`,
      [uuid, ADMIN_NAME, ADMIN_EMAIL, password_hash]
    );
    console.log(`[seed:admin] Created super_admin user (${ADMIN_EMAIL}).`);
  }

  console.log('---');
  console.log(`Login email:    ${ADMIN_EMAIL}`);
  console.log(`Login password: ${ADMIN_PASSWORD}`);
  console.log('---');
  console.log('Change this password after first login.');

  await pool.end();
}

main().catch((err) => {
  console.error('[seed:admin] Failed:', err);
  process.exit(1);
});
