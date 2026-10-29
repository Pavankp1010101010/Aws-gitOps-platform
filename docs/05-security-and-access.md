# Security and access plan

[Back to project overview](../README.md)

This is a design baseline, not a security certification or implemented control set.

## Identity

- Use short-lived authenticated AWS access on the workstation.
- Use GitHub Actions OIDC with narrowly scoped trust conditions, including the permitted repository and branch/environment.
- Separate image-publication permissions from infrastructure-provisioning permissions.
- Give the EC2 role only the ECR, S3, and Systems Manager permissions required.
- Require IMDSv2 and restrict workload access to instance metadata where feasible; verify rather than assuming this gives pod-level isolation.
- Use a narrowly scoped GitHub App or equivalent short-lived identity for deployment-update PRs.
- Use minimal read-only credentials for Argo CD if the configuration repository is private.

## Network exposure

- Restrict the security group to the explicitly intended application web ports.
- Prefer Systems Manager for host management instead of public SSH.
- Do not publicly expose the Kubernetes API, PostgreSQL, Argo CD, Grafana, Prometheus, or Alertmanager.
- Keep database connectivity internal to the cluster.
- Use port forwarding through the restricted management path for admin interfaces.
- Validate both security-group rules and actual listening ports.
- Add HTTPS before handling authenticated sessions or sensitive data over public access.

Systems Manager requires the agent, instance permissions, workstation/session prerequisites, and outbound connectivity. No private VPC endpoints are assumed in this cost-conscious public-subnet design.

## Secrets

- No secrets in Git, image layers, workflow output, Terraform inputs committed to source, or cloud-init user data.
- Initially inject application secrets through a documented secure operator procedure.
- Enable Kubernetes secret encryption at rest during cluster setup.
- Restrict Kubernetes RBAC and access to host disks, backups, and snapshots.
- Avoid placing generated application passwords in Terraform state.
- Protect Terraform state as sensitive even when configuration files contain no passwords.
- Rotate credentials after a suspected disclosure; deletion from the latest Git revision alone is insufficient.

The secure secret initialization procedure is a deliberate manual bootstrap prerequisite, not a claim of fully unattended recovery.

## Artifact and change controls

- Pin application deployments to image digests.
- Pin infrastructure dependencies, charts, bootstrap downloads, and CI actions appropriately.
- Define Trivy failure severity, fixability handling, and time-bounded documented exceptions.
- Fail tests and scans explicitly.
- Require reviews/checks where the chosen GitHub plan supports them; verify enforcement rather than assuming availability.
- Never expose privileged AWS credentials to untrusted pull-request code.

## Data and backups

- Use synthetic demonstration data only.
- Encrypt EBS and S3 storage.
- Block public access to state and backup buckets.
- Use distinct storage and lifecycle policies for state and database backups.
- Use a backup process that produces consistent PostgreSQL backups and validates uploads.
- Test restore access separately from backup-write access.
- Do not expose dump contents or secret-bearing configuration in portfolio screenshots.

## Recovery considerations

Document which identity retrieves backups, how application credentials are re-initialized, and which resources are intentionally retained. Test these steps before claiming recoverability.
