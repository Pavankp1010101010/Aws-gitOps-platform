# Prerequisites and deployment guide

[Project overview](../README.md) | [Terraform details](../platform/terraform/README.md) | [Cost and cleanup](../docs/07-cost-and-cleanup.md)

This guide prepares a fresh copy of the project for one operator's AWS account and GitHub repository. The configuration helper creates local Terraform inputs and renders account-specific repository, ECR, region, and notification settings. It does **not** create AWS resources or configure credentials. No AWS environment is included with the repository; the steps below describe how an operator can deploy their own.

## Supported baseline and limitations

- One Ubuntu 24.04 x86_64 EC2 host runs K3s, the support-ticket application, PostgreSQL, Argo CD, and monitoring.
- Terraform and the AWS provider are pinned to 1.17.1 and 6.71.0. The project is intended for standard AWS commercial regions only; China, GovCloud, and isolated partitions are not supported.
- The project uses a public subnet and public IPv4 for outbound bootstrap, package, registry, and SSM traffic. It configures no inbound security-group rules, SSH key, NAT Gateway, EKS, RDS, or load balancer.
- Supported host types are `t3.micro`, `t3.small`, `t3.medium`, `t3.large`, and `m7i-flex.large`. Only `m7i-flex.large` was used for the measured monitoring/load evidence; smaller choices may not have enough capacity. Availability varies by region and account.
- The VPC uses `10.77.0.0/16` and its subnet uses `10.77.1.0/24`. Choose an account/region where these ranges do not conflict with any network you intend to connect.
- Argo CD clones the configured GitHub repository over unauthenticated HTTPS. The repository must be public for this baseline. Private-repository authentication is not implemented here.
- GitOps trusts the repository's `main` branch. Keep `main` as the default branch unless you deliberately update and validate the Terraform trust policy, Argo revisions, and workflows together.
- The initial application image must be published to the new ECR repository and its digest committed to the Helm values before the app can become healthy. This is described below.

## Costs and access prerequisites

