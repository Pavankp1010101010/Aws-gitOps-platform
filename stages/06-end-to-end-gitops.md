# Stage 06 - End-to-end GitOps delivery

[Stage index](README.md) | [Previous](05-k3s-and-argocd.md) | [Next](07-monitoring.md)

Status: Complete (2026-10-31). The [release workflow](https://github.com/Pavankp1010101010/Aws-gitOps-platform/actions/runs/41175533162) published the image and opened [deployment PR #12](https://github.com/Pavankp1010101010/Aws-gitOps-platform/pull/12), which was reviewed and merged. Argo CD is Synced and Healthy at GitOps commit `d8cacc018aa4675fe8f3f64e69b1c7127ec377aa`; the running application uses image digest `sha256:cccccecd88c300e721dc421ddd95144f3cda31a35ce92addc0ca4c7b3400294f`, sourced from application commit `083c0e5036bbb11a3671e4cd416bd7a79ae84965`. The [deployment-branch CI](https://github.com/Pavankp1010101010/Aws-gitOps-platform/actions/runs/41175579956) and [post-merge CI](https://github.com/Pavankp1010101010/Aws-gitOps-platform/actions/runs/41175822020) passed, and the live loopback smoke passed.

## Entry conditions

Stages 03 and 05 pass; CI can assume the authorized AWS publication role.

## Goal

Connect reviewed application changes to a working Kubernetes release without competing deployment tools.

## Work checklist

- [x] Implement trusted-main image publication after passing application CI, including scanning and restricted OIDC.
- [x] Implement digest-pinned GitOps update PR creation and trace the image to its source commit.
- [x] Implement Helm configuration for the application, internal PostgreSQL, storage, probes, and resources (no public ingress).
- [x] Provision the database Secret out of band without rendering or committing its value.
- [x] Implement an Argo Sync-wave migration Job after PostgreSQL is healthy and before the application rollout, using the checksum-verified migration runner.
- [x] Configure Argo CD reconciliation and PVC protection from automated pruning; the child Application is Synced and Healthy.
- [x] Implement and run the loopback-only synthetic API smoke check against the live deployment.
- [x] Document private-only service exposure and SSM-based access.

## Work locations

Application build/migrations in [application](../application/README.md); Helm/Argo CD in [platform/kubernetes](../platform/kubernetes/README.md); smoke checks in [platform/tests](../platform/tests/README.md); CI at the repository-root workflow path.

## Exit checks

- [x] Approved source merge produces a passing image and deployment-update PR.
- [x] Deployment PR merge results in Argo CD applying the exact image digest.
- [x] SSM-initiated loopback smoke check exercised ticket creation, updates/comments, filtered listing, and retrieval.
- [x] Synthetic ticket and comment survived application pod replacement.
- [x] PostgreSQL remained internal on ClusterIP; its PVC was Bound and application data persisted across app replacement.
- [x] Image digest traces back to source commit, CI run, and deployment PR.
- [x] CI does not independently apply application resources; Argo CD is the cluster reconciler.

APP-02, CI-03, and CD-01 evidence is recorded above and in the linked CI runs and deployment PR.

## Cost and approval gate

Stage 06 delivery is verified; proceed to Stage 07. AWS charges continue while the host is running. The current cleanup deadline is 2026-11-01 21:00 IST.
