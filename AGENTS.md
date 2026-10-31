# Game development and release rules

- Read [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md) before branching or preparing a release.
- Develop/test gameplay on `main` with Godot's fallback font. Do not run typography or store-image generators during normal gameplay work.
- `aesthetic/typography-v1` preserves the approved presentation; it is not a second gameplay branch. Never replace current gameplay with files from it.
- Create `release/<version>` from current `main`; use `release/tools/apply_aesthetics.ps1` for a reviewed three-way integration. Resolve conflicts in favor of current gameplay while adding only presentation changes.
- Regenerate typography-dependent assets once after gameplay/text freeze, using the explicit `--finalize-release` authoring flag. Validate before exporting fresh binaries.
- Do not merge the aesthetic/release branch wholesale into `main`. Backport only focused gameplay fixes, keeping basic-font development intact.
- Preserve history; no resets, force pushes, moved tags or automatic publication. Store credentials stay out of Git. Changes in this repository do not authorize website/business repository changes.
