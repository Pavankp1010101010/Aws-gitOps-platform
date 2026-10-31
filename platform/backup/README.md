# PostgreSQL backups

Status: the host timer, S3 upload, scoped seven-day retention, isolated restore, and backup alert path have been verified. A destructive host rebuild remains unperformed.

The host runs the backup as a root-owned systemd timer, not as a Kubernetes pod. This keeps EC2 instance-role credentials out of application and backup containers while retaining the existing role's S3 access scoped to `postgres/*`.

The service waits for the private PostgreSQL pod, creates a PostgreSQL custom-format dump through the pod's local socket, validates the archive with `pg_restore --list`, uploads it to the Terraform-managed private bucket with AES256 server-side encryption, and verifies the uploaded size and encryption. Temporary dump files are mode 0600 under `/var/lib/agtp-postgres-backup/tmp` and are removed after the attempt. The host writes last-success/last-attempt metrics for node exporter.

The timer runs daily at 02:15 UTC with up to 15 minutes of jitter and catches up after downtime. The applied S3 lifecycle policy expires current `postgres/automated/` objects after seven days and removes noncurrent versions one day after expiration. Because the bucket is versioned, physical removal may lag the seven-day current-object expiry by about a day. The existing bucket already had an unrelated object version and delete marker under `postgres/`; the lifecycle filter deliberately excludes that legacy prefix.

## Install and test

The bucket already exists in Terraform; obtain its name with `terraform output -raw backup_bucket_name`. For a replacement host or reinstall, use `deploy-postgres-backup.ps1` from Windows with the instance ID and bucket name. It verifies the AWS account and running project-host tag, packages only these checked-in files, stages them through SSM, and invokes the installer as root. The installer validates the instance role and Kubernetes API, installs the timer, and does not print credentials.

Run one controlled backup with:

```bash
systemctl start agtp-postgres-backup.service
systemctl --no-pager --full status agtp-postgres-backup.service
journalctl --no-pager -u agtp-postgres-backup.service -n 30
```

Verify the latest object timestamp, nonzero `ContentLength`, `AES256` server-side encryption, and `agtp_postgres_backup_last_success_timestamp_seconds` in Prometheus before calling the backup path healthy. New objects use only the `postgres/automated/` prefix. A systemd failure is surfaced through the textfile metrics and Alertmanager rules; the overdue alert fires when no successful backup is recorded within 24 hours.

Restores must use a separate isolated database and synthetic data. Never overwrite the active database for a drill. The seven-day lifecycle is not a substitute for testing that an off-host backup can be restored.

## Verified live result - 2026-10-31

- The systemd timer is enabled and active. Backup `postgres/automated/20261031T090505Z.dump` uploaded successfully at 09:05:07Z with AES256 encryption; its size was 7,397 bytes, and the success metric recorded one successful attempt.
- The backup restored into a temporary isolated database with 4 tickets, 3 comments, and 2 migrations. SSM reported a one-second restore command duration; the temporary database and host dump were removed.
- At 10:35:25Z, the latest verified backup point was 90.3 minutes old. No data-loss incident occurred; this is the observed potential recovery-point age at that check.
- Backup-failed and backup-overdue alerts fired and resolved in Prometheus/Alertmanager, and the operator confirmed receipt.
