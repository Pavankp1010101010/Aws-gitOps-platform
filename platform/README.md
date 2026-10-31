# Platform

[Back to project overview](../README.md)

Status (2026-10-31): Stages 04-08 are deployed and verified on the rebuilt m7i-flex.large host. The approved rebuild restored the encrypted backup in 20m17s; the post-rebuild backup timer and monitoring are healthy. The failed-release exercise preserved service but required stale-operation termination and exceeded the 10-minute convergence target. Environment retirement remains approval-gated.

## Navigation

| Folder | Intended responsibility |
|---|---|
| [terraform](terraform/README.md) | AWS infrastructure and remote-state bootstrap |
| [bootstrap](bootstrap/README.md) | Initial host, K3s, and Argo CD setup |
| [delivery](delivery/README.md) | CI and deployment-update workflow design |
| [kubernetes](kubernetes/README.md) | Helm and Argo CD desired configuration |
| [monitoring](monitoring/README.md) | Metrics, dashboards, alert rules |
| [tests](tests/README.md) | Platform acceptance and load tests |

## Ownership

Terraform owns AWS resources. Bootstrap owns initial host/cluster setup. Argo CD owns ongoing Kubernetes application and platform resources.

Bootstrap creates the initial Argo CD/root application once; it must not continuously compete with GitOps ownership.

## Repository note

This project uses a monorepo. Executable workflows belong at root `.github/workflows`. The `delivery` folder holds platform delivery documentation/policy, not GitHub Actions discovery files.
