# Stage 08 - Reliability, load, and recovery

[Stage index](README.md) | [Previous](07-monitoring.md) | [Next](09-completion-and-handover.md)

Status: In progress. Non-destructive recovery work is proceeding; the host rebuild remains gated on explicit user approval.

## Entry conditions

Stage 07 is verified. Recovery targets and synthetic-data scope are recorded in the acceptance matrix. Explicit approval for the destructive host rebuild is pending; do not destroy or replace the active host without it.

## Goal

Prove platform behavior during failures, rather than assuming it from configuration.

## Work checklist

- [ ] Implement consistent scheduled PostgreSQL backups to private encrypted S3 (seven-day retention).
- [ ] Validate uploads, backup timestamps, retention, failure reporting, and overdue-backup alerts.
- [ ] Implement controlled k6 traffic with documented request mix and duration.
- [ ] Run application pod replacement and failed-release exercises.
- [ ] Revert the GitOps release and verify actual service restoration.
- [ ] Restore an off-host backup into an isolated database and verify tickets/comments.
- [ ] Perform an approved host rebuild using Terraform/bootstrap, secure secret initialization, and data restoration.
- [ ] Update recovery runbooks from actual commands, findings, and timings.

## Work locations

Checks/load scripts in [platform/tests](../platform/tests/README.md); host backup service in [platform/backup](../platform/backup/README.md); operational instructions in [runbooks](../docs/runbooks).

## Exit checks

- [ ] K8S-01 and CD-02 pass with measured recovery time.
- [ ] DR-01 verifies data and reports backup recovery point/data-loss window.
- [ ] DR-02 and AWS-01 prove host rebuild without undocumented console changes.
- [ ] Backup failure/overdue notifications are received.
- [ ] Load results report request rate, duration, p95 latency, errors, and host sizing against previously selected targets.
- [ ] Schema compatibility and single-host downtime limitations are documented.
- [ ] Unexpected failures are fixed and retested, not hidden behind successful summaries.

Do not overwrite the active database for a drill. Do not destroy the only data copy. Do not claim HPA, high availability, or zero downtime unless separately implemented and proven.

## Cost and approval gate

Review measured results before final handover. Remove temporary drill resources after checking their exact identities.

The approved initial targets are a 24-hour maximum backup recovery point, a 30-minute database restore, a 10-minute release recovery, a 60-minute host rebuild, and a 5 requests/second, five-minute synthetic load with p95 at or below 500 ms and errors below 1%. The load dataset is 100 synthetic tickets with an even list/detail mix. The user selected seven-day S3 backup retention. Do not claim targets as achieved until measured.
