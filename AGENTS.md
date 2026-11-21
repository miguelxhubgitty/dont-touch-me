# Game development and release rules

## Branches and owner authorization

- Start every change on a dedicated topic branch based on updated `origin/main`. Keep `main` as the approved integration baseline. Use GitHub PRs for integration.
- Inspect the current branch, Git status, worktrees, and local/remote divergence. Preserve unfinished and unpushed work in place. Use a separate worktree when needed. Keep unrelated changes separate. Do not reset, clean, force-push, auto-stash, overwrite, or discard existing work.
- **Standard mode is the default.** Obtain the owner's design approval for meaningful changes, implement and test on a topic branch, open a focused PR, and wait for explicit approval to merge the reviewed PR. Design approval alone authorizes implementation.
- **Authorized batch mode requires the owner to explicitly approve both a defined, ordered sequence of tasks and permission to merge the verified PR for each task.** Record that scope. Create a separate branch, regression tests, and PR for every task. Verify each merged result before starting the next branch from updated `origin/main`. Stop the batch on a real regression, conflict, unexpected change, or decision outside the approved scope. Report each PR, merge SHA and verification result.
- Both modes use the protected PR workflow. Neither authorizes unrelated changes, releases, publication, deployments, or changes to another repository.
- After an authorized merge, verify `origin/main` and update a clean local main only by fast-forward when needed. Remove a merged task branch only after checking it has no unique work or changes to preserve and is not in use.
- Keep `docs/foundation-context-2026-11-02` permanently isolated. Read it for history. Never merge, cherry-pick or copy its files to `main`. Preserve `aesthetic/typography-v1`, historical release branches, frozen Alpha artifacts and release tags.

Read [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md) for the detailed procedure and [CURRENT_STATE.md](CURRENT_STATE.md) for the live development snapshot. GitHub branch protection and these instructions apply together.

## Verification and handoff

