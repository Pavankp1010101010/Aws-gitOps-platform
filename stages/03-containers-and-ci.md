# Stage 03 - Containers and CI

[Stage index](README.md) | [Previous](02-local-application.md) | [Next](04-aws-foundation.md)

Status: Complete. Local image/regression checks and hosted required-check failure/recovery passed; PR #1 remains unmerged.

## Entry conditions

Stage 02 application and tests pass.

## Goal

Make builds reproducible and prevent failing code from becoming a release artifact.

## Work checklist

- [x] Add a pinned, non-root application Dockerfile and appropriate build context exclusions.
- [x] Add local application/database container startup and documented configuration.
- [x] Configure and execute GitHub Actions at the repository root workflow path.
- [x] Run tests, build an image, and scan it with Trivy (scan blocked, not passed).
- [x] Define severity thresholds, exception expiry, and failure handling.
- [x] Pin dependencies and CI actions appropriately.
- [x] Configure available review/check enforcement and restricted workflow permissions.
- [x] Verify required-check context/enforcement and blocked PR behavior; exact remaining classic-protection settings are user-confirmed, not independently authenticated.
- [x] Keep privileged AWS credentials unavailable to untrusted pull requests (workflow requests read-only contents and no AWS/OIDC credentials).

## Work locations

Dockerfile and application tests in [application](../application/README.md). Delivery design in [platform/delivery](../platform/delivery/README.md); executable workflows belong at repository-root `.github/workflows`, not inside that documentation directory.

## Exit checks

- [x] Fresh container build starts successfully and reaches PostgreSQL.
- [x] A deliberate failing application test fails hosted CI and the PR is blocked; removing it restores passing CI.
- [x] Scan policy enforcement is tested locally with controlled HIGH/LOW reports, not an unsafe production dependency change.
- [x] Container restart preserves database data.
- [x] Local build/test commands are reproducible from documented prerequisites.
- [x] Actual image passes HIGH/CRITICAL scan without unapproved exceptions.

## Results and next actions

See [Stage 03 results](../docs/11-stage03-results.md) and the [scan policy](../platform/delivery/scan-policy.md).

13 application checks passed. The Alpine image starts as non-root, migrates, reaches PostgreSQL, and retains data across application-container restart. Hosted CI passed, then failed on an approved temporary application test while the required-check policy blocked PR #1, then passed after test removal.

Previously reported OpenSSL findings were resolved by pinning available 3.5.9-r0 packages. The unchanged scan returned zero HIGH/CRITICAL findings, followed by passing patched-image regression checks.

The user approved feature-branch publication and temporary failing-test verification and manually enabled the actual required job. See the results document for linked runs and verification limits. Services are stopped. No merge or Stage 04 work is approved.

Record CI-01 and CI-02 results. Registry publication and final digest traceability wait for AWS setup.

## AWS and approval gate

No AWS provisioning in this stage. Before Stage 04, explicitly approve region, cost estimate, budget notifications, and environment runtime.
