# Host and cluster bootstrap

[Platform overview](../README.md) | [Stage 05](../../stages/05-k3s-and-argocd.md)

Status: Deployed on 2026-10-30. Cloud-init, K3s, encrypted secrets, Traefik,
Argo CD readiness, reboot recovery, and no-drift checks pass. The root
Application synced revision `c7f1bc58004fb5d95c0ec79073da471fe1963df7` and
reconciled its ConfigMap smoke test. A private image pull, token-refresh, and
workstation port-forward remain pending.

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
instance. Inspect a fresh Terraform plan for the exact replacement and
dependent alarm changes before applying it. The current host has no
application workload or user data to preserve. Do not reuse historical plans.

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
systemd; Kubernetes restarts Argo CD and Traefik pods. Validate a fresh ECR
pull from a unique, immutable image after at least 12 hours from the initial
test pull. An already-cached image is not evidence of credential refresh.
