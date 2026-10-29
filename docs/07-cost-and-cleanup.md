# Cost and cleanup

[Back to project overview](../README.md)

## Cost model

No AWS resources exist as a result of this documentation step. Future deployment is not guaranteed free.

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

## Before provisioning

1. Choose a region and tag resources with project, owner, and environment.
2. Define acceptable spend and maximum demonstration runtime.
3. Estimate EC2, storage, IPv4, and supporting-service costs.
4. Configure budget notifications. Alerts are not a spending cap.
5. Record a teardown owner and reminder.
6. Review the Terraform plan for unexpected managed services.
7. Verify account free allowances or credits rather than assuming eligibility.

## Cleanup procedure

1. Capture redacted evidence and measured results.
2. Decide whether backups must be retained for later recovery tests.
3. Inspect the intended Terraform destroy plan.
4. Destroy only the explicitly selected project environment.
5. Inspect the AWS account/region for remaining project resources.
6. Handle intentionally retained ECR images, S3 contents/versions, EBS volumes, snapshots, IP addresses, alarms, and notification resources.
7. Retain the state backend until managed infrastructure is accounted for.
8. If retiring the project completely, use a separate reviewed procedure to retire the backend and retained data.
9. Check cost reporting again after its reporting delay.

Do not configure destructive bucket cleanup just to make teardown succeed. State and backup retention must be an explicit decision.

## Cost record

| Deployment date | Region | Instance and disk | Start/end time | Estimated spend | Observed charge | Retained resources |
|---|---|---|---|---|---|---|
| Not deployed | Not selected | Not selected | Not applicable | Not estimated | Not measured | None created |

Stopping EC2 is not full cleanup: storage and other resources may continue to incur charges.
