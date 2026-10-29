# Stage 02 verification results

[Project overview](../README.md) | [Stage 02](../stages/02-local-application.md)

Date: 2026-10-29. Scope: local application only; no AWS, Kubernetes, CI pipeline, GitHub upload, or production-readiness claim.

## Implemented

- Node.js 24/Express web application and JSON API.
- PostgreSQL tickets, comments, constraints, persistent storage, versioned migrations.
- Input validation, parameterized queries, pagination, explicit failures, safe browser text rendering.
- Liveness, database/schema readiness, version information, Prometheus-format metrics.
- Application signal shutdown handlers with a bounded shutdown deadline.
- Dedicated local development/test databases, project-owned Compose resources, random ignored credentials.

## Versions

| Component | Version |
|---|---|
| Node.js | 24.16.0 |
| npm | 11.13.0 |
| Express | 5.3.0 |
| pg | 8.23.1 |
| Metrics client | @prometheus-io/client 0.16.1 |
| PostgreSQL | 17.11, Alpine image pinned by digest in Compose |

`prom-client` was initially resolved but emitted a deprecation warning pointing to `@prometheus-io/client`. It was replaced before final validation. The lockfile records the selected dependency graph.

## Checks and observations

| Check | Result |
|---|---|
| Syntax checks | Passed |
| Automated integration checks | 13 passed, 0 failed |
| Migration reapplication | Passed; no duplicate tables or changes |
| Browser ticket creation | Passed with synthetic title, description, high priority, and assignee |
| Browser lifecycle | Open -> In Progress -> Resolved -> Open passed |
| Browser comments | Comment displayed and retained after page reload |
| Browser filters | Resolved excluded reopened ticket; Open/High included it |
| Application restart persistence | Integration test retained ticket and comments across HTTP app recreation |
| Actual database stop | Liveness 200; readiness 503; ticket API 503 |
| Actual database restart | Readiness 200; browser-created ticket and comment retained |
| Metrics | Counter/histogram present; ticket IDs and arbitrary paths are not route labels |

The database failure test stopped only `support-ticket-dev`'s database. No existing TimesTen resource was touched.

## Test isolation

Tests require a separate `ticket_test` database on loopback port 55432 and reject the development URL. They truncate only tickets/comments in the dedicated test database, not development data. API tests bind temporary loopback ports; browser verification used the approved port 3100.

## Boundaries

- Pod replacement persistence awaits Stage 06 (APP-02).
- CI gates, vulnerability-image scans, Kubernetes deployment, load targets, notifications, and disaster recovery remain untested.
- npm's zero-vulnerability report is only the install-time package advisory result, not a security guarantee.
- Local PostgreSQL uses a development superuser; production database privileges require a separate least-privilege design.
- No auth is implemented. Services must remain private/loopback with synthetic data.
- The database volume and ignored `.env` are intentionally retained. The generated password is not present in documentation or Git.

## Final execution record

- Final `npm.cmd run check`: passed.
- Final `npm.cmd test`: 13 checks passed, 0 failed, 0 skipped.
- Standalone server readiness: 200. Its registered SIGTERM callback was invoked with `process.emit('SIGTERM')`; shutdown logged and the process exited successfully. This verifies handler behavior, not Windows OS signal delivery.
- Project PostgreSQL container stopped after verification.
- No listeners remained on application port 3100 or database port 55432.
- Project database volume, stopped container/network, dependency installation, image cache, and ignored `.env` retained intentionally.
- Development data contains one synthetic browser-verification ticket and comment; automated test data is in the separate test database.
- No local Git commit/push or shared-tool/global configuration change performed.
