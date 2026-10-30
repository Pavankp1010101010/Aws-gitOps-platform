# Kubernetes and GitOps configuration

[Platform overview](../README.md)

Status: Stage 05 bootstrap manifests are implemented; live Argo CD reconciliation remains to be verified.

## Intended contents

- Argo CD root/platform/application definitions.
- A safe bootstrap reconciliation ConfigMap under `cluster/`.
- Helm chart for the application.
- Deployment, Service, ingress, configuration, and restricted secret references.
- Readiness/liveness checks and measured resource requests/limits.
- PostgreSQL StatefulSet or selected maintained chart with persistent storage.
- Backup CronJob and explicit backup success/failure reporting.
- Namespace, service-account, and RBAC configuration.

## Design constraints

- Keep PostgreSQL internal.
- Pin image digests and chart versions.
- Reference secrets; never commit their plaintext values.
- Do not assume NetworkPolicy is enforced without testing the K3s network configuration.
- Avoid probes that restart every application replica during a shared database outage.
- Test local-volume permissions, pod replacement, and host-rebuild behavior.
- Define Argo CD pruning carefully around persistent data and namespaces.
- No baseline autoscaling claim; HPA requires a separate implemented and tested milestone.

Stateful resources and backup retention must have deliberate deletion behavior. Automated pruning must not accidentally erase the only usable database or backup.
