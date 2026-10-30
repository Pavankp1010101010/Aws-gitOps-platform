# Stage 06 - End-to-end GitOps delivery

[Stage index](README.md) | [Previous](05-k3s-and-argocd.md) | [Next](07-monitoring.md)

Status: In progress (2026-10-31). Core implementation is complete; hosted release behavior, live deployment, and end-to-end acceptance remain unverified.

## Entry conditions

Stages 03 and 05 pass; CI can assume the authorized AWS publication role.

## Goal

Connect reviewed application changes to a working Kubernetes release without competing deployment tools.

## Work checklist

- [x] Implement trusted-main image publication after passing application CI, including scanning and restricted OIDC.
- [x] Implement digest-pinned GitOps update PRs and trace the image to its source commit.
- [x] Implement Helm configuration for the application, internal PostgreSQL, storage, probes, and resources (no public ingress).
- [x] Reference the database Secret without rendering or committing its value; live initialization is pending.
- [x] Implement an Argo Sync-wave migration Job after PostgreSQL is healthy and before the application rollout, using the checksum-verified migration runner.
- [x] Configure Argo CD reconciliation and PVC protection from automated pruning; live behavior is unverified.
- [x] Implement an explicit loopback-only synthetic API smoke check; running it against the live deployment is pending.
- [x] Document private-only service exposure and SSM-based access; live access verification is pending.

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
