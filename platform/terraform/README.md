# Terraform infrastructure

[Platform overview](../README.md)

Status: planned. No Terraform configuration or backend has been created.

## Intended resources

- VPC, public subnet, internet gateway, and route table.
- Restricted security group.
- EC2 instance, encrypted EBS, and instance profile.
- ECR repository and image retention policy.
- Private encrypted S3 backup bucket with explicit retention.
- OIDC trust and narrowly scoped CI roles.
- EC2 status-check alarms and notification resources.
- Project tags and resource outputs that do not expose secrets.

## State bootstrap

Use separately managed private encrypted S3 state storage with versioning and supported state locking. Select a pinned Terraform version and compatible native S3 locking configuration during implementation.

The backend must exist before the main configuration uses it. Document bootstrap, state migration, access permissions, and backend retirement separately from environment destruction.

## Required checks

Formatting, validation, reviewed plan, authorized apply, restricted endpoint access, rebuild, and reviewed destroy. Never commit state, private keys, provider caches, or secret variable files.

Budget setup is a pre-deployment prerequisite; do not assume Terraform automatically prevents overspending.
