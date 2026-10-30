# Stage 04 - Local foundation results

[Project overview](../README.md) | [Stage 04 checklist](../stages/04-aws-foundation.md) | [Terraform guide](../platform/terraform/README.md)

Date: 2026-10-30. Stage 04 is complete.

## Approved scope and boundaries

- User confirmed PR #1 was merged; GitHub API verified merge commit `413e16b0e94bc90395ea0d847b9a609d5b6826d4`.
- Created local branch `stage04/aws-foundation` from merged `origin/main`, after verifying a clean worktree.
- User approved project-local Terraform/provider downloads and local implementation/validation.
- Region confirmed: `us-east-1`; preferred Availability Zone: `us-east-1c`.
- Initially the AWS profile was deferred. Subsequently the user approved identity, inventory, and pricing/compatibility reads; see the read-only preparation below. Credential-file contents were not accessed.
- User approved the reviewed state-bucket bootstrap apply only. Environment provisioning remains separately gated by credit/feature review and plan approval.
- No Stage 04 commit or upload was performed. Bootstrap plan/apply and environment backend initialization evidence are recorded below.

## Local tooling

| Item | Evidence |
|---|---|
| Terraform | 1.17.1 Windows AMD64, official HashiCorp release |
| Archive SHA256 | `a3b71365cff94c0f978cf75d86addb075ea1bb6409055ea0ab359bf057d7898a` |
| Integrity check | Archive matched the checksum downloaded from the official release site over HTTPS; no separate GPG-signature verification was performed |
| Install location | Ignored project `.cache/tools/terraform/1.17.1`; no global installation or PATH change |
| AWS provider | Pinned 6.71.0; Terraform reported it signed by HashiCorp during initialization |
| Provider locks | Generated for both roots; intended for version control |

