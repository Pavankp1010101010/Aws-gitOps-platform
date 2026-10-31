# Stage 06 - End-to-end GitOps delivery

[Stage index](README.md) | [Previous](05-k3s-and-argocd.md) | [Next](07-monitoring.md)

Status: In progress (2026-10-31). Argo CD deployed the chart, and private API smoke plus application-pod persistence checks passed. The main-branch workflow successfully assumed AWS credentials, built/scanned/published the image, and pushed its digest branch; creating the GitOps PR is blocked until repository Actions PR-creation permission is enabled.

## Entry conditions

Stages 03 and 05 pass; CI can assume the authorized AWS publication role.

## Goal

Connect reviewed application changes to a working Kubernetes release without competing deployment tools.

## Work checklist

- [x] Implement trusted-main image publication after passing application CI, including scanning and restricted OIDC.
- [x] Implement digest-pinned GitOps update PR creation and trace the image to its source commit; actual PR creation awaits repository workflow permission.
- [x] Implement Helm configuration for the application, internal PostgreSQL, storage, probes, and resources (no public ingress).
- [x] Provision the database Secret out of band without rendering or committing its value.
- [x] Implement an Argo Sync-wave migration Job after PostgreSQL is healthy and before the application rollout, using the checksum-verified migration runner.
- [x] Configure Argo CD reconciliation and PVC protection from automated pruning; the child Application is Synced and Healthy.
- [x] Implement and run the loopback-only synthetic API smoke check against the live deployment.
- [x] Document private-only service exposure and SSM-based access.

## Work locations

Application build/migrations in [application](../application/README.md); Helm/Argo CD in [platform/kubernetes](../platform/kubernetes/README.md); smoke checks in [platform/tests](../platform/tests/README.md); CI at the repository-root workflow path.

## Exit checks

- [ ] Approved source merge produces a passing image and deployment-update PR.
- [ ] Deployment PR merge results in Argo CD applying the exact image digest.
- [x] SSM-initiated loopback smoke check exercised ticket creation, updates/comments, filtered listing, and retrieval.
- [x] Synthetic ticket and comment survived application pod replacement.
- [x] PostgreSQL remained internal on ClusterIP; its PVC was Bound and application data persisted across app replacement.
- [ ] Image digest traces back to source commit, CI run, and deployment PR.
- [x] CI does not independently apply application resources; Argo CD is the cluster reconciler.

Record APP-02, CI-03, and CD-01 evidence.

## Cost and approval gate

Review the working release path before Stage 07. AWS charges continue.
