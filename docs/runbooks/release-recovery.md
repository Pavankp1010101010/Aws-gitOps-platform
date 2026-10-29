# Runbook: failed application release

[Project overview](../../README.md) | [Architecture](../03-architecture-and-flows.md)

Status: planned procedure. Resource names, commands, and links must be filled in and tested after implementation.

## Preconditions

- An approved known-good image digest/configuration is identifiable.
- Operator has Git, restricted cluster access, and dashboard access.
- Database migration compatibility has been checked.
- No unrelated infrastructure incident explains the symptoms.

## Detection and diagnosis

1. Record failure time, symptoms, and deployed image digest.
2. Check Argo CD sync/health and Kubernetes rollout status.
3. Inspect pod events, readiness, restarts, and scoped logs.
4. Compare request errors and latency against the previous healthy period.
5. Determine whether reverting the application is safe for the current schema.

## Recovery

1. Revert the deployment configuration change through the approved Git process.
2. Do not rely on an imperative Kubernetes rollback: Argo CD may overwrite changes not reflected in Git.
3. Confirm Argo CD reconciles the intended known-good digest.
4. Run the application smoke test, including a safe database operation.
5. Verify replicas, error rate, latency, and resolved notifications.
6. Record recovery time and any remaining impact.

## Stop conditions

- Schema or data changes make the previous application incompatible.
- The database is unavailable or data corruption is suspected.
- The single EC2 host is unavailable.

In these cases, follow the [database and host recovery procedure](database-and-host-recovery.md) or an explicitly reviewed forward-fix plan. Do not blindly reverse database migrations.

## After recovery

Write a short incident report: impact, timeline, cause, action taken, measured recovery time, and prevention work.
