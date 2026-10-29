# Project brief

[Back to project overview](../README.md)

## Problem statement

A small development team manually deploys an application to an AWS server. Infrastructure setup is difficult to reproduce, release steps vary, and failures are hard to detect and recover from. The team needs an automated and auditable delivery process within a limited demonstration budget.

This is a simulated portfolio scenario, not a claim about a real customer's environment.

## Proposed solution

Provision AWS infrastructure with Terraform, bootstrap K3s on EC2, build and test immutable application images with GitHub Actions, and deploy approved configuration using Argo CD. Monitor the platform with Prometheus and Grafana, route alerts with Alertmanager, and test release and database recovery.

## Goals and proof

| Goal | Required proof |
|---|---|
| Reproducible infrastructure | Create and rebuild infrastructure through reviewed automation |
| Reliable artifacts | Tests and scan policy pass before publishing a release image |
| Auditable delivery | Trace running image digest to source commit and approved deployment change |
| Visible operation | Dashboard shows application traffic, errors, latency, and resource use |
| Recoverable releases | Git revert restores service during a deliberate failed release |
| Recoverable data | Restore an off-host backup and verify expected records |
| Cost awareness | Record actual resource usage, observed charges, and cleanup evidence |

## Baseline scope

- One AWS region, one public subnet, and one EC2 instance.
- One single-node K3s cluster.
- A Support Ticket Tracker application and PostgreSQL.
- An approval-controlled deployment flow.
- Prometheus, Grafana, Alertmanager, and actionable notifications.
- Off-instance database backups in S3.
- Restricted administration and documented recovery procedures.

The initial environment has one application deployment namespace. Staging and production-like namespaces may be added after the baseline works. Namespaces on the same host are not independent production environments.

## Out of scope for the baseline

- Production availability guarantees or zero-downtime claims.
- Managed EKS, RDS, NAT Gateway, and AWS load balancers.
- Multi-region recovery or multi-node high availability.
- A complex microservices application.
- A full centralized logging platform; start with Kubernetes/container logs.
- Automated database schema rollback.

## Application problem and scope

Support requests scattered across messages make ownership and resolution difficult to follow. The [Support Ticket Tracker](../application/README.md) centralizes ticket creation, priority, status, assignee labels, and comments.

The initial demo uses synthetic data and private access. It is not a public customer-support service. Application code and platform code remain in separate directories.

## Design trade-offs

| Decision | Benefit | Limitation |
|---|---|---|
| K3s on EC2 | AWS and Kubernetes experience with fewer managed services | Host, cluster, and patching responsibilities remain ours |
| PostgreSQL in-cluster | Lower service footprint | Backup, storage, and recovery must be implemented |
| Traefik on host web ports | No separate AWS load balancer | No managed load-balancer availability |
| Public-subnet host | Avoids NAT Gateway | Requires careful exposure and restricted administration |
| Single host | Simpler demonstration | Host loss interrupts application and monitoring |

## Success statement

"I built and tested a cost-conscious AWS delivery platform with infrastructure as code, immutable artifacts, approval-controlled GitOps, monitoring, and documented recovery."

Use this statement only after implementation and testing. Until then, describe this as a project in progress.
