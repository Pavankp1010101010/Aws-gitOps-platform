# Runbook: database and host recovery

[Project overview](../../README.md) | [Validation](../08-validation-and-evidence.md)

Status: backup implementation is being validated. No isolated restore or host rebuild has been performed.

## Database restore prerequisites

- A completed, readable backup exists outside the EC2 host.
- Backup timestamp, PostgreSQL version, format, and integrity metadata are known.
- The host-side systemd timer runs daily at 02:15 UTC with up to 15 minutes of jitter; S3 lifecycle expires current PostgreSQL backup objects after seven days.
- Backup failures and a missing/overdue success timestamp are surfaced through node-exporter textfile metrics and Alertmanager.
- Restore identity has necessary S3 and decryption permissions.
- A separate isolated restore database and storage are available.
- Credentials can be re-initialized securely.

## Restore drill

1. Record restore start time and selected backup recovery point.
2. Download/access the selected backup securely.
3. Verify its integrity and compatibility.
4. Restore to a new isolated database, never over the active database for a drill.
5. Verify schema, expected ticket records, comments, and representative queries.
6. Point an isolated application instance to the restored database.
7. Create a synthetic ticket, add a comment, and verify status updates and reopening.
8. Record elapsed time, verified data, and potential data-loss window.
9. Remove only the explicitly identified temporary drill resources.

For a real incident, approve and document application cutover separately. Avoid allowing writes to old and restored databases simultaneously.

## Host rebuild

1. Determine whether the original host/data can be recovered without replacement.
2. Preserve relevant evidence; do not destroy the only data copy.
3. Review Terraform state and the intended replacement plan.
4. Recreate compute and run the pinned bootstrap process.
5. Re-initialize secrets and validate ECR/Git access.
6. Let Argo CD recreate platform and application configuration.
7. Follow the isolated database restore and validation steps above.
8. Perform a controlled cutover and verify ingress/DNS if the address changed.
9. Verify dashboards, notifications, scheduled backups, and host alarms.
10. Record total recovery time and any manual steps.

## Limitations

- Single-host failure causes downtime.
- A local persistent volume does not survive every host/disk replacement scenario.
- Git does not contain application data or bootstrap secrets.
- Scheduled backups permit loss of changes after the selected recovery point.
- Monitoring history may be lost with the host.
