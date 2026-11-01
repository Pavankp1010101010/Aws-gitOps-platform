# Cost and cleanup guide

[Project overview](../README.md) | [Prerequisites](../prerequisites/README.md) | [Terraform operations](../platform/terraform/README.md)

## Cost considerations

The deployment is not free by default. Potential charges include:

| Resource | Potential charge |
|---|---|
| EC2 and EBS | Instance runtime and provisioned root storage |
| Public IPv4 and networking | Address usage, internet egress, and data transfer |
| ECR | Stored image layers and applicable transfer/scanning features |
| S3 | Terraform state, backup objects and versions, requests, and transfer |
| CloudWatch and SNS | Alarm, metrics/logging usage, and notifications |
| Snapshots | Retained backup storage if created |

Rates and account allowances vary by region and change over time. Estimate the intended instance, storage, network use, and runtime with the [AWS Pricing Calculator](https://calculator.aws/) and review account-specific terms before provisioning. The repository does not configure a hard spending cap or automatically shut down resources.

Keep demonstrations short-lived, monitor account activity, and set a calendar reminder to review and tear down the environment. A `TeardownAfter` tag is informational only. Billing data can arrive after resources are removed, so review account charges again after cleanup.

## Safe teardown procedure

1. Stop deployments, image publishing, scheduled backup jobs, and application writes.
2. Confirm the AWS account, profile, region, Terraform workspace, and backend before running commands.
3. Decide whether database data, image artifacts, and state history must be retained. Create and verify off-host copies before deleting anything that must survive.
4. Generate a fresh Terraform destroy plan. Inspect its account, region, resource list, and retention effects; apply only that exact reviewed plan.
5. Keep the environment state available until Terraform confirms the environment resources are destroyed.
6. Inventory the exact project ECR repository and S3 buckets, including object versions, delete markers, and incomplete multipart uploads. Review each inventory before deleting its data.
7. Retire the separate state backend only after environment teardown is complete and the bootstrap state is safely preserved.
8. Verify that only intended project resources are gone. Preserve unrelated or pre-existing resources even if their names or region appear similar.
9. Review EC2 instances and volumes, S3 versions, ECR images, Elastic IPs, snapshots, alarms, and delayed billing data.

The Terraform S3 buckets use `force_destroy = false`; teardown must not bypass that protection with blanket deletion, old plans, force flags, or broad account-wide cleanup commands. Follow the detailed, account-specific sequence in the [prerequisites guide](../prerequisites/README.md) and [Terraform runbook](../platform/terraform/README.md).
