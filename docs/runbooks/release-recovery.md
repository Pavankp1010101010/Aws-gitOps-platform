# Runbook: failed application release

[Project overview](../../README.md) | [Architecture](../03-architecture-and-flows.md) | [Delivery guide](../../platform/delivery/README.md)

## Preconditions

- A known-good image digest and matching Git configuration are identifiable.
- The operator has access to Git and the private cluster through the approved management path.
- Database migration compatibility has been reviewed.
- No unrelated infrastructure incident explains the symptoms.

## Detect and diagnose

1. Record the failure time, symptoms, and deployed image digest.
2. Check Argo CD sync/health and Kubernetes rollout status.
3. Inspect pod events, readiness, restarts, and scoped logs.
4. Compare request errors and latency against a previous healthy period.
5. Determine whether reverting the application is safe for the current database schema.

## Recover

1. Revert the deployment configuration change through the reviewed Git process.
2. Do not rely on an imperative Kubernetes rollback; Argo CD may overwrite changes not present in Git.
3. Confirm Argo CD reconciles the intended known-good digest.
4. Run the application smoke test, including a safe database operation.
5. Verify readiness, request behavior, metrics, and resolved notifications.
6. Record recovery time and any remaining impact.

If an Argo operation remains stuck, confirm the desired revision and image digest, then use the supported Argo CD operation-termination command. Reconcile the current Git revision and verify the migration Job, application readiness, and database state. Do not directly patch the Application operation field or blindly reverse database migrations.

## Stop conditions

Stop and obtain an explicitly reviewed forward-fix or recovery plan if schema/data changes make the previous image incompatible, database corruption is suspected, or the EC2 host is unavailable. Follow the [database and host recovery runbook](database-and-host-recovery.md) as appropriate.

## After recovery

Write a concise incident report covering impact, timeline, cause, action taken, measured recovery time, and prevention work.
