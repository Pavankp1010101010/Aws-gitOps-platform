# Validation and evidence

[Back to project overview](../README.md)

Local application checks ran in Stage 02; see [actual results and limitations](10-stage02-results.md). Stage 03 added [container/scan and hosted CI checks](11-stage03-results.md); patched image, hosted gate, and required-check failure/recovery passed. Live cloud, Kubernetes, and Stage 08 recovery results are recorded below.

Stage 01 workstation and isolated container checks are recorded separately in the [workstation record](09-workstation-and-isolation.md); they do not pass the application/platform checks below.

## Acceptance matrix

| ID | Check | Pass condition | Status |
|---|---|---|---|
| APP-01 | Ticket creation, filtering, assignment label, comments, and status lifecycle | Expected API responses and browser behavior, including reopening resolved tickets | Passed locally: automated and browser |
| APP-02 | Persistence | Records survive application and database pod replacement | Passed: both pods replaced independently; 104 tickets and 3 comments remained, and readiness returned HTTP 200 |
| APP-03 | Input/database errors | Invalid input rejected; unavailable database reported explicitly | Passed locally, including actual database stop |
| APP-04 | Health endpoints | Liveness/readiness distinguish process and dependency health appropriately | Passed locally: live 200, ready 503 during outage |
| CI-01 | Broken test | CI fails and no release update is proposed | Passed: temporary application test failed the required hosted job; PR blocked; removal restored success. The separate trusted release workflow was not triggered by that pull-request failure. |
| CI-02 | Scan policy | Policy-blocking finding blocks release; exceptions are documented | Passed: HIGH blocked/LOW passed; initial image blocked; patched image and hosted scan passed; no exceptions |
| CI-03 | Artifact traceability | Running digest maps to source commit and successful CI | Passed in Stage 06: live digest maps to application commit `083c0e5036bbb11a3671e4cd416bd7a79ae84965`; release, deployment-branch CI, post-merge CI, deployment PR #12, and live smoke are recorded in the [Stage 06 evidence](../stages/06-end-to-end-gitops.md). |
| AWS-01 | Rebuild | Automation recreates intended resources without undocumented console changes | Not run |
| AWS-02 | Restricted access | Admin/database endpoints are not publicly reachable | Passed in Stage 05: tested public ports unreachable; Services are ClusterIP |
| K8S-01 | Pod recovery | Deleted application pod is replaced and becomes ready | Passed: service recovery in 6.79 seconds |
| K8S-02 | Registry authentication | Fresh private-image pulls work after original ECR token lifetime | Accelerated cache-reset pull passed; behavior after the original token's full 12-hour expiration was not directly tested |
| CD-01 | Approved release | Approved Git change reaches the cluster and smoke test passes | Passed in Stage 06 |
| CD-02 | Failed release recovery | Git revert restores known-good behavior | Functionally passed: the app stayed on the known-good digest and the reverted revision synced; Argo convergence exceeded the 10-minute operational recovery window. HookFailed cleanup fix merged and synced in PR #28; controlled retest remains pending. |
| MON-01 | Metrics | Traffic produces request, error, and latency measurements | Passed in Stage 07; Stage 08 load results are below |
| MON-02 | Notifications | Known failure produces received firing/resolved notifications | Passed: Stage 07 notifications and Stage 08 backup failure/overdue alerts were received |
| DR-01 | Database restore | Off-host backup restores into an isolated database with verified records | Passed: the latest backup restored 104 tickets and 3 comments; earlier restore also verified 2 migrations |
| DR-02 | Host rebuild | Host recreation plus secret initialization and restore returns service | Not run |
| COST-01 | Cleanup | Remaining resources match explicit retention decisions | Not run |

## Performance and recovery measurements

Set a target before testing. Do not invent baseline values.