- Preserve established behavior and add regression coverage for meaningful changes. Verify both authored and procedural animation paths, hit detection and interruptions when affected.
- Run the relevant [test runner modes](TESTING.md#development-test-runner). Isolate test settings from player preferences. Check exit codes and runtime errors. Investigate shutdown warnings in context, including a normal game close where relevant, before treating them as test-only. A leak during normal play, a failed test, or a reproducible runtime error blocks integration.
- Update the relevant plan, current-state documentation and journal. Report the scope, PR and commit, tests with results and coverage limits, and any work or decisions still pending.

## Code Quality & Refactoring Policy

Prefer simple, maintainable code. Before adding logic, look for existing functions or behavior you can reuse or improve. Address root causes where practical. Introduce abstractions, classes, managers, or compatibility layers only when there is a demonstrated need.

- Small refactors directly related to an approved task are permitted when they simplify the implementation, preserve behavior, and pass relevant tests.
- Obtain explicit owner approval before a larger structural change, even if you discover it during an approved task. Obtain explicit approval before overwriting, removing, modifying, or refactoring unrelated code.
- Before removing apparently unused functionality, verify its purpose, callers, and dependencies. Preserve unrelated changes, including uncommitted local work.

### Refactoring opportunities

Notice worthwhile opportunities during normal development. When an opportunity falls outside the approved task, finish the assigned work if it can proceed independently and report the opportunity with:

- **What** — relevant files, functions, or systems.
- **Why** — the specific problem or unnecessary complexity.
- **Solution** — the proposed rewrite, consolidation, or removal.
- **Impact** — affected behavior and dependencies.
- **Risk** — possible regressions and tests needed.
- **Priority** — now, later, or not worthwhile.

Implementation of those opportunities requires owner authorization. If an out-of-scope decision blocks the assigned work, follow the project's approval and stop rules.

## Release boundaries

- Develop/test gameplay on a dedicated topic branch derived from approved `main`, with Godot's fallback font. Do not run typography or store-image generators during normal gameplay work.
- `aesthetic/typography-v1` preserves the approved presentation; it is not a second gameplay branch. Never replace current gameplay with files from it.
- Create `release/<version>` from current `main`; use `release/tools/apply_aesthetics.ps1` for a reviewed three-way integration. Resolve conflicts in favor of current gameplay while adding only presentation changes.
- Release typography is prepared only after gameplay and dialogue freeze. Reuse compliant cached Ink Free complete-phrase artwork. Render outdated or insufficient phrases at a native minimum of 4× their logical text dimensions via the existing `--finalize-release` workflow. Verify actual 4K fullscreen sharpness before export. Follow the [release typography standard](BRANCH_WORKFLOW.md#release-typography-standard).
- Do not merge the aesthetic/release branch wholesale into `main`. Backport only focused gameplay fixes, keeping basic-font development intact.
- Preserve history; no resets, force pushes, moved tags or automatic publication. Store credentials stay out of Git. Changes in this repository do not authorize website/business repository changes.

## Planning and tracking

- Before changing gameplay, check `GAME_ROADMAP.md` and the relevant files under `plans/` for proposed features and reported bugs.
- Treat newly reported bugs and feature ideas as **plans**, not as authorization to immediately implement, regenerate assets, or change a published release. Record a focused plan with observed behavior, investigation, acceptance criteria and target release when appropriate.
- Keep planning commits distinct from implementation commits. When implementing an approved item, update its status and reference the implementation commit; do not mark an item complete without validation.
- Preserve the development/release branch rules above and never silently alter an existing published build.

## Development journal and public devlogs

- Maintain `docs/INTERNAL_DEVELOPER_JOURNAL.md` as the owner's thorough, plain-English, source-grounded explanation of current mechanics, decisions, history, known bugs, tests, and every meaningful change. Update it alongside implementation and verified release changes; keep planned vs shipped distinct. Link exact functions/commits and explain technical concepts digestibly. Never invent unverified details.
- Public itch.io devlogs are short, curt, dry, candid and focused on annoyances, overlooked problems, and concrete fixes. Write under the byline `— Butter Boy`. Avoid marketing hype, forced positivity, internal implementation minutiae, or unsupported anecdotes. Do not publish posts without approval; keep drafts separate from the internal journal.

## Design-first implementation approval

- Required sequence: **Proposal → Pseudocode → Owner approval → Implementation → Testing → Journal update → Release preparation**. Keep the approved behavioral specification synchronized with implementation; compare the two during testing and update the journal before release preparation.
- The retroactive Alpha reference is [docs/ALPHA_BEHAVIOR_SPEC.md](docs/ALPHA_BEHAVIOR_SPEC.md), with immutable provenance in [docs/ALPHA_SOURCE_AUDIT.md](docs/ALPHA_SOURCE_AUDIT.md). Describing already-published Alpha behavior is not a new feature proposal or authorization to alter it. Distinguish Alpha, current development and future proposals; preserve the historical baseline when adding later specifications.

- For every meaningful gameplay, animation, audio, or system change, first create/update a plan under `plans/` describing player-visible behavior, source-grounded current behavior, proposed pseudocode, edge cases, acceptance criteria, and relevant design choices. Add a Mermaid state/decision flowchart when helpful.
- Present the proposed pseudocode and trade-offs to the owner and **obtain explicit approval before implementing**. Approval of the overall workflow is not approval of individual future changes.
- After design approval, implement only on the dedicated topic branch and follow the authorization mode above for merging. If the code requires a material deviation, document it and request approval rather than silently changing the intended behavior.
- Validate against the approved pseudocode, update the plan with implementation/test/commit status, and synchronize the detailed internal journal's English explanations, pseudocode, flowcharts, and code references.
- Trivial typo, formatting, and nonbehavioral documentation corrections may skip full pseudocode review; record meaningful changes as usual.

## Owner preference — multiples of nine

- When choosing an otherwise arbitrary, tunable number (timing, spacing, counts, dimensions or similar design parameters), **prefer multiples of 9** where practical, including sensible decimal increments such as `0.09`, `0.45`, `0.9` and `1.8`. For decimal timings, nine-based increments such as `0.09 s` are good defaults when they fit the interaction.
- Treat this as a **tie-breaker, not a strict rule**. Never change measured values, existing requirements, legal/financial data, IDs, accessibility constraints, platform specifications, performance targets, or tested behavior just to reach a multiple of nine.
- If a non-nine value works better for correctness or user experience, use it and briefly explain why when relevant.
