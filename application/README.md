# Support Ticket Tracker

[Project overview](../README.md) | [Stage 02 results](../docs/10-stage02-results.md) | [Stage 03 results/blockers](../docs/11-stage03-results.md)

A small private-demo application that replaces scattered support messages with a persistent ticket list, priority/status tracking, assignee labels, and timestamped comments.

## Features

- Create, list, and view tickets.
- Priorities: low, medium, high.
- Statuses: Open, In Progress, Resolved; resolved tickets can be reopened.
- Optional assignee label; it is not an authenticated user identity.
- Status/priority filters and pagination.
- PostgreSQL persistence, versioned migrations, and automated integration tests.
- Health/readiness endpoints, version information, and Prometheus metrics.

No email ingestion, attachments, hard deletion, SLA engine, authentication, or multi-tenancy. Use synthetic data only. Do not expose this unauthenticated application to real users or the public internet.

## Stack and layout

Node.js 24.16.0, Express 5.3.0, pg 8.23.1, @prometheus-io/client 0.16.1, PostgreSQL 17.11. PostgreSQL's container digest is pinned in Compose; npm's lockfile pins application dependencies.

```text
application/
|-- src/               API, database access, server lifecycle, metrics
|-- public/            Browser HTML, CSS, JavaScript
|-- migrations/        Ordered immutable SQL migrations
|-- scripts/           Local environment setup and migration runner
|-- database/          First-volume initialization of dedicated test database
|-- test/              API and real PostgreSQL integration checks
|-- Dockerfile         Non-root, digest-pinned application image
|-- .dockerignore      Allowlisted build context
|-- compose.yaml       Local app/database and explicit migration service
|-- .env.example       Sanitized configuration example
|-- .nvmrc             Project Node baseline
|-- package.json
`-- package-lock.json
```

Container startup is implemented in Stage 03. The image passed local and hosted HIGH/CRITICAL scans after pinning OpenSSL runtime libraries to 3.5.9-r0. Required-check failure/recovery was verified in Stage 03; see the [validation evidence](../docs/11-stage03-results.md). Terraform, Kubernetes, monitoring deployment, and GitOps implementation belong in the separate [platform directory](../platform/README.md).

## Prerequisites and isolation

- Confirmed Node.js 24 runtime and npm.
- Docker Desktop permitted for your use, Linux engine available.
- Work only from this application directory.
- Check that loopback ports 3100 and 55432 and Compose project name `support-ticket-dev` are not occupied by another workload.
- Obtain approval before starting services or changing shared settings. Do not stop or prune unrelated Docker resources.

No global npm tools or shared runtime/configuration changes are required.

## Windows quick start

Run in PowerShell. These commands start project-specific local services; they do not provision AWS or upload anything.

```powershell
$repoRoot = (git rev-parse --show-toplevel)
Set-Location -LiteralPath (Join-Path $repoRoot 'application')
npm.cmd ci --ignore-scripts
npm.cmd run setup:local
docker --context desktop-linux compose up -d --wait db
npm.cmd run migrate
npm.cmd run check
npm.cmd test
npm.cmd start
```

Run each command only after the previous one succeeds. On subsequent runs, skip `setup:local` if `.env` already exists. It intentionally refuses to overwrite credentials.

Open `http://127.0.0.1:3100`. Keep the app's terminal open; use Ctrl+C to stop. Use a second PowerShell terminal in the same directory for checks.

The `.env` setup generates a random local-only password and separate URLs for `ticket_dev` and `ticket_test`. Keep that file private. Git ignore rules are not encryption or Windows ACL hardening.

### Stop after use

```powershell
# Stop the application with Ctrl+C in its terminal first.
docker --context desktop-linux compose stop db
```

This retains the project container/network and named volume so data survives. Do not run `down -v`, delete the volume, or reset credentials without an explicit data-deletion decision. This project never needs a global Docker prune.

## Containerized local startup (Stage 03)

Use this instead of `npm.cmd start`, not alongside it: both use loopback port 3100. Generate `.env` first only if it does not exist.

```powershell
$repoRoot = (git rev-parse --show-toplevel)
Set-Location -LiteralPath (Join-Path $repoRoot 'application')
docker --context desktop-linux compose build app
docker --context desktop-linux compose up -d --wait db
docker --context desktop-linux compose run --rm --no-deps migrate
docker --context desktop-linux compose up -d --wait app
```

Run each command only after the previous succeeds. Open `http://127.0.0.1:3100`. This is a private local demo, not approval to deploy the image publicly.

Migrations are explicit: the application does not mutate schema automatically. The `migrate` service uses the same image and database connection but is not a long-lived application service. Rebuild before running it after source/migration changes.

```powershell
docker --context desktop-linux compose stop app db
```

The local app/database use the existing project-owned volume and private Compose network. The application listens on all interfaces inside its container, but only loopback is published on the host. Container runtime credentials are inspectable by local Docker administrators; do not use production credentials.

