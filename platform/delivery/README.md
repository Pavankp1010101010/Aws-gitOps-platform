# Delivery automation

[Platform overview](../README.md) | [Flows](../../docs/03-architecture-and-flows.md)

Status: root `.github/workflows/application-ci.yml` is published on PR #1 and verified on GitHub. Application delivery/ECR/GitOps automation remains future work.

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

## Approved application changes

1. Build an image tagged with the source commit.
2. Scan against the documented Trivy policy.
3. Authenticate to AWS using restricted GitHub OIDC.
4. Publish the passing image to ECR.
5. Resolve its immutable digest.
6. Open a deployment-update pull request changing that digest in GitOps configuration.

## Deployment changes

Validate chart/manifests, require configured review/checks, and merge. Argo CD applies the change; a separately implemented smoke-check mechanism reports user-facing success or failure.

## Infrastructure changes

Run Terraform checks and a safely authorized plan. Apply only through the selected approved operator or protected workflow process.

## Implementation requirements

- Put actual workflow YAML at repository-root `.github/workflows`.
- Keep the confirmed monorepo application/platform split.
- Limit token permissions and OIDC trust.
- Serialize conflicting applies/deployment updates where needed.
- Pin third-party actions.
- Surface failures and maintain links between source, artifact, deployment PR, and validation.
