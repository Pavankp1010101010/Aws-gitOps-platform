# Stage 03 - Containers and CI

[Stage index](README.md) | [Previous](02-local-application.md) | [Next](04-aws-foundation.md)

Status: In progress. Patched image scan and local checks pass; approved publication and hosted enforcement checks remain.

## Entry conditions

Stage 02 application and tests pass.

## Goal

Make builds reproducible and prevent failing code from becoming a release artifact.

## Work checklist

- [x] Add a pinned, non-root application Dockerfile and appropriate build context exclusions.
- [x] Add local application/database container startup and documented configuration.
- [x] Prepare GitHub Actions at the repository root workflow path (local only; hosted execution pending).
- [x] Run tests, build an image, and scan it with Trivy (scan blocked, not passed).
- [x] Define severity thresholds, exception expiry, and failure handling.
- [x] Pin dependencies and CI actions appropriately.
- [ ] Configure available review/check enforcement and restricted workflow permissions.
- [ ] Recheck exact branch-protection settings through authorized access and test effective PR/check enforcement; Stage 01 verified only public protection metadata and user-confirmed detailed selections.
- [x] Keep privileged AWS credentials unavailable to untrusted pull requests (workflow requests read-only contents and no AWS/OIDC credentials).

## Work locations

Dockerfile and application tests in [application](../application/README.md). Delivery design in [platform/delivery](../platform/delivery/README.md); executable workflows belong at repository-root `.github/workflows`, not inside that documentation directory.

## Exit checks

- [x] Fresh container build starts successfully and reaches PostgreSQL.
- [ ] A deliberate failing test fails CI.
- [x] Scan policy enforcement is tested locally with controlled HIGH/LOW reports, not an unsafe production dependency change.
- [x] Container restart preserves database data.
- [x] Local build/test commands are reproducible from documented prerequisites.
- [x] Actual image passes HIGH/CRITICAL scan without unapproved exceptions.

## Results and next actions

See [Stage 03 results](../docs/11-stage03-results.md) and the [scan policy](../platform/delivery/scan-policy.md).

13 application checks passed. The deliberate failing runner fixture returned 1; this is not hosted CI verification. The final Alpine image starts as non-root, migrates, reaches PostgreSQL, and retains data across application-container restart.

Previously reported OpenSSL findings were resolved by pinning available 3.5.9-r0 packages. The unchanged scan returned zero HIGH/CRITICAL findings, followed by passing patched-image regression checks.

The user subsequently approved reviewed feature-branch publication, a PR, and temporary failing-test verification; no merge or protection changes are approved. No hosted enforcement result is claimed yet. Services are stopped. Keep this stage incomplete until hosted checks and protection enforcement pass.

Record CI-01 and CI-02 results. Registry publication and final digest traceability wait for AWS setup.

## AWS and approval gate

No AWS provisioning in this stage. Before Stage 04, explicitly approve region, cost estimate, budget notifications, and environment runtime.
