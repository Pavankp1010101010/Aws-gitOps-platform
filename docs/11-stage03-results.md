# Stage 03 results and blockers

[Project overview](../README.md) | [Stage 03](../stages/03-containers-and-ci.md)

Date: 2026-10-29. Status: Complete. Patched image, local regression, hosted CI, and required-check failure/recovery verified. PR remains open and unmerged.

## Approved scope

User approved project-only image builds, services, Trivy downloads/scans, application restart checks, and service cleanup. User separately approved the revised Alpine image after the first image was blocked.

Initially GitHub configuration was local only. The user subsequently approved reviewed feature-branch commits/push, a PR, and a temporary failing application test followed by removal. The user manually configured the required check after guided approval. No merge is approved. Registry publication and AWS provisioning remain out of scope.

## Implemented

- Digest-pinned Node.js 24.16.0 Alpine multi-stage Dockerfile.
- Production dependencies installed from the lockfile in a build stage.
- Unused npm removed from the runtime; application/migrations run directly with Node.
- Non-root runtime (`uid=1000`), allowlisted build context, no local credentials/tests copied.
- Compose application, database, and explicit migration service.
- Loopback-only ports, read-only application filesystem, dropped capabilities, no-new-privileges, and resource limits.
- Published GitHub Actions workflow with digest-pinned PostgreSQL/Trivy and SHA-pinned checkout/setup-node v6 actions.
- CI tests, image build, native Trivy gate, and controlled failure-policy fixtures.
- Node scripts accept CI environment variables without requiring a local `.env`.

The Alpine switch is a container-only change. It does not replace the workstation's Node installation.

## Verified locally

| Check | Result |
|---|---|
| Initial and revised image builds | Passed; final retained Dockerfile builds the validated Alpine candidate |
| Database migrations from application image | Passed |
| Container readiness and PostgreSQL connectivity | Passed |
| Application user | `node`, UID/GID 1000 |
| Runtime content boundary | No `/app/.env`, `/app/test`, or bundled npm |
| Syntax and application integration tests | 13 passed after CI-compatible script changes |
| Intentional failing test fixture | Exit 1, as expected; no failing test added to application suite |
| Synthetic HIGH scan report | Trivy convert exit 1 |
| Synthetic LOW scan report | Trivy convert exit 0 under HIGH/CRITICAL policy |
| Application container restart | Existing development ticket/comment retained |
| Linux container SIGTERM | Structured shutdown event observed during restart |
| Project services | App and database stopped after checks |

An initial attempt to execute a test fixture through stdin was unsupported by `node --test`. It was replaced by a named explicit fixture, which returned the expected exit code. This is not a claim that hosted CI was exercised.

## Actual scan progression

Scanner: Trivy 0.69.3, pinned digest in the workflow. Scan source: locally saved image archive; no Docker socket or remote image-upload service used.

| Candidate | HIGH | CRITICAL | Outcome |
|---|---|---|---|
| Node 24.16.0 Debian bookworm-slim plus application | 79 | 5 | Blocked |
| Node 24.16.0 Alpine, unused npm removed | 2 | 0 | Blocked |
| Same Alpine base, libcrypto3/libssl3 pinned to 3.5.9-r0 | 0 | 0 | Passed, exit 0 |

Counts are package findings, not unique vulnerabilities. Full reports are ignored local files in `.cache/trivy/application-report.json` and `.cache/trivy/alpine-report.json`.

### Previously blocking findings - now resolved in the scanned image

| Finding | Runtime package | Installed | Scanner-reported fixed version |
|---|---|---|---|
| CVE-2026-14456, HIGH | libcrypto3 | 3.5.7-r0 | 3.5.8-r0 |
| CVE-2026-14456, HIGH | libssl3 | 3.5.7-r0 | 3.5.8-r0 |

The first exact-version attempt used 3.5.8-r0, which was unavailable. On rechecking signed Alpine v3.24 package indexes, 3.5.9-r0 was available. Both libraries are now explicitly pinned to that version in the runtime Dockerfile. The new image built and passed the unchanged gate with zero HIGH/CRITICAL findings. No workstation runtime was changed.

