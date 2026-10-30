# Implementation roadmap

[Back to project overview](../README.md)

Use the [stages directory](../stages/README.md) for the authoritative execution order, current status, prerequisites, work checklists, and completion gates.

The detailed stages replace the earlier high-level milestone numbering:

```text
00 Planning
 -> 01 Decisions and workstation
 -> 02 Local Support Ticket Tracker
 -> 03 Containers and CI
 -> 04 AWS foundation
 -> 05 K3s and Argo CD
 -> 06 End-to-end GitOps
 -> 07 Monitoring
 -> 08 Reliability and recovery
 -> 09 Completion, portfolio, and cleanup
```

Local application and CI checks come before paid infrastructure in the recommended sequence. ECR publication is wired after AWS identity and registry setup. Do not mark a stage complete until its checks have been executed and evidence recorded.

## Decisions required before implementation

- Choose AWS region and maximum acceptable demonstration spend.
- Select an EC2 size based on measured application and monitoring needs.
- Choose notification destination and configure its credentials securely.
- Decide local runtime and whether local k3d testing is needed.
- Define scan exceptions, approval controls, performance targets, and recovery targets.
- Decide demo endpoint access and HTTPS requirements.

## Implementation rules

1. Build one working slice at a time.
2. Keep deployment ownership with Argo CD.
3. Do not add tools without a concrete requirement.
4. Never record guessed performance or recovery numbers as results.
5. Update these guides when implemented behavior differs from the plan.
6. Do not provision AWS until the cost and access prerequisites are approved.

## Next intended action

Stages 00-03 are complete and PR #1 is merged. Stage 04 has [local Terraform implementation and mock validation](12-stage04-local-results.md) for us-east-1/AZ us-east-1c. Next obtain authorization for account/free-allowance checks, review capacity/pricing, and approve budget/runtime and exact plans before any cloud provisioning.

Application source, tests, migrations, Dockerfile, Compose, hosted CI, and local AWS Terraform configuration are implemented. No AWS infrastructure or Kubernetes platform is deployed.
