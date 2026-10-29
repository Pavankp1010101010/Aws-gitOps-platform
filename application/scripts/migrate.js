import { createPool, migrate } from '../src/db.js';

const pool = createPool(process.env.DATABASE_URL);
pool.on('error', () => { console.error('Database pool connection error.'); });
try {
  await migrate(pool);
  console.log('Database migrations applied successfully.');
} catch (error) {
  console.error('Migration failed.', { code: error.code ?? 'MIGRATION_ERROR' });
  process.exitCode = 1;
} finally {
  await pool.end();
}
