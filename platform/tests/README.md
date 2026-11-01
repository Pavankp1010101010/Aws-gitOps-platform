# Platform validation helpers

[Platform overview](../README.md) | [Validation guide](../../docs/08-validation-and-evidence.md)

These helpers validate local artifacts and controlled behavior. They do not prove successful deployment to an AWS account.

## Test assets

- `fixtures/intentional-failure.mjs`: explicit runner-failure test; expected exit code is 1. Do not include it in the normal passing suite.
- `fixtures/trivy-high.json` and `fixtures/trivy-low.json`: synthetic scanner reports for checking severity and exit-code policy.
- `validate-chart.sh`: checks rendered chart resources for private ClusterIP Services, secret references, ordered migrations, persistent-volume prune protection, and digest-pinned images.
- `smoke-test.mjs`: synthetic ticket create/update/comment/list/retrieve checks. It rejects non-loopback targets and leaves the synthetic record in the selected database.
- `smoke-test.test.mjs`: verifies the smoke helper's API contract and loopback-target restriction.
- `update-image-digest.py` and `test_update_image_digest.py`: update and test the application image digest/source commit without changing the PostgreSQL image digest.
- `platform/monitoring/tests/`: Prometheus rule extraction and alert-rule fixtures.

The root CI workflow invokes these checks. Scanner fixtures validate policy behavior, not scanner detection accuracy. Every release candidate still requires an actual image scan.

## Private smoke test

After deployment, create an authenticated Systems Manager port-forward to the application, then run:

```powershell
$env:SMOKE_BASE_URL = 'http://127.0.0.1:18443'
node platform/tests/smoke-test.mjs
Remove-Item Env:\SMOKE_BASE_URL
```

The smoke test writes synthetic data and does not remove the created record. Use only a deployment and dataset you control.

## Safety

- Use synthetic data for tests and demonstrations.
- Select the exact account, instance, namespace, and database before operational checks.
- Destructive recovery drills require a fresh reviewed plan and explicit approval.
- Never run a load test against an unrelated or employer-owned endpoint.
- Do not fill the live host disk to test low-space alerts.
- Keep evidence free of secrets, account identifiers, and private user data.
