import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const base = new URL(process.env.SMOKE_BASE_URL ?? 'http://127.0.0.1:3100');
if (!['127.0.0.1', 'localhost', '[::1]'].includes(base.hostname) ||
    base.protocol !== 'http:' || base.username || base.password ||
    base.pathname !== '/' || base.search || base.hash) {
  throw new Error('SMOKE_BASE_URL must be an HTTP loopback URL, such as the local SSM port-forward.');
}

async function request(path, method = 'GET', body) {
  const response = await fetch(new URL(path, base), {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(10_000),
  });
  assert.equal(response.ok, true, `${method} ${path} returned HTTP ${response.status}`);
  return response.json();
}

await request('/health/ready');

const marker = randomUUID();
const created = await request('/api/tickets', 'POST', {
  title: `Stage 06 synthetic smoke ${marker}`,
  description: 'Automated private deployment verification.',
});
assert.ok(Number.isInteger(created.data?.id), 'Ticket creation did not return an ID.');

const updated = await request(`/api/tickets/${created.data.id}`, 'PATCH', {
  status: 'in_progress',
  priority: 'high',
  assignee: 'stage06-smoke',
});
assert.equal(updated.data.status, 'in_progress');
assert.equal(updated.data.priority, 'high');

const comment = `Stage 06 synthetic smoke ${marker}`;
await request(`/api/tickets/${created.data.id}/comments`, 'POST', { body: comment });

const detail = await request(`/api/tickets/${created.data.id}`);
assert.equal(detail.data.title, `Stage 06 synthetic smoke ${marker}`);
assert.equal(detail.data.assignee, 'stage06-smoke');
assert.ok(detail.data.comments.some(item => item.body === comment), 'Created comment was not returned.');

const query = new URLSearchParams({ status: 'in_progress', priority: 'high', limit: '100' });
const list = await request(`/api/tickets?${query}`);
assert.ok(list.data.tickets.some(ticket => ticket.id === created.data.id), 'Updated ticket was not returned by the filtered list.');

console.log(`Smoke test passed for ticket ${created.data.id}: create, update, comment, filtered list, and retrieval.`);
