# Runbook: database and host recovery

[Project overview](../../README.md) | [Validation](../08-validation-and-evidence.md)

Status: scheduled backup, scoped retention, backup alerts, and an isolated restore have been verified. A destructive host rebuild has not been performed and still requires explicit approval.

## Database restore prerequisites

- A completed, readable backup exists outside the EC2 host. The latest verified object was `postgres/automated/20261031T110153Z.dump` (8,702 bytes, AES256); the earlier `postgres/automated/20261031T090505Z.dump` was also restored successfully.
- Backup timestamp, PostgreSQL version, format, and integrity metadata are known.
- The host-side systemd timer runs daily at 02:15 UTC with up to 15 minutes of jitter; S3 lifecycle expires current PostgreSQL backup objects after seven days.
- Backup failures and a missing/overdue success timestamp are surfaced through node-exporter textfile metrics and Alertmanager.
- Restore identity has necessary S3 and decryption permissions.
- A separate isolated restore database and storage are available. The latest backup restored 104 tickets and 3 comments; the earlier restore verified 4 tickets, 3 comments, and 2 migrations. Temporary databases and host dumps were removed afterward.
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

## Verified backup and restore evidence - 2026-10-31

- The host systemd timer is enabled and active. The successful backup attempt was recorded in the textfile metrics.
- Seven-day current-object expiry and one-day noncurrent-version cleanup apply only to `postgres/automated/`; the pre-existing legacy prefix was excluded.
- The isolated restore command completed in one second according to SSM. This measures the command execution, not a full host rebuild or application cutover.
- At 10:35:25Z, the latest verified recovery point (09:05:07Z) was 90.3 minutes old. No data-loss incident occurred; this is the observed potential recovery-point age at that check.
- At 11:05:25Z, the latest backup was restored into an isolated database and matched the live database's 104-ticket/3-comment counts. The temporary database was removed. At 11:09:47Z, the backup recovery point was 7m54s old.
- At 11:05:53Z, the PostgreSQL pod was replaced; readiness returned at 11:06:01Z. Ticket and comment counts remained 104 and 3, and the application readiness endpoint returned HTTP 200.
- Backup-failed and backup-overdue alerts fired and resolved in Prometheus/Alertmanager, and the operator confirmed receipt.

## Failed-release recovery evidence - 2026-10-31

The test revision referenced a nonexistent image digest. The migration hook pod entered `ImagePullBackOff` and never ran; the application Deployment remained ready on the known-good digest and PostgreSQL was not changed. After the revert PR merged, the stale Argo operation and hook required operator cleanup followed by a sync of current `main`. Argo completed the reverted revision at 10:32:03Z; readiness returned HTTP 200 and the database still contained 104 tickets. Argo completed 11m30s after revert merge and 14m23s after revert commit creation, exceeding the 10-minute operational recovery window; no API outage was observed and service restoration was not needed.

For a future stuck operation, first confirm the current desired revision and image digest, then use the supported Argo CD `app terminate-op` command rather than directly patching the Application operation field. Inspect the migration Job and pod before removing only that failed hook; never delete or restart the application database as part of this cleanup. Re-sync the current branch and verify the Argo operation, application readiness, and database state.

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
