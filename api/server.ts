import http from 'http';
import app from './app';
import { env } from './config/env';
import { testConnection } from './config/db';
import { initSocket } from './utils/socket';

async function main() {
  try {
    await testConnection();
  } catch (err) {
    console.error('[db] Failed to connect to MySQL. Check your .env settings.', err);
    process.exit(1);
  }

  const server = http.createServer(app);
  initSocket(server);

  server.listen(env.port, () => {
    console.log(`🚀 Server running on http://localhost:${env.port} [${env.nodeEnv}]`);
    console.log(`🔌 Socket.io ready for realtime order & rider tracking`);
  });
}

main();
