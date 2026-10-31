# Kubernetes and GitOps configuration

[Platform overview](../README.md)

Status: Stages 05-08 are complete. The application and PostgreSQL are healthy through Argo CD after the approved host rebuild and off-host restore; the private readiness endpoint returned HTTP 200 with 104 tickets and 3 comments. The failed-release convergence target miss remains documented. The scheduled host-side backup implementation is in [platform/backup](../backup/README.md).

## Intended contents

- Argo CD root/platform/application definitions.
- A safe bootstrap reconciliation ConfigMap under `cluster/`.
- Helm chart for the application and internal PostgreSQL.
- Private ClusterIP Services, configuration, and restricted secret references; no public ingress is configured.
- Readiness/liveness checks and measured resource requests/limits.
- PostgreSQL StatefulSet with persistent storage retained from automated pruning.
- Argo Sync-wave migration Job using the application's checksum-verified migration runner (database wave 0, migration wave 1, application wave 2).
- Host-side systemd backup timer with explicit success/failure metrics; it uses the host instance role without passing AWS credentials to pods.
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
- Monitoring interfaces must remain private; Grafana uses an out-of-band admin Secret.
- Alertmanager must not receive EC2 credentials. SNS notifications use the host-side authenticated bridge described in [monitoring configuration](../monitoring/README.md).

Stateful resources and backup retention must have deliberate deletion behavior. Automated pruning must not accidentally erase the only usable database or backup.

The chart expects the `support-ticket-db` Secret (key `password`) to be provisioned in the application namespace out of band. Do not commit the generated password or render a Kubernetes Secret from Helm values. Create it on the private host through the approved SSM path before the first Argo sync.
