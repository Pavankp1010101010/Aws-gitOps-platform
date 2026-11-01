# Security and access

[Project overview](../README.md) | [Architecture and flows](03-architecture-and-flows.md) | [Deployment guide](../prerequisites/README.md)

This is a private demonstration platform, not a production security certification. Review controls and residual risks for the account and workload before deployment.

## Identity and credentials

- Use short-lived AWS CLI authentication for operators; do not commit access keys or shared profiles.
- GitHub Actions uses OIDC and a repository- and branch-scoped image-publisher role. Application pull-request CI receives no AWS credentials.
- Keep image publication and infrastructure administration as separate trust/permission paths.
- Require IMDSv2 on EC2. This does not provide pod-level IAM isolation; treat all workloads on the host as part of the host trust boundary.
- Store Terraform state, generated inputs, application secrets, Grafana credentials, and webhook tokens as sensitive data. Keep them out of source, logs, images, and pull-request output.
- Provision the PostgreSQL Secret out of band through an authenticated Systems Manager session.
- Rotate credentials after a suspected disclosure; removing a secret from the latest revision does not erase Git history.

## Network exposure

- The EC2 security group has no inbound rules. The public IPv4 exists for outbound connectivity only.
- Administrators use Systems Manager and local port forwarding; do not add public SSH, Kubernetes API, NodePort, or load-balancer access.
- Application, PostgreSQL, Argo CD, Prometheus, Grafana, and Alertmanager Services are private to the cluster.
- Systems Manager requires an active agent, instance permissions, workstation/session prerequisites, and outbound connectivity.
- The application has no user authentication and is intended only for synthetic demonstration data. Do not expose it to the public internet or use it for sensitive data.

## Software supply chain

- Deploy application images by immutable digest and retain the source commit reference.
- Pin infrastructure providers, chart versions, bootstrap artifacts, and GitHub Actions revisions.
- The container scan blocks HIGH and CRITICAL findings. A passing scan is not a security guarantee and applies only to the scanned artifact/database snapshot.
- Require review and checks for GitOps changes. Verify branch-protection enforcement in the target GitHub repository rather than assuming it is enabled.
- Do not give privileged credentials to untrusted pull-request code.

## Data protection and recovery

- Use synthetic ticket data for demonstrations.
- Encrypt EBS and S3 storage; block public access to Terraform state and backup buckets.
- Keep application and database services internal, and retain the backup/state deletion safeguards.
- Test backup restoration into an isolated database. Do not overwrite the active database during a recovery drill.
- Review the [backup guide](../platform/backup/README.md) and [recovery runbooks](runbooks/) before destructive maintenance.
