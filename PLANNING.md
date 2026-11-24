# Don't Touch Me — Planning and Continuation Record

Last updated: 2026-11-24. Source: PLANNING — Don't Touch Me conversation, repository evidence and agent release reports. This is a living planning checkpoint, not a transcript, release manifest or authorization to implement/publish.

## Continuity protocol

- Read this file first when starting or resuming the Don't Touch Me planning chat. Then read current AGENTS.md, relevant plans, PR heads and release evidence; reconcile this dated snapshot against them.
- Maintain this single PLANNING.md in place on the permanent docs/planning-history branch. Commit concise dated revisions directly to that branch at meaningful planning milestones (decisions, changed requirements, review outcomes, blockers, next steps), at the owner's request, and before a chat handoff when possible. Git history preserves earlier versions. No new file per chat, no force-push, no branch deletion and no merge of the planning-history branch into main or a release branch.
- Consolidate superseded status; preserve unresolved questions and explicit owner decisions. Distinguish proposed, approved, implemented, tested, and published work. Record source links and exact relevant PRs/commits, evidence limits and what remains.
- Keep detailed technical specifications in plans/, the roadmap, CURRENT_STATE.md, release records and the internal developer journal. Link rather than duplicate them. The planning record is the quick-start context, not a replacement for canonical documentation.
- This repository is public, including non-main branches. Do not save secrets, passwords, signing key locations, private transcripts, personal information, or sensitive account details. No automatic background sync or paid API is required; an inactive chat cannot guarantee a checkpoint.
- Planning updates never authorize implementation, merges, signing, tagging, submissions or publication. Follow AGENTS.md and BRANCH_WORKFLOW.md.

## Project and roles

- Game: Don't Touch Me; Godot 4.7.2; 2D interactive character game. Repository: https://github.com/miguelxhubgitty/dont-touch-me
- ChatGPT: planning, design direction, coordination, review, implementation prompts and scoped GitHub work. Claude Code and Codex: implementation and local verification in their own workspaces; Claude currently handles the release machine. Owner: design, merge and publication approvals.
- Keep responses and prompts concise. In the planning chat, “ok” after a next-task recommendation means provide the next copyable implementation prompt; after a specific merge approval request it means authorize that merge. Include model/reasoning level in implementation prompts when useful.
- Prefer simplicity, reuse, and multiples of nine for arbitrary tunable constants; correctness overrides the preference. Never overwrite unrelated work. Use tiered tests, avoid repeated full runs, unnecessary credit consumption or asset regeneration. Keep project workspaces separate and coordinate through GitHub.
- Visual pipeline: original artwork/Adobe-based visual framework with Godot AnimationPlayer and procedural animation/controller code. The owner accepts this hybrid approach; do not recreate existing animations in Adobe merely for consistency. Puffer-huff, Recoil, Stretch and Humming use native Godot motion/keyframes and/or procedural drawing; full Adobe authorship is not established.

## Current checkpoint — 0.1.1 release preparation

**Feature development and release artwork are complete for the approved scope.** No further feature or asset work before release unless a real validation failure requires a focused fix.

