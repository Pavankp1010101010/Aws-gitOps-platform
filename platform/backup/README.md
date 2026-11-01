# PostgreSQL backups

[Platform overview](../README.md) | [Security and access](../../docs/05-security-and-access.md) | [Recovery runbooks](../../docs/runbooks/database-and-host-recovery.md)

The host runs PostgreSQL backups as a root-owned systemd timer rather than in a Kubernetes pod. This keeps EC2 instance-role credentials out of application and backup containers.

The service waits for the private PostgreSQL pod, creates a PostgreSQL custom-format dump through the pod's local socket, validates the archive with `pg_restore --list`, uploads it to the Terraform-managed private bucket with AES256 server-side encryption, and verifies the uploaded size and encryption. Temporary dump files are mode 0600 under `/var/lib/agtp-postgres-backup/tmp` and are removed after the attempt. The host writes last-success/last-attempt metrics for node exporter.

The timer runs daily at 02:15 UTC with up to 15 minutes of jitter and catches up after downtime. The S3 lifecycle policy expires current `postgres/automated/` objects after seven days and removes noncurrent versions one day after expiration. Other prefixes are not covered by this policy.

## Install and test

The bucket name is available from `terraform output -raw backup_bucket_name`. From Windows, use `deploy-postgres-backup.ps1` with the instance ID and bucket name. It verifies the active AWS account and running project-host tag, packages only the checked-in installer files, stages them through Systems Manager, and invokes the installer as root. The installer validates the instance role and Kubernetes API and does not print credentials.

Run one controlled backup with:

```bash
systemctl start agtp-postgres-backup.service
systemctl --no-pager --full status agtp-postgres-backup.service
journalctl --no-pager -u agtp-postgres-backup.service -n 30
```

Verify the latest object timestamp, nonzero `ContentLength`, `AES256` server-side encryption, and `agtp_postgres_backup_last_success_timestamp_seconds` in Prometheus before relying on the backup path. A systemd failure is surfaced through textfile metrics and Alertmanager rules; the overdue alert fires when no successful backup is recorded within 24 hours.

## Restore safety

Restore into a separate isolated database using synthetic data. Never overwrite the active database for a drill. The configured retention period is not a substitute for testing that an off-host backup can be restored.
