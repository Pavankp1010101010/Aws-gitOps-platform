# Terraform infrastructure

[Project overview](../../README.md) | [Stage 04](../../stages/04-aws-foundation.md) | [Local results and approval gates](../../docs/12-stage04-local-results.md)

Status: Stage 04 infrastructure is complete: configuration and six isolated mocked tests pass, all 29 resources are applied with no Terraform drift, and live S3 protections are verified. The m7i-flex.large host is running, SSM Run Command succeeded, the EC2 alarm is OK, and the SNS policy uses explicit actions. Budget/ECR/backup safeguards were verified. The corrected SNS subscription is confirmed and the user received a test message; one stale unconfirmed request remains from the earlier address typo. Cost monitoring and cleanup remain due by the agreed deadline.

## Layout

```text
terraform/
|-- bootstrap/
|   |-- versions.tf              Pinned CLI/provider and account guard
|   |-- main.tf                  Private encrypted versioned state bucket
|   |-- .terraform.lock.hcl       Provider checksums (commit this)
|   |-- terraform.tfvars.example  Synthetic input template
|   `-- tests/state.tftest.hcl    Mocked state-protection assertions
`-- environment/
    |-- versions.tf              Pinned CLI/provider, partial S3 backend
    |-- variables.tf             Explicit account, size, budget, identity decisions
    |-- main.tf                  Network, EC2, ECR, backups
    |-- identity.tf              Host and GitHub image-publication IAM
    |-- notifications.tf         Budget, SNS subscription, EC2 alarm
    |-- outputs.tf               Operational identifiers
    |-- .terraform.lock.hcl       Provider checksums (commit this)
    |-- backend.hcl.example       Non-secret backend template
    |-- terraform.tfvars.example  Synthetic values, not deployment approval
    `-- tests/foundation.tftest.hcl
