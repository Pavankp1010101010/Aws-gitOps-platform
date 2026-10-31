# Delivery automation

[Platform overview](../README.md) | [Flows](../../docs/03-architecture-and-flows.md)

Status: application CI and the Stage 06 release-to-GitOps flow are verified. Deployment PR #12 was merged after its checks passed; Argo CD applied the pinned image digest and the live smoke check passed. See the [Stage 06 evidence](../../stages/06-end-to-end-gitops.md).

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

The main-branch release flow successfully assumed AWS OIDC credentials, built/scanned/published the application image, and created [deployment PR #12](https://github.com/Pavankp1010101010/Aws-gitOps-platform/pull/12). The image digest and source commit were reviewed and merged; its dispatched CI passed, and Argo CD now reports the child Application Synced and Healthy with that digest. The earlier failed PR-creation attempt was recovered after enabling the repository permission described below.

The repository must allow GitHub Actions to create pull requests: **Settings > Actions > General > Workflow permissions > Allow GitHub Actions to create and approve pull requests**. The release workflow has narrowly scoped `pull-requests: write` permission; the repository setting must also permit that token capability. If a release job pushes a `deploy/application-*` branch but cannot open the PR, enable the setting and rerun the `Application CI` workflow for the same source commit; the release workflow can create the PR from the existing branch.

## Deployment changes

Validate chart/manifests, require configured review/checks, and merge. Argo CD applies the change. Stage 06 verified this path end to end; the loopback-only synthetic API smoke helper is documented in [platform tests](../tests/README.md).

## Infrastructure changes

Run Terraform checks and a safely authorized plan. Apply only through the selected approved operator or protected workflow process.

## Implementation requirements

- Put actual workflow YAML at repository-root `.github/workflows`.
- Keep the confirmed monorepo application/platform split.
- Limit token permissions and OIDC trust.
- Serialize conflicting applies/deployment updates where needed.
- Pin third-party actions.
- Surface failures and maintain links between source, artifact, deployment PR, and validation.
