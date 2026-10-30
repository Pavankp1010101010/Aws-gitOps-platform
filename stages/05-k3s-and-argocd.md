# Stage 05 - K3s and Argo CD bootstrap

[Stage index](README.md) | [Previous](04-aws-foundation.md) | [Next](06-end-to-end-gitops.md)

Status: In progress (2026-10-30).

## Entry conditions

Stage 04 resources exist and restricted host management works.

## Goal

Prepare a reproducible cluster that can pull private images and reconcile Git configuration.

## Work checklist

- [x] Implement pinned cloud-init/bootstrap and reapply through reviewed Terraform as needed; final cloud-init succeeded and Terraform reports no drift.
- [x] Install/configure K3s, validate persistent storage across pod replacement, enable secret encryption, and configure private Traefik.
- [x] Install the compatible ECR credential-provider binary and kubelet configuration using the instance role; a private image pull remains to be verified.
- [x] Install pinned Argo CD `v3.5.6`; the root Application manifest is prepared.
- [ ] Apply the root Application after its configured Git path is available on the target revision.
- [ ] Configure read-only Git access appropriate to the repository visibility. The current public repository needs no Git credential; do not commit credentials if it becomes private.
- [ ] Establish restricted dashboard/API access through management port forwarding.
- [x] Document bootstrap logs, failure detection, reboot, and rerun behavior.

## Work locations

[Bootstrap](../platform/bootstrap/README.md) and [Kubernetes](../platform/kubernetes/README.md). Update Terraform only for infrastructure/bootstrap wiring.

## Exit checks

- [x] Cluster and services recover after a host reboot.
- [ ] A private test image can be pulled using refreshable credentials.
- [ ] Verify a fresh pull after the original ECR token lifetime; do not reuse an already cached image as proof.
- [ ] Argo CD fetches the intended Git repository and reconciles a safe test resource.
- [x] Traefik is a ClusterIP Service on ports 80/443; no Kubernetes LoadBalancer Service appears.
- [x] Administration endpoints remain inaccessible from the public internet; tested ports 22, 80, 443, 6443, and 8443 are unreachable, and the host security group has no ingress rules.

Record K8S-02 and relevant AWS-02 evidence. If token-refresh validation is still pending, do not mark the stage complete.

## Cost and approval gate

AWS charges continue on the already-running Stage 04 host. Keep work on that
host where possible; do not add managed AWS services or open public inbound
ports. Do not extend runtime beyond 2026-11-01 21:00 IST without revisiting
cleanup. Continue to Stage 06 automatically after every exit check passes;
pause only if a user-held dependency prevents safe completion.
