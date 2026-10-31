# Alpha documentation source and evidence audit

Audited October 31, 2026. Documentation verification, not a new release or gameplay test. See [behavior specification](ALPHA_BEHAVIOR_SPEC.md) and [developer journal](INTERNAL_DEVELOPER_JOURNAL.md).

## Baseline provenance

- Latest main fetched before branching: `8cee57ced64e5640872518e2a3822a6e93c65d03`.
- Branch: `codex/alpha-documentation`, created directly from that main; review PR targets the game repository. No automatic merge.
- Published runtime export source: `9788e0343cb888a31ea9092f7409e2455a961261`.
- Annotated tag `v0.1.0-alpha` resolves to `d61c86568b40c23a291db7aa2757ffe82e1896e8`. Its annotation describes preparation before publication.
- Publication record introduced by `6bf3a467bdc994f5a29ebf47975bb10b0c499fc1`, merged at `c2ea4a003403c7568944e74dd069e03a9e9d2bff`.

[Alpha preparation report](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/release/ALPHA_REPORT.md) identifies the actual export source. Git diff confirms identical runtime paths (scripts/, assets/, main.tscn, project.godot, export_presets.cfg, icon.svg) between export source, tag and publication tip. These are source-tree checks, not a fresh comparison with downloaded binaries/servers.