Sources: [Terraform release](https://releases.hashicorp.com/terraform/1.17.1/) and [AWS provider registry](https://registry.terraform.io/providers/hashicorp/aws/6.71.0).

## Implemented local configuration

- Separate state-bucket bootstrap and environment roots.
- Region/account guards; explicit instance size, AMI, alert budget, and teardown inputs.
- Project VPC/subnet/routing, no inbound security-group access.
- Encrypted EC2 root storage, IMDSv2, standard CPU credits, SSM instance role.
- Immutable ECR and protected private encrypted/versioned backups.
- Restricted GitHub image-publisher role with explicit existing/new OIDC ownership.
- Account-wide budget alerts, SNS email, and an EC2 status-check alarm.
- Private backend input file ignored, sanitized examples, operator guide and retention limitations.

## Executed local checks

| Check | Result |
|---|---|
| CLI runs from project-local path | Passed |
| Provider initialization with `-backend=false` | Passed for both roots |
| Bootstrap `terraform validate` | Passed |
| Environment `terraform validate` | Passed |
| Bootstrap mock test | 1 passed |
| Environment mock tests | 4 passed |
| Final recursive formatting check | Passed |
| Documentation navigation | 151 relative links resolved |
| Ignore assertions | 5 private/generated paths excluded; 4 examples/provider locks remain publishable |
| Git diff integrity | Passed; changes remain local and uncommitted on the Stage 04 branch |

The tests use only the mocked AWS provider and plan-mode assertions. They do not prove AWS pricing, eligibility, IAM authorization, backend locking, live infrastructure, SSM sessions, email delivery, or host capacity.

## Pending before any AWS provisioning

1. Non-root profile identity verification is complete; temporary credentials, effective permissions and MFA enforcement are not established by STS identity output alone.
2. Verify actual credit terms, remaining allowances, and eligibility for the proposed host/disk/IP/services and account feature availability.
3. Approve host/AMI selection and complete the supporting-service quantities behind the preliminary regional estimate.
4. Obtain numeric alert budget, runtime/deadline, recipient email, retention decisions, and provisioning approval.
5. Inspect existing names/OIDC provider and account quotas without modifying shared resources.
6. Bootstrap state storage, initialize environment backend, and review actual Terraform plans in separate approved steps.
7. Apply only an approved plan; perform live Stage 04 acceptance checks and save evidence.

## Approved read-only preparation

- STS identity checks first identified root access; a subsequently configured
  project profile successfully authenticated as an IAM user. Full account
  identifiers and credential material are not recorded here.
- User approved regional inventory and account-wide S3 bucket-name/OIDC-provider
  listing. Existing resources remain untouched; no OIDC provider was found.
  The discovered default VPC does not overlap the proposed project network.
- User selected a weekend demonstration with reviewed cleanup and reported a
  Free account plan with available credits. No account-plan upgrade is approved.
- AWS Pricing GetProducts returned Linux shared-tenancy On-Demand hourly rates
  of $0.0416 for t3.medium and $0.0832 for t3.large, and $0.08/GB-month for gp3.
- EC2 reports 4 GiB and 8 GiB memory respectively, both x86_64, with
  `FreeTierEligible=false`. Both have offerings in us-east-1c; this is not a
  launch capacity reservation or a test of account credit eligibility.
- Canonical owner `099720109477` returned Ubuntu 24.04 x86_64 EBS images.
  Latest returned candidate: `ami-0d6dd9e8265d48906`, named
  `ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20261023`.
  This is metadata verification only; SSM agent operation still needs validation.
- The initial pricing command failed local CLI argument parsing; corrected
  argument grouping returned the rates above. No provisioning was attempted.
- See the [cost estimate](07-cost-and-cleanup.md#preliminary-weekend-estimate):
  t3.large with 30 GiB gp3 and one IPv4 address has a 48-hour core estimate of
  $4.3936 before credits/tax. The provisional $5-$7 total is not a hard cap or
  complete supporting-service quote.
- No real backend initialization, Terraform plan/apply, credential/profile
  modification, existing-resource cleanup, commit or upload was performed.

## Deployment preparation decisions

- User selected t3.medium instead of the recommended t3.large. Prepare for
  2 vCPU / 4 GiB RAM, 30 GiB gp3 and one public IPv4 address. The 48-hour
  core estimate is $2.3968 before credits/tax and supporting services.
  Complete-stack memory and CPU capacity remain untested; do not resize
  automatically if monitoring or other workloads do not fit.
- User confirmed $8 total project usage before credits, including retained
  resources, and an $8 monthly account-wide budget alert. Neither budget alerts
  nor the teardown tag enforce a hard spending cap.
- Planned start: 2026-10-31 12:00 IST (2026-10-31T06:30:00Z).
  Cleanup deadline: 2026-11-02 12:00 IST (2026-11-02T06:30:00Z), or earlier
  on user request. No scheduler exists; an operator must execute cleanup.
  Do not start the host before the planned deployment session.
- The latest cleanup instruction is to remove everything created for this
  project, not pre-existing resources. Earlier temporary state/backup retention
  must not be interpreted as indefinite retention. Exact retirement sequencing
  and any temporary retention/review date remain to be agreed before apply.
  Bucket protections currently block full destroy intentionally; do not bypass
  them without a reviewed retirement procedure.
- These are preparation decisions, not approval of a Terraform apply.

## Approved state-bootstrap plan

- User explicitly approved bootstrap local-backend initialization, identity and
  candidate bucket-name availability checks, and a real saved Terraform plan.
- Verified the profile is non-root again, then used process-scoped profile and
  account variables. No shared profile or credential file was edited.
- A randomly suffixed `agtp-demo-state-...` candidate returned HTTP 404 from
  HeadBucket. This is not a reservation or guarantee against a later collision.
- Local bootstrap initialization succeeded. Saved ignored plan:
  `platform/terraform/bootstrap/stage04-bootstrap.tfplan`.
- SHA256: `C5E7AE2B7D57C9C1C596767885E916309B6C680B0D0522C527C1474BBAE08CF3`.
- Plan has five creates: state bucket, versioning, AES256 encryption,
  public-access block and bucket policy. No changes or deletions are planned.
- Inspected saved-plan values confirm versioning, AES256, all four public-access
  blocks and `force_destroy=false`. Source also has `prevent_destroy=true`.
  Policy JSON remains unknown until apply because it uses the new bucket ARN;
  the TLS-only source policy was reviewed, but live policy checks are pending.
- Two initial invocations failed CLI argument parsing; quoted Terraform
  arguments fixed the issue. No apply was attempted.
- This creates only state storage if separately approved. It does not create
  EC2, the environment backend or the rest of the platform. Saved plans contain
  private metadata and remain excluded from Git. Re-plan if inputs/configuration
  change or the plan is stale before applying.
- After reviewing the summary, the user instructed proceeding with the next
  step, authorizing this state-bucket apply only.

## Executed state-bootstrap apply

- On 2026-10-29, rechecked the saved plan SHA256 above and the same-account,
  non-root identity before applying the exact saved plan.
- Apply succeeded: five added, zero changed, zero destroyed. This is one new
  project state bucket and four configuration resources, not five buckets.
- Live S3 API checks passed: us-east-1, versioning enabled, AES256 encryption,
  all four public-access blocks enabled, non-public policy status and the
  deny-insecure-transport statement.
- Local bootstrap state contains the five expected resource addresses.
  State, backup-state filename and saved plan are excluded from Git.
  Local state must be securely retained; no remote migration or external
  recovery copy of bootstrap state is claimed.
- S3 requests/storage can now consume credits. No EC2, environment resources,
  budget or alarm were created. Existing AWS resources remain untouched.
- Environment backend initialization/locking tests and the environment
  plan/apply are still pending. The applied bootstrap plan is historical
  evidence, not a plan to apply again.


## Environment backend initialization

- User instructed proceeding after the state-bootstrap completion summary.
- Verified no environment backend input, tfvars or local state files existed
  before creating ignored `environment/backend.hcl`; no file was overwritten.
- Rechecked non-root identity against the bootstrap plan's approved account.
- Environment `init -reconfigure -backend-config=backend.hcl -input=false`
  succeeded with process-scoped profile selection, S3 encryption and native
  lockfile configuration. No state migration was performed.
- `terraform validate` passed and the selected workspace is `default`.
- Backend initialization does not prove state write/delete access or concurrent
  locking. Those checks remain pending before claiming remote-state acceptance.
- No environment plan/apply or EC2 creation was performed. A private notification
  recipient and explicit new-OIDC-provider choice are still required for inputs.

## Reviewed environment plan

- User approved private input preparation, project collision/quota reads,
  temporary S3 locking and a real environment plan, but not apply.
- Saved the supplied notification email in ignored `terraform.tfvars`, along
  with selected sizing, AMI, region/AZ, $8 alert and UTC cleanup deadline.
  Account ID was supplied through the planning process environment.
- Rechecked GitHub OIDC absence and project IAM role/profile, ECR, budget and
  SNS names: no conflicts found. User authorized planning a new OIDC provider
  only if absent. Existing account resources remain untouched.
- Standard On-Demand EC2 quota returned eight vCPUs; no running/pending
  instances were found. This is not a reservation or guarantee of launch
  capacity or Free-plan feature availability.
- A randomly suffixed project backup-bucket candidate returned HTTP 404;
  the name is not reserved until creation.
- Environment plan succeeded with native S3 locking enabled:
  29 additions, zero changes, zero deletions.
  Saved ignored plan: `platform/terraform/environment/stage04-environment.tfplan`.
- SHA256: `BBE50C321239FFE08EA9061173C78858D080CFD98390301A5D31727C8F836B56`.
- Actual saved-plan assertions passed for t3.medium, selected Ubuntu AMI,
  30 GiB encrypted/deleted-on-termination disk, standard CPU credits, IMDSv2,
  no security-group ingress, isolated VPC, preferred AZ, $8 budget and
  2026-11-02T06:30:00Z cleanup tag. ECR immutability and bucket/registry
  deletion guards were also checked.
- No EKS, RDS, AWS load balancer, NAT gateway or Elastic IP is in the plan.
  The host still has one auto-assigned public IPv4 for outbound access.
- The publisher's source trust remains exact repository/main and audience,
  with ECR publication permissions only; full policies referencing new ARNs
  contain apply-time unknowns and need live verification after approved apply.
- The plan completed and a subsequent HeadObject returned 404 for the current
  lock object. Concurrent contention and state-object write permissions remain
  untested; no manual lock deletion or force-unlock was performed.
- No environment apply, EC2 creation, GitHub workflow AWS authentication,
  commit or upload occurred. Credit coverage, retirement sequencing, SSM agent
  operation and final apply approval remain outstanding. Re-plan/review before
  the weekend if inputs, configuration or account conditions change.

## Remote-state write and contention acceptance

- User explicitly approved an isolated built-in `terraform_data` probe using a
  unique `validation/<random>/terraform.tfstate` key in the project state bucket,
  including cleanup of only that test key's versions and lock artifacts.
- Initial child-process launch was interrupted before successful creation;
  it was not treated as a pass. Managed execution sessions subsequently ran
  the isolated apply successfully.
- Observed the native S3 lock during a 30-second local sleep. A competing real
  Terraform plan failed specifically with `Error acquiring the state lock`.
- The first apply completed successfully. A remote `state pull` verified exactly
  one built-in `terraform_data` resource, proving state write/read for this
  operator on the test key. No EC2 or other environment infrastructure was used.
- Destroyed the isolated resource and verified empty state and no current lock.
  Removed ten exact test state/lock versions and delete markers, then verified
  zero versions/markers remained at that unique prefix.
- Environment plan SHA256 remained unchanged. Test-key permissions do not prove
  future users have access, or rule out key-specific policies on production
  state; the environment plan itself already exercised production-key locking.
- Documented the proposed [full retirement sequence](07-cost-and-cleanup.md#full-project-retirement-sequence).
  Destructive bucket emptying, removal of lifecycle protections and final destroy
  still require separate review/approval at cleanup time.
- Account-specific credit/feature eligibility and final environment apply
  approval remain pending. No environment apply is authorized by these tests.

## Updated Free-plan check and deployment-today preparation

- On 2026-10-30, the user asked to prepare to deploy today, while acknowledging
  that Free-plan eligibility and refreshed-plan review still gate apply.
- With separate approval, AWS `GetAccountPlanState` reported plan type FREE,
  status ACTIVE, $138.35 USD remaining credits, expiration 2027-04-22, and the
  Free Tier usage API returned eight Always Free usage items. The usage list
  contained no EC2 item. This is a usage snapshot, not an assurance that every
  planned service/feature is allowed or credit-eligible, and not a spending cap.
- Refreshed the environment plan using the non-root project profile and
  process-scoped account ID. The plan was create-only with 29 additions, zero
  changes, zero deletions, including one t3.medium host. The refreshed saved
  plan is `platform/terraform/environment/stage04-environment-20261030.tfplan`.
- Refreshed-plan SHA256:
  `2023BF3A495D20ABBD9D4A61AEF75AD013366FB1F3DE541661F0F4319E40A696`.
  Security-group planned ingress is empty; environment S3 lock was absent after
  planning. The file is ignored and not published.
- A local PowerShell validation initially used the reserved `$Host` variable
  name and stopped after plan generation; a subsequent corrected validation
  passed and inspected the plan without exposing the notification email.
- Free-plan service/feature eligibility and credit application to the planned
  EC2/other service usage remain unverified. No environment apply or EC2 start
  is authorized by refreshing the plan. Apply requires a separate explicit
  approval of this exact current plan and all remaining cost/eligibility gates.

## Revised deployment limits and plan

- The user confirmed the AWS Console showed no upgrade required for the planned
  services/features. This is a user-reported eligibility check; AWS API usage
  data alone does not establish service coverage or credit treatment.
- User revised the monthly account-wide alert to $10 and the project gross
  usage boundary to $10 before credits. An alert is not a hard cap and includes
  unrelated account usage.
- User set the cleanup deadline to 2026-11-01 21:00 IST
  (2026-11-01T15:30:00Z) and authorized beginning Stage 5 after Stage 4;
  Stage 5 work has not started. The project is still to stop/clean up by this
  deadline, even if later stages are unfinished.
- Updated only ignored private inputs for the $10 monthly alert and deadline,
  then generated a new create-only plan:
  `platform/terraform/environment/stage04-environment-20261030-revised.tfplan`.
- Revised plan: 29 additions, zero changes, zero deletions; one t3.medium EC2
  instance; planned budget amount $10; cleanup tag 2026-11-01T15:30:00Z.
- SHA256:
  `50B91F362EDBFB16B42512EF4C2B61176DCF456477CB45B225129905CAA42926`.
- This plan supersedes both earlier saved environment plans. It is ignored by
  Git and has not been applied. Previous apply approval was for a different
  plan and does not authorize applying this revised plan.
- Apply requires explicit approval of this exact hash and the revised cost /
  cleanup boundary. At the time this plan was generated, no AWS infrastructure
  beyond the state bucket had been created; no Stage 5 work had begun.

## Partial Stage 4 apply and Free-plan instance restriction

- On 2026-10-30, the user explicitly approved applying revised plan hash
  `50B91F362EDBFB16B42512EF4C2B61176DCF456477CB45B225129905CAA42926`.
- Terraform created 26 of 29 planned resources. The following three are absent
  from remote state: EC2 host, SNS topic policy, and EC2 status-check alarm.
- AWS rejected `t3.medium`: “The specified instance type is not eligible for
  Free Tier.” No EC2 instance was launched.
- AWS rejected the SNS policy's wildcard action on two attempts (`SNS:*` and
  `sns:*`). The topic's default policy was inspected read-only to determine its
  explicit supported actions; the corrected policy is recorded below.
- A read-only AWS query reports these x86_64 Free Tier-eligible choices in
  us-east-1c: t3.micro (1 GiB, $0.0104/hour), t3.small (2 GiB, $0.0208/hour),
  t8i.micro (1 GiB, $0.01248/hour), t8i.small (2 GiB, $0.02496/hour),
  c7i-flex.large (4 GiB, $0.08479/hour), and m7i-flex.large (8 GiB,
  $0.09576/hour). “Eligible” is AWS metadata, not a
  promise of sufficient capacity or overall project costs.
- The original t3.medium has 4 GiB but cannot be launched under this Free-plan
  restriction. 1-2 GiB candidates are unlikely to support the complete planned
  K3s/ArgoCD/monitoring stack; m7i-flex.large is the only listed 8 GiB choice.
  At that time, Terraform validation permitted only t3 sizes; the configuration
  was subsequently extended for m7i-flex.large with conditional T-series
  credit settings.
- Partial environment resources remained deployed at that point and no EC2
  host had launched. Later recovery results are recorded below.
- Do not retry or reuse any older saved plan. Any further apply requires a new
  plan and separate explicit approval.
- The policy now uses an explicit action list rather than a wildcard; the
  policy-only replacement plan is recorded below.
- Read-only SNS inspection reports the subscription is `PendingConfirmation`;
  the endpoint was not displayed. The user must confirm via the SNS email before
  relying on alert delivery.
- The user selected m7i-flex.large (8 GiB) for the replacement host. AWS
  reports it eligible and offered in us-east-1c. Its 51-hour core estimate for
  compute, one public IPv4 and 30 GiB gp3 is about $5.34 before supporting
  services/tax. The prior provisional total for t3.medium no longer applies;
  gross project usage could approach or exceed the $10 boundary.
- Corrected Terraform now permits m7i-flex.large and omits the T-series
  credit_specification block for non-burstable types. Tests run in an isolated
  backend-disabled copy passed: six passed, zero failed, including the SNS
  action prefix and m7i-flex credit configuration checks.
- Recovery plan `stage04-recovery-20261030.tfplan` contained three creates
  (EC2 host, SNS topic policy, alarm), 26 no-ops, and zero updates/deletions.
  The user approved it. AWS created the host and alarm but rejected the SNS
  policy; do not reuse this plan.
- Recovery-plan SHA256:
  `C19D9C1CEAFCE4B68E232E3AA12EF7B0AE3351B4CA6CC0A5D1F5E18234C589DA`.
  This is the fingerprint of the applied recovery plan, not authorization to
  repeat it or remove existing resources.
- The user has not received the SNS confirmation email. Subscription remains
  pending, so alert delivery is not yet verified.

## Current status after recovery apply

- On 2026-10-30, the user explicitly approved applying the recovery plan above
  and accepted that gross project usage could exceed $10.
- AWS launched the m7i-flex.large host at 2026-10-30 12:42:05 UTC. The host is
  running; Systems Manager reports `Online`; its security group has zero
  inbound rules. The CloudWatch status-check alarm exists, actions are enabled,
  and its observed state is `OK`.
- Terraform state now manages all 29 intended resources. The original
  three-create recovery plan partially succeeded; the separate, reviewed
  explicit-action plan then created the SNS topic policy successfully.
- AWS rejected two earlier policy attempts because they included a wildcard
  action (`SNS:*` and then `sns:*`). Case changes alone did not resolve it.
  Inspection of the topic's prior default policy showed eight explicit owner
  actions; the successful policy uses that exact action list and grants
  CloudWatch only `SNS:Publish`.
- The successful policy plan,
  `platform/terraform/environment/stage04-recovery-sns-actions-20261030.tfplan`,
  proposed one create, 28 no-ops, zero updates, and zero deletions. SHA256:
  `63143DB94738D845A0AF0A8E43BBD8EA3D31A077789B3C772A2FF33AE4F8E959`.
  The approved apply completed: one added, zero changed, zero destroyed.
- Live verification confirms the applied policy matches the explicit action
  list; the host is running, SSM reports `Online`, its security group has zero
  inbound rules, and the alarm is `OK` with actions enabled. The monthly $10
  budget is present. ECR is immutable/encrypted with its lifecycle policy; the
  backup bucket has versioning, AES256 encryption, all public-access blocks,
  an HTTPS-only policy, and is not public.
- Before the correction, SNS reported one pending subscription. The user
  identified a typo in the private notification address as the cause. The
  private input was corrected and the approved plan replaced the
  Terraform-managed SNS subscription and updated the budget notification
  recipient. The address is intentionally not recorded here.
- Email-correction plan
  `platform/terraform/environment/stage04-notification-email-correction-20261030.tfplan`
  proposes 1 add, 1 in-place change, and 1 delete: replace the old pending SNS
  subscription and update the budget email recipient. It makes no compute
  changes. SHA256:
  `4C199ACB85AE37C3E62310817A961CB6405A27D8056D123C7A3422972B0D3C64`.
  The plan output was reviewed with email values redacted; the approved apply
  completed with one add, one change, and one delete.
- The host is billable from its launch time. Its 51-hour core estimate is about
  $5.34 before supporting services/tax; total gross project use may exceed $10.
  The user-selected cleanup deadline is 2026-11-01 21:00 IST. The deadline tag
  and budget alert do not stop the host; keep runtime/cleanup visible.
- A non-mutating SSM Run Command (`/bin/true`) completed successfully. SSM
  connectivity is proven without installing the Session Manager plugin; an
  interactive session was not tested. After AWS confirmed the corrected SNS
  subscription, one direct SNS test message was published. The CloudWatch alarm
  target was verified, but no synthetic alarm-state transition was forced; user
  confirmation of message receipt remains pending.
- After the address correction, SNS reports one pending subscription, one
  confirmed, and one deleted. The Terraform-managed subscription for the
  corrected address is confirmed; one stale unconfirmed request from the typo
  remains. Endpoints were verified in memory and not displayed.
- The user confirmed receipt of the direct SNS test message. The CloudWatch
  alarm target was verified; no synthetic alarm-state transition was forced.
- A fresh Terraform plan reported no changes. The state contains all 29
  intended Stage 04 resources. A read-only resource check found no EKS, RDS,
  NAT Gateway, or load balancer resources managed by the project.
- Stage 04 is complete. Stage 05 has not started. The host remains billable;
  final charge measurement and separately approved cleanup are due by the
  agreed deadline. The stale pending request cannot receive topic notifications
  unless it is confirmed.

## Safety

No Docker workload, TimesTen file, global tool, shared AWS profile, default VPC, existing IAM provider, or GitHub protection setting was modified. HashiCorp artifacts/provider packages were downloaded publicly; project code/credentials were not uploaded.

Only the approved project state bucket and its protection configuration were created. This does not account for pre-existing account usage.
