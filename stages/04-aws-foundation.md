# Stage 04 - AWS foundation

[Stage index](README.md) | [Previous](03-containers-and-ci.md) | [Next](05-k3s-and-argocd.md)

Status: Not started.

## Entry conditions

Stages 01 and 03 are complete. AWS account access, region, expected spend, and provisioning approval are explicitly confirmed.

## Goal

Create the minimum AWS foundation through reviewed Terraform, with cost and identity controls.

## Work checklist

- [ ] Estimate charges; configure budget notifications and a teardown reminder.
- [ ] Select host/disk sizing with monitoring headroom; do not assume the smallest instance fits.
- [ ] Bootstrap encrypted private remote state, versioning, locking, and access controls.
- [ ] Implement Terraform for VPC, subnet, routing, security group, EC2/EBS, IAM, ECR, and backup S3.
- [ ] Implement OIDC trust and least-privilege CI publication access.
- [ ] Prepare Systems Manager administration and instance metadata restrictions.
- [ ] Configure external EC2 status-check alarm/SNS resources and confirm notification subscription.
- [ ] Define tags, backup retention, and protected state/backend lifecycle.
- [ ] Review plan before apply and record non-sensitive outputs.

## Work location

[Terraform directory](../platform/terraform/README.md).

## Exit checks

- [ ] Formatting/validation pass and the reviewed plan matches approved scope.
- [ ] Authorized apply succeeds; state locking/access are verified.
- [ ] Systems Manager access works without opening public SSH.
- [ ] No public database, Kubernetes API, or dashboard ports are allowed.
- [ ] No EKS, RDS, AWS load balancer, or NAT Gateway is unintentionally created.
- [ ] ECR/S3 access is scoped as designed; alarms have a configured external destination.
- [ ] Cost start time and retention decisions are recorded.

Full rebuild proof (AWS-01) waits for Stage 08; access checks contribute to AWS-02.

## Cost and approval gate

Billable resources begin here. Stop, tear down, or explicitly approve continued runtime if the next stage is delayed. Review results before Stage 05.
