# Cost and cleanup

[Back to project overview](../README.md)

## Cost model

The approved project state bucket and its protection configuration have been created and verified. Stage 04 deployed the environment foundation, including an m7i-flex.large host, ECR, backup bucket, notifications, and alarm. The current host, `i-01c6edc2d87a8be2d`, launched at 2026-10-31 12:07:36 UTC during the approved Stage 08 rebuild; earlier instances also accrued runtime charges before replacement. S3 requests/storage can also consume credits.

The user selected us-east-1 (preferred zone us-east-1c), approved the foundation and recovery, and set a manual cleanup deadline of 2026-11-01 21:00 IST. The non-root project profile has been verified against remote Terraform state. The active m7i-flex.large EC2 host runs the application, PostgreSQL, K3s, Argo CD, and monitoring. Work should reuse that host, avoid new managed services, and keep public ingress closed. Credits and budget alerts do not cap gross usage; unused EC2 hours do not establish eligibility for a larger host or cover storage, public-IP, and supporting charges.

| Resource | Potential charge |
|---|---|
| EC2 | Instance runtime |
| EBS | Provisioned storage, applicable performance charges |
| Public IPv4 | Allocated/in-use public address charges under current AWS terms |
| ECR | Stored images and applicable transfer/scanning features |
| S3 | State/backups, versions, requests, transfer |
| CloudWatch and SNS | Alarm, logging, metrics, and notification usage where applicable |
| Data transfer | Internet egress and other applicable paths |
| Snapshots | Retained backup storage if created |

Avoiding EKS, RDS, NAT Gateway, and load balancers removes those services' charges, not all AWS charges. Verify current regional prices and account eligibility using official AWS pricing before deployment.

## Preliminary weekend estimate

