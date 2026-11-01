# CI and GitOps delivery

[Project overview](../../README.md) | [Architecture and flow diagrams](../../docs/03-architecture-and-flows.md) | [Prerequisites](../../prerequisites/README.md)

## Application CI

The root `.github/workflows/application-ci.yml` workflow runs on pull requests, pushes to `main`, and manual dispatch. It validates the application, PostgreSQL integration, Helm/Kustomize output, monitoring rules, and platform helper tests. It builds and scans the application image as a CI check; pull-request CI has no AWS credentials or OIDC token permission.

The scan gate blocks reported HIGH and CRITICAL vulnerabilities. Read the [container scan policy](scan-policy.md) before changing scanner versions, severities, or failure behavior.

## Release and deployment

After an application change reaches `main` and its `Application CI` run succeeds, `.github/workflows/application-release.yml`:

1. Confirms the successful commit is still the latest relevant application change.
2. Builds the application image from that commit and scans it using the configured policy.
3. Assumes the narrowly scoped AWS image-publisher role with GitHub OIDC short-lived credentials.
4. Publishes the image to the configured immutable ECR repository and resolves its digest.
5. Opens or updates a deployment pull request containing the image digest and source commit.
6. Dispatches CI for the generated deployment branch.

Review and merge the deployment pull request only after its checks pass. Argo CD then reconciles the Helm release from Git; Actions does not apply Kubernetes resources directly.

## Repository setup

Configure these non-secret Actions variables using the prerequisite guide and Terraform outputs:

| Variable | Purpose |
|---|---|
| `AWS_ACCOUNT_ID` | Guard against an unexpected AWS account |
| `AWS_REGION` | ECR and AWS provider region |
| `AWS_PUBLISH_ROLE_ARN` | GitHub OIDC image-publisher role |
| `ECR_REPOSITORY` | Immutable application image repository |

Grant Actions permission to create pull requests in the repository settings. Do not configure long-lived AWS access keys as GitHub secrets. The baseline uses the public `main` branch; changing repository visibility or the default branch requires coordinated updates to GitHub trust and Argo CD configuration.

The optional manually dispatched ECR credential-provider smoke workflow is for registry checks. It is not a substitute for the normal tested and scanned release workflow.
