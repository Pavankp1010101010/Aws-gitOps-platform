import { createPool } from './db.js';
import { createApp } from './app.js';

const host = process.env.HOST ?? '127.0.0.1';
const port = Number(process.env.PORT ?? 3100);
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('PORT must be 1-65535.');
const pool = createPool(process.env.DATABASE_URL);
pool.on('error', error => console.error(JSON.stringify({ event: 'database_pool_error', code: error.code ?? 'DATABASE_ERROR' })));
const { app, registry } = createApp(pool, { version: process.env.APP_VERSION ?? 'local' });
const server = app.listen(port, host, () => console.log(JSON.stringify({ event: 'listening', host, port })));
server.on('error', async error => {
  console.error(JSON.stringify({ event: 'listen_failed', code: error.code }));
  await pool.end();
  registry.clear();
  process.exitCode = 1;
});
let closing = false;
function shutdown(signal) {
  if (closing) return;
  closing = true;
  console.log(JSON.stringify({ event: 'shutdown', signal }));
  const timer = setTimeout(() => {
    console.error(JSON.stringify({ event: 'shutdown_timeout' }));
    process.exit(1);
  }, 10000);
  timer.unref();
  server.close(async () => {
    try {
      await pool.end();
      registry.clear();
      clearTimeout(timer);
    } catch {
      console.error(JSON.stringify({ event: 'shutdown_failed' }));
      process.exitCode = 1;
    }
  });
}
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
