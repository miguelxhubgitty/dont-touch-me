# Game development and release rules

- Read [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md) before branching or preparing a release.
- Develop/test gameplay on `main` with Godot's fallback font. Do not run typography or store-image generators during normal gameplay work.
- `aesthetic/typography-v1` preserves the approved presentation; it is not a second gameplay branch. Never replace current gameplay with files from it.
- Create `release/<version>` from current `main`; use `release/tools/apply_aesthetics.ps1` for a reviewed three-way integration. Resolve conflicts in favor of current gameplay while adding only presentation changes.
- Regenerate typography-dependent assets once after gameplay/text freeze, using the explicit `--finalize-release` authoring flag. Validate before exporting fresh binaries.
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
