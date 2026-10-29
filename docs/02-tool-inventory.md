# Tool inventory

[Back to project overview](../README.md)

Tools below describe the intended platform. Stage 01 verified existing workstation tools without installing software; see the [workstation record](09-workstation-and-isolation.md). Cloud/platform tools are not yet configured. Pin compatible charts, images, and dependencies when introduced.

## Core tools

| Tool/service | Responsibility | Planned location |
|---|---|---|
| Git and GitHub | Source history, pull requests, approvals | Developer workstation and repositories |
| AWS CLI | Authenticated infrastructure inspection and operations | Workstation and CI where required |
| Terraform | AWS provisioning and reviewed change plans | `platform/terraform` |
| Cloud-init | Initial EC2 and cluster bootstrap | `platform/bootstrap` |
| Ubuntu LTS | EC2 operating system | AWS EC2 |
| K3s | Kubernetes runtime and scheduling | EC2 |
| Docker | Build application container images | Local development and GitHub Actions |
| GitHub Actions | Tests, builds, scans, image publication, deployment-update PRs | Repository-root workflow directories once layout is decided |
| Trivy | Container image vulnerability scan | CI |
| Amazon ECR | Private container image storage | AWS |
| Helm | Application and platform packaging | GitOps configuration |
| Argo CD | Kubernetes reconciliation from approved Git configuration | K3s |
| Traefik | Application ingress | Bundled K3s component |
| PostgreSQL | Application persistence | K3s |
| Prometheus | Metrics collection and alert-rule evaluation | K3s |
| Grafana | Dashboards and operational visualization | K3s |
| Alertmanager | Alert grouping and notification routing | K3s |
| kube-prometheus-stack | Helm packaging for the monitoring components and exporters | K3s |
| k6 | Controlled traffic generation and performance checks | Workstation or designated test runner |
| Amazon S3 | Database backup storage and separate Terraform state storage | AWS |
| AWS Systems Manager | Restricted host administration and port forwarding | AWS and workstation session plugin |
| CloudWatch alarms and SNS | Host status-check notifications outside K3s | AWS |

K3s uses containerd to run containers. Docker does not need to be installed on the EC2 host just to run K3s workloads.

## Application choice

The [Support Ticket Tracker](../application/README.md) is implemented locally using Node.js 24.16.0, Express 5.3.0, pg 8.23.1, @prometheus-io/client 0.16.1, and PostgreSQL 17.11. Application dependencies are pinned in the manifest/lockfile, and the PostgreSQL image digest is pinned in local Compose configuration. See [Stage 02 results](10-stage02-results.md).

Application implementation belongs in `application`; infrastructure and deployment implementation belong in the separate `platform` directory.

## AWS identity and secrets

- GitHub Actions OIDC: short-lived AWS access for authorized workflows.
- EC2 instance role: minimum required host permissions.
- ECR kubelet credential provider: refreshable node image-pull authentication, subject to pinned K3s compatibility validation.
- Kubernetes Secrets: initial application secret storage with at-rest encryption and restricted RBAC.
- A documented secure manual secret initialization step: no plaintext secrets in Git or cloud-init user data.

An instance role is shared host identity; it is not EKS workload identity. Do not claim pod-level IAM isolation in this baseline.

## Optional later additions

| Addition | Reason to add it |
|---|---|
| Local k3d cluster | Test deployment configuration before spending on AWS |
| Loki | Search centralized logs after the baseline monitoring works |
| SOPS with age or an external secret integration | Improve reproducible secret delivery after choosing a secure key-management design |
| HTTPS with a domain and certificate automation | Required before exposing authenticated or sensitive application use publicly |

## Installation policy

1. Install only what the current milestone needs.
2. Verify supported versions and official installation instructions.
3. Record versions and platform prerequisites.
4. Pin dependencies rather than using unqualified `latest`.
5. Keep workstation, CI, and host responsibilities separate.

Nothing requires installing every tool on the developer's computer.
