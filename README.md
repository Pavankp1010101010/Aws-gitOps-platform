# AWS GitOps Delivery Platform

A cost-conscious DevOps portfolio project demonstrating repeatable AWS infrastructure, controlled application delivery, monitoring, and recovery.

> Current status (2026-10-31): Stages 00-07 are complete. Stage 08 non-destructive checks are recorded, including an isolated restore of 104 tickets and 3 comments, pod-recovery, load, and alert drills. During the failed-release drill, the app and database stayed healthy; the failed hook was removed after its deadline, but Argo retried until the stale operation was terminated and current `main` synced successfully at 11:54:11Z. The 10-minute release-recovery target was exceeded. Stage 08 host rebuild and Stage 09 cost review/evidence/teardown remain open and approval-gated; the single m7i-flex.large host remains live.

## Start here

1. Read the [project brief](docs/01-project-brief.md) to understand the problem and scope.
2. Read the [architecture and flows](docs/03-architecture-and-flows.md) to follow infrastructure, deployment, traffic, and recovery.
3. Check the [tool inventory](docs/02-tool-inventory.md) for what each tool does.
4. Follow the [stage index and progress tracker](stages/README.md) from Stage 00 through Stage 09.
5. Use the [validation plan](docs/08-validation-and-evidence.md) to prove each milestone works.

## Directory map

```text
aws-gitops-platform/
|-- README.md                         Project entry point, status, and navigation
|-- .github/workflows/                Application CI, release, and credential-refresh workflows
|-- stages/                           Stage 00-09 checklists and evidence tracker
|-- docs/
|   |-- 01-project-brief.md            Problem, goals, scope, limitations
|   |-- 02-tool-inventory.md           Tools, responsibilities, installation policy
|   |-- 03-architecture-and-flows.md   Component diagram and operational flows
|   |-- 04-implementation-roadmap.md   Ordered milestones and completion criteria
|   |-- 05-security-and-access.md      Identity, secrets, network access
|   |-- 06-monitoring-and-alerting.md  Prometheus, Grafana, alerts
|   |-- 07-cost-and-cleanup.md         Billable resources, observed costs, and gated teardown
|   |-- 08-validation-and-evidence.md  Acceptance checks and measured results
|   |-- 09-workstation-and-isolation.md Confirmed setup, checks, safety boundaries
|   |-- 10-stage02-results.md          Actual local application checks and limits
|   |-- 11-stage03-results.md          Container/scan results and completion blockers
|   |-- 12-stage04-local-results.md    Terraform validation, tests, and AWS approval gates
|   `-- runbooks/                      Release, database, and host recovery procedures
|-- application/
|   |-- README.md                     Startup, API, tests, troubleshooting
|   |-- src/                          Application API, database access, server
|   |-- public/                       Browser interface
|   |-- migrations/                   Versioned SQL
|   |-- scripts/                      Environment setup and migrations
|   |-- test/                         Automated integration checks
|   |-- database/                     Dedicated test database initialization
|   |-- Dockerfile                    Non-root application image
|   |-- compose.yaml                  Local app/database and migration service
|   `-- package.json                  Pinned dependencies and commands
`-- platform/
    |-- README.md                     Platform ownership and layout
    |-- terraform/                    Bootstrap/environment roots, locks, mock tests, guide
    |-- bootstrap/README.md           Pinned host, K3s, and Argo CD bootstrap
    |-- delivery/README.md            CI and immutable-image GitOps release flow
    |-- kubernetes/README.md          Helm charts and Argo CD desired state
    |-- monitoring/README.md          Prometheus, Grafana, and verified alerts
    |-- backup/README.md              Host-side PostgreSQL backups and restore evidence
    `-- tests/README.md               Platform, recovery, and load-test evidence
```

The AWS foundation, single-node K3s cluster, Argo CD delivery, monitoring, and application are deployed. Recovery evidence includes a release-convergence target miss and a completed reconciliation after a controlled failed release; the app remained healthy, but the stale Argo operation required manual termination. Host rebuild and final environment retirement remain approval-gated.

## Deployed platform (baseline)