The runtime deliberately has no npm. Run `node scripts/migrate.js` for container migration tasks rather than `npm run migrate`. Host-side npm commands still work. Base-image digest and application dependencies are pinned; network registry availability and future security updates still require maintenance.

## Configuration

| Variable | Purpose |
|---|---|
| DATABASE_URL | Development application database connection |
| TEST_DATABASE_URL | Dedicated test database; never use development/real data |
| POSTGRES_PASSWORD | Local database initialization; generated by setup |
| HOST | Defaults to 127.0.0.1; keep loopback for this private demo |
| PORT | Defaults to 3100 |
| APP_VERSION | Source/release identifier; `local` for this milestone |

Changing the password in `.env` does not update an already initialized PostgreSQL volume. Perform a deliberate credential rotation rather than deleting data to fix a mismatch.

## Private Kubernetes deployment (Stage 06)

The support-ticket application and PostgreSQL are deployed in the `support-ticket` namespace through Argo CD. Both Services are `ClusterIP`; no public ingress or load balancer is configured. Do not expose this unauthenticated demo to the public internet.

After a successful `Application CI` run for a push to `main`, the release workflow builds and scans the tested image, publishes it to ECR, and proposes its immutable digest in a GitOps pull request. CI does not apply application resources; Argo CD deploys the digest only after the GitOps change is reviewed and merged. The application database password is provisioned out of band and is not stored in Git.

The repository must allow GitHub Actions to create pull requests under **Settings > Actions > General > Workflow permissions**. If an image-release run pushes its `deploy/application-*` branch but cannot create the PR, enable that setting and rerun Application CI for the source commit to retry PR creation.

For private API smoke checks, use an SSM-mediated loopback port-forward as described in the [platform test guide](../platform/tests/README.md).

## API

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/tickets` | Title/description required; optional priority/assignee |
| GET | `/api/tickets` | Filter by status/priority; limit 1-100 (default 50), offset 0-1000000 |
| GET | `/api/tickets/:id` | Ticket with chronological comments |
| PATCH | `/api/tickets/:id` | Update status, priority, or assignee |
| POST | `/api/tickets/:id/comments` | Add nonempty `body` |
| GET | `/health/live` | Process responds; does not depend on database |
| GET | `/health/ready` | Database reachable and tickets schema usable; 503 otherwise |
| GET | `/api/version` | Configured application version |
| GET | `/metrics` | Prometheus text-format metrics |

API status values are `open`, `in_progress`, and `resolved`. Titles allow 160 characters, descriptions 5000, assignees 100, comments 2000. Text is trimmed. Lists are newest-first. There is intentionally no ticket deletion endpoint.

Invalid input returns 400, oversized bodies 413, missing resources 404, recognized database connectivity failures 503, and unexpected failures 500. Errors include a request identifier where handled centrally; structured server errors omit credentials and submitted ticket text.

## Tests

`npm.cmd test` uses real PostgreSQL on loopback port 55432 and only permits database name `ticket_test`, distinct from `DATABASE_URL`. It migrates and truncates that dedicated test database, then checks workflows, constraints, filters, invalid input, errors, health, metrics, persistence, and migration history.

Do not point these tests at shared/production data. Do not run two copies concurrently against the same test database.

## Migrations

`npm.cmd run migrate` applies ordered SQL files in a transaction with an advisory lock and stored checksums. Re-running is safe; modifying an already applied migration fails explicitly. Add new migrations rather than rewriting history.

Migration 002 adds an index without changing the existing API/schema contract: a simple backward-compatible change. Reverting an application image does not undo schema changes; there is no automatic database down-migration.

## Metrics

HTTP request count and duration histogram use bounded method/route/status labels. Route templates, not raw ticket IDs or query strings, are recorded. Node process metrics are exposed too. Prometheus/Grafana deployment remains a later stage.

## Troubleshooting

- **Port occupied:** do not kill its owner. Inspect ownership and request approval for a different project port/configuration.
- **Database unhealthy:** inspect only this project's `docker compose logs db`; keep logs private.
- **Readiness 503:** confirm database health, credentials, and successful migrations. Liveness may remain 200 correctly.
- **Test database missing:** init scripts run only for a new volume. Inspect the project database and explicitly create the dedicated test database if needed; do not delete the development volume.
- **PowerShell npm policy:** use `npm.cmd`; do not change global execution policy.
- **Dependency failure:** use the lockfile with `npm.cmd ci --ignore-scripts`; do not install globally.
- **Local startup fails:** check the structured startup error and port; do not change an unrelated service.

## Verification

See the [Stage 02 results](../docs/10-stage02-results.md) and [Stage 03 results/blockers](../docs/11-stage03-results.md). Health/metrics endpoints alone do not prove cloud reliability, backups, high availability, or recovery targets.
