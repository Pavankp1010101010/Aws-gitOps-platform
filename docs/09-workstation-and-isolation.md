# Workstation decisions and isolation

[Project overview](../README.md) | [Stage 01](../stages/01-decisions-and-workstation.md)

## Confirmed on 2026-10-29

- Application: Support Ticket Tracker.
- Stack: Node.js 24, Express, browser HTML/CSS/JavaScript, PostgreSQL.
- Layout: one local Git repository, with separate application/platform directories.
- GitHub visibility: public, confirmed by the user and public API. Destination: [Pavankp1010101010/Aws-gitOps-platform](https://github.com/Pavankp1010101010/Aws-gitOps-platform). User approved adding `origin` and fetching; both succeeded. Publication is not approved.
- Local runtime: existing Docker Desktop Linux engine; user approved using it and an isolated smoke test.
- Access: private demo, synthetic data only.
- Initial performance/recovery targets: approved in the [validation plan](08-validation-and-evidence.md).

## Observed workstation

These are observed versions, not a declaration that all combinations are compatible with future AWS/K3s versions.

| Component | Observed value | Action |
|---|---|---|
| Git | 2.48.1.windows.1 | Reused |
| Node.js | 24.16.0 | Reused; application `.nvmrc` records exact local baseline |
| npm | 11.13.0 | Reused through `npm.cmd`; no PowerShell execution-policy change |
| Docker CLI/engine | 29.1.3 | Reused without settings changes |
| Docker context | desktop-linux | Read current context; test explicitly targeted this engine |
| WSL | docker-desktop running under WSL2 | No distribution/settings changes |
| AWS CLI | 2.34.61 | Version checked only; no AWS account calls |
| kubectl | 1.34.1 | Client version checked only; no cluster calls |
| Helm | 4.3.1 | Version checked only |
| Terraform | Not found on PATH | Defer installation/approval to Stage 04 |
| GitHub CLI | Not found on PATH | Optional; not needed to initialize Git |
| Host RAM | Approximately 31.4 GiB | Read-only observation |
| Docker memory allocation | Approximately 15.3 GiB | No allocation changes |
| Docker CPUs | 22 | No allocation changes |
| C drive free space | Approximately 181.8 GiB | Point-in-time observation |

Express, PostgreSQL, chart, K3s, and CI dependency versions must be selected and pinned at the stage that introduces them. Verify Helm/K3s/kubectl compatibility then; do not replace shared tools merely to match a preferred version.

The `.nvmrc` file documents a project baseline; it does not install or switch Node globally. Use a project-scoped runtime approach and seek approval before a future shared-version change. Commit dependency lockfiles once created.

## Executed smoke test

- Image: public Docker Hub `hello-world`, resolved digest `sha256:c567b231f65614688711a75f31518a064258a51d442117a3e771a3a8fdba78ef`.
- Container: `agtp-stage01-check-4843da1a01`.
- Network: none inside the test container.
- No published ports, host bind mounts, named volumes, or privileged mode.
- Result: successful hello-world output and exit code 0.
- Cleanup: `--rm` removed the test container; exact-name post-check returned none.
- The downloaded image remains in the shared image cache as disclosed in approval. No pruning was performed.

Registry access to download the public test image transferred no project files. Use digest-pinned images for subsequent reproducibility; this one-time smoke test initially resolved the public default tag.

## Isolation policy

The project has no ancestor Git repository and was initialized only in its own root with branch `main`. No global Git configuration was modified.

Before any step that could overlap existing work, explain the impact and obtain approval:

- Shared tool installations/upgrades, PATH changes, execution policy, Git global settings.
- Docker daemon/context changes, WSL settings, engine restart, resource allocation, pruning.
- Starting long-lived services/containers, publishing host ports, creating volumes.
- Modifying another workspace, connecting to an existing cluster, changing kubeconfig or AWS profiles.
- GitHub publishing/remotes and AWS provisioning or billable activity.
- Destructive drills, data deletion, or environment teardown.

For later container work:

1. Use a dedicated Compose project name such as `support-ticket-dev`; never rely on the current unrelated workspace.
2. Inspect intended host ports and existing Compose project names before choosing them.
3. Use project-owned volumes/networks and clearly labeled resources.
4. Bind local services to loopback unless another access path is explicitly approved.
5. Do not mount existing database directories or reuse employer data/configuration.
6. Never use global prune or stop unrelated containers.
7. Remove only explicitly identified project resources.

At the end of Stage 01, no application/database ports or volumes had been created. Stage 02 subsequently received explicit approval for isolated resources; see [its results and cleanup record](10-stage02-results.md). A name prefix is a convention, not proof that no collision exists.

## GitHub verification on 2026-10-29

- Public repository exists; default branch is `main`.
- Remote `main` already has an initial commit: `ed3a5f99062edc74df5302e2862050781e66ab5e`.
- Initially the public branches API reported `protected: false` for `main`; after the user's manual configuration, the branch endpoint returned `protected: true`.
- The public repository rulesets endpoint returned no rulesets.
- No authenticated account, subscription details, or repository settings were changed.

Sources: [repository API](https://api.github.com/repos/Pavankp1010101010/Aws-gitOps-platform), [branches API](https://api.github.com/repos/Pavankp1010101010/Aws-gitOps-platform/branches), [rulesets API](https://api.github.com/repos/Pavankp1010101010/Aws-gitOps-platform/rulesets), and [GitHub branch protection documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches).

## Approved protection policy - user reports configured

- Require pull requests for `main`.
- Do not require another person's approving review for a solo project; the author cannot approve their own PR.
- Block force pushes and branch deletion.
- Require conversation resolution and apply protection to administrators.
- Add required CI status checks in Stage 03 after real check names exist.
- Verify effective enforcement in Stage 03 when the first controlled PR/checks are available.

User confirmed completing the manual setup on 2026-10-29. A subsequent read-only public check verified protection enabled and required status checks off, as intended before CI exists.

The detailed classic-protection endpoint returned HTTP 401 without authentication. Exact PR/review, conversation, administrator, deletion, and force-push settings could not be independently read. These selections are user-attested. No settings were changed by the assistant, and no push/PR enforcement test was performed.

## Remaining approval and synchronization boundary

User approved adding the local `origin` and fetching remote history; both succeeded on 2026-10-29. No local files were staged, committed, overwritten, or uploaded. GitHub settings will be configured manually by the user using the approved policy. Uploads require separate approval and a staged-content review.

At Stage 01 completion, the remote contained its initial README and local work had no commits. During the separately approved Stage 03 publication, remote history was preserved, README intent reconciled, and the feature branch was published. See [Stage 03 evidence](11-stage03-results.md). No force-push or merge occurred.

Stage 01 is complete using user-confirmed settings plus public evidence that protection is enabled. Detailed authenticated verification/enforcement testing remains a Stage 03 follow-up, not a claimed result. No application/platform acceptance results are implied by the Docker smoke test.
