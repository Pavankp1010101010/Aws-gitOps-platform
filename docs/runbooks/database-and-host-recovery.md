# Runbook: database and host recovery

[Project overview](../../README.md) | [Backup guide](../../platform/backup/README.md) | [Architecture](../03-architecture-and-flows.md)

Use synthetic data for recovery exercises. Verify the AWS account, region, instance, bucket, and database before running operational commands. Destructive recovery or infrastructure changes require a fresh reviewed plan and explicit approval.

## Database restore prerequisites

- A completed, readable backup exists outside the EC2 host.
- The backup timestamp, PostgreSQL version, format, and integrity metadata are known.
- The restore identity has the required access to the selected backup.
- A separate isolated restore database and storage are available.
- Application credentials can be initialized securely and are not retrieved from Git.

## Restore drill

1. Record the restore start time and selected backup recovery point.
2. Access the selected backup securely and verify its integrity and compatibility.
3. Restore it to a new isolated database; never overwrite the active database during a drill.
4. Verify schema migrations, expected ticket records, comments, and representative queries.
5. Point an isolated application instance to the restored database.
6. Create a synthetic ticket, add a comment, and verify status updates and reopening.
7. Record elapsed time, verified data, and the potential data-loss window.
8. Remove only the explicitly identified temporary drill resources.

For a real incident, approve and document application cutover separately. Avoid allowing writes to old and restored databases simultaneously.

## Host rebuild

1. Determine whether the original host and data can be recovered without replacement.
2. Preserve any required data and evidence; do not destroy the only data copy.
3. Review Terraform state and a fresh plan for the exact replacement.
4. Recreate compute and run the pinned bootstrap process.
5. Re-initialize secrets securely and validate ECR and Git access.
6. Let Argo CD recreate platform and application configuration.
7. Restore the selected backup into the isolated PostgreSQL workload.
8. Perform a controlled cutover and verify application readiness.
9. Verify dashboards, notifications, scheduled backups, and host alarms.
10. Record total recovery time and manual steps.

## Limitations

- A single-host failure causes downtime.
- A local persistent volume does not survive every host/disk replacement scenario.
- Git does not contain application data or bootstrap secrets.
- Scheduled backups permit loss of changes after the selected recovery point.
- Monitoring history may be lost with the host.
