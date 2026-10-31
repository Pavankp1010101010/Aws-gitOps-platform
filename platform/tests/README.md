# Platform tests

[Platform overview](../README.md) | [Acceptance matrix](../../docs/08-validation-and-evidence.md)

Status: controlled failure-policy fixtures, rendered Helm-chart safety checks, and smoke-helper contract tests are implemented. Stage 08 backup, restore, load, pod-recovery, alert, failed-release, and approved host-rebuild checks are recorded below; the 10-minute failed-release convergence target was missed.

The post-merge Stage 06 verification used the deployed digest `sha256:cccccecd88c300e721dc421ddd95144f3cda31a35ce92addc0ca4c7b3400294f`. The repository smoke helper passed in the live application pod (synthetic ticket 4); Argo CD reported Synced/Healthy, and both application and PostgreSQL Services remained `ClusterIP`. See the [Stage 06 evidence](../../stages/06-end-to-end-gitops.md).

## Implemented fixtures

- `fixtures/intentional-failure.mjs`: explicit runner-failure test; expected exit 1. Do not include it in the passing application suite.
- `fixtures/trivy-high.json`: synthetic report; expected native Trivy convert exit 1 with HIGH/CRITICAL gate.
- `fixtures/trivy-low.json`: synthetic report; expected native Trivy convert exit 0 with the same gate.
- `validate-chart.sh`: checks rendered chart resources for private ClusterIP Services, secret references (not rendered Secret objects), ordered migrations, PVC prune protection, and digest-pinned images.
- `smoke-test.mjs`: synthetic ticket create/update/comment/list/retrieve check. It refuses non-loopback targets and leaves the synthetic record in place.
- `smoke-test.test.mjs`: exercises the smoke helper against the application's direct-JSON API contract and verifies non-loopback targets are rejected.
- `update-image-digest.py`: updates only the top-level app digest/source commit; `test_update_image_digest.py` verifies that the internal PostgreSQL digest remains untouched.

See [scan policy](../delivery/scan-policy.md). These fixtures do not install vulnerable packages or prove hosted CI enforcement. The root workflow invokes them explicitly.

## Stage 08 live results - 2026-10-31

- Backup upload and seven-day retention were verified for `postgres/automated/`; the successful object was 7,397 bytes with AES256 encryption.
- Isolated restore verified 4 tickets, 3 comments, and 2 migrations. The SSM restore command reported one second.
- The fresh 11:01:53Z backup (8,702 bytes, AES256) restored into an isolated database with 104 tickets and 3 comments; the temporary database was removed afterward.
- The k6 v2.3.0 five-minute run against 100 synthetic tickets completed 1,501 requests at 5.003 RPS, p95 3.01 ms, 0% failures, and zero dropped iterations on one m7i-flex.large host.
- Application pod replacement restored service in 6.79 seconds; the database remained at 104 tickets.
- Replacing the PostgreSQL pod preserved 104 tickets and 3 comments; application readiness returned HTTP 200.
- Backup failure and overdue alerts fired/resolved, and the operator confirmed receipt.
- The failed release's migration hook could not pull its nonexistent digest and did not run. The app and database stayed healthy on the known-good revision. The failed hook Job disappeared after its active deadline, but Argo retried the operation; the operator terminated the stale operation and synced current `main`. At 11:54:11Z Argo reported `Synced/Healthy` at `5e78eec81ff57056978d823257b521561044b286`; `/health/ready` returned HTTP 200, no migration Job remained, and the database contained 104 tickets and 3 comments. The measured revert convergence exceeded the 10-minute target (11m30s after merge; 14m23s after commit creation); no API outage was observed and service restoration was not needed.
- PR #28 merged the `HookFailed` migration-hook deletion policy and Argo synced it at `7fbced8d6bf3adc1cde44d28c633d7082335c9f3`. The failed hook was removed after its active deadline, but Argo retry required operator termination and a sync to current `main`.
- The approved Terraform host replacement was applied with the reviewed 1-add/1-change/1-destroy plan. The 11:01:53Z AES256 backup restored 104 tickets and 3 comments; `/health/ready` returned HTTP 200 at 12:27:10Z, 20m17s after the first destructive EC2 change. A post-apply Terraform plan reported no changes.

## Future checks

- Optional repeat of the smoke test against the private deployment through a local SSM port-forward:
  ```powershell
  $env:SMOKE_BASE_URL = 'http://127.0.0.1:18443'
  node platform/tests/smoke-test.mjs
  Remove-Item Env:\SMOKE_BASE_URL
  ```
- Verify database persistence after restarting PostgreSQL or rebuilding the host.
- Host rebuild and post-cleanup resource checks (require explicit approval).

## Safety rules

- Default test data must be synthetic.
- Destructive drills require explicit target selection and approval.
- Never run a load test against an unrelated or employer-owned endpoint.
- Do not fill the host disk to test low-space alerts.
- Keep evidence free of secrets.
- Do not label planned checks as passing results.
