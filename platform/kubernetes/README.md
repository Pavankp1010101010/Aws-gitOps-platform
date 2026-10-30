# Kubernetes and GitOps configuration

[Platform overview](../README.md)

Status: Stage 05 bootstrap is complete. The Stage 06 Helm chart is synced and Healthy in Argo CD; the private app and PostgreSQL are Running with a Bound 4 Gi PVC. API CRUD smoke and persistence across app-pod replacement passed; image-publication PR flow remains to be verified.

## Intended contents

- Argo CD root/platform/application definitions.
- A safe bootstrap reconciliation ConfigMap under `cluster/`.
- Helm chart for the application and internal PostgreSQL.
- Private ClusterIP Services, configuration, and restricted secret references; no public ingress is configured.
- Readiness/liveness checks and measured resource requests/limits.
- PostgreSQL StatefulSet with persistent storage retained from automated pruning.
- Argo Sync-wave migration Job using the application's checksum-verified migration runner (database wave 0, migration wave 1, application wave 2).
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

The chart expects the `support-ticket-db` Secret (key `password`) to be provisioned in the application namespace out of band. Do not commit the generated password or render a Kubernetes Secret from Helm values. Create it on the private host through the approved SSM path before the first Argo sync.
