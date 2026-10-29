# Stage 03 results and blockers

[Project overview](../README.md) | [Stage 03](../stages/03-containers-and-ci.md)

Date: 2026-10-29. Status: In progress. Local image blocker resolved; publication and hosted enforcement checks pending.

## Approved scope

User approved project-only image builds, services, Trivy downloads/scans, application restart checks, and service cleanup. User separately approved the revised Alpine image after the first image was blocked.

Initially GitHub configuration was local only. The user subsequently approved reviewed feature-branch commits/push, a PR, and a temporary failing application test followed by removal. No merge or protection-setting change is approved. Registry publication and AWS provisioning remain out of scope.

## Implemented

- Digest-pinned Node.js 24.16.0 Alpine multi-stage Dockerfile.
- Production dependencies installed from the lockfile in a build stage.
- Unused npm removed from the runtime; application/migrations run directly with Node.
- Non-root runtime (`uid=1000`), allowlisted build context, no local credentials/tests copied.
- Compose application, database, and explicit migration service.
- Loopback-only ports, read-only application filesystem, dropped capabilities, no-new-privileges, and resource limits.
- Local GitHub Actions workflow with digest-pinned PostgreSQL/Trivy and SHA-pinned checkout/setup-node actions.
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

## Completion blockers

1. Image fix and local regression are complete.
2. Publication is approved; finish file review, preserve remote history, and publish through a feature branch/PR.
3. Execute GitHub-hosted CI, prove a failing application test fails the real PR check, and verify exact protection/check enforcement through authorized access.
4. Configure the actual required check after its name exists; do not mark hosted enforcement complete from a local runner test.

## Safety and retention

Only project resources were started/restarted/stopped. Existing TimesTen configuration, global tools, Docker settings, AWS profiles, and kubeconfig were not changed.

Project data volume, stopped containers/network, images/build cache, ignored credentials, scanner database cache, and reports are retained. The generated `.cache/scan/application.tar` archive was removed after scanning. No long-lived scanner was left running.

Final checks: Compose configuration validated without printing credentials; both project containers exited; ports 3100/55432 had no listeners; 138 relative documentation links resolved; `.env` and scan cache are ignored. No workflow-specific linter or GitHub-hosted run has validated the prepared workflow yet.
