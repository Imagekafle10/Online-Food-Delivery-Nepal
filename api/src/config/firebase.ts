import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging as fbGetMessaging, Messaging } from 'firebase-admin/messaging';

let messaging: Messaging | null = null;
let tried = false;

/**
 * Reads the Firebase service account from env:
 *   FIREBASE_SERVICE_ACCOUNT_BASE64  (recommended on Render: base64 of the JSON file)
 *   or FIREBASE_SERVICE_ACCOUNT_JSON (raw JSON string)
 * If neither is set, push is silently disabled (the rest of the API keeps working).
 */
export function getMessaging(): Messaging | null {
  if (!tried) {
    tried = true;
    try {
      const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
      const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      const json = b64 ? Buffer.from(b64, 'base64').toString('utf8') : raw;
      if (!json) {
        console.warn('[push] Firebase credentials not set - push notifications disabled');
      } else {
        const app = getApps()[0] ?? initializeApp({ credential: cert(JSON.parse(json)) });
        messaging = fbGetMessaging(app);
        console.log('[push] Firebase Admin initialised');
      }
    } catch (e: any) {
      console.error('[push] Firebase init failed:', e.message);
    }
  }
  return messaging;
}
