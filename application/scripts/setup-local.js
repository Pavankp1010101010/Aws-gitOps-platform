import { randomBytes } from 'node:crypto';
import { writeFileSync } from 'node:fs';

const password = randomBytes(24).toString('hex');
const content = [
  `POSTGRES_PASSWORD=${password}`,
  `DATABASE_URL=postgresql://ticket_app:${password}@127.0.0.1:55432/ticket_dev`,
  `TEST_DATABASE_URL=postgresql://ticket_app:${password}@127.0.0.1:55432/ticket_test`,
  'HOST=127.0.0.1', 'PORT=3100', 'APP_VERSION=local', '',
].join('\n');

try {
  writeFileSync(new URL('../.env', import.meta.url), content, { flag: 'wx', mode: 0o600 });
  console.log('Created ignored .env with random local credentials. Existing files are never overwritten.');
} catch (error) {
  console.error(error.code === 'EEXIST' ? '.env already exists; preserve it or explicitly move it before setup.' : 'Local setup failed.');
  process.exitCode = 1;
}
