# Host and cluster bootstrap

[Platform overview](../README.md) | [Architecture and flows](../../docs/03-architecture-and-flows.md) | [Prerequisites](../../prerequisites/README.md)

The host bootstrap installs K3s and Argo CD on the configured EC2 instance.
The environment is not currently deployed by the repository maintainers.

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
The Argo CD API/UI is available through a loopback-bound host port-forward and
Systems Manager session; the security group has no inbound rules.

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
instance. Instance replacement deletes the local root disk and may lose the
active database. Before any replacement, verify a fresh off-host backup and
isolated restore, inspect a fresh Terraform plan for the exact changes, and
obtain explicit approval. Never reuse a saved plan from an earlier deployment.

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

The `.github/workflows/ecr-credential-smoke.yml` workflow uses the main-branch
OIDC publisher role to build and publish an immutable private smoke image.
The smoke workflow is optional and intended for registry/credential-provider
checks. The normal application release uses the tested-and-scanned image path
described in the [delivery guide](../delivery/README.md).

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
