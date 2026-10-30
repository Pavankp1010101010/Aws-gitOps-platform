# Stage 06 - End-to-end GitOps delivery

[Stage index](README.md) | [Previous](05-k3s-and-argocd.md) | [Next](07-monitoring.md)

Status: In progress (2026-10-31).

## Entry conditions

Stages 03 and 05 pass; CI can assume the authorized AWS publication role.

## Goal

Connect reviewed application changes to a working Kubernetes release without competing deployment tools.

## Work checklist

- [ ] Extend trusted-branch CI to publish the tested/scanned image to ECR.
- [ ] Open a GitOps update PR using the image digest and narrowly scoped identity.
- [ ] Implement Helm configuration for application, internal PostgreSQL, storage, ingress, probes, and resources.
- [ ] Reference initialized secrets without committing values.
- [ ] Add an explicit migration strategy compatible with rolling application changes.
- [ ] Configure Argo CD reconciliation and safe pruning behavior.
- [ ] Implement an explicit user-facing smoke-check mechanism and failure reporting.
- [ ] Document private demo access; do not accidentally expose a public write-enabled application.

## Work locations

Application build/migrations in [application](../application/README.md); Helm/Argo CD in [platform/kubernetes](../platform/kubernetes/README.md); smoke checks in [platform/tests](../platform/tests/README.md); CI at the repository-root workflow path.

## Exit checks

- [ ] Approved source merge produces a passing image and deployment-update PR.
- [ ] Deployment PR merge results in Argo CD applying the exact image digest.
- [ ] Smoke checks exercise ticket creation, updates/comments, and retrieval.
- [ ] Ticket records survive application pod replacement.
- [ ] Private database access and persistence behavior are verified.
- [ ] Image digest traces back to source commit, CI run, and deployment PR.
- [ ] CI does not independently apply application resources.

Record APP-02, CI-03, and CD-01 evidence.

## Cost and approval gate

Review the working release path before Stage 07. AWS charges continue.
