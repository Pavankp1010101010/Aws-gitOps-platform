# Platform tests

[Platform overview](../README.md) | [Acceptance matrix](../../docs/08-validation-and-evidence.md)

Status: controlled failure-policy fixtures, rendered Helm-chart safety checks, and smoke-helper contract tests are implemented. The live private API smoke and app-pod persistence check passed; remaining platform/load checks are pending.

## Implemented fixtures

- `fixtures/intentional-failure.mjs`: explicit runner-failure test; expected exit 1. Do not include it in the passing application suite.
- `fixtures/trivy-high.json`: synthetic report; expected native Trivy convert exit 1 with HIGH/CRITICAL gate.
- `fixtures/trivy-low.json`: synthetic report; expected native Trivy convert exit 0 with the same gate.
- `validate-chart.sh`: checks rendered chart resources for private ClusterIP Services, secret references (not rendered Secret objects), ordered migrations, PVC prune protection, and digest-pinned images.
- `smoke-test.mjs`: synthetic ticket create/update/comment/list/retrieve check. It refuses non-loopback targets and leaves the synthetic record in place.
- `smoke-test.test.mjs`: exercises the smoke helper against the application's direct-JSON API contract and verifies non-loopback targets are rejected.
- `update-image-digest.py`: updates only the top-level app digest/source commit; `test_update_image_digest.py` verifies that the internal PostgreSQL digest remains untouched.

See [scan policy](../delivery/scan-policy.md). These fixtures do not install vulnerable packages or prove hosted CI enforcement. The root workflow invokes them explicitly.

## Future checks

- Terraform formatting, validation, and plan review.
- Optional repeat of the smoke test against the private deployment through a local SSM port-forward:
  ```powershell
  $env:SMOKE_BASE_URL = 'http://127.0.0.1:18443'
  node platform/tests/smoke-test.mjs
  Remove-Item Env:\SMOKE_BASE_URL
  ```
- Verify database persistence after restarting PostgreSQL or rebuilding the host.
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
