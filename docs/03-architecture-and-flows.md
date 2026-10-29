# Architecture and flows

[Back to project overview](../README.md)

These are intended flows. Implementation and verification are pending.

## 1. Component architecture

```text
Developer -> GitHub -> GitHub Actions -> ECR
                |                         |
                | approved configuration  | image pull
                v                         v
AWS VPC / public subnet
+--------------------------------------------------------+
| EC2 instance / single-node K3s                          |
|                                                        |
| Argo CD ----> Helm-managed application/platform objects |
|                                                        |
| Traefik -> Web UI/API -> PostgreSQL -> persistent disk  |
|                |                                       |
|                v                                       |
| Exported metrics -> Prometheus -> Grafana               |
|                          |                             |
|                          v                             |
|                    Alertmanager -> notification target |
|                                                        |
| Scheduled database backup ------------------------+    |
+---------------------------------------------------|----+
                                                    v
                                               S3 backups

EC2 status checks -> CloudWatch alarm -> SNS notification
Administrator -> Systems Manager -> restricted admin access
Terraform -> AWS infrastructure (not application deployments)
```

## 2. Infrastructure provisioning

1. Bootstrap separate remote-state storage and locking.
2. Open an infrastructure change pull request.
3. Run formatting, validation, and an authorized Terraform plan.
4. Review the plan before applying.
5. Terraform creates networking, roles, ECR, backup storage, alarms, and EC2.
6. Cloud-init configures the host, K3s, and registry credential provider.
7. Bootstrap Argo CD with a pinned version and a root application.
8. Configure required credentials through the documented secure setup procedure.
9. Argo CD reconciles platform and application configuration.
10. Run acceptance checks and record results.

The initial Terraform apply may be an explicit operator action. Automated infrastructure applies should be introduced only after approvals and identity controls are configured.

## 3. Application delivery

```text
Application pull request
  -> tests and validation
  -> review and merge
  -> build image once
  -> Trivy scan against documented policy
  -> push passing artifact to ECR
  -> open GitOps PR updating immutable image digest
  -> review and merge GitOps PR
  -> Argo CD reconciliation
  -> Kubernetes readiness checks
  -> deployment smoke test
  -> observe metrics
```

GitHub Actions publishes artifacts and proposes configuration changes. It does not independently deploy the same Kubernetes resources as Argo CD.

An explicit smoke-test mechanism and result reporting must be implemented. Argo CD reporting an application as healthy is not a substitute for testing the user-facing API.

## 4. User request

```text
Browser
  -> EC2 public endpoint, permitted web port
  -> Traefik host ingress
  -> frontend/API Kubernetes Service
  -> application pod
  -> internal PostgreSQL Service
  -> database pod and persistent volume
```

Do not create a Kubernetes Service that unexpectedly provisions a cloud load balancer. Validate K3s ServiceLB/Traefik exposure and security-group rules explicitly.

Database ports are not public. Plain HTTP is acceptable only for a controlled non-sensitive demo. Do not transmit real credentials or sensitive data without HTTPS.

## 5. Monitoring and notifications

```text
Application / node / Kubernetes exporters
  -> Prometheus scrapes metrics
  -> Grafana queries Prometheus
  -> Prometheus evaluates alert rules
  -> Alertmanager sends notifications
```

CloudWatch EC2 status-check alarms supply a separate host-failure signal. They do not prove application availability; an external application probe is a later enhancement.

## 6. Failed-release recovery

```text
Detect failure -> inspect evidence -> revert GitOps change
  -> Argo CD applies last known good configuration
  -> smoke test -> verify metrics -> document incident
```

No automatic rollback is assumed. A container rollback does not reverse database schema changes.

## 7. Data and host recovery

```text
Database -> scheduled consistent backup -> S3

Host failure
  -> Terraform/bootstrapping recreates compute
  -> secure secret initialization
  -> Argo CD restores configuration
  -> restore backup into isolated database
  -> verify data and connectivity
  -> controlled application reconnection
```

Git and Terraform cannot reconstruct unbacked-up application data.
