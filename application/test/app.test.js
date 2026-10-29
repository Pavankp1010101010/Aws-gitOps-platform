import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createApp } from '../src/app.js';
import { createPool, migrate } from '../src/db.js';

const databaseUrl = process.env.TEST_DATABASE_URL;
if (!databaseUrl) throw new Error('TEST_DATABASE_URL is required; run local setup.');
const url = new URL(databaseUrl);
if (url.pathname !== '/ticket_test' || !['127.0.0.1', 'localhost'].includes(url.hostname) ||
    url.port !== '55432' || databaseUrl === process.env.DATABASE_URL) {
  throw new Error('Tests may reset only the dedicated loopback ticket_test database on port 55432.');
}
const pool = createPool(databaseUrl);
pool.on('error', error => console.error(JSON.stringify({ event: 'test_pool_error', code: error.code })));
const logs = [];
const logger = { error: entry => logs.push(JSON.parse(entry)) };
let server;
let registry;
let base;
let id;

async function start() {
  const instance = createApp(pool, { logger, version: 'test-version', defaultMetrics: false });
  registry = instance.registry;
  server = instance.app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}`;
}
async function stop() {
  await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  registry.clear();
}
async function request(path, method = 'GET', body) {
  const response = await fetch(base + path, {
    method, headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: response.status, data: await response.json() };
}
before(async () => {
  await migrate(pool);
  await migrate(pool);
  await pool.query('TRUNCATE comments, tickets RESTART IDENTITY');
  await start();
});
after(async () => {
  if (server?.listening) await stop();
  await pool.end();
});

test('health, readiness, version and static browser assets', async () => {
  assert.equal((await request('/health/live')).status, 200);
  assert.equal((await request('/health/ready')).status, 200);
  assert.deepEqual((await request('/api/version')).data, { version: 'test-version' });
  const page = await fetch(base);
  assert.equal(page.status, 200);
  assert.match(page.headers.get('content-security-policy'), /default-src 'self'/);
  assert.match(await page.text(), /Support Ticket Tracker/);
});
test('creates a persistent ticket with defaults and literal markup', async () => {
  const response = await request('/api/tickets', 'POST', {
    title: '<script>not executable</script>', description: "Can't access the demo", assignee: 'Demo engineer',
  });
  assert.equal(response.status, 201);
  assert.equal(response.data.status, 'open');
  assert.equal(response.data.priority, 'medium');
  assert.equal(response.data.assignee, 'Demo engineer');
  assert.ok(response.data.created_at);
  id = response.data.id;
  const detail = await request(`/api/tickets/${id}`);
  assert.deepEqual(detail.data.comments, []);
  assert.equal(detail.data.title, '<script>not executable</script>');
});
test('updates priority, assignee, lifecycle and reopening', async () => {
  for (const status of ['in_progress', 'resolved', 'open']) {
    const response = await request(`/api/tickets/${id}`, 'PATCH', { status, priority: 'high', assignee: 'Second engineer' });
    assert.equal(response.status, 200);
    assert.equal(response.data.status, status);
    assert.equal(response.data.priority, 'high');
    assert.equal(response.data.assignee, 'Second engineer');
  }
});
test('comments are timestamped, associated and returned in order', async () => {
  for (const body of ['Investigating the issue', 'Service verified']) {
    const response = await request(`/api/tickets/${id}/comments`, 'POST', { body });
    assert.equal(response.status, 201);
    assert.ok(response.data.created_at);
  }
  const detail = await request(`/api/tickets/${id}`);
  assert.deepEqual(detail.data.comments.map(comment => comment.body), ['Investigating the issue', 'Service verified']);
});
test('filters and pagination isolate matching tickets', async () => {
  await request('/api/tickets', 'POST', { title: 'Low priority issue', description: 'Synthetic data', priority: 'low' });
  const filtered = await request('/api/tickets?priority=high&status=open&limit=1&offset=0');
  assert.equal(filtered.status, 200);
  assert.equal(filtered.data.tickets.length, 1);
  assert.equal(filtered.data.tickets[0].id, id);
  assert.equal((await request('/api/tickets?status=resolved')).data.tickets.length, 0);
  assert.equal((await request('/api/tickets?limit=1&offset=1')).data.tickets.length, 1);
});
test('invalid input, IDs, pagination and enum values are rejected', async () => {
  for (const body of [null, [], {}, { title: ' ', description: 'valid' },
    { title: 'a'.repeat(161), description: 'valid' }, { title: 'valid', description: 'valid', priority: 'urgent' }]) {
    assert.equal((await request('/api/tickets', 'POST', body)).status, 400);
  }
  for (const path of ['/api/tickets/0', '/api/tickets/abc', '/api/tickets/2147483648',
    '/api/tickets?limit=0', '/api/tickets?offset=-1', '/api/tickets?status=bad',
    '/api/tickets?status=open&status=resolved', "/api/tickets?priority=';DROP%20TABLE%20tickets;--"]) {
    assert.equal((await request(path)).status, 400);
  }
  assert.equal((await request(`/api/tickets/${id}`, 'PATCH', {})).status, 400);
  assert.equal((await request(`/api/tickets/${id}`, 'PATCH', { title: 'unsupported' })).status, 400);
  assert.equal((await request(`/api/tickets/${id}/comments`, 'POST', { body: ' ' })).status, 400);
});
test('malformed/oversized JSON and missing resources fail explicitly', async () => {
  const malformed = await fetch(base + '/api/tickets', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{' });
  assert.equal(malformed.status, 400);
  assert.equal((await request('/api/tickets', 'POST', { title: 'a', description: 'x'.repeat(20000) })).status, 413);
  assert.equal((await request('/api/tickets/2000000')).status, 404);
  assert.equal((await request('/api/tickets/2000000', 'PATCH', { status: 'resolved' })).status, 404);
  assert.equal((await request('/api/tickets/2000000/comments', 'POST', { body: 'test' })).status, 404);
  assert.equal((await request('/unknown')).status, 404);
  assert.ok(logs.some(entry => entry.status === 400 && entry.requestId));
});
test('database constraints enforce statuses independently of API validation', async () => {
  await assert.rejects(pool.query("UPDATE tickets SET status = 'invalid' WHERE id = $1", [id]), { code: '23514' });
});
test('readiness fails when real database schema is unavailable while liveness stays up', async () => {
  await pool.query('ALTER TABLE tickets RENAME TO tickets_temporarily_unavailable');
  try {
    assert.equal((await request('/health/ready')).status, 503);
    assert.equal((await request('/health/live')).status, 200);
    const response = await request('/api/tickets');
    assert.equal(response.status, 500);
    assert.equal(response.data.error, 'Request failed.');
    assert.ok(logs.some(entry => entry.event === 'readiness_failed'));
  } finally {
    await pool.query('ALTER TABLE tickets_temporarily_unavailable RENAME TO tickets');
  }
  assert.equal((await request('/health/ready')).status, 200);
});
test('database connection failure returns unavailable and logs without exposing credentials', async () => {
  const failedPool = { query: async () => { const error = new Error('sensitive connection details'); error.code = 'ECONNREFUSED'; throw error; } };
  const instance = createApp(failedPool, { logger, defaultMetrics: false });
  const failedServer = instance.app.listen(0, '127.0.0.1');
  await once(failedServer, 'listening');
  try {
    const failedBase = `http://127.0.0.1:${failedServer.address().port}`;
    assert.equal((await fetch(failedBase + '/health/ready')).status, 503);
    assert.equal((await fetch(failedBase + '/health/live')).status, 200);
    const response = await fetch(failedBase + '/api/tickets');
    assert.equal(response.status, 503);
    assert.doesNotMatch(await response.text(), /sensitive/);
  } finally {
    await new Promise(resolve => failedServer.close(resolve));
    instance.registry.clear();
  }
});
test('metrics use route patterns rather than ticket IDs or query strings', async () => {
  await request(`/api/tickets/${id}`);
  await request('/unknown/arbitrary-path?secret=not-a-label');
  const response = await fetch(base + '/metrics');
  const metrics = await response.text();
  assert.equal(response.status, 200);
  assert.match(metrics, /http_requests_total\{[^}]*route="\/api\/tickets\/:id"/);
  assert.match(metrics, /http_request_duration_seconds_bucket/);
  assert.doesNotMatch(metrics, /arbitrary-path|secret=|route="\/api\/tickets\/\d+"/);
});
test('data and comments survive application restart', async () => {
  await stop();
  await start();
  const detail = await request(`/api/tickets/${id}`);
  assert.equal(detail.status, 200);
  assert.equal(detail.data.comments.length, 2);
  assert.equal(detail.data.assignee, 'Second engineer');
});
test('migration checksum guard rejects changed history without applying partial changes', async () => {
  const { rows } = await pool.query("SELECT checksum FROM schema_migrations WHERE name = '001-tickets.sql'");
  await pool.query("UPDATE schema_migrations SET checksum = 'changed' WHERE name = '001-tickets.sql'");
  try {
    await assert.rejects(migrate(pool), /Applied migration changed: 001-tickets.sql/);
    assert.equal((await request(`/api/tickets/${id}`)).status, 200);
  } finally {
    await pool.query("UPDATE schema_migrations SET checksum = $1 WHERE name = '001-tickets.sql'", [rows[0].checksum]);
  }
  await migrate(pool);
});