- main: `f40c9d871de4d0a99db71cfb6cc90b110ea96160` at checkpoint. PR [#69](https://github.com/miguelxhubgitty/dont-touch-me/pull/69) backported the Web Polygon2D fix without release aesthetics.
- release/0.1.1: `fdc078e36baf4280a5a61c38a2b9d0ba55ac7cba`. [PR #68](https://github.com/miguelxhubgitty/dont-touch-me/pull/68) is a review-only draft; never merge into main. [PR #70](https://github.com/miguelxhubgitty/dont-touch-me/pull/70) merged into the release branch; its [CI run](https://github.com/miguelxhubgitty/dont-touch-me/actions/runs/45400910209) passed. No outstanding required integration PR at checkpoint. Historical/deferred PRs may remain open.
- Freeze the original v0.1.0-alpha and PR #14. No incremental feature releases before 0.1.1; preserve Alpha assets, history, store records and tag.
- Approved Windows, Web, Linux and macOS artifacts were built from `5660a2e`; Android packages from `0f639b7`; Microsoft MSIX from the approved Windows ZIP. Claude reported checksums and external archive verified. Preserve their actual provenance; do not rebuild unaffected packages. PR #70 hardened mixed-commit publication validation. Actual local offline prepare after the merge is still pending.
- No v0.1.1 tag, production signing, submission or publication was reported completed. Recheck before acting. Published Alpha status differs by platform; canonical release branch registry is the source of truth.

### Release content

17 regular reactions plus WAKE; kitten/puppy/robot audio, Sound off by default and saved, five volume controls, rapid-tap attenuation and interruption fades. New Recoil and Puffer-huff, Stretch and Humming, Yawn/Microsleep/Fighting Sleep/Sleep Twitch; movement continuity and contact audio; Android/iOS orientation and privacy controls; release-only Space Grotesk and complete-phrase Ink Free artwork. Sleep 18 seconds; gameplay values and animation details in canonical plans. Keep the basic-font main and release aesthetics separate.

### Remaining gates (independent by platform)

| Target | Checkpoint | Next action |
| --- | --- | --- |
| Windows | Approved ZIP, smoke test passed (reported) | Final integrity/provenance and authorized distribution |
| Microsoft Store | Unsigned MSIX built; Game listing selected, other listing untouched | Certification and approved submission |
| Google Play | Unsigned AAB and debug APK built; code 4 verified; 16 KB static checks passed (reported) | Owner enters password locally; sign copy with existing verified upload key, validate, physical/internal tests, authorized submission |
| Web | Chromium/Edge and Firefox gameplay passed; WebGL warnings resolved | Firefox audible-output verification, Safari compatibility, approved distribution |
| Linux | Built, not native-tested | Native smoke test |
| macOS | Universal build, ad-hoc/unnotarized; not native-tested | Native smoke test, accurately disclose signing limitations |
| Amazon | Alpha live; update package not selected | Check existing store signing configuration and compatibility; use production artifact, correct listing copy, approved submission |
| Samsung | Authentication pending | Owner signs in; verify actual status/requirements |
| iOS | Production preset prepared, no 0.1.1 archive | Mac/Xcode export, signing, native iPhone/TestFlight checks and approval |
| GitHub Releases, itch.io, Game Jolt | Alpha live | Preserve Alpha; publish approved 0.1.1 artifacts only after required release checks and separate authorization |
| Playgama / other platforms | Deferred | No new work without approval |

### Immediate next step

Resume local release work from the verified release head after Claude usage becomes available. Sync without overwriting local work; run the publication prepare/provenance check on the existing packages and confirm latest release-head validation, complete signing and device checks, Firefox audio and Amazon signing checks. No new asset generation. Owner must supply access/passwords/hardware as required; do not claim real-world tests from synthetic or static checks. Remaining platform-specific work can proceed independently. Tag and publish only after explicit approval and applicable gates; never merge PR #68 into main.

## Future plans (not assignments)

- Architecture review after current release, scoped and explicitly approved; prefer simple improvements over unnecessary rewrites.
- Deferred sound polish/candidates (PR #20), ambience/music, recognizable-song humming ideas, emotional stages/aura tiers, trust/petting, statistics, cosmetics and customization. No monetization without separate approval. See GAME_ROADMAP.md and plans/.
- Separate WANDIEL website work from game development. No automatic website changes on a game release.

## Canonical references

- [AGENTS.md on main](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/AGENTS.md), [branch workflow](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/BRANCH_WORKFLOW.md), [roadmap](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/GAME_ROADMAP.md), [current state](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/CURRENT_STATE.md), [developer journal](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/docs/INTERNAL_DEVELOPER_JOURNAL.md).
- [0.1.1 release checklist](https://github.com/miguelxhubgitty/dont-touch-me/blob/release/0.1.1/release/RELEASE_CHECKLIST.md), [platform registry](https://github.com/miguelxhubgitty/dont-touch-me/blob/release/0.1.1/release/distribution/platforms.json), [production signing](https://github.com/miguelxhubgitty/dont-touch-me/blob/release/0.1.1/release/PRODUCTION_SIGNING.md), [release PR #68](https://github.com/miguelxhubgitty/dont-touch-me/pull/68).
- Existing historical foundation branch docs/foundation-context-2026-11-02 remains isolated and untouched.

**New-chat instruction:** Read this record, reconcile current GitHub state, summarize the project and next action concisely, and continue planning without repeating completed work. No implementation or release authorization is implied.
