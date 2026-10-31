# Stage 08 - Reliability, load, and recovery

[Stage index](README.md) | [Previous](07-monitoring.md) | [Next](09-completion-and-handover.md)

Status: In progress. Non-destructive recovery checks are recorded; the 10-minute release-recovery target was missed, and the host rebuild remains gated on explicit user approval.

## Entry conditions

Stage 07 is verified. Recovery targets and synthetic-data scope are recorded in the acceptance matrix. Explicit approval for the destructive host rebuild is pending; do not destroy or replace the active host without it.

## Goal

Prove platform behavior during failures, rather than assuming it from configuration.

## Work checklist

- [x] Implement scheduled PostgreSQL backups to private encrypted S3 (seven-day retention).
- [x] Validate uploads, backup timestamps, scoped retention, failure reporting, and overdue-backup alerts.
- [x] Run controlled k6 traffic with the documented request mix and duration.
- [x] Run application pod replacement and failed-release exercises.
- [x] Revert the GitOps release and verify actual service health; record that Argo convergence exceeded the 10-minute operational recovery window, although the app remained healthy throughout.
- [x] Restore both a baseline and fresh off-host backup into isolated databases and verify tickets/comments.
- [x] Replace the PostgreSQL pod and confirm ticket/comment persistence and application readiness.
- [ ] Perform an approved host rebuild using Terraform/bootstrap, secure secret initialization, and data restoration.
- [x] Update recovery runbooks from actual findings and timings.

## Work locations

Checks/load scripts in [platform/tests](../platform/tests/README.md); host backup service in [platform/backup](../platform/backup/README.md); operational instructions in [runbooks](../docs/runbooks).

## Exit checks

- [x] K8S-01 and CD-02 have measured outcomes; the app remained healthy throughout, while revert-to-Argo-success took 11m30s after merge (14m23s after commit creation) and exceeded the 10-minute operational recovery window.
- [x] DR-01 verifies data and reports the backup recovery point; at 11:09:47Z the latest verified backup was 7m54s old and restored 104 tickets/3 comments (no real incident occurred).
- [ ] DR-02 and AWS-01 prove host rebuild without undocumented console changes.
- [x] Backup failure/overdue notifications were received.
- [x] Load results report request rate, duration, p95 latency, errors, and host sizing against previously selected targets.
- [x] Schema compatibility and single-host downtime limitations are documented.
- [ ] HookFailed cleanup fix is merged and synced; repeat the controlled recovery test. The first Argo convergence exceeded the 10-minute operational recovery window.

Do not overwrite the active database for a drill. Do not destroy the only data copy. Do not claim HPA, high availability, or zero downtime unless separately implemented and proven.

## Cost and approval gate

Review measured results before final handover. Remove temporary drill resources after checking their exact identities.

The approved initial targets are a 24-hour maximum backup recovery point, a 30-minute database restore, a 10-minute release recovery, a 60-minute host rebuild, and a 5 requests/second, five-minute synthetic load with p95 at or below 500 ms and errors below 1%. The load dataset is 100 synthetic tickets with an even list/detail mix. The user selected seven-day S3 backup retention. Do not claim targets as achieved until measured.
