# Delivery automation

[Platform overview](../README.md) | [Flows](../../docs/03-architecture-and-flows.md)

Status: application CI is implemented. Stage 06 adds a main-branch release workflow and digest-pinned GitOps PR automation; hosted release behavior and the resulting PR checks still need verification.

## Implemented local CI configuration

- Events: pull requests, pushes to main, and manual dispatch.
- Read-only contents permission; no cloud credentials or OIDC token permission.
- Pinned checkout/setup-node revisions; pinned PostgreSQL and Trivy image digests.
- Ephemeral CI-only test database credentials, not reused local/production secrets.
- Locked install, syntax/integration checks, controlled runner-failure fixture.
- Image build/export, offline HIGH/LOW scan-policy checks, then actual image scan.
- No publication or deployment step.

See the [scan policy](scan-policy.md) and [Stage 03 results](../../docs/11-stage03-results.md). The patched image passes the local and hosted HIGH/CRITICAL gate. An actual temporary failing application test failed the required hosted job and blocked the PR; removing it restored success.

The user selected `Application tests and image scan` as required. Public metadata verifies GitHub Actions as the source and enforcement for everyone. Exact other classic-protection settings remain user-confirmed; no bypass/merge was attempted. PR #1 is open and unmerged.

## Application pull requests

Run application tests and validation without providing privileged AWS credentials to untrusted code.

The application CI workflow also lints and renders the Helm chart and runs its rendered-manifest safety checks.

## Approved application changes

After a successful `Application CI` run for a push to `main`, the release workflow:

1. Confirms the tested commit is still the latest application change on `main`.
2. Builds the application image from that exact commit and scans it against the HIGH/CRITICAL Trivy policy.
3. Authenticates to AWS using the restricted GitHub OIDC image-publisher role.
4. Publishes the passing image to ECR and resolves its immutable digest.
5. Opens or updates a deployment PR with the digest and source commit in Helm values.
6. Dispatches application CI for the generated branch because GitHub's `GITHUB_TOKEN` does not trigger the usual pull-request workflow event.

This automation is implemented but not yet verified end to end on GitHub. Confirm the dispatched CI run is attached to the deployment PR and satisfies its configured required check before merging.

## Deployment changes

Validate chart/manifests, require configured review/checks, and merge. Argo CD applies the change. A user-facing smoke-check mechanism is not implemented yet.

## Infrastructure changes

Run Terraform checks and a safely authorized plan. Apply only through the selected approved operator or protected workflow process.

## Implementation requirements

- Put actual workflow YAML at repository-root `.github/workflows`.
- Keep the confirmed monorepo application/platform split.
- Limit token permissions and OIDC trust.
- Serialize conflicting applies/deployment updates where needed.
- Pin third-party actions.
- Surface failures and maintain links between source, artifact, deployment PR, and validation.
