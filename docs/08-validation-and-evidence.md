# Validation and evidence

[Back to project overview](../README.md)

Local application checks ran in Stage 02; see [actual results and limitations](10-stage02-results.md). Stage 03 added [container/scan and hosted CI checks](11-stage03-results.md); patched image, hosted gate, and required-check failure/recovery passed. Cloud, Kubernetes, and recovery-target checks have not run.

Stage 01 workstation and isolated container checks are recorded separately in the [workstation record](09-workstation-and-isolation.md); they do not pass the application/platform checks below.

## Acceptance matrix

| ID | Check | Pass condition | Status |
|---|---|---|---|
| APP-01 | Ticket creation, filtering, assignment label, comments, and status lifecycle | Expected API responses and browser behavior, including reopening resolved tickets | Passed locally: automated and browser |
| APP-02 | Persistence | Records survive application pod replacement | Not run |
| APP-03 | Input/database errors | Invalid input rejected; unavailable database reported explicitly | Passed locally, including actual database stop |
| APP-04 | Health endpoints | Liveness/readiness distinguish process and dependency health appropriately | Passed locally: live 200, ready 503 during outage |
| CI-01 | Broken test | CI fails and no release update is proposed | Passed: temporary application test failed required hosted job; PR blocked; removal restored success. No release-publication step exists yet |
| CI-02 | Scan policy | Policy-blocking finding blocks release; exceptions are documented | Passed: HIGH blocked/LOW passed; initial image blocked; patched image and hosted scan passed; no exceptions |
| CI-03 | Artifact traceability | Running digest maps to source commit and successful CI | Not run |
| AWS-01 | Rebuild | Automation recreates intended resources without undocumented console changes | Not run |
| AWS-02 | Restricted access | Admin/database endpoints are not publicly reachable | Not run |
| K8S-01 | Pod recovery | Deleted application pod is replaced and becomes ready | Not run |
| K8S-02 | Registry authentication | Fresh private-image pulls work after original ECR token lifetime | Not run |
| CD-01 | Approved release | Approved Git change reaches the cluster and smoke test passes | Not run |
| CD-02 | Failed release recovery | Git revert restores known-good behavior | Not run |
| MON-01 | Metrics | Traffic produces request, error, and latency measurements | Not run |
| MON-02 | Notifications | Known failure produces received firing/resolved notifications | Not run |
| DR-01 | Database restore | Off-host backup restores into an isolated database with verified records | Not run |
| DR-02 | Host rebuild | Host recreation plus secret initialization and restore returns service | Not run |
| COST-01 | Cleanup | Remaining resources match explicit retention decisions | Not run |

## Performance and recovery measurements

Set a target before testing. Do not invent baseline values.

| Measurement | Definition | Target | Actual |
|---|---|---|---|
| Deployment duration | Approved deployment merge to successful smoke test | To define | Not measured |
| Failure detection time | Known failure start to received notification | <= 5 minutes | Not measured |
| Release recovery time | Recovery action start to verified healthy service | <= 10 minutes | Not measured |
| Database recovery time | Restore start to verified usable data | <= 30 minutes | Not measured |
| Potential backup data-loss window | Incident time minus restored backup recovery point | <= 24 hours while daily backups meet schedule | Not measured |
| Load behavior | p95 latency and errors at stated request rate and duration | p95 <= 500 ms; errors < 1%; 5 requests/second for 5 minutes | Not measured |
| Host rebuild time | Rebuild start to restored verified application | <= 60 minutes | Not measured |

These initial targets were approved in Stage 01; they are not achieved results. Use 100 synthetic tickets and an even list/detail request mix for the initial load test (1,500 scheduled requests); report achieved request count, dropped iterations, and failures as well as latency. Confirm dataset/resource sizing and any explicit target revision before testing.

Daily scheduling alone does not guarantee a 24-hour recovery point: monitor backup completion/freshness and account for job duration. Deployment duration remains informational until an explicit target is agreed.

For load tests, record tool version, request mix, dataset, host size, duration, and sample count. Do not claim autoscaling unless it is implemented and tested; the baseline does not promise HPA or node scaling.

## Evidence to retain after implementation

- Redacted pipeline links, source commits, image digests, and deployment PRs.
- Terraform plan/apply summaries without sensitive state.
- Grafana screenshots with visible test intervals.
- Alert receipts and corresponding failure timestamps.
- Recovery steps, elapsed times, and verified database queries.
- Actual cost notes and post-teardown resource checks.
- A short walkthrough showing a release and a controlled failure/recovery.

Add a dedicated evidence folder only when real evidence exists. Exclude credentials, database dumps, account-sensitive details, and employer information.
