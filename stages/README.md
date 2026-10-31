# Project stages

[Project overview](../README.md) | [Roadmap](../docs/04-implementation-roadmap.md)

This is the authoritative stage order and progress tracker for the Support Ticket Tracker and AWS GitOps platform.

## Stage index

| Stage | Outcome | Prerequisite | Status |
|---|---|---|---|
| [00 - Planning](00-planning.md) | Documented scope, architecture, and separate application/platform directories | None | Complete: documentation only |
| [01 - Decisions and workstation](01-decisions-and-workstation.md) | Confirmed choices, source control, and verified local tools | 00 | Complete: protection enabled verified; detailed settings user-confirmed |
| [02 - Local application](02-local-application.md) | Working ticket application with PostgreSQL and tests | 01 | Complete: local checks passed; services stopped |
| [03 - Containers and CI](03-containers-and-ci.md) | Reproducible image build and tested CI checks | 02 | Complete: image gate, hosted CI, blocked-failure and recovery verified; PR unmerged |
| [04 - AWS foundation](04-aws-foundation.md) | Approved, Terraform-managed AWS resources | 01, 03; cost approval | Complete: all 29 resources applied, verified, and no Terraform drift |
| [05 - K3s and Argo CD](05-k3s-and-argocd.md) | Restricted, bootstrapped cluster with working registry/Git access | 04 | Complete: Argo healthy, private ECR pull and accelerated fresh-credential check passed, SSM access verified |
| [06 - End-to-end GitOps](06-end-to-end-gitops.md) | Approved source changes reach the application through immutable images | 03, 05 | Complete |
| [07 - Monitoring](07-monitoring.md) | Useful dashboards and verified notifications | 06 | Complete |
| [08 - Reliability and recovery](08-reliability-and-recovery.md) | Measured load, release recovery, backup restore, and rebuild results | 07 | In progress |
| [09 - Completion and handover](09-completion-and-handover.md) | Reproducible portfolio evidence, honest results, verified cleanup | 08 | Not started |

Stage 04 waits for local checks to reduce unnecessary cloud runtime. This is the recommended execution sequence, not a technical requirement that AWS needs application code.

## How to use

1. Open the next stage and verify its entry conditions.
2. Continue to the next stage automatically after the current stage's exit checks pass.
3. Perform the work in `application` or `platform`, as specified.
4. Execute the exit checks and record actual evidence.
5. Update this table and the stage's checkboxes only after verification.
6. Pause only for a genuine user-held dependency, such as unavailable credentials, an irreversible data decision, an external account setting, or a material ambiguity. Do not pause for routine stage-transition approval.

Allowed implementation statuses: Not started, In progress, Blocked, Complete. Statuses here reflect project execution, not document creation.

## Evidence and approval record

Append an entry when implementation occurs:

| Date | Stage | Approval/scope | Verification and evidence location | Remaining issues |
|---|---|---|---|---|
| 2026-10-29 | 01 | Stack, local monorepo initialization, isolated Docker smoke test, private access, and initial targets approved | [Workstation record](../docs/09-workstation-and-isolation.md); Docker test passed and container removed | GitHub visibility and protection verification deferred; no cloud/code implementation |
| 2026-10-29 | 01 | User supplied newly created public GitHub repository; read-only public checks performed | [GitHub verification](../docs/09-workstation-and-isolation.md); remote `main` exists and is unprotected; no rulesets returned | Protection policy/settings approval pending; no local remote, upload, or GitHub changes |
| 2026-10-29 | 01 | Origin/fetch and solo-maintainer policy approved | Origin added and fetched; remote contains initial README; no upload or local commit | User manual protection setup/verification pending |
| 2026-10-29 | 01 | User confirmed manual protection setup | Public API: main protected; status checks off. Detailed endpoint HTTP 401; exact settings user-confirmed | Stage 01 complete; effective PR/CI enforcement to test in Stage 03; Stage 02 not approved yet |
| 2026-10-29 | 02 | Stage and isolated dependency/database setup approved, including dedicated test resets | [Stage 02 results](../docs/10-stage02-results.md): 13 passing checks, browser workflows, actual database outage and recovery | Services stopped, volume retained; Stage 03 awaits approval |
| 2026-10-29 | 03 | Project-only build/scan/restarts and revised Alpine image approved; GitHub files local only | [Stage 03 results](../docs/11-stage03-results.md): non-root container, 13 checks, offline scan fixtures, restart persistence; services stopped | 2 HIGH scan findings; hosted CI and protection enforcement pending publication approval |
| 2026-10-29 | 03 | Pinned OpenSSL fix, regression, reviewed feature-branch publication/PR and temporary failing-test verification approved | Patched scan: zero HIGH/CRITICAL; 13 tests and container checks passed; services stopped | Hosted CI/protection verification pending; no merge or Stage 04 approval |
| 2026-10-29 | 03 | User pushed/opened PR #1 and configured required CI check; controlled failure/recovery published | [Hosted evidence](../docs/11-stage03-results.md): initial pass, intentional test failure with blocked PR, restored pass; required check applies to everyone | Stage 03 complete; PR unmerged; Stage 04 not started or approved |
| 2026-10-29 | 04 | User merged PR #1 and approved local Terraform tooling/branch setup only; region us-east-1/AZ us-east-1c | [Local Stage 04 results](../docs/12-stage04-local-results.md): official checksum, two valid roots, five mocked tests | Profile deferred; free allowances/estimate and all provisioning approvals pending; no cloud resources |
| 2026-10-30 | 04 | User approved foundation provisioning and the reviewed recovery; gross usage may exceed $10 | [Stage 04 results](../docs/12-stage04-local-results.md): 29 resources in state, no drift, SSM Run Command and SNS delivery verified, six mocked tests pass | One stale unconfirmed SNS request; host is billable; final charge measurement and cleanup remain due by the agreed deadline |
| 2026-10-30 | 05 | Stage 04 acceptance verified; automatic stage progression requested | Final cloud-init succeeded; K3s/Argo recovered after reboot; encrypted secrets enabled; Traefik/Argo Services ClusterIP; ECR provider returned redacted instance-role credentials; PVC data survived pod replacement; tested public ports were unreachable; no inbound rules or Terraform drift; Argo synced revision `c7f1bc58004fb5d95c0ec79073da471fe1963df7` and reconciled the smoke ConfigMap | Private image pull/12-hour refresh and workstation SSM tunnel remain (local Session Manager plugin unavailable) |
| 2026-10-31 | 05 | User selected the accelerated credential-refresh test rather than waiting for the original 12-hour ECR token to expire | [Stage 05 results](05-k3s-and-argocd.md): successful OIDC/ECR workflow; immutable image pull with matching digest; after K3s restart, fresh `GetAuthorizationToken` in CloudTrail and another successful pull; Argo healthy; SSM loopback access verified | The original token's post-expiry behavior was not directly tested; accelerated limitation is documented |
| 2026-10-31 | 06 | Automatic progression after Stage 05 completion | [Stage 06 results](06-end-to-end-gitops.md): reviewed release and GitOps PRs merged; Argo healthy at the digest-pinned image; CI and private loopback smoke passed | Complete |
| 2026-10-31 | 07 | Automatic progression after Stage 06; operator confirmed receipt of Alertmanager firing/resolved and CloudWatch alarm/OK test pairs | [Stage 07 results](07-monitoring.md): Argo healthy; Prometheus/Grafana queries, dashboards, SNS paths, and point-in-time host/pod resource usage verified | Sustained-load capacity and delivery latency not measured; backup monitoring deferred until Stage 08 |
| 2026-10-31 | 08 | Automatic progression after Stage 07; non-destructive recovery work only until explicit rebuild approval | Existing RTO/RPO and load targets are recorded in the [acceptance matrix](../docs/08-validation-and-evidence.md); seven-day S3 retention selected; synthetic data only | Destructive host rebuild not approved |

Use the [acceptance matrix](../docs/08-validation-and-evidence.md) for detailed test results. Store real, redacted evidence only once it exists; link it from this record.

## Credit-usage boundary

The assistant cannot see account credit consumption or detect the requested 93% consumed threshold. The user must monitor usage and signal that threshold. On that signal, pause implementation and request further approval. Stage approvals provide additional checkpoints; they are not credit metering.

## Definition of project completion

- The ticket application works and persists data.
- AWS infrastructure and bootstrap are reproducible.
- CI tests and scan policy enforce the release path.
- Approved GitOps changes deploy immutable artifacts with successful smoke checks.
- Monitoring and independent host notifications are tested.
- Recovery and load results are measured, not assumed.
- Costs, limitations, setup, and cleanup are documented and verified.
- No baseline acceptance check remains silently untested or failed.

Documentation completion alone does not mean platform completion.