[Publication report](https://github.com/miguelxhubgitty/dont-touch-me/blob/c2ea4a003403c7568944e74dd069e03a9e9d2bff/release/PUBLICATION_v0.1.0-alpha.md) records October31 public release at https://wandiel.itch.io/dont-touch-me, project5273390, Windows upload20184231/build2263119, html5 upload20184236/build2263122, both v0.1.0-alpha. Existing packages were reused; public browser startup and unpacked Windows download contents were verified then. Original Windows ZIP SHA-256: `42a43d68e9c0dd2af46da6dfa6f74d32b4e4c2242a68771dc046900134bcbdc9`. This task does not freshly certify hosting or redownload builds.

Release/publication source was inspected read-only with git show, not merged into the documentation branch. Main's older all-unpublished registry/report statements predate these release-branch records.

## Alpha versus development

| System | Published Alpha | Main at 8cee57ce |
| --- | --- | --- |
| Controller mechanics | All behavior in specification | Identical; diff is only typography/filtering |
| Scene | One Node2D | Identical |
| Text | Space Grotesk title/sleep letters; cached Ink Free phrases | Engine fallback font |
| Runtime version |0.1.0-alpha/code2; Windows0.1.0.0 |1.0.0/code1; Windows1.0.0.0 |
| Catalog |Alpha release metadata |Alpha plan, not proof of main sync/export |
| Export presets |6: Android, Windows, unsigned AAB, Web, Linux, macOS |3: Android, Windows, unsigned AAB |
| Assets |Finalized Alpha typography/captures/cover |Historical basic-font captures; no regeneration here |
| Plans |No audio/trust/customization/counters |Still absent; roadmap/sleep-eye proposal added |
| Publication |Later release record says public Windows/Web |Older distribution records not synchronized |

The controller diff was reviewed hunk by hunk: typography preload, font/filter initialization, centered-text signature/implementation, title flag and bubble width. Every other function and all reaction math are identical. Project settings differ only in config/version. Main as a complete project is therefore **not** the published Alpha.

## Exact source/function concordance

Immutable Alpha links; numbered sections refer to the behavior specification. Includes all22 blob functions, both typography functions, data-only resources and relevant test entry points.

| Source/function | Immutable location | Coverage |
| --- | --- | --- |
| `scripts/blob.gd::_ready` | [line 58](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L58) | Specification sections 1,11 |
| `scripts/blob.gd::_resize` | [line 64](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L64) | Specification sections 5,9 |
| `scripts/blob.gd::_notification` | [line 76](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L76) | Specification sections 4 |
| `scripts/blob.gd::_unhandled_input` | [line 82](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L82) | Specification sections 2 |
| `scripts/blob.gd::_process` | [line 89](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L89) | Specification sections 4 |
| `scripts/blob.gd::advance` | [line 93](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L93) | Specification sections 4 |
| `scripts/blob.gd::tier` | [line 120](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L120) | Specification sections 3 |
| `scripts/blob.gd::choose_reaction` | [line 126](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L126) | Specification sections 3 |
| `scripts/blob.gd::contains_touch` | [line 131](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L131) | Specification sections 2 |
| `scripts/blob.gd::touch_at` | [line 149](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L149) | Specification sections 2-5 |
| `scripts/blob.gd::begin_reaction` | [line 164](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L164) | Specification sections 5 |
| `scripts/blob.gd::_ease` | [line 182](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L182) | Specification sections 6 |
| `scripts/blob.gd::_update_pose` | [line 186](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L186) | Specification sections 4,6-7 |
| `scripts/blob.gd::_silhouette` | [line 283](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L283) | Specification sections 9 |
| `scripts/blob.gd::_ellipse` | [line 294](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L294) | Specification sections 9 |
| `scripts/blob.gd::_text_center` | [line 301](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L301) | Specification sections 10-11 |
| `scripts/blob.gd::_draw` | [line 305](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L305) | Specification sections 8-10 |
| `scripts/blob.gd::_draw_sign` | [line 343](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L343) | Specification sections 10 |
| `scripts/blob.gd::_panel` | [line 351](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L351) | Specification sections 10 |
| `scripts/blob.gd::_box_flaps` | [line 360](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L360) | Specification sections 2,10 |
| `scripts/blob.gd::_draw_box` | [line 366](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L366) | Specification sections 10 |
| `scripts/blob.gd::_draw_bubble` | [line 380](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/blob.gd#L380) | Specification sections 10 |
| `scripts/typography.gd::width` | [line 8](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/typography.gd#L8) | Specification sections 11 |
| `scripts/typography.gd::draw_text` | [line 13](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/scripts/typography.gd#L13) | Specification sections 11 |
| `assets/typography/phrases.gd` | [whole file](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/assets/typography/phrases.gd) | Configuration/resource |
| `main.tscn` | [whole file](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/main.tscn) | Configuration/resource |
| `project.godot` | [whole file](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/project.godot) | Configuration/resource |
| `export_presets.cfg` | [whole file](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/export_presets.cfg) | Configuration/resource |
| `assets/fonts/title.tres` | [whole file](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/assets/fonts/title.tres) | Configuration/resource |
| `tests/behavior.gd::_initialize` | [line 7](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/behavior.gd#L7) | Journal testing chapter |
| `tests/behavior.gd::check` | [line 10](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/behavior.gd#L10) | Journal testing chapter |
| `tests/behavior.gd::run` | [line 16](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/behavior.gd#L16) | Journal testing chapter |
| `tests/release.gd::_initialize` | [line 8](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/release.gd#L8) | Journal testing chapter |
| `tests/release.gd::check` | [line 11](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/release.gd#L11) | Journal testing chapter |
| `tests/release.gd::run` | [line 17](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/release.gd#L17) | Journal testing chapter |
| `tests/render.gd::_initialize` | [line 5](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/render.gd#L5) | Journal testing chapter |
| `tests/render.gd::run` | [line 8](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/render.gd#L8) | Journal testing chapter |
| `tests/fingerprints.gd::check` | [line 6](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/fingerprints.gd#L6) | Journal testing chapter |
| `tests/fingerprints.gd::_initialize` | [line 12](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/fingerprints.gd#L12) | Journal testing chapter |
| `tests/typography.gd::check` | [line 8](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/typography.gd#L8) | Journal testing chapter |
| `tests/typography.gd::_initialize` | [line 14](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/tests/typography.gd#L14) | Journal testing chapter |

## Other examined source and release materials

The following current-main files were inspected for architecture, planned status, test scope, settings, resource geometry, release rules and historical claims. They are **read-only**, not changed by this task. Some reports are older snapshots and are explicitly treated as such.

- [AGENTS.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/AGENTS.md)
- [BRANCH_WORKFLOW.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/BRANCH_WORKFLOW.md)
- [GAME_ROADMAP.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/GAME_ROADMAP.md)
- [plans/sleep-eye-jitter.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/plans/sleep-eye-jitter.md)
- [WORKFLOW_VALIDATION.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/WORKFLOW_VALIDATION.md)
- [TESTING.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/TESTING.md)
- [README.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/README.md)
- [CHANGELOG.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/CHANGELOG.md)
- [.gitignore](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/.gitignore)
- [DISTRIBUTION_PLANS.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/DISTRIBUTION_PLANS.md)
- [release/RELEASE_SYSTEM.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/RELEASE_SYSTEM.md)
- [release/BUILD_REPORT.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/BUILD_REPORT.md)
- [release/FINAL_AUDIT.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/FINAL_AUDIT.md)
- [release/PRODUCTION_SIGNING.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/PRODUCTION_SIGNING.md)
- [release/IOS_EXPORT.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/IOS_EXPORT.md)
- [release/README.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/README.md)
- [release/assets/README.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/assets/README.md)
- [release/assets/manifest.json](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/assets/manifest.json)
- [release/assets-inventory.json](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/assets-inventory.json)
- [release/catalog/game.json](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/catalog/game.json)
- [release/distribution/platforms.json](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/distribution/platforms.json)
- [release/tools/source_fingerprint.gd](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/tools/source_fingerprint.gd)
- [release/tools/validate_package.gd](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/tools/validate_package.gd)
- [release/tools/apply_aesthetics.ps1](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/tools/apply_aesthetics.ps1)
- [release/tools/generate_assets.gd](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/tools/generate_assets.gd)
- [release/tools/generate_branding.gd](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/tools/generate_branding.gd)
- [release/tools/release.py](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/release/tools/release.py)
- [tests/test_distribution.py](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/tests/test_distribution.py)
- [tests/workflow.ps1](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/tests/workflow.ps1)
- [tests/web_smoke.cjs](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/tests/web_smoke.cjs)
- [icon.svg](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/icon.svg)
- [assets/icon_monochrome.svg](https://github.com/miguelxhubgitty/dont-touch-me/blob/8cee57ced64e5640872518e2a3822a6e93c65d03/assets/icon_monochrome.svg)

Alpha-only/published-release additions were read at their own snapshots:

- [release/ALPHA_REPORT.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/release/ALPHA_REPORT.md)
- [release/tools/generate_typography.gd](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/release/tools/generate_typography.gd)
- [assets/fonts/title.tres](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/assets/fonts/title.tres)
- [assets/typography/phrases.gd](https://github.com/miguelxhubgitty/dont-touch-me/blob/d61c86568b40c23a291db7aa2757ffe82e1896e8/assets/typography/phrases.gd)
- [release/PUBLICATION_v0.1.0-alpha.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/c2ea4a003403c7568944e74dd069e03a9e9d2bff/release/PUBLICATION_v0.1.0-alpha.md)
- [release/ITCH_PUBLISHING.md](https://github.com/miguelxhubgitty/dont-touch-me/blob/c2ea4a003403c7568944e74dd069e03a9e9d2bff/release/ITCH_PUBLISHING.md)
- [release/distribution/itch.json](https://github.com/miguelxhubgitty/dont-touch-me/blob/c2ea4a003403c7568944e74dd069e03a9e9d2bff/release/distribution/itch.json)
- [release/tools/itch.py](https://github.com/miguelxhubgitty/dont-touch-me/blob/c2ea4a003403c7568944e74dd069e03a9e9d2bff/release/tools/itch.py)
- [tests/test_itch.py](https://github.com/miguelxhubgitty/dont-touch-me/blob/c2ea4a003403c7568944e74dd069e03a9e9d2bff/tests/test_itch.py)

## Historical cross-reference

Commit subjects/history and the relevant source diffs were checked, especially the actual cardboard-input correction and the Alpha/main controller diff. These links allow the owner to inspect a milestone without relying on a moving branch. Related tooling commits on main/release are distinct commits, not necessarily distinct runtime behavior.

| Commit | Recorded subject |
| --- | --- |
| [9307c4b](https://github.com/miguelxhubgitty/dont-touch-me/commit/9307c4b8a678eb23108925827e685b21218f6956) | Build complete Don't Touch Me procedural Godot game |
| [ca4c5d8](https://github.com/miguelxhubgitty/dont-touch-me/commit/ca4c5d871e237fabcd378e987c75752ba6dac603) | Enable Android texture imports and verify APK export |
| [46eeff3](https://github.com/miguelxhubgitty/dont-touch-me/commit/46eeff363edd104187de9aaccd1b3dc165c5a0e4) | Finalize version 1.0 testing and mobile release preparation |
| [ecdb9bb](https://github.com/miguelxhubgitty/dont-touch-me/commit/ecdb9bbb70629afe273efd4c4b75949ed5a8c0fd) | Prepare complete version 1.0 store release package |
| [b301c9e](https://github.com/miguelxhubgitty/dont-touch-me/commit/b301c9ef2c19f67a4bb3712f686c548d7cb0b73f) | Publish privacy policy and finish owner-only release handoff |
| [a6bacc4](https://github.com/miguelxhubgitty/dont-touch-me/commit/a6bacc4c80ba9b3aab91c24a1e543ba53fb725a1) | Make asset inventory verification portable across checkout line endings |
| [58523bb](https://github.com/miguelxhubgitty/dont-touch-me/commit/58523bbdb95b2e0e601740b175f3d8cf62caee90) | Merge remote-tracking branch 'origin/main' |
| [f902ddf](https://github.com/miguelxhubgitty/dont-touch-me/commit/f902ddf047828f9b8f23ab16427e33001a7029c0) | Delete business/README.md |
| [c0bfa4e](https://github.com/miguelxhubgitty/dont-touch-me/commit/c0bfa4e18b8d4050c810518d48df66bfa76acc22) | Use Space Grotesk and Ink Free phrase graphics in actual gameplay |
| [c739782](https://github.com/miguelxhubgitty/dont-touch-me/commit/c7397822bf4e4303404f57544b1c35f3db57165f) | Restore baseline gameplay presentation on main; retain typography on aesthetic branch |
| [5be3a20](https://github.com/miguelxhubgitty/dont-touch-me/commit/5be3a20475bba305c3ca26a07141771792e6b309) | Add gameplay-first release branch workflow and portable source validation |
| [4a364f5](https://github.com/miguelxhubgitty/dont-touch-me/commit/4a364f57b075b8bfd792ad76cd2d461ceb471b04) | Preserve typography snapshot with reusable release tooling and portable checks |
| [c395f26](https://github.com/miguelxhubgitty/dont-touch-me/commit/c395f26b592576a213fe80abba0e3098d4101e44) | Use fixed integration base and verify patches through a temporary index |
| [e908b2a](https://github.com/miguelxhubgitty/dont-touch-me/commit/e908b2ad923289648539d0accb6a66d6fa50ab9d) | Use fixed integration base and reject conflicts before changing release files |
| [33ddbc1](https://github.com/miguelxhubgitty/dont-touch-me/commit/33ddbc194cb7bd535896536ad94bc321a4ee0d4c) | Cover safe rejection of overlapping future presentation edits |
| [82e88dc](https://github.com/miguelxhubgitty/dont-touch-me/commit/82e88dc3ad66a62b36a02981a539955d8a0810b6) | Cover safe rejection of overlapping future presentation edits |
| [d5a2874](https://github.com/miguelxhubgitty/dont-touch-me/commit/d5a2874142268d90481142c07379d4a92721943d) | Document verified branch integration and finalization instructions |
| [7ea86fc](https://github.com/miguelxhubgitty/dont-touch-me/commit/7ea86fcee2168d0808ad070b8ca2a5a5c13ffc9e) | Record branch workflow validation and update release authoring instructions |
| [a35fb02](https://github.com/miguelxhubgitty/dont-touch-me/commit/a35fb02411042ed106c43863e81fc40bc19b563b) | Apply approved typography to Public Alpha v0.1.0-alpha |
| [78356d9](https://github.com/miguelxhubgitty/dont-touch-me/commit/78356d93fc875fd0b15835b982c40a03648a7c82) | Add reusable offline multi-format release and distribution tooling |
| [6842e56](https://github.com/miguelxhubgitty/dont-touch-me/commit/6842e56e335af5c078c14d507a41db573cb766d8) | Add reusable offline multi-format release and distribution tooling |
| [9788e03](https://github.com/miguelxhubgitty/dont-touch-me/commit/9788e0343cb888a31ea9092f7409e2455a961261) | Finalize Public Alpha v0.1.0-alpha metadata and shared release artwork |
| [4713bc1](https://github.com/miguelxhubgitty/dont-touch-me/commit/4713bc1c45758bc25fc087692781a4667f5e9160) | Handle Godot 4.7 Web startup and nonpersistent Android build tooling |
| [a250b99](https://github.com/miguelxhubgitty/dont-touch-me/commit/a250b993dbde7fcbe18768f2753ec01a5dd0a578) | Handle Godot 4.7 Web startup and nonpersistent Android build tooling |
| [ede5a6c](https://github.com/miguelxhubgitty/dont-touch-me/commit/ede5a6cee8b44aa3b2199416c8e08ed594667f93) | Record engine provenance and preserve explicit runtime validation failures |
| [df018a8](https://github.com/miguelxhubgitty/dont-touch-me/commit/df018a8f1f35f4e57c34c9f5d9ee9720f7d5665a) | Record engine provenance and preserve explicit runtime validation failures |
| [d61c865](https://github.com/miguelxhubgitty/dont-touch-me/commit/d61c86568b40c23a291db7aa2757ffe82e1896e8) | Record prepared Public Alpha artifacts and distribution readiness |
| [b8c04e9](https://github.com/miguelxhubgitty/dont-touch-me/commit/b8c04e9805cc462f876f354e9287efb48a1ffb51) | Add guarded Butler draft uploads for validated Alpha packages |
| [2d0e3b6](https://github.com/miguelxhubgitty/dont-touch-me/commit/2d0e3b6d64b24c5f6d7dac97dec3f129d37762a7) | Record verified private Alpha uploads and approved itch tagline |
| [ee0372c](https://github.com/miguelxhubgitty/dont-touch-me/commit/ee0372cae0a66e10518ecc38c051c364d114c9dd) | Integrate verified draft-only itch.io publishing automation |
| [0815422](https://github.com/miguelxhubgitty/dont-touch-me/commit/0815422efd3762897c3658424d96dacce6872b19) | Verify same-listing Alpha uploads and correct Windows platform tag |
| [abfe1eb](https://github.com/miguelxhubgitty/dont-touch-me/commit/abfe1ebeac3c5e5f317eb79204a745ee99ee0ac8) | Record verified Windows download alongside HTML5 draft |
| [b9fa56f](https://github.com/miguelxhubgitty/dont-touch-me/commit/b9fa56f5664dfe9b9fe1c85191ca7eb8da6b1162) | Document future audio design and gameplay expansion roadmap |
| [d79c3b4](https://github.com/miguelxhubgitty/dont-touch-me/commit/d79c3b4f169bf9c46e3ba381b89a199338a0d671) | Plan sleeping animation eye-jitter fix without changing gameplay |
| [ed70cc4](https://github.com/miguelxhubgitty/dont-touch-me/commit/ed70cc42e4c9710b32c0d49dd2630559e3b99532) | Instruct Codex to track proposed game changes separately from implementations |
| [2c5a708](https://github.com/miguelxhubgitty/dont-touch-me/commit/2c5a708339e6c7b97047c49b1f3098fb6d86d8ac) | Add hidden-eyes sleep option to planned animation fix |
| [6bf3a46](https://github.com/miguelxhubgitty/dont-touch-me/commit/6bf3a467bdc994f5a29ebf47975bb10b0c499fc1) | Record authorized itch.io Public Alpha publication and verified play options |
| [c2ea4a0](https://github.com/miguelxhubgitty/dont-touch-me/commit/c2ea4a003403c7568944e74dd069e03a9e9d2bff) | Record Public Alpha v0.1.0-alpha release on itch.io |
| [9c5becb](https://github.com/miguelxhubgitty/dont-touch-me/commit/9c5becbab21ed707179807291bcedaa136be41a3) | Establish detailed internal developer journal standard |
| [1741ec2](https://github.com/miguelxhubgitty/dont-touch-me/commit/1741ec28849744f48b75b2d2f35a5485a37fdd21) | Require detailed internal journal and Butter Boy public devlog voice |
| [8cee57c](https://github.com/miguelxhubgitty/dont-touch-me/commit/8cee57ced64e5640872518e2a3822a6e93c65d03) | Require owner-approved pseudocode plans before gameplay changes |

## Verification performed for this documentation PR

- Fetched current remote branches/tags; inspected AGENTS, branch workflow, roadmap, the complete plans directory (one sleep-eye plan), journal scaffold, Alpha source, development source, release reports/settings/resources/test source and relevant history.
- Confirmed source-tree identity across export source9788e03, tagd61c865 and publicationc2ea4a0 for every runtime path listed above.
- Compared the **whole** Alpha controller with main after removing only the documented typography/filtering changes: exact equality passed. This is stronger than assuming matching reaction names means matching behavior.
- Reviewed pseudocode against each controller function and each reaction override, including ordering, threshold-crossing whole-delta decay, interruption snapping, shield/peek priority, shared random stream, direct-helper versus input rules and WAKE's repetition exception.
- Mechanically checked all16 reaction headings/names/durations against the actual DURATIONS dictionary: passed.
- Generated function concordance from actual pinned source line positions, not guessed line numbers. Checked all local Markdown links/anchors and84 immutable source links/line locations in the initial complete draft; passed. Later additions are included in final link/scope checks.
- Fenced-code blocks balanced and Git whitespace validation passed. Mermaid source is provided; an independent Mermaid rendering tool was not used here.
- Change allowlist is exactly AGENTS.md plus the three docs chapters. Compared all gameplay scripts/assets/scene/project/export settings, tests, release directory and hosted HTML pages with the main base: unchanged. No release binary, artwork, audio, version/tag or published content was generated or edited.

No Godot import, gameplay suite, render generator, export, emulator, physical-device test or website publication was run for this documentation-only change. Historical passing results in the journal come from identified reports; they are not relabeled as fresh tests. No production credentials were accessed or created.

## System-to-test traceability and remaining gaps

| System | Existing automated evidence inspected | Important uncovered question |
| --- | --- | --- |
| Pressed input/misses/releases |behavior run; release viewport dispatch | Physical event delivery/multitouch on actual phones |
| Current silhouette/transforms and box blocking |behavior hitbox/cardboard/peek-eye and edge loops | Every antialiased edge/rounded corner pixel |
| Tier pools/randomness/nonrepeat |behavior boundary/250-sample loops; release long sessions | Statistical fairness/discovery guarantee (not implemented); repeated WAKE is exempt |
| Annoyance buildup/clamp/decay |behavior1000-hit loop; release grace/threshold checks | No real-time off-focus accumulation, by current source |
| All16 reaction poses/completion |behavior durations loop; release41-sample/aspect and helper matrix | Continuous visual quality between sampled frames |
| Protected escape/hide recovery |behavior600-step spam; release long-session recovery | Actual device rapid-input stress over prolonged play |
| Idle blink/gaze/breath/outline |Pose source, render idle/sleep, simulation advancement | No dedicated natural-blink/gaze cadence or smoothness assertions |
| Sleep/wake |behavior40-second rest/wake; release threshold/background/focus | Root cause/reproduction of reported eye jitter |
| Resize/focus |behavior forced resize; release4 layouts/notification assertions | OS app switching/cutouts/unsupported tiny layouts |
| Text/eyes/props/draw order |release dialogue width; Alpha typography; render snapshots | Native iOS font/capture/safe-area presentation |
| Capture provenance/metadata |fingerprints; validate_package; inventory tooling | Matching dimensions/hashes doesn't guarantee store acceptance |
| Release integration/package/cache |workflow19-assertion report; Python14-test fixtures | Native Linux/macOS/iOS runtime unavailable in recorded handoff |
| itch publication safety |Later release test_itch source includes6 tests, including live-listing rejection | No fresh upload/status action here; tests inspected, not rerun |

Exact numerical tuning motivations are not recoverable from the inspected history. The sleep report establishes an observation and a proposal, not a proven cause. No binary reverse engineering/fresh public download was performed, so published runtime provenance is reported as recorded export identity plus verified Git runtime equality. Current server state, account verification, legal judgments and future store rules aren't newly audited by this PR.

The earlier privacy HTML still labeling1.0 is recorded as a separate follow-up by the publication report. Main's older version/catalog/publication views are deliberately documented rather than silently synchronized under a no-release-file-change task. Plans remain plans; no sleep-eye fix, sound, counter, trust, petting, customization or monetization is claimed shipped.
