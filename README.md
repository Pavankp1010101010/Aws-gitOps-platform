# AWS GitOps Delivery Platform

A cost-conscious DevOps portfolio project demonstrating repeatable AWS infrastructure, controlled application delivery, monitoring, and recovery.

> Current status: Stages 00-02 are complete. Stage 03 patched containers and image scan pass locally; approved feature-branch publication and hosted CI/protection verification are next. Project services are stopped. No AWS resources exist. Exact GitHub protection settings remain user-confirmed.

## Start here

1. Read the [project brief](docs/01-project-brief.md) to understand the problem and scope.
2. Read the [architecture and flows](docs/03-architecture-and-flows.md) to follow infrastructure, deployment, traffic, and recovery.
3. Check the [tool inventory](docs/02-tool-inventory.md) for what each tool does.
4. Follow the [stage index and progress tracker](stages/README.md) from Stage 00 through Stage 09.
5. Use the [validation plan](docs/08-validation-and-evidence.md) to prove each milestone works.

## Directory map

```text
aws-gitops-platform/
|-- README.md                         Entry point and navigation
|-- .github/workflows/                Prepared CI workflow; not uploaded/executed
|-- stages/                           Ordered execution checklists and progress tracker
|-- docs/
|   |-- 01-project-brief.md            Problem, goals, scope, limitations
|   |-- 02-tool-inventory.md           Tools, responsibilities, installation policy
|   |-- 03-architecture-and-flows.md   Component diagram and operational flows
|   |-- 04-implementation-roadmap.md   Ordered milestones and completion criteria
|   |-- 05-security-and-access.md      Identity, secrets, network access
|   |-- 06-monitoring-and-alerting.md  Prometheus, Grafana, alerts
|   |-- 07-cost-and-cleanup.md         Billable resources and teardown checklist
|   |-- 08-validation-and-evidence.md  Tests, measurements, portfolio evidence
|   |-- 09-workstation-and-isolation.md Confirmed setup, checks, safety boundaries
|   |-- 10-stage02-results.md          Actual local application checks and limits
|   |-- 11-stage03-results.md          Container/scan results and completion blockers
|   `-- runbooks/
|       |-- release-recovery.md       Failed application release recovery
|       `-- database-and-host-recovery.md
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
    |-- terraform/README.md           Planned AWS infrastructure
    |-- bootstrap/README.md           Planned host and cluster initialization
    |-- delivery/README.md            Planned CI workflows and GitOps resources
    |-- kubernetes/README.md          Planned Helm and Argo CD configuration
    |-- monitoring/README.md          Planned dashboards, rules, notifications
    `-- tests/README.md               Planned platform checks and load tests
```

Application/container code and CI configuration are implemented locally. AWS/Kubernetes platform deployment remains planned; scan fixtures and delivery policy live under the platform directory.

## Intended platform

| Area | Planned choice |
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
| Stage plan | Stages 00-02 complete; Stage 03 in progress, hosted checks pending |
| Application selection | Support Ticket Tracker |
| Application language/framework decision | Node.js 24, Express, browser HTML/CSS/JavaScript, PostgreSQL confirmed |
| Workstation and local Git | Verified tools and isolated Docker test; origin configured/fetched, no local commit or upload |
| Application code and automated tests | Implemented; 13 checks passed and browser workflow verified |
| Local development environment | App/database containers verified and stopped; volume and ignored .env retained |
| Application container and image scan | Non-root Alpine build and patched HIGH/CRITICAL scan pass locally |
| Terraform and remote-state bootstrap | Not implemented |
| K3s bootstrap and registry authentication | Not implemented |
| CI | Workflow prepared locally; hosted execution and enforcement pending |
| GitOps and monitoring deployment | Not implemented |
| Recovery drills and measured results | Not performed |
| AWS deployment | Not performed |

## Repository organization

This directory is one initialized local Git repository on branch `main`, with the approved `origin` remote configured and fetched. No local commits or GitHub uploads have been created.

Keep application implementation in [application](application/README.md) and platform implementation in [platform](platform/README.md). Application-local development files belong with the application; AWS/Kubernetes deployment configuration belongs with the platform.

The confirmed layout is a monorepo with separate application/platform folders. The prepared GitHub Actions workflow is in root `.github/workflows`, using explicit working directories and no path filters so future required checks do not remain pending on documentation-only PRs.

The user created the public [GitHub repository](https://github.com/Pavankp1010101010/Aws-gitOps-platform). Remote `main` contains an initial README commit; preserve that history during later approved synchronization. Public API checks confirm branch protection is enabled. Detailed settings are user-confirmed, with effective PR/CI enforcement to be tested in Stage 03.

See [workstation decisions and isolation](docs/09-workstation-and-isolation.md) before changing shared tools, starting services, or choosing ports.

## Important limitations

- One EC2 host is a single point of failure.
- Kubernetes pod replacement does not provide host-level high availability.
- In-cluster monitoring cannot reliably report the loss of its own host.
- Git stores desired configuration, not database contents.
- Runbooks are planned procedures, not evidence that recovery has succeeded.
- No command in this documentation should be treated as an implemented deployment script.

Do not copy employer code, data, credentials, or configuration into this portfolio.