```

Terraform 1.17.1 and AWS provider 6.71.0 are pinned. The approved local Terraform executable is in ignored `.cache/tools/terraform/1.17.1` at the project root. It is not installed globally and PATH is unchanged.

## Safe local validation (no AWS)

From PowerShell:

```powershell
Set-Location -LiteralPath 'C:\Users\JGVC36\Documents\Personal\Project\aws-gitops-platform'
$tf = Join-Path (Get-Location) '.cache\tools\terraform\1.17.1\terraform.exe'
& $tf '-chdir=platform\terraform' fmt -check -recursive
& $tf '-chdir=platform\terraform\bootstrap' init -backend=false -input=false
& $tf '-chdir=platform\terraform\bootstrap' validate
& $tf '-chdir=platform\terraform\bootstrap' test
& $tf '-chdir=platform\terraform\environment' init -backend=false -input=false
& $tf '-chdir=platform\terraform\environment' validate
& $tf '-chdir=platform\terraform\environment' test
```

Run each command only after its predecessor succeeds. Provider downloads require network access. The test files declare `mock_provider "aws"` and use `command = plan`; they do not create real resources or evaluate account capacity.

Do not run a real `plan` or `apply` merely because mock tests passed. Account authorization, billing review, real inputs, and backend setup are separate prerequisites.

## Designed resources and limits

- One new project VPC/subnet/route path in `us-east-1`, preferred AZ `us-east-1c`.
- No existing/default VPC, security group, bucket, role, or instance is adopted.
- One x86 host: type is required with no default. T3 sizes use standard CPU credits; `m7i-flex.large` is non-burstable and omits T-series credit settings. AWS eligibility does not guarantee capacity or overall project costs.
- Encrypted gp3 root disk; size defaults to 30 GiB but requires allowance/capacity review.
- Standard CPU credits, not unlimited; sustained CPU can throttle.
- A public IPv4 for outbound connectivity; no inbound rules at all. No SSH key or public admin/app access.
- IMDSv2 and hop limit 1. These do not establish pod-level IAM isolation.
- Systems Manager instance permissions. The selected Ubuntu AMI must have a working SSM agent; no install script or agent verification is claimed in this stage.
- One immutable-tag ECR repository, encrypted storage, untagged-image lifecycle only.
- Separate encrypted/versioned private S3 backups. No automatic backup expiry; incomplete multipart uploads abort after seven days.
- Exact immutable owner/repository-ID and main-branch GitHub OIDC trust for image publication, not provisioning.
- Account-wide monthly USD budget notifications, SNS email subscription, EC2 status-check alarm.
- No EKS, RDS, AWS load balancer, NAT Gateway, Elastic IP, or private interface endpoint.

No database, K3s, Argo CD, ingress, or credentials are provisioned by this configuration. Host bootstrap is Stage 05.

## Existing-account collision checks

Before any real plan:

1. User supplies the approved project account/profile name. Do not edit shared AWS profiles or inspect credential values.
2. Read caller identity with explicit profile after approval; compare the account with `allowed_account_ids`.
3. Check project names, VPC CIDR overlap with intended connected networks, region/AZ availability, quotas, Ubuntu x86_64 AMI ownership, and instance capacity.
4. Inspect the account's GitHub OIDC provider. If it exists, set its ARN and keep `create_github_oidc_provider=false`. This references it without changing/importing it.
5. Only if the provider is verified absent and creation is approved, set `create_github_oidc_provider=true` and existing ARN null.
6. Do not import, replace, or delete an existing resource to resolve a name collision. Stop for approval and review a project name change.

The default OIDC inputs deliberately fail a real plan unless exactly one ownership choice is made. Terraform guards account/region mistakes but does not detect every overlap or authorization issue.

## Free-tier and cost gate

Free hours do not establish that the chosen instance, root disk, IPv4, ECR, S3, or alarms are free. Eligibility depends on the account's actual offer, remaining limits/credits, region, and instance type.

Before provisioning, obtain an official estimate and explicit approval of:

- Account/profile, region/AZ, verified AMI and instance size.
- Disk/IP and supporting-service costs, free allowances, and expected total runtime.
- A numeric budget alert threshold, notification email, teardown deadline, and calendar reminder.
- Limits of the host for application plus monitoring; a micro instance may be inadequate.

`monthly_budget_usd` has no default and zero is rejected. This is an alert threshold, not authorization to spend or a hard cap. The account-wide budget includes unrelated account spending, deliberately avoiding tag-activation assumptions. Stage 04 created and verified the $10 monthly budget and the host status-check alarm.

`TeardownAfter` is only a tag, not automated shutdown. Budget reporting/notifications are delayed and SNS email requires confirmation.

## State bootstrap and remote backend

This sequence is planned only and must be approved before execution:

1. Fill ignored bootstrap variable inputs using actual approved values, not examples.
2. Initialize the bootstrap root with its local backend, review/save the plan, and separately approve apply.
3. Verify the new bucket's encryption, versioning, public-access block, and TLS-only policy.
4. Securely retain the bootstrap root's local state and backup outside Git. They may contain sensitive metadata. Loss of that state complicates management of the retained bucket.
5. Copy `environment/backend.hcl.example` to ignored `backend.hcl`; fill the real bucket. Never embed credentials.
6. Initialize the environment's S3 backend with that file after approval. Keep `encrypt=true`, `use_lockfile=true`, and the dedicated environment key.
7. Grant the operator state read/write plus lock-object read/write/delete permissions for that key. Do not grant the host or image-publication role access to Terraform state.
8. Test lock behavior with controlled concurrent operations before claiming it works.

Only the environment's state is configured for S3 in this baseline. The bootstrap root intentionally starts with protected local state; moving that state remotely requires a separate reviewed backend migration and distinct key, not casual copying or overwriting.

Use explicit session-scoped `AWS_PROFILE` only after approval. No profile value is hardcoded in provider/backend configuration.

## Apply and acceptance gate

After authorized AWS checks, backend setup, and real-input review:

1. Produce a saved plan; inspect resources, account, IAM trust, budget, public IP, and destruction/retention effects.
2. Obtain approval for that exact plan before apply. A sample tfvars file is not approval.
3. Confirm SNS email subscription; test notifications separately from alarm creation.
4. Verify SSM online/session access and restricted network exposure.
5. Verify least-privilege ECR/S3 access, account guard, state access, and locking.
6. Record resource runtime/cost start and reviewed teardown reminder.

IAM role presence does not prove SSM, registry refresh, or backups work. Those require live verification, and K3s image authentication is Stage 05.

## Retention and teardown

- State and backup buckets have `prevent_destroy`; nonempty ECR has `force_delete=false`.
- Full environment destroy is intentionally blocked by the protected backup bucket. Do not assume one destroy command cleans everything.
- Before stopping/destroying compute, preserve needed data and confirm the exact environment and state.
- For teardown, explicitly design retained-resource management/handoff first. A separate reviewed retirement procedure must handle protection changes, retained bucket resources/state, versions, and image contents. Do not use blanket targeting, state removal, force flags, or bucket emptying to bypass the gate.
- The root disk is deleted with instance termination. It is not a durable backup.
- State/backups/image storage can incur charges after compute is stopped.

See the proposed [full retirement sequence](../../docs/07-cost-and-cleanup.md#full-project-retirement-sequence). It preserves the remote backend until environment destruction succeeds, then retires the backend using local bootstrap state. No destruction, data emptying or protection changes are authorized by preparation alone.
