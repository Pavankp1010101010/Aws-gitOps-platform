import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { once } from 'node:events';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const smokeScript = fileURLToPath(new URL('./smoke-test.mjs', import.meta.url));

function runSmoke(env, timeout = 15_000) {
  return new Promise(resolve => {
    const child = spawn(process.execPath, [smokeScript], { env });
    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => child.kill(), timeout);
    child.stdout.setEncoding('utf8').on('data', chunk => { stdout += chunk; });
    child.stderr.setEncoding('utf8').on('data', chunk => { stderr += chunk; });
    child.once('error', error => {
      clearTimeout(timer);
      resolve({ error, status: null, stdout, stderr });
    });
    child.once('close', status => {
      clearTimeout(timer);
      resolve({ status, stdout, stderr });
    });
  });
}

test('smoke test covers the application direct-JSON API contract', async () => {
  const ticket = {
    id: 731,
    title: '',
    status: 'open',
    priority: 'medium',
    assignee: null,
    comments: [],
  };
  const server = createServer(async (request, response) => {
    let body = '';
    for await (const chunk of request) body += chunk;
    const payload = body ? JSON.parse(body) : {};
    const send = (value, status = 200) => {
      response.writeHead(status, { 'Content-Type': 'application/json' });
      response.end(JSON.stringify(value));
    };

    if (request.url === '/health/ready') return send({ status: 'ready' });
    if (request.url === '/api/tickets' && request.method === 'POST') {
      Object.assign(ticket, payload);
      return send(ticket, 201);
    }
    if (request.url === `/api/tickets/${ticket.id}` && request.method === 'PATCH') {
      Object.assign(ticket, payload);
      return send(ticket);
    }
    if (request.url === `/api/tickets/${ticket.id}/comments` && request.method === 'POST') {
      ticket.comments.push({ body: payload.body });
      return send(ticket.comments.at(-1), 201);
    }
    if (request.url === `/api/tickets/${ticket.id}` && request.method === 'GET') {
      return send(ticket);
    }
    if (request.url.startsWith('/api/tickets?')) return send({ tickets: [ticket] });
    return send({ error: 'Route not found.' }, 404);
  });

  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try {
    const result = await runSmoke({
      ...process.env,
      SMOKE_BASE_URL: `http://127.0.0.1:${server.address().port}`,
    });
    assert.equal(result.error, undefined, result.error?.message);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /create, update, comment, filtered list, and retrieval/);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
});

test('smoke test rejects non-loopback targets before connecting', () => {
  const result = spawnSync(process.execPath, [smokeScript], {
    encoding: 'utf8',
    timeout: 5_000,
    env: { ...process.env, SMOKE_BASE_URL: 'https://example.com' },
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /must be an HTTP loopback URL/);
});