No part of this deployment should be assumed free. Charges may include EC2 runtime, the EBS gp3 volume, public IPv4, ECR image storage, S3 state and backup storage, monitoring/notifications, and any retained versions or logs. Actual amounts depend on account eligibility, region, usage, and runtime. Use the [AWS Pricing Calculator](https://calculator.aws/) and review account-specific free allowances before provisioning.

The deployment has no automatic spending cap or shutdown. The `TeardownAfter` instance tag is informational and does not stop or delete resources. Monitor account activity, set a calendar reminder, and review billing after teardown because cost reporting can be delayed.

Have the following ready:

1. A dedicated AWS account or an explicitly approved account, with permission to create the resources described in [Terraform's resource and cost notes](../platform/terraform/README.md).
2. Short-lived AWS CLI authentication (for example, AWS IAM Identity Center/SSO). Do not put access keys in the repository or configuration JSON.
3. A public GitHub repository containing this project, Actions enabled, and `main` as the default branch.
4. Permission to set repository Actions variables and to enable **Allow GitHub Actions to create and approve pull requests** under **Settings → Actions → General → Workflow permissions**.
5. A verified Ubuntu 24.04 LTS x86_64 AMI ID published by Canonical in the chosen region, an available AZ, and an instance type/capacity appropriate for the stack.
6. Globally unique S3 bucket names for Terraform state and PostgreSQL backups.
7. An email address you control for SNS host notifications. Confirm the subscription message after deployment.

### Tools

| Tool | Version/use |
|---|---|
| Git | Clone, review, and publish the configuration change |
| Python | 3.10+; the configuration helper and its tests use only the standard library |
| Terraform | 1.17.1, matching `required_version` and the checked-in provider lockfiles |
| AWS CLI | v2, for short-lived authentication and post-deployment checks |
| Docker Engine | Needed for local application/container workflows; GitHub-hosted CI also builds images |
| Node.js/npm | Node.js 24 for local application tests, matching the CI runtime |
| PowerShell | Useful on Windows for AWS SSO and the backup deployment script |
| `kubectl` | Optional on the workstation; operational Kubernetes access is through Systems Manager and a port-forward |

Install tools from their official sources. Check `terraform version`, `aws --version`, `python --version`, `node --version`, and `docker version` before starting. Do not copy ignored `.cache` binaries from another operator.

## Choose account and identity values

Set up AWS CLI authentication outside this repository. For an existing SSO profile, authenticate and confirm only the account ID:

```powershell
aws sso login --profile YOUR_PROFILE
aws sts get-caller-identity --profile YOUR_PROFILE --query Account --output text
$env:AWS_PROFILE = 'YOUR_PROFILE'
```

Do not continue until the returned account is the intended target. The environment provider also uses Terraform's `allowed_account_ids` guard.

Pick a standard commercial AWS region and an AZ actually offered to this account:

```powershell
aws ec2 describe-availability-zones --region YOUR_REGION `
  --query 'AvailabilityZones[?State==`available`].ZoneName' --output table
```

To find a candidate Canonical Ubuntu 24.04 x86_64 AMI in that region, filter for the Canonical publisher ID and verify the returned name, architecture, and date before using the ID:

```powershell
aws ec2 describe-images --region YOUR_REGION --owners 099720109477 `
  --filters 'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' `
            'Name=state,Values=available' `
            'Name=architecture,Values=x86_64' `
  --query 'Images | sort_by(@, &CreationDate)[-1].[ImageId,Name,CreationDate]' --output table
```

The AMI must include a working SSM agent. The helper validates the AMI ID format but does not verify its publisher, availability, or SSM behavior.

For a public repository, retrieve the numeric IDs from its API response:

```powershell
$repository = Invoke-RestMethod 'https://api.github.com/repos/OWNER/REPOSITORY'
$repository.id
$repository.owner.id
```

Use the first value for `github_repository_id` and the second for
`github_repository_owner_id`. These immutable IDs keep the AWS OIDC subject
scoped to the exact repository and `main`; the repository slug alone is not
used as a broad trust condition. Inspect
`aws iam list-open-id-connect-providers --profile YOUR_PROFILE` before deciding
whether to create or reuse the account's GitHub provider. Do not create a
duplicate provider.

## Configure a fresh clone

From the repository root in PowerShell:

```powershell
Copy-Item prerequisites\project-config.example.json prerequisites\project-config.json
notepad prerequisites\project-config.json
```

Edit every account-specific value:

| JSON key | Value |
|---|---|
| `aws_account_id` | The 12-digit account verified with `sts get-caller-identity` |
| `aws_region`, `availability_zone` | A supported region and an available AZ in it |
| `project_name` | A unique lowercase 3–32 character prefix, beginning with a letter |
| `instance_type` | One of the supported types listed above; review capacity and cost |
| `ami_id` | Verified Canonical Ubuntu 24.04 x86_64 AMI ID |
| `root_volume_gib` | Integer 20–100; default example is 30 GiB |
| `state_bucket_name`, `backup_bucket_name` | Distinct, globally unique lowercase S3 names |
| `notification_email` | An address you control |
| `teardown_after_utc` | A future UTC RFC3339 timestamp; the tag does not automate teardown |
| `github_repository` | Public `owner/repository` slug |
| `github_repository_owner_id`, `github_repository_id` | Numeric immutable IDs from GitHub |
| `create_github_oidc_provider` | `true` only after confirming the provider is absent and approving its creation |
| `existing_github_oidc_provider_arn` | `null` when creating a verified-absent provider; otherwise the exact existing ARN and set `create_github_oidc_provider` to `false` |

The example deliberately contains fake account/AMI/bucket/identity values and will fail validation until replaced. Exactly one OIDC provider option must be selected. The helper does not contact AWS or GitHub to verify supplied values.

Run the local generator and inspect its changes:

```powershell
python prerequisites\configure.py
python -m unittest discover -s prerequisites -p "test_configure.py" -v
git diff --check
git diff
```

The helper writes ignored `terraform.tfvars` files and `backend.hcl`, and updates the tracked Argo repository URLs, ECR image repository, region, account, project host tag, and SNS topic settings. The private `prerequisites\project-config.json`, Terraform inputs, backend file, and state are ignored by Git. Never force-add them. The generator is local-only; it does not call AWS, GitHub, or any third party.

Review the diff carefully, then commit and push the rendered public-repository and account-specific runtime settings in your fork. Do **not** commit the private config JSON, generated `.tfvars`, backend configuration, Terraform state, or credentials.

## Validate locally before provisioning

From the repository root:

```powershell
terraform fmt -check -recursive platform\terraform
terraform -chdir=platform\terraform\bootstrap init -backend=false -input=false
terraform -chdir=platform\terraform\bootstrap validate
terraform -chdir=platform\terraform\bootstrap test
terraform -chdir=platform\terraform\environment init -backend=false -input=false
terraform -chdir=platform\terraform\environment validate
terraform -chdir=platform\terraform\environment test
```

These are local validation/mock-test commands; they do not provision resources. Provider downloads require network access. The mocked tests do not prove account capacity, IAM permissions, costs, or successful real deployment.

## Provisioning sequence

Provisioning is optional and billable. Review [the full Terraform gates and teardown details](../platform/terraform/README.md) before applying anything. Use the profile for the intended account and inspect each exact plan; never use a stale plan from another account.

1. Initialize and validate the bootstrap root. It uses local state and creates only the private, versioned state bucket:

   ```powershell
   terraform -chdir=platform\terraform\bootstrap init -input=false
   terraform -chdir=platform\terraform\bootstrap validate
   terraform -chdir=platform\terraform\bootstrap plan -out=bootstrap.tfplan
   terraform -chdir=platform\terraform\bootstrap show -no-color bootstrap.tfplan
   ```

   Inspect the account, bucket name, encryption, versioning, public-access block, policy, and cost. Apply only after approving that exact plan:

   ```powershell
   terraform -chdir=platform\terraform\bootstrap apply bootstrap.tfplan
   ```

   Keep the bootstrap root's local state and backup secure and available until backend teardown is complete.

2. Initialize the environment with the generated S3 backend configuration, then review and apply its saved plan only after separate cost/resource approval:

   ```powershell
   terraform -chdir=platform\terraform\environment init -backend-config=backend.hcl
   terraform -chdir=platform\terraform\environment validate
   terraform -chdir=platform\terraform\environment plan -out=environment.tfplan
   terraform -chdir=platform\terraform\environment show -no-color environment.tfplan
   ```

   The environment creates the VPC/EC2 host, IAM roles, ECR repository, backup bucket, SNS notifications, and a host status alarm. It does not create a NAT Gateway, public ingress, SSH access, EKS, RDS, or an account-level spending cap. Inspect every resource and destruction/retention effect before apply.

3. Confirm the host is online in Systems Manager, verify cloud-init/bootstrap health, and confirm the SNS subscription. See [host operations](../platform/bootstrap/README.md), [monitoring](../platform/monitoring/README.md), and [backup setup](../platform/backup/README.md). On Windows, the backup deployment script uses `$env:AWS_PROFILE` when set; otherwise it uses the AWS CLI's default profile.

4. In GitHub repository **Settings → Secrets and variables → Actions → Variables**, set the non-secret variables below from the approved account/configuration and Terraform outputs:

   | Variable | Source |
   |---|---|
   | `AWS_ACCOUNT_ID` | `aws_account_id` |
   | `AWS_REGION` | `aws_region` |
   | `AWS_PUBLISH_ROLE_ARN` | `terraform output -raw github_image_publisher_role_arn` |
   | `ECR_REPOSITORY` | `terraform output -raw ecr_repository_name` |

   These workflows use GitHub OIDC and short-lived AWS credentials; do not add static AWS access keys as GitHub secrets. Enable the repository permission for Actions to create pull requests.

5. The chart starts with an all-zero placeholder image digest so it cannot silently reference another operator's ECR image. Make and merge a meaningful application change on a feature branch after the AWS variables and OIDC role are configured. Its successful `Application CI` run triggers the release workflow, which builds and scans the image, publishes it, and opens a digest-pinned deployment PR. Review and merge that PR; Argo CD may report the application unhealthy until a real digest exists in this account's ECR. The manual ECR smoke workflow is optional and is for registry/credential-provider checks, not the normal scanned release.

6. Verify the application through a private Systems Manager tunnel rather than opening public ingress. See [delivery operations](../platform/delivery/README.md) and [validation evidence](../docs/08-validation-and-evidence.md).

## Teardown and data retention

Teardown is not automatic. Before destroying anything, decide what database data, image artifacts, and Terraform state must be retained. Stop scheduled backup jobs and deployments first, confirm account and backend, make/verify any required off-host data copy, create a fresh destroy plan, and inspect its exact resource list. Preserve unrelated/pre-existing resources.

Destroy the environment through Terraform and keep its remote state until the environment destroy succeeds. The versioned state bucket has `force_destroy = false`; state versions and lock-file history require a separate, explicitly reviewed retirement step after the environment is gone. Retain the bootstrap root's local state until the bucket is successfully retired. Do not use blanket deletion, `terraform state rm`, force flags, old plans, or broad AWS cleanup commands to bypass protection.

Check EC2 instances/volumes, S3 buckets and object versions, ECR images, Elastic IPs, snapshots, alarms, and delayed cost reporting after teardown. See [cost and cleanup](../docs/07-cost-and-cleanup.md) and the [Terraform runbook](../platform/terraform/README.md). Never delete resources merely because they share an account, region, or project-like name.

## Troubleshooting

- **Configuration helper rejects inputs:** compare JSON keys with the example, use the actual account/repository IDs, choose an AZ in the selected region, and verify unique bucket names.
- **Terraform rejects the account:** stop and check the active AWS profile/account; do not remove the `allowed_account_ids` guard.
- **OIDC assume-role fails:** verify the GitHub owner/repository numeric IDs, `main` branch, AWS provider ARN, Actions `id-token: write` permission, and the four repository Actions variables.
- **Host does not become ready:** use Systems Manager and review cloud-init logs, Ubuntu/SSM support, outbound access, instance capacity, and the AMI/region match.
- **Image pull fails:** check the ECR repository variable, image digest, immutable image presence, host role, and K3s ECR credential-provider logs.
- **Argo CD cannot load Git:** confirm the repository is public and the rendered URL and target revision match `main`.

Do not paste AWS credentials, state contents, admin passwords, notification tokens, or private logs into issues or public discussions.