The patched image then passed migrations, readiness, non-root and image-content checks, all 13 application tests, and application-container restart persistence. Both project services were stopped afterward. Report: ignored `.cache/trivy/patched-report.json`.

Exact distribution package pins may eventually leave rolling package mirrors. A later maintenance update must review/pin an available compatible version or refreshed base digest and repeat the same tests; do not silently fall back to vulnerable packages.

These are scanner-reported package findings, not an independently confirmed exploitability analysis. No ignore rule, severity reduction, or unfixed-finding exclusion was introduced.

## Publication and hosted enforcement evidence

The 58-file initial publication inventory was checked for the generated local database password, private-key headers, and recognized AWS/GitHub credential patterns; none were found. Ignored environment files, node_modules, scanner cache/reports, and database storage were excluded. Pattern checks reduce risk but do not constitute a complete secret audit.

Remote history was preserved by adopting `origin/main` as the local parent without changing worktree files, then creating `stage03/containers-ci`. The remote README description remains represented in the expanded overview, and its original commits remain ancestors. No force-push occurred.

The assistant's first push attempts failed authentication. The user authenticated/pushed interactively and opened [PR #1](https://github.com/Pavankp1010101010/Aws-gitOps-platform/pull/1). Subsequent feature-branch pushes succeeded. No shared credential helper or global Git configuration was modified.

| Evidence | Result |
|---|---|
| [Initial hosted CI](https://github.com/Pavankp1010101010/Aws-gitOps-platform/actions/runs/40895320395), source `cce2123` | Success: tests, build, fixtures, and actual scan |
| Public main branch metadata after user configuration | Required `Application tests and image scan`, GitHub Actions app ID 15368, enforcement level `everyone` |
| [Intentional failure run](https://github.com/Pavankp1010101010/Aws-gitOps-platform/actions/runs/40896314569), source `1363ca6` | Required job failed at syntax/integration step due to temporary application test |
| PR metadata at failing head | `mergeable_state: blocked`, open, unmerged |
| [Restored passing run](https://github.com/Pavankp1010101010/Aws-gitOps-platform/actions/runs/40896625562), source `83df691` | Success after temporary test removal and maintained action pins |
| PR metadata at restored head | `mergeable_state: clean`, open, unmerged |

The failure run logs identify `test/stage03-gate-verification.test.js` and the intentional Stage 03 test. The temporary file is deleted in the current branch; it remains in Git history as drill evidence. The permanent runner fixture under platform tests is separate and is expected to fail only when explicitly invoked by its verification step.

The hosted runtime warned that the old pinned v4 actions targeted deprecated Node 20. Both actions were updated to SHA-pinned v6 revisions using the maintained runtime; the restored run passed with those revisions.

No merge or administrator bypass was attempted as a test. Exact classic-protection details beyond public metadata remain user-attested because unauthenticated detailed access returned 401. The required-check context/enforcement and blocked PR state were independently observed.

## Completion and boundary

All Stage 03 exit checks have evidence. ECR publication, source-to-running-cluster digest traceability, GitOps deployments, AWS provisioning, and Stage 04 are not included. The open PR is not merged; merging requires separate user approval.

## Safety and retention

Only project resources were started/restarted/stopped. Existing TimesTen configuration, global tools, Docker settings, AWS profiles, and kubeconfig were not changed.

Project data volume, stopped containers/network, images/build cache, ignored credentials, scanner database cache, and reports are retained. The generated `.cache/scan/application.tar` archive was removed after scanning. No long-lived scanner was left running.

Final handover checks: 142 relative documentation links resolved; diff checks passed; the temporary failing test was absent; project containers were exited; ports 3100/55432 had no listeners; private environment and scanner files remained ignored. The disposable scan archive was removed and reports/cache retained. GitHub accepted and executed the workflow; no separate workflow-specific linter was installed.
