# Platform

[Back to project overview](../README.md)

Status: application CI and failure-policy fixtures are implemented; Stage 04 AWS foundation is deployed and verified. Stage 05 K3s/Argo CD bootstrap is in progress on the existing host. Kubernetes/bootstrap configuration is being made reproducible; monitoring remains planned.

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
