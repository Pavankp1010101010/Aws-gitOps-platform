# Host and cluster bootstrap

[Platform overview](../README.md) | [Stage 05](../../stages/05-k3s-and-argocd.md)

Status: Deployed on 2026-10-30. Cloud-init, K3s, encrypted secrets, Traefik,
Argo CD readiness, host-reboot recovery, and no-drift checks pass. The root
Application reconciled its ConfigMap smoke test. A private image pull and an
accelerated credential-refresh check after restarting K3s passed; the original
ECR token's behavior after its full 12-hour expiry was not directly tested.
SSM access to the private Argo endpoint was verified.

## Pinned components

| Component | Pin | Verification |
|---|---|---|
| K3s | `v1.36.5+k3s1` | Official release binary SHA-256 and versioned installer SHA-256 are checked before install |
| ECR kubelet credential provider | `v1.37.0` | Published binary SHA-256 is checked; the stable kubelet credential-provider v1 API is configured |
| Argo CD | `v3.5.6` | Versioned install manifest SHA-256 is checked before server-side apply |
| Traefik | K3s-packaged chart | Version is tied to the pinned K3s release; `HelmChartConfig` sets the Service to `ClusterIP` |

Argo CD 3.5's tested Kubernetes matrix includes v1.36. The ECR provider uses
the stable kubelet exec credential API and is configured with a 10-hour cache
so it refreshes credentials before ECR's 12-hour token lifetime.

## Bootstrap behavior

Terraform embeds `bootstrap.sh`, `root-app.yaml`, and the cloud-config template
in EC2 user data. No credentials or notification addresses are embedded.
Cloud-init installs K3s with Kubernetes Secret encryption enabled, disables
K3s ServiceLB, configures the ECR credential provider to use the EC2 role via
IMDSv2, installs the K3s-packaged Traefik as a private ClusterIP Service, and
installs the pinned Argo CD manifest. Argo CD's API/UI remains ClusterIP-only.
The bundled Traefik v40 chart reads its Service type from
`service.spec.type`; the bootstrap sets that exact value.
The host runs a port-forward bound to `127.0.0.1:8443`; use Systems Manager
port forwarding to reach it. The security group remains without inbound rules.

The root Application reads the public project repository over unauthenticated
HTTPS and targets `platform/kubernetes/cluster`. Its initial safe test resource
is a ConfigMap. Argo auto-detects Kustomize from the path's
`kustomization.yaml`; do not force directory processing. It does not prune Git
resources automatically. Apply
`/etc/agtp/root-app.yaml` only after that path is present on the configured Git
revision; the bootstrap does not report a false success while the repository
path is missing.

The bootstrap script fails explicitly on unsupported OS/architecture, failed
artifact checksums, incorrect K3s version, unavailable IMDSv2, or failed
Kubernetes/Argo readiness. It waits for Argo deployments and its controller
before waiting for pods, so initial pod creation is not mistaken for failure.
It is safe to rerun at the pinned K3s version; it refuses implicit K3s
upgrades/downgrades. Review logs before rerunning:

- `/var/log/agtp-stage05-bootstrap.log`
- `/var/log/cloud-init-output.log`
- `cloud-init status --long`
- `systemctl status k3s agtp-argocd-port-forward`

Changing EC2 user data with `user_data_replace_on_change = true` replaces the
instance. The current host runs the application, PostgreSQL, monitoring, and
Argo CD, and contains synthetic ticket data. Instance replacement deletes the
local root disk and may lose the active database. Before any replacement,
verify a fresh off-host backup and isolated restore, inspect a fresh Terraform
plan for the exact instance/alarm changes, and obtain explicit approval. Do not
reuse historical plans or treat a successful pod restart as proof of host
rebuild recovery.

## Operations

Run cloud commands using the approved non-root profile and the project region.
The profile name is deliberately not hardcoded in Terraform.

On the host, via Systems Manager Run Command:

```bash
sudo /usr/local/sbin/agtp-stage05-bootstrap.sh
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f /etc/agtp/root-app.yaml
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n argocd get applications
```

After applying the root Application, wait for its sync and health fields to
report `Synced` and `Healthy` before recording GitOps acceptance.

The `.github/workflows/stage05-ecr-smoke.yml` workflow uses the main-branch
OIDC publisher role to build and publish an immutable private smoke image.
The image pull and accelerated credential-provider refresh after clearing the
K3s cache are verified in the [Stage 05 evidence](../../stages/05-k3s-and-argocd.md).
The original token's full 12-hour expiration behavior was not directly tested.

For private browser/API access, first establish a Session Manager port-forward
to remote port 8443 (the local SSM plugin is required), then browse to
`https://localhost:8443`. Stop the session when finished. Do not expose a
NodePort, LoadBalancer, public Kubernetes API, or dashboard ingress.

Argo CD's first-install administrator password is stored in the
`argocd-initial-admin-secret` Kubernetes Secret. Retrieve it only through a
trusted SSM session, never place it in source control or command logs, and
change it after the first login. The web/API endpoint is reachable only over
the loopback-bound port-forward.

After a host reboot, K3s and the loopback Argo port-forward start through
systemd; Kubernetes restarts Argo CD and Traefik pods. For future image-pull
tests, use a unique immutable image and `imagePullPolicy: Always`; an
already-cached image is not evidence of credential refresh.
