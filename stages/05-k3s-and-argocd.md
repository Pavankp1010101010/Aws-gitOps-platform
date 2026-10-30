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
- [x] Install the compatible ECR credential-provider binary and kubelet configuration using the instance role; a fresh private image pull using `imagePullPolicy: Always` is verified below.
- [x] Publish and pull an immutable private smoke image using the restricted GitHub OIDC workflow; the successful pull is recorded below, while the workflow's final digest lookup awaits the scoped permission fix.
- [x] Install pinned Argo CD `v3.5.6`; the root Application manifest is prepared.
- [x] Apply the root Application after its configured Git path is available on the target revision.
- [x] Configure read-only Git access appropriate to the repository visibility. The public repository requires no Git credential; Argo fetched and synced it.
- [x] Verify workstation access through restricted SSM dashboard/API port forwarding; the Argo dashboard returned HTTP 200 through a loopback-only local tunnel.
- [x] Document bootstrap logs, failure detection, reboot, and rerun behavior.

This repository uses [GitHub's immutable OIDC subject format](https://docs.github.com/en/actions/reference/security/oidc#immutable-subject-claims),
including owner ID `93963930` and repository ID `1438499998`; the previous
name-only trust condition caused the STS `AccessDenied`. The Terraform change
pins IAM trust to the exact immutable main-branch subject. The smoke workflow
verifies the assumed AWS account using STS before logging in to ECR.
Its `ecr:DescribeImages` permission is limited to the project repository so the
workflow can record the pushed image digest without broader registry access.

## Stage 05 validation evidence

- GitHub Actions run [41107993982](https://github.com/Pavankp1010101010/Aws-gitOps-platform/actions/runs/41107993982) assumed the restricted role and pushed immutable tag `stage05-41107993982`, digest `sha256:895f426eeb61a31faf4744b2249215b5ea0c91e08dc303306d8b8163d453d4a9`. The job then failed at its final `ecr:DescribeImages` lookup; the repository-scoped permission fix is in review branch `stage05/ecr-digest-permission`.
- A one-off pod with `imagePullPolicy: Always` reached `Running` using that ECR image. Its reported image ID matched the digest above; the temporary namespace was deleted after the test.
- SSM port forwarding to the host's loopback Argo endpoint returned HTTP 200. The workstation listener was `127.0.0.1:18443`; no public ingress was opened.

## Work locations

[Bootstrap](../platform/bootstrap/README.md) and [Kubernetes](../platform/kubernetes/README.md). Update Terraform only for infrastructure/bootstrap wiring.

## Exit checks

- [x] Cluster and services recover after a host reboot.
- [x] A private test image can be pulled using the K3s ECR credential provider; the unique smoke tag used `imagePullPolicy: Always`.
- [ ] Verify a fresh pull after the original ECR token lifetime; do not reuse an already cached image as proof.
- [x] Argo CD fetched revision `c7f1bc58004fb5d95c0ec79073da471fe1963df7` and reconciled the `gitops-bootstrap-check` ConfigMap; the Application reports `Synced` and `Healthy`.
- [x] Traefik is a ClusterIP Service on ports 80/443; no Kubernetes LoadBalancer Service appears.
- [x] Administration endpoints remain inaccessible from the public internet; tested ports 22, 80, 443, 6443, and 8443 are unreachable, and the host security group has no ingress rules.

Record K8S-02 and relevant AWS-02 evidence. If token-refresh validation is still pending, do not mark the stage complete.

## Cost and approval gate

AWS charges continue on the already-running Stage 04 host. Keep work on that
host where possible; do not add managed AWS services or open public inbound
ports. Do not extend runtime beyond 2026-11-01 21:00 IST without revisiting
cleanup. Continue to Stage 06 automatically after every exit check passes;
pause only if a user-held dependency prevents safe completion.
