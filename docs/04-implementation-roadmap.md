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

- Test effective PR/CI protection enforcement in Stage 03 (protection enabled verified in Stage 01; exact settings user-confirmed).
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

Finish [Stage 03](11-stage03-results.md): the patched image passes the unchanged gate and publication is approved; next preserve remote history, publish reviewed files through a feature branch/PR, and verify hosted CI/protection behavior. Stages 01 and 02 are complete. Keep application implementation in `application` and platform implementation in `platform`.

Local application source, tests, migrations, Dockerfile, Compose configuration, and a local-only CI workflow are implemented. AWS/Kubernetes infrastructure is not implemented.
