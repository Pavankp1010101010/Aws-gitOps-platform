# Stage 05 - K3s and Argo CD bootstrap

[Stage index](README.md) | [Previous](04-aws-foundation.md) | [Next](06-end-to-end-gitops.md)

Status: Not started.

## Entry conditions

Stage 04 resources exist and restricted host management works.

## Goal

Prepare a reproducible cluster that can pull private images and reconcile Git configuration.

## Work checklist

- [ ] Implement pinned cloud-init/bootstrap and reapply through reviewed Terraform as needed.
- [ ] Install/configure K3s, persistent storage, secret encryption, and Traefik.
- [ ] Configure a compatible refreshable ECR credential provider using the instance role.
- [ ] Install a pinned Argo CD version and root application.
- [ ] Initialize private Git access and necessary secrets through the secure documented procedure.
- [ ] Establish restricted dashboard/API access through management port forwarding.
- [ ] Document bootstrap logs, failure detection, reboot, and rerun behavior.

## Work locations

[Bootstrap](../platform/bootstrap/README.md) and [Kubernetes](../platform/kubernetes/README.md). Update Terraform only for infrastructure/bootstrap wiring.

## Exit checks

- [ ] Cluster and services recover after a host reboot.
- [ ] A private test image can be pulled using refreshable credentials.
- [ ] Verify a fresh pull after the original ECR token lifetime; do not reuse an already cached image as proof.
- [ ] Argo CD fetches the intended Git repository and reconciles a safe test resource.
- [ ] Traefik exposure matches the intended host ports; no managed load balancer appears.
- [ ] Administration endpoints remain inaccessible from the public internet.

Record K8S-02 and relevant AWS-02 evidence. If token-refresh validation is still pending, do not mark the stage complete.

## Cost and approval gate

AWS charges continue. Review results and runtime before Stage 06.