| Area | Implemented choice |
|---|---|
| AWS infrastructure | VPC, public subnet, EC2, IAM, ECR, S3 |
| Infrastructure automation | Terraform and cloud-init |
| Container orchestration | Single-node K3s on EC2 |
| CI and image scanning | GitHub Actions, Docker, Trivy |
| Delivery | Argo CD and Helm |
| Application | Support Ticket Tracker website and API |
| Database | PostgreSQL in K3s with backups outside the host |
| Monitoring | Prometheus, Grafana, Alertmanager |
| Load testing | k6 |

No EKS, RDS, AWS load balancer, or NAT Gateway is planned for the baseline. This reduces the managed-service footprint; it does not make AWS free.

## Implementation status

| Deliverable | Status |
|---|---|
| Documentation and navigable folder structure | Created |
| Stage plan | Stages 00-07 complete; Stage 08 in progress; Stage 09 handover/cleanup in progress |
| Application selection | Support Ticket Tracker |
| Application language/framework decision | Node.js 24, Express, browser HTML/CSS/JavaScript, PostgreSQL confirmed |
| Workstation and local Git | Verified tools; published feature branch/PR #1; remote history preserved |
| Application code and automated tests | Implemented; 13 checks passed and browser workflow verified |
| Local development environment | App/database containers verified and stopped; volume and ignored .env retained |
| Application container and image scan | Non-root Alpine build and patched HIGH/CRITICAL scan pass locally and in CI |
| Terraform and remote-state bootstrap | Applied; 29 resources verified with no drift; six mocked tests pass |
| K3s bootstrap and registry authentication | Single-node cluster deployed; private ECR credential-provider refresh verified with the documented accelerated test |
| CI | Hosted tests/build/scan pass; required-check failure blocked a PR; release workflow creates digest-pinned deployment PRs |
| GitOps delivery | Argo CD and Helm deployed; approved image update and private smoke test passed |
| Monitoring | Prometheus/Grafana dashboards and Alertmanager/CloudWatch notifications verified |
| Backups and recovery | Encrypted S3 backup, isolated restore, alerts, pod replacement, and load test passed; failed-release recovery preserved service but exceeded the convergence target and required manual Argo operation termination; host rebuild remains |
| Stage 09 portfolio and cleanup | Documentation and cost review underway; destructive rebuild and teardown still require explicit approval |

## Repository organization

This directory is a monorepo on `main`; the application, Terraform, Kubernetes, monitoring, and recovery implementation is versioned in the public repository. Pull requests are used for reviewed changes.

Keep application implementation in [application](application/README.md) and platform implementation in [platform](platform/README.md). Application-local development files belong with the application; AWS/Kubernetes deployment configuration belongs with the platform.

The confirmed layout is a monorepo with separate application/platform folders. The prepared GitHub Actions workflow is in root `.github/workflows`, using explicit working directories and no path filters so future required checks do not remain pending on documentation-only PRs.

The public [GitHub repository](https://github.com/Pavankp1010101010/Aws-gitOps-platform) retains its original main history. Public API checks confirm `Application tests and image scan` is required for everyone; an intentional failing application test blocked the PR and removing it restored passing CI. Other detailed protection selections remain user-confirmed. See [Stage 03 evidence](docs/11-stage03-results.md).

See [workstation decisions and isolation](docs/09-workstation-and-isolation.md) before changing shared tools, starting services, or choosing ports.

## Important limitations

- One EC2 host is a single point of failure.
- Kubernetes pod replacement does not provide host-level high availability.
- In-cluster monitoring cannot reliably report the loss of its own host.
- Git stores desired configuration, not database contents. The off-host backup is the verified recovery copy; the local persistent volume does not survive every host-replacement scenario.
- One EC2 host is a single point of failure; successful pod recovery is not host-level high availability.
- The repository documents tests and operational procedures; only checks explicitly marked passed have live evidence.
- The active environment incurs ongoing charges. The seven-day backup lifecycle covers only `postgres/automated/`; confirm retained-resource and teardown decisions before removing it.

Do not copy employer code, data, credentials, or configuration into this portfolio.