Checked 2026-10-29 using AWS Pricing GetProducts for Linux, shared-tenancy,
On-Demand EC2 without additional software in us-east-1, and gp3 storage.
The public [VPC pricing page](https://aws.amazon.com/vpc/pricing/) lists
$0.005 per public IPv4 address-hour.

| Component | Assumption | 48-hour cost before credits/tax |
|---|---|---|
| EC2, historical candidate | t3.large, 2 vCPU / 8 GiB, $0.0832/hour | $3.9936 |
| EC2, historical smaller candidate | t3.medium, 2 vCPU / 4 GiB, $0.0416/hour | $1.9968 |
| Root disk | 30 GiB gp3, $0.08/GB-month, 30-day month approximation | $0.16 |
| Public IPv4 | One auto-assigned address, $0.005/hour | $0.24 |
| Core subtotal, t3.large | Compute + disk + address | $4.3936 |
| Core subtotal, t3.medium | Compute + disk + address | $2.3968 |

AWS rejected t3.medium as ineligible for this Free plan; neither historical t3
estimate is the current host plan. On 2026-10-30, AWS reported m7i-flex.large
(2 vCPU / 8 GiB) as Free Tier eligible and offered in us-east-1c, at
$0.09576/hour. From the replacement host launch at 2026-10-31 12:07:36 UTC to
the chosen deadline, approximately 27.4 hours remain; compute, one public IPv4
and 30 GiB gp3 total about $2.85 before credits/tax. This is only the remaining
core estimate for the current host, not total project spend; it excludes
earlier host runtime, state/backups, ECR storage, data transfer, taxes, and
other supporting usage.
The c7i-flex.large alternative (2 vCPU / 4 GiB, $0.08479/hour) has a roughly
$4.26 core estimate for that window, but less memory headroom. Neither price is
a capacity reservation, complete quote, or spending cap.

The earlier $5-$7 weekend range was a rough t3-based planning estimate and is
superseded for the selected m7i-flex.large. The prior $4.76 estimate applied
to the host that was terminated during the approved rebuild. The current
$2.85 estimate is only the remaining core usage for the replacement host until
the chosen deadline, not a guaranteed maximum or total project estimate.
Previous host replacements, the state bucket, supporting services, taxes,
usage after the deadline, large transfers, snapshots, or paid options add
cost. The $10 project usage boundary could be exceeded. Review actual billing
after its reporting delay; credits reduce eligible net payment but do not
change gross usage.

AWS `GetAccountPlanState` reported an active Free plan with $138.35 remaining
credits on 2026-10-30. Its usage report contained no EC2 usage item. The user
reports the console confirmed no upgrade is required for the selected services,
but AWS specifically rejected t3.medium; only instance-level eligibility
metadata supported the replacement choice. Do not upgrade the account plan or
enable Organizations. Budget alerts do not stop spending, can be delayed, and
the current account-wide budget includes unrelated usage and may reflect credit
offsets.

Read-only inventory found an existing stopped instance, attached storage, two
unassociated Elastic IP allocations, a default VPC and an S3 bucket. Leave all
existing resources untouched. This was not an all-region audit. The proposed
10.77.0.0/16 network does not overlap the discovered 172.31.0.0/16 default VPC.

## Before provisioning

1. Choose a region and tag resources with project, owner, and environment.
2. Define acceptable spend and maximum demonstration runtime.
3. Estimate EC2, storage, IPv4, and supporting-service costs.
4. Configure budget notifications. Alerts are not a spending cap.
5. Record a teardown owner and reminder. The Terraform deadline tag is not an automated stop mechanism.
6. Review the Terraform plan for unexpected managed services.
7. Verify account free allowances or credits rather than assuming eligibility.

## Cleanup procedure

1. Capture redacted evidence and measured results.
2. Decide whether backups must be retained for later recovery tests.
3. Inspect the intended Terraform destroy plan.
4. Destroy only the explicitly selected project environment after reviewing retention handling. The current backup bucket has `prevent_destroy`, so a full destroy deliberately blocks until a separate reviewed retained-resource handoff/retirement procedure exists; do not bypass protections blindly.
5. Inspect the AWS account/region for remaining project resources.
6. Handle intentionally retained ECR images, S3 contents/versions, EBS volumes, snapshots, IP addresses, alarms, and notification resources.
7. Retain the state backend until managed infrastructure is accounted for.
8. If retiring the project completely, use a separate reviewed procedure to retire the backend and retained data.
9. Check cost reporting again after its reporting delay.

Do not configure destructive bucket cleanup just to make teardown succeed. State and backup retention must be an explicit decision.

### Full project retirement sequence

This is the proposed procedure for the user's full-cleanup request, not
authorization to delete resources now. Keep the existing account resources
outside every deletion scope.

1. Stop deployments, image publishing and database writes. Capture evidence and
   agree whether any data must be exported privately. Before irreversible
   deletion, explicitly confirm disposal of project backups and image contents.
2. Resolve the exact environment and bootstrap resource IDs from their states,
   verify the account/profile, and securely preserve both states outside Git.
   Never select buckets by a broad name prefix.
3. Inventory all versions, delete markers and incomplete multipart uploads in
   the exact project backup bucket, and all image digests in the exact project
   ECR repository. Review the inventory before deleting its contents.
   An S3 recursive object deletion alone does not remove all historical versions.
4. After separate approval, empty only those reviewed project data resources.
   Re-list to prove no versions, markers, multipart uploads or images remain.
   Keep `force_destroy=false` and ECR `force_delete=false`.
5. In a separately reviewed retirement change, remove only the backup bucket's
   `prevent_destroy` guard. Do not remove the bucket resource from configuration,
   discard its state, use blanket targeting, or enable force deletion.
6. Generate a fresh full environment destroy plan against remote state. Verify
   its deletions exactly match the project inventory, with no pre-existing
   resources, and obtain approval before applying that exact plan.
   The environment's backend bucket must still exist during this operation.
7. Verify the environment state has no managed resources and check for project
   leftovers, including disk volumes and auto-assigned public IP release.
   Do not delete the GitHub OIDC provider if another consumer has begun using it;
   stop for an explicit ownership/retention decision instead.
8. After successful environment retirement, preserve the final empty environment
   state privately. Inspect every version/marker and incomplete upload in the
   exact project state bucket. Confirm no other state/workspace or client
   depends on it and that no operation holds a lock.
9. With separate irreversible-deletion approval, empty that bucket, remove only
   the bootstrap bucket's `prevent_destroy` guard in a reviewed change, and
   generate/review/apply the bootstrap destroy plan using its local state.
   Keep local bootstrap state until deletion and final verification succeed.
10. Verify both inventories are retired, retain redacted evidence, and check
    delayed usage reporting. Restore normal source protections afterward and
    review local private-file retention separately; never publish state/plans.

If retirement is blocked, do not silently extend runtime past the deadline.
Notify the user and obtain approval for a narrowly scoped containment action
(such as stopping only the project instance) while storage and other remaining
costs are tracked. Stopping compute is not completion of cleanup.

## Cost record

| Deployment date | Region | Instance and disk | Start/end time | Estimated spend | Observed charge | Retained resources |
|---|---|---|---|---|---|---|
| State bootstrap applied 2026-10-29; environment applied 2026-10-30; host rebuilt 2026-10-31 | us-east-1 | 29 environment resources are managed; current m7i-flex.large host `i-01c6edc2d87a8be2d` launched at 12:07:36Z with an encrypted 30-GiB gp3 root disk. Earlier host replacements also accrued runtime. | User-selected deadline: 2026-11-01 21:00 IST; manual cleanup, even if later stages are unfinished | Replacement-host core usage from launch to deadline is estimated at $2.85 before credits/tax; total project usage may exceed the $10 gross boundary. The $10 monthly account-wide alert is not a cap. | Latest Cost Explorer query (2026-10-31) returned account-wide, credit-adjusted data only through 2026-10-30; no project-attributable or final charge is available. | State bucket and environment resources exist; clean retirement requires reviewed state/backup sequencing |

### Cost Explorer check - 2026-10-31

The latest Cost Explorer query was account-wide and grouped by service. Daily
unblended totals through 2026-10-30 were near zero or credit-adjusted; the
2026-10-31 period was not yet reported. This is delayed billing data, not
evidence that the project is free or that gross charges are zero. Cost Explorer
cannot attribute unrelated account usage to this project without appropriate
cost-allocation setup. The `agtp-demo-monthly` budget is USD 10/month,
account-wide, and advisory only.

At the replacement host launch, approximately 27.4 hours remained until the
selected cleanup deadline. Its compute, public IPv4, and 30 GiB gp3 core-cost
estimate was about USD 2.85 before credits/tax. This is not a total project
estimate: earlier instance runtime, retained buckets, images, alarms, requests,
transfers, and delayed reporting are excluded.

Stopping EC2 is not full cleanup: storage and other resources may continue to incur charges.