| Measurement | Definition | Target | Actual |
|---|---|---|---|
| Deployment duration | Approved deployment merge to successful smoke test | To define | Not measured |
| Failure detection time | Known failure start to received notification | <= 5 minutes | Not measured |
| Release recovery time | Recovery action start to verified healthy service | <= 10 minutes | No service interruption: the app stayed ready on the known-good digest, so no service restoration was needed. Argo completed the reverted revision 11m30s after PR merge (14m23s after revert commit creation), exceeding the operational recovery window; no API outage was observed. |
| Database recovery time | Restore start to verified usable data | <= 30 minutes | Baseline SSM restore reported 1 second; fresh 104-ticket/3-comment isolated restore completed in 2 seconds |
| Potential backup data-loss window | Incident time minus restored backup recovery point | <= 24 hours while daily backups meet schedule | No incident occurred. Latest verified backup: 11:01:53Z on 2026-10-31; isolated restore completed at 11:05:27Z and recovered 104 tickets/3 comments. At 11:09:47Z, that recovery point was 7m54s old. |
| Load behavior | p95 latency and errors at stated request rate and duration | p95 <= 500 ms; errors < 1%; 5 requests/second for 5 minutes | Passed with k6 v2.3.0: 1,501 requests in 5 minutes (5.003 RPS), p95 3.01 ms, 0% errors, 0 dropped iterations; 100 synthetic tickets on one m7i-flex.large host |
| Host rebuild time | Rebuild start to restored verified application | <= 60 minutes | Not measured |

These initial targets were approved in Stage 01; they are not achieved results. Use 100 synthetic tickets and an even list/detail request mix for the initial load test (at least 1,500 measured load requests); report achieved request count, dropped iterations, and failures as well as latency. A constant-arrival-rate run may include the start-boundary iteration, so a count above 1,500 is valid. Confirm dataset/resource sizing and any explicit target revision before testing.

Daily scheduling alone does not guarantee a 24-hour recovery point: monitor backup completion/freshness and account for job duration. Deployment duration remains informational until an explicit target is agreed.

For load tests, record tool version, request mix, dataset, host size, duration, and sample count. Do not claim autoscaling unless it is implemented and tested; the baseline does not promise HPA or node scaling.

## Stage 08 live evidence - 2026-10-31

- The host backup timer is enabled and active. Backup `postgres/automated/20261031T090505Z.dump` uploaded successfully with AES256 encryption (7,397 bytes); success metrics reported one successful attempt. Seven-day expiry and one-day noncurrent-version cleanup are scoped to `postgres/automated/`, leaving the legacy prefix untouched.
- The backup restored into a temporary isolated database. It contained 4 tickets, 3 comments, and 2 migrations. The temporary database and host dump were removed after verification.
- A fresh backup, `postgres/automated/20261031T110153Z.dump`, completed at 11:01:53Z (8,702 bytes). S3 reported AES256 encryption. At 11:05:25Z, it was restored into a uniquely named temporary database; the restore contained all 104 active tickets and 3 comments. The temporary database was removed after verification.
- The k6 v2.3.0 five-minute run used an even list/detail mix over 100 synthetic tickets: 1,501 requests, 5.003 RPS, p95 3.01 ms, 0% request failures, and zero dropped iterations. The host was a single m7i-flex.large; these results do not establish multi-node or sustained capacity.
- Deleting the application pod restored service in 6.79 seconds. A separate PostgreSQL pod replacement completed in 8 seconds; ticket/comment counts remained 104/3 and `/health/ready` returned HTTP 200. The fresh backup was taken before this database-persistence drill.
- Backup failure and overdue alerts were triggered and resolved in Prometheus and Alertmanager; the operator confirmed receipt of the notifications.
- The failed-release exercise used a nonexistent image digest. Its migration hook entered `ImagePullBackOff` and did not run; the application stayed ready on the known-good digest. After the revert PR merged, Argo's old operation required stale-hook cleanup and a sync of current `main`. Argo completed revision `d2a48a22` at 10:32:03Z; `/health/ready` returned HTTP 200 and the database still contained 104 tickets. The operation completed 11m30s after revert merge (10:20:33Z) and 14m23s after revert commit creation (10:17:40Z). This exceeds the 10-minute operational recovery window, although no API outage was observed and service restoration was not needed.

## Evidence to retain after implementation

- Redacted pipeline links, source commits, image digests, and deployment PRs.
- Terraform plan/apply summaries without sensitive state.
- Grafana screenshots with visible test intervals.
- Alert receipts and corresponding failure timestamps.
- Recovery steps, elapsed times, and verified database queries.
- Actual cost notes and post-teardown resource checks.
- A short walkthrough showing a release and a controlled failure/recovery.

Add a dedicated evidence folder only when real evidence exists. Exclude credentials, database dumps, account-sensitive details, and employer information.
