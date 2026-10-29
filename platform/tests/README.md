# Platform tests

[Platform overview](../README.md) | [Acceptance matrix](../../docs/08-validation-and-evidence.md)

Status: controlled failure-policy fixtures implemented; remaining platform/load checks are planned.

## Implemented fixtures

- `fixtures/intentional-failure.mjs`: explicit runner-failure test; expected exit 1. Do not include it in the passing application suite.
- `fixtures/trivy-high.json`: synthetic report; expected native Trivy convert exit 1 with HIGH/CRITICAL gate.
- `fixtures/trivy-low.json`: synthetic report; expected native Trivy convert exit 0 with the same gate.

See [scan policy](../delivery/scan-policy.md). These fixtures do not install vulnerable packages or prove hosted CI enforcement. The root workflow invokes them explicitly.

## Future checks

- Terraform formatting, validation, and plan review.
- Helm linting/rendering and Kubernetes configuration validation.
- User-facing application smoke test.
- ECR private image pull after credential refresh.
- Controlled failed-release recovery.
- Prometheus rule tests and real notification delivery.
- k6 request-rate, latency, and error measurements.
- Isolated PostgreSQL restore verification.
- Host rebuild and post-cleanup resource checks.

## Safety rules

- Default test data must be synthetic.
- Destructive drills require explicit target selection and approval.
- Never run a load test against an unrelated or employer-owned endpoint.
- Do not fill the host disk to test low-space alerts.
- Keep evidence free of secrets.
- Do not label planned checks as passing results.
