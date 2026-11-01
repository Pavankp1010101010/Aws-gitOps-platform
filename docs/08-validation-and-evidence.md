# Validation guide

[Project overview](../README.md) | [Architecture and flows](03-architecture-and-flows.md) | [Platform tests](../platform/tests/README.md)

Use these checks to validate changes locally before relying on hosted CI. They do not prove a successful deployment in an AWS account.

## Application

From `application/`:

```powershell
npm ci --ignore-scripts
npm run check
npm test
```

The integration suite uses a dedicated PostgreSQL test database. Follow the [application guide](../application/README.md) for safe local setup and test-data boundaries.

## Terraform

From the repository root, with Terraform 1.17.1 available:

```powershell
terraform fmt -check -recursive platform\terraform
terraform -chdir=platform\terraform\bootstrap init -backend=false -input=false
terraform -chdir=platform\terraform\bootstrap validate
terraform -chdir=platform\terraform\bootstrap test
terraform -chdir=platform\terraform\environment init -backend=false -input=false
terraform -chdir=platform\terraform\environment validate
terraform -chdir=platform\terraform\environment test
```

Terraform mock tests do not create AWS resources and do not establish that the account has permissions, quotas, capacity, or an approved cost profile. Do not substitute a real plan/apply for these local checks without following the deployment approval gates.

## Kubernetes and platform

The `Application CI` workflow validates application tests, image policy, Helm rendering, Kubernetes manifests, monitoring rules, and platform helper tests. Relevant checks can also be run locally using the commands in that workflow and the [platform test guide](../platform/tests/README.md).

Before any real rollout:

- Review the exact Terraform plan and verify the target account and region.
- Check the rendered Helm/Kustomize output and ensure application/database services remain private.
- Confirm the selected image exists in ECR and that the desired state references its immutable digest.
- Verify readiness, application behavior, database persistence, and only the monitoring/recovery claims actually exercised.
- Test restore and teardown procedures deliberately; do not infer them from a passing build or mock test.

## Evidence quality

Record reproducible evidence with the code change or release: tool versions, command and exit status, target configuration, relevant commit/image digest, and measured outcome. Redact account identifiers, credentials, email addresses, customer data, and secret-bearing logs. Distinguish local/mock validation from hosted CI and live-account verification.
