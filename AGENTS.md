# Game development and release rules

Procedures: [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md), [TESTING.md](TESTING.md), [CURRENT_STATE.md](CURRENT_STATE.md), the `dtm-dev` and `dtm-release` skills. Global approval, secrets and workspace rules also apply.

## Branches and owner authorization

- Every change starts on a topic branch from updated `origin/main`, integrated by GitHub PR. `main` is the approved baseline.
- Inspect branch, status, worktrees and local/remote divergence first. Preserve unfinished and unpushed work; use a separate worktree when needed. Never reset, clean, force-push, auto-stash, overwrite or discard existing work.
- **Standard mode (default):** owner design approval for meaningful changes, implement and test on a topic branch, open a focused PR, wait for explicit approval to merge it.
- **Authorized batch mode:** only when the owner approves both a defined, ordered task list and permission to merge each verified PR. One branch, regression tests and PR per task; verify each merge before the next. Stop on a regression, conflict, unexpected change or out-of-scope decision.
- Neither mode authorizes unrelated changes, releases, publication, deployments or changes to another repository. After an authorized merge, verify `origin/main`; remove the merged task branch only after checking it holds no unique work and is not in use.
- Keep `docs/foundation-context-2026-11-02` isolated: read it, never merge, cherry-pick or copy it. Preserve `aesthetic/typography-v1`, historical release branches, frozen Alpha artifacts and release tags.

## Design first

- Order: Proposal → Pseudocode → Owner approval → Implementation → Testing → Journal update → Release preparation. Approving the workflow is not approving a change.
- Before changing gameplay, check `GAME_ROADMAP.md` and the relevant `plans/` files for proposed features and reported bugs.
- A meaningful gameplay, animation, audio or system change needs a `plans/` entry first: player-visible behavior, source-grounded current behavior, pseudocode, edge cases, acceptance criteria. Reported bugs and ideas are plans, not authorization. Record planning separately from implementation; never mark an item complete without validation.
- Alpha behavior is in `docs/ALPHA_BEHAVIOR_SPEC.md` (provenance: `docs/ALPHA_SOURCE_AUDIT.md`); describing it is not a change. Trivial typo, formatting or non-behavioral documentation fixes may skip pseudocode.
- Refactoring or replacing code needs the owner's approval of a proposal (problem, changes or deletions, benefit, dependencies, risks, verification). A bug-fix approval is not permission to rewrite.

## Verification

- Preserve established behavior and add regression coverage. Verify both authored and procedural animation paths, hit detection and interruptions when affected.
- Test in tiers (TESTING.md): affected suites while developing; `fast`, `audio` or `animation` before review; CI runs fast checks on every code PR; `full` once per merged batch and before each release. Never repeat full runs a task does not need; `-Quiet` never relaxes failure detection. Isolate test settings from player preferences, check exit codes and runtime errors, and investigate shutdown warnings in context before dismissing them.
- CI is Linux with a dummy audio driver and software rendering only; platform, audio-output, GPU and device checks stay manual. A failed test, a leak in normal play or a reproducible runtime error blocks integration.
- Update the plan, `CURRENT_STATE.md` and `docs/INTERNAL_DEVELOPER_JOURNAL.md` (plain-English, source-grounded, planned vs shipped kept distinct, never invented).
- Public itch.io devlogs are drafts until the owner approves them: short, dry, candid, byline `— Butter Boy`; never publish without approval.

## Release boundaries

- Develop and test gameplay with Godot's fallback font. Do not run typography or store-image generators during gameplay work.
- `release/<version>` is cut from current `main`, with `release/tools/apply_aesthetics.ps1` for a reviewed three-way integration. Resolve conflicts in favor of current gameplay. Never merge release or aesthetic branches wholesale into `main`; backport only focused gameplay fixes. Never use `aesthetic/typography-v1` files in gameplay work.
- Release typography is prepared only after the gameplay and dialogue freeze (see BRANCH_WORKFLOW.md).
- Never move tags, publish automatically, or silently alter a published build. Store credentials stay out of Git. Nothing here authorizes website or business repository changes.
