# Platform

[Back to project overview](../README.md)

Status: documentation only. No infrastructure or deployment configuration is executable yet.

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

If published as a separate repository, workflows belong at that repository's root `.github/workflows`. This documentation folder named `delivery` is not a GitHub Actions workflow discovery path.
