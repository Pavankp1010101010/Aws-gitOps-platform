# AWS GitOps Delivery Platform

An end-to-end DevOps portfolio project for a support-ticket application. It combines AWS infrastructure as code, a single-node K3s platform, GitHub Actions CI, immutable container delivery, Argo CD GitOps, monitoring, and database backup/recovery.

The AWS environment used to validate the project has been retired. A fresh deployment is optional, account-specific, and may incur charges.

## Get started

1. Read the [prerequisites and deployment guide](prerequisites/README.md) before configuring an account.
2. Follow the [architecture and flow diagrams](docs/03-architecture-and-flows.md).
3. Run the [local application](application/README.md) and its tests.
4. Review the [security and access guide](docs/05-security-and-access.md).
5. Use the [validation guide](docs/08-validation-and-evidence.md) and component documentation:
   - [Terraform infrastructure](platform/terraform/README.md)
   - [Host and K3s bootstrap](platform/bootstrap/README.md)
   - [CI and GitOps delivery](platform/delivery/README.md)
   - [Kubernetes configuration](platform/kubernetes/README.md)
   - [Monitoring](platform/monitoring/README.md)
   - [Database backups](platform/backup/README.md)
   - [Recovery runbooks](docs/runbooks/)
   - [Cost and teardown guidance](docs/07-cost-and-cleanup.md)

## Repository layout

```text
.
|-- .github/workflows/       CI, image release, and optional ECR smoke test
|-- application/             Express application, PostgreSQL schema, tests, and local container setup
|-- prerequisites/           Private configuration helper and portable deployment guide
|-- docs/                    Architecture, security, operations, validation, and recovery guides
|   |-- 03-architecture-and-flows.md Architecture and request/delivery/network diagrams
|   |-- 05-security-and-access.md   Identity, secrets, and network guidance
|   |-- 06-monitoring-and-alerting.md Observability and notification design
|   |-- 07-cost-and-cleanup.md      Cost awareness and safe teardown
|   |-- 08-validation-and-evidence.md Local and deployment validation guide
|   `-- runbooks/                  Release and database/host recovery procedures
|-- platform/
|   |-- terraform/           AWS bootstrap and environment roots
|   |-- bootstrap/           EC2 cloud-init and K3s/Argo CD setup
|   |-- kubernetes/          Helm chart and Argo CD desired state
|   |-- delivery/            Release and image-scanning policy
|   |-- monitoring/          Prometheus, Grafana, and notifications
|   |-- backup/              PostgreSQL backup and restore automation
|   `-- tests/               Platform validation and smoke-test helpers
```

## Technology and design

| Concern | Implementation |
|---|---|
| Application | Node.js 24, Express, browser UI, PostgreSQL |
| Infrastructure | Terraform and AWS commercial regions |
| Runtime | One Ubuntu x86_64 EC2 host running K3s |
| Delivery | GitHub Actions, ECR, immutable image digests, Argo CD, Helm |
| Observability | Prometheus, Grafana, Alertmanager, CloudWatch host checks |
| Data protection | Encrypted/versioned S3 backups and documented restore procedures |
| Administration | Systems Manager sessions and private port forwarding; no inbound security-group rules |

This is a single-host demonstration, not a highly available production design. It does not provision EKS, RDS, a public application endpoint, a NAT Gateway, or an AWS load balancer. Review capacity, security, recovery objectives, and regional pricing before adapting it for other uses.

## Important safety notes

- Never commit `prerequisites/project-config.json`, generated Terraform variables/backend settings, Terraform state/plan files, credentials, or application secrets.
- Review every Terraform plan and confirm the target AWS account before applying or destroying infrastructure.
- The project does not configure an automatic spending cap or automatic teardown. Monitor account activity and clean up resources deliberately.
- Argo CD reads a public GitHub repository on the `main` branch in the documented baseline. Private-repository authentication and alternate-branch support require additional configuration.
- The first deployment must publish an application image and merge the generated digest-pinned GitOps change before the application can become healthy.
