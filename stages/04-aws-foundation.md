# Stage 04 - AWS foundation

[Stage index](README.md) | [Previous](03-containers-and-ci.md) | [Next](05-k3s-and-argocd.md)

Status: Complete (2026-10-30). All 29 Terraform resources are in remote state, and a fresh plan reports no drift. The m7i-flex.large host is running (launched 2026-10-30 12:42 UTC); SSM Run Command succeeded, its security group has zero inbound rules, and the alarm is OK. The SNS policy, $10 monthly budget, ECR, and backup safeguards are verified. The corrected SNS subscription is confirmed, and the user received the one-time SNS test message. One stale unconfirmed request from the earlier address typo remains; it cannot receive topic notifications unless confirmed.

## Entry conditions

Stages 01 and 03 are complete; PR #1 is merged. The user approved provisioning using the non-root project profile in us-east-1 / us-east-1c and accepted the possibility of exceeding the $10 gross usage boundary. AWS Free Tier eligibility/credits remain estimates, not a cost cap.

## Goal

Create the minimum AWS foundation through reviewed Terraform, with cost and identity controls.

## Work checklist

- [x] Prepare preliminary us-east-1 pricing estimate and identify free-tier uncertainty.
- [x] Select 30 GiB gp3, us-east-1c, and one public IPv4; AWS rejected t3.medium and the m7i-flex.large replacement is running.
- [x] Create and verify encrypted, versioned, private state bucket.
- [x] Initialize environment S3 backend and test isolated state read/write plus lock contention; remove test artifacts.
- [x] Implement and locally validate Terraform for network, host, IAM, ECR, backup S3, budget, notifications, and alarm.
- [x] Limit planned GitHub OIDC trust to the approved repository's main branch and project ECR publishing.
- [x] Record $10 monthly account-wide alert, $10 total project usage boundary, notification email, updated cleanup deadline, and full project cleanup request.
- [x] User-reported AWS console confirmation that planned services need no Free-plan upgrade; account API shows $138.35 credits, but credits/alerts do not cap usage.
- [x] Document the retirement sequence: preserve state through environment deletion, handle versioned backups separately, and remove the state bucket last. Actual deletion requires a fresh reviewed plan and approval.
- [x] Select m7i-flex.large (AWS reports Free Tier-eligible, 8 GiB); actual cost and workload capacity remain estimates, not guarantees.
- [x] Replace the rejected SNS wildcard with explicit supported actions and test the policy plus m7i-flex credit behavior with six isolated mocked tests.
- [x] Apply the approved three-create recovery plan; AWS created the EC2 host and alarm.
- [x] Verify the running host, SSM agent Online, zero inbound security-group rules, and alarm state OK.
- [x] Apply a separately approved policy-only plan using explicit SNS actions after AWS rejected wildcard-action policies.
- [x] Verify the applied SNS policy, $10 monthly budget, immutable/encrypted ECR with lifecycle policy, and encrypted/versioned/private HTTPS-only backup bucket.
- [x] Correct the private notification address after the user identified a typo; apply the reviewed SNS subscription replacement and budget-recipient update.
- [x] Confirm the corrected SNS subscription; one stale pending request remains.
- [x] Confirm receipt of the SNS test message; SSM Run Command connectivity and the alarm's SNS target are verified.
- [x] Record live acceptance evidence, host launch time, cleanup owner, and deadline.

## Local implementation progress

- [x] Download project-local Terraform 1.17.1 and verify official published archive checksum; no PATH/global changes.
- [x] Create Stage 04 feature branch from merged main.
- [x] Implement bootstrap/environment Terraform configuration and pinned provider locks.
- [x] Implement account/region guards and restricted network, identity, storage, and notification configuration.
- [x] Validate both roots and execute six mocked plan tests.
- [x] Document safe local commands, AWS gates, existing-account collision checks, and retained-resource teardown limits.

These local checks do not complete the cloud work checklist above. See [local results](../docs/12-stage04-local-results.md) and [Terraform operator guide](../platform/terraform/README.md).

## Cost and lifecycle notes

The selected profile authenticates as a non-root IAM user. AWS reports an
active Free plan with $138.35 credits and expiry 2027-04-22. The user confirmed
in the console that no plan upgrade is required for the selected services.
The user set a $10 gross project usage boundary before credits, a $10 monthly
account-wide alert, and a manual cleanup deadline of 2026-11-01 21:00 IST.
Neither credits nor alerts are a spending cap. The notification email is stored
only in the ignored private variables file.

The t3.medium launch was rejected. The user selected m7i-flex.large and
explicitly accepted the possibility that total gross usage may exceed $10 for
the approved recovery. Its estimated 51-hour core usage is about $5.34; the
running host began accruing costs at 2026-10-30 12:42 UTC. All 29 resources are
applied and verified. The corrected private notification input is applied to
the SNS subscription and budget. The corrected subscription is confirmed, and
the user received the test message. One stale request remains pending from the
typo but cannot receive notifications unless confirmed. Stage 5 has not begun.
See the [preliminary estimate](../docs/07-cost-and-cleanup.md#preliminary-weekend-estimate)
and [full retirement sequence](../docs/07-cost-and-cleanup.md#full-project-retirement-sequence).
Do not upgrade the account plan or reuse an earlier saved plan. Keep the
running host within the approved cleanup deadline. The $10 alert is not a cap;
measure actual charges after billing data updates.

## Post-acceptance follow-up

- [ ] Measure final charges and complete separately approved cleanup by the agreed deadline. A Terraform tag or budget alert does not stop or delete resources automatically.

## Work location

[Terraform directory](../platform/terraform/README.md).

## Exit checks

- [x] Local formatting/validation and six isolated mocked tests pass; isolated state access and lock contention pass.
- [x] Reviewed policy-only plan is explicitly approved and applied successfully.
- [x] Systems Manager Run Command access works without opening public SSH.
- [x] No public database, Kubernetes API, or dashboard ports are allowed; live host security group has zero ingress rules.
- [x] No EKS, RDS, AWS load balancer, or NAT Gateway is managed by this project.
- [x] ECR/S3 safeguards, SNS policy, corrected subscription, and test-message receipt are verified.
- [x] Cost start time, live acceptance evidence, and cleanup owner/deadline are recorded.

Full rebuild proof (AWS-01) waits for Stage 08; access checks contribute to AWS-02.

## Cost and approval gate

Billable resources begin here. Stop, tear down, or explicitly approve continued runtime if the next stage is delayed. Review results before Stage 05.
