# Stage 01 - Decisions and workstation

[Stage index](README.md) | [Previous](00-planning.md) | [Next](02-local-application.md)

Status: Complete. Workstation checks passed; public repository and enabled protection verified. Detailed protection selections are user-confirmed, not independently authenticated.

## Entry conditions

Stage 00 is complete; approval to begin this stage is recorded.

## Goal

Remove decisions that could cause rework and verify the local development prerequisites.

## Work checklist

- [x] Confirm proposed Node.js LTS, Express, browser HTML/CSS/JavaScript, and PostgreSQL stack.
- [x] Choose monorepo or two repositories while preserving separate application/platform directories.
- [x] Choose GitHub visibility and verify available branch protection/approval features.
- [x] Initialize the agreed source-control layout and exclude secrets, state, caches, and local data.
- [x] Choose and verify a Windows-compatible Linux-container runtime, including licensing and virtualization prerequisites.
- [x] Verify Git, Node.js/package manager, and container runtime versions.
- [x] Record verified workstation versions and pin the Node baseline; remaining dependency compatibility/pins are stage-specific prerequisites.
- [x] Agree baseline demo access: private administration, synthetic data only.
- [x] Set application acceptance, performance, and recovery targets before measuring.

The user approved reuse of the existing Docker Desktop runtime as permitted; licensing was not independently audited. WSL2 operation and an isolated Linux-container run were verified.

## Work locations

Project-level navigation and repository configuration; application-specific setup in [application](../application/README.md). Do not initialize a repository in the unrelated existing workspace.

## Exit checks

- [x] Required local tools execute successfully; container runtime can run a test container.
- [x] Repository boundaries and workflow discovery paths are documented.
- [x] No credential or employer data is tracked.
- [x] Stack and access decisions are recorded in the existing guides.

## Verified record and verification limits

See [workstation decisions and isolation](../docs/09-workstation-and-isolation.md) for versions, smoke-test result, cleanup, and approval boundaries.

Only the project root was initialized with Git. No local files are staged/tracked and no local commit exists. The approved `origin` is configured and remote history fetched; nothing was uploaded. Ignore rules are a preventive measure, not a substitute for checking staged content before a later commit.

The user created the public [GitHub repository](https://github.com/Pavankp1010101010/Aws-gitOps-platform). Initial checks found an unprotected `main`. After the user reported completing the approved settings, a repeat public API check returned `protected: true`; required status checks remain off as planned until Stage 03. No public rulesets were returned, consistent with using classic protection.

The detailed protection endpoint returned HTTP 401 without authentication. PR requirements, conversation resolution, administrator enforcement, and force-push/deletion restrictions are recorded as user-confirmed, not independently verified. Stage completion is based on that confirmation plus public protection evidence; it is not an end-to-end enforcement test. Recheck effective behavior during Stage 03 before relying on protected delivery.

Remote/fetch approval did not authorize uploads or automated GitHub setting changes. Preserve the remote's existing history when synchronization is later approved.

## AWS and approval gate

No AWS provisioning. Obtain approval for Stage 02 after reporting decisions and checks.
