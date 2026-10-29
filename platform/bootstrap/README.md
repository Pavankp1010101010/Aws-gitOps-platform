# Host and cluster bootstrap

[Platform overview](../README.md)

Status: planned. No cloud-init or installation scripts exist.

## Intended sequence

1. Prepare a supported Ubuntu LTS host.
2. Apply required base configuration and validate Systems Manager access.
3. Install a pinned K3s version with deliberate ingress, storage, secret-encryption, and networking settings.
4. Configure and validate a compatible ECR kubelet credential provider using the instance role.
5. Install a pinned Argo CD version.
6. Initialize required credentials through the separate secure procedure.
7. Create the root Argo CD application.
8. Report bootstrap failures explicitly and retain useful non-secret logs.

## Requirements

- No passwords or tokens embedded in user data.
- Safe rerun behavior where supported; document one-time steps.
- No assumption that a one-time ECR login remains valid indefinitely.
- No public Kubernetes API or admin dashboards.
- Validate reboot behavior, service startup, clock synchronization, and fresh image pulls after token expiration.
- Record download sources and verify artifacts where supported.

Access to a private GitOps repository must be initialized before the root application can fetch it.
