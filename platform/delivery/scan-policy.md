# Container scan policy

[Delivery guide](README.md) | [CI and GitOps flows](../../docs/03-architecture-and-flows.md)

## Gate

- Scanner: pinned Trivy 0.69.3 image/digest in the workflow.
- Scope: OS and supported application dependencies in the final built image.
- Block any reported HIGH or CRITICAL vulnerability, including findings without a fix.
- Do not use `--ignore-unfixed`, `continue-on-error`, or a success fallback.
- Scanner/database/download failures fail the job; no offline stale-database fallback.
- LOW/MEDIUM findings do not block this baseline gate. Review the full report separately when triaging; passing is not a security guarantee.
- Vulnerability scanning is not a source-code, secret, configuration, or exploitability assessment.

The scanner reads a saved image archive. No Docker socket, host credentials, or project source is mounted into it. It downloads vulnerability databases; it does not upload the image to a scanning service.

## Exceptions

No exceptions or ignore file are configured.

Any future exception requires explicit approval, finding/package IDs, rationale, owner, compensating controls, and an expiry date. An executable expiry check must accompany the exception before it is accepted. Do not silently relax severity thresholds to make CI pass.

## Controlled verification

The [HIGH fixture](../tests/fixtures/trivy-high.json) must return exit 1 when converted using the policy flags. The [LOW fixture](../tests/fixtures/trivy-low.json) must return exit 0. These synthetic reports do not install vulnerable dependencies and are not actual image findings.

Fixture checks verify severity/exit behavior, not scanner detection accuracy. Every release candidate must also pass an actual image scan. Passing applies to the scanned image and vulnerability database snapshot, not all future builds.
