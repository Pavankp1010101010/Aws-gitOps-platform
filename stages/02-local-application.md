# Stage 02 - Local Support Ticket Tracker

[Stage index](README.md) | [Previous](01-decisions-and-workstation.md) | [Next](03-containers-and-ci.md)

Status: Complete. Local implementation, automated checks, browser workflow, database outage/recovery, and cleanup verified on 2026-10-29.

## Entry conditions

Stage 01 is complete and the application stack is confirmed.

## Goal

Build a useful, locally testable ticket application before introducing cloud deployment.

## Work checklist

- [x] Implement ticket creation, listing, detail view, and priority/status filters.
- [x] Implement Open, In Progress, Resolved, and reopen behavior.
- [x] Add optional assignee labels and timestamped comments.
- [x] Add PostgreSQL schema, migrations, constraints, and parameterized queries.
- [x] Implement browser UI, validation, explicit API errors, and graceful shutdown.
- [x] Add liveness, readiness, version information, and Prometheus metrics.
- [x] Provide local PostgreSQL startup with persistent storage and non-secret configuration examples.
- [x] Add automated tests with isolated test data.
- [x] Document local setup, test commands, configuration, and troubleshooting.

## Work location

[Application directory](../application/README.md). Keep cloud and Kubernetes configuration out of this implementation.

## Exit checks

- [x] Ticket lifecycle, comments, assignment labels, and filters work in browser/API.
- [x] Records survive application restart.
- [x] Invalid input and database failure have explicit, tested behavior.
- [x] Readiness reflects required database availability without causing inappropriate liveness restarts.
- [x] Metrics expose bounded request labels and latency histograms.
- [x] Automated tests pass; no passwords are committed.

## Evidence and retained resources

See [Stage 02 results](../docs/10-stage02-results.md) for 13 automated checks, browser verification, actual database interruption, migration/shutdown checks, and limits.

User approved application-local dependencies, project-owned database container/volume, loopback ports 3100/55432, and dedicated test database resets. Temporary processes are stopped; the development volume and ignored credentials are retained. The next startup requires explicitly starting the database and application again.

Record APP-01, APP-03, and APP-04 local results in the [validation plan](../docs/08-validation-and-evidence.md). APP-02 pod persistence remains for Stage 06.

## AWS and approval gate

No AWS provisioning. Review the working application before Stage 03.
