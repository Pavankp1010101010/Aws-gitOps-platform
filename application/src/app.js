import express from 'express';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import { Registry, Counter, Histogram, collectDefaultMetrics } from '@prometheus-io/client';

const priorities = ['low', 'medium', 'high'];
const statuses = ['open', 'in_progress', 'resolved'];

class InputError extends Error {}

function object(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new InputError('A JSON object is required.');
  return value;
}

function text(value, field, max, empty = false) {
  if (typeof value !== 'string' || value.trim().length > max || (!empty && !value.trim())) {
    throw new InputError(`${field} must be ${empty ? '0' : '1'}-${max} characters.`);
  }
  return value.trim();
}

function choice(value, field, allowed) {
  if (!allowed.includes(value)) throw new InputError(`${field} must be one of: ${allowed.join(', ')}.`);
  return value;
}

function ticketId(value) {
  if (!/^[1-9]\d*$/.test(value) || Number(value) > 2147483647) throw new InputError('Invalid ticket ID.');
  return Number(value);
}

export function createApp(pool, { version = 'local', logger = console, defaultMetrics = true } = {}) {
  const app = express();
  app.disable('x-powered-by');
  const registry = new Registry();
  if (defaultMetrics) collectDefaultMetrics({ register: registry });
  const requests = new Counter({
    name: 'http_requests_total', help: 'Completed HTTP requests.',
    labelNames: ['method', 'route', 'status'], registers: [registry],
  });
  const duration = new Histogram({
    name: 'http_request_duration_seconds', help: 'HTTP request latency in seconds.',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5], registers: [registry],
  });
  app.use((req, res, next) => {
    req.requestId = randomUUID();
    res.setHeader('X-Request-ID', req.requestId);
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Security-Policy', "default-src 'self'; frame-ancestors 'none'; base-uri 'none'");
    const start = process.hrtime.bigint();
    res.on('finish', () => {
      const method = ['GET', 'POST', 'PATCH', 'HEAD', 'OPTIONS'].includes(req.method) ? req.method : 'OTHER';
      const route = req.route?.path ?? (req.path === '/' ? '/' : 'unmatched');
      const labels = { method, route, status: String(res.statusCode) };
      requests.inc(labels);
      duration.observe(labels, Number(process.hrtime.bigint() - start) / 1e9);
    });
    next();
  });
  app.use(express.json({ limit: '16kb' }));
  app.get('/health/live', (req, res) => res.json({ status: 'ok' }));
  app.get('/health/ready', async (req, res) => {
    try {
      await pool.query('SELECT 1 FROM tickets LIMIT 1');
      res.json({ status: 'ready' });
    } catch (error) {
      logger.error(JSON.stringify({ event: 'readiness_failed', requestId: req.requestId, code: error.code ?? 'DATABASE_ERROR' }));
      res.status(503).json({ error: 'Database is unavailable or migrations are missing.', requestId: req.requestId });
    }
  });
  app.get('/api/version', (req, res) => res.json({ version }));
  app.get('/metrics', async (req, res) => {
    res.type(registry.contentType).send(await registry.metrics());
  });
  app.get('/api/tickets', async (req, res) => {
    const values = [];
    const where = [];
    for (const [field, allowed] of [['status', statuses], ['priority', priorities]]) {
      if (req.query[field] !== undefined) {
        values.push(choice(req.query[field], field, allowed));
        where.push(`${field} = $${values.length}`);
      }
    }
    const limit = req.query.limit ?? '50';
    const offset = req.query.offset ?? '0';
    if (typeof limit !== 'string' || !/^\d+$/.test(limit) || +limit < 1 || +limit > 100 ||
        typeof offset !== 'string' || !/^\d+$/.test(offset) || +offset > 1000000) {
      throw new InputError('limit must be 1-100 and offset 0-1000000.');
    }
    values.push(+limit, +offset);
    const result = await pool.query(`SELECT * FROM tickets ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
      ORDER BY id DESC LIMIT $${values.length - 1} OFFSET $${values.length}`, values);
    res.json({ tickets: result.rows, limit: +limit, offset: +offset });
  });
  app.post('/api/tickets', async (req, res) => {
    const body = object(req.body);
    const values = [
      text(body.title, 'title', 160), text(body.description, 'description', 5000),
      choice(body.priority ?? 'medium', 'priority', priorities),
      text(body.assignee ?? '', 'assignee', 100, true),
    ];
    const { rows } = await pool.query(`INSERT INTO tickets (title, description, priority, assignee)
      VALUES ($1, $2, $3, $4) RETURNING *`, values);
    res.status(201).location(`/api/tickets/${rows[0].id}`).json(rows[0]);
  });
  app.get('/api/tickets/:id', async (req, res) => {
    const id = ticketId(req.params.id);
    const { rows } = await pool.query('SELECT * FROM tickets WHERE id = $1', [id]);
    if (!rows.length) return res.status(404).json({ error: 'Ticket not found.' });
    const comments = await pool.query('SELECT * FROM comments WHERE ticket_id = $1 ORDER BY id', [id]);
    res.json({ ...rows[0], comments: comments.rows });
  });
  app.patch('/api/tickets/:id', async (req, res) => {
    const id = ticketId(req.params.id);
    const body = object(req.body);
    const allowed = ['status', 'priority', 'assignee'];
    const keys = Object.keys(body);
    if (!keys.length || keys.some(key => !allowed.includes(key))) throw new InputError('Update status, priority, or assignee only.');
    const values = keys.map(key => key === 'assignee' ? text(body[key], key, 100, true) :
      choice(body[key], key, key === 'status' ? statuses : priorities));
    const assignments = keys.map((key, index) => `${key} = $${index + 1}`);
    values.push(id);
    const { rows } = await pool.query(`UPDATE tickets SET ${assignments.join(', ')}, updated_at = clock_timestamp()
      WHERE id = $${values.length} RETURNING *`, values);
    if (!rows.length) return res.status(404).json({ error: 'Ticket not found.' });
    res.json(rows[0]);
  });
  app.post('/api/tickets/:id/comments', async (req, res) => {
    const id = ticketId(req.params.id);
    const body = text(object(req.body).body, 'body', 2000);
    const { rows } = await pool.query(`WITH updated AS (
      UPDATE tickets SET updated_at = clock_timestamp() WHERE id = $1 RETURNING id
    ) INSERT INTO comments (ticket_id, body) SELECT id, $2 FROM updated RETURNING *`, [id, body]);
    if (!rows.length) return res.status(404).json({ error: 'Ticket not found.' });
    res.status(201).json(rows[0]);
  });
  app.use(express.static(fileURLToPath(new URL('../public/', import.meta.url))));
  app.use((req, res) => res.status(404).json({ error: 'Route not found.' }));
  app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    let status = 500;
    let message = 'Request failed.';
    if (error instanceof InputError || error.type === 'entity.parse.failed') {
      status = 400;
      message = error instanceof InputError ? error.message : 'Malformed JSON.';
    } else if (error.type === 'entity.too.large') {
      status = 413;
      message = 'Request body is too large.';
    } else if (error.code?.startsWith('08') || ['ECONNREFUSED', '57P01', '57P02', '57P03', '53300'].includes(error.code)) {
      status = 503;
      message = 'Database is unavailable.';
    }
    logger.error(JSON.stringify({ event: 'request_failed', requestId: req.requestId, status, code: error.code ?? error.type ?? error.name }));
    res.status(status).json({ error: message, requestId: req.requestId });
  });
  return { app, registry };
}
