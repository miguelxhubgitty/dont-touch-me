# Public Alpha macOS package correction — November 1, 2026

The existing [v0.1.0-alpha release](https://github.com/miguelxhubgitty/dont-touch-me/releases/tag/v0.1.0-alpha) now serves a corrected macOS ZIP. This was an explicitly authorized replacement of the macOS package and its checksum entry, not a new game version or devlog. No PR was merged.

## Validation before replacement

The immutable tag object remains `2833340e4ca470620f6bdff91c8834fe70c7096d`, resolving to approved source commit `d61c86568b40c23a291db7aa2757ffe82e1896e8`. The scratch export's source commit `7af0d6dc06372713ca223cfb0e02e92fd5b9f0cf` has identical scripts, assets, scene and project configuration to the tag. The release branch, tag and approved game files were not rewritten.

The corrected PCK is not byte-identical to the historical Windows-produced PCK. Both contain the same 49 resource paths. Gameplay bytecode, imported textures/fonts, project binary and other resources match exactly except five entries: three text files differ only in CRLF/LF encoding (icon SVG and two license notices), the UID cache differs, and the exported main-scene serialization differs. Normalized text hashes match; loading the scene confirms the identical Node2D root and `res://scripts/blob.gd` binding with identical properties. The UID cache is regenerated import metadata. No gameplay, visuals or behavior change was identified. The app Info.plist, external icon and privacy resource are byte-identical.

Automated package validation passed ZIP CRC checks, Unix executable permissions (`100755`) and strict signature verification for **all architectures**. Every app file inside the corrected ZIP matches the local exported app used for interaction checks. Earlier native startup smoke testing (`--headless --quit-after 120`) exited 0 for these exact app bytes.

On this Intel MacBookPro16,1 running macOS 26.3.1 (a), agent-operated native UI checks reconfirmed startup/rendering, repeated mouse reactions, inactivity sleep, click-to-wake with `I was DREAMING.`, and resizing through native window zoom/restore. The blob remained visible and scaled/recentered in the enlarged window. These are UI observations, not automated test assertions; exhaustive smoothness, every reaction, Apple Silicon hardware and system suspend/resume are not claimed.

The former app failed its resource seal because signing was disabled and the template signature was retained. The corrected app has an ad-hoc signature and sealed resources. The original **“damaged”** signature error is resolved. The user observed the remaining **“Apple could not verify”** warning for the quarantined corrected package. It is **not Developer ID signed or notarized**, and ad-hoc integrity does not confer Gatekeeper trust. Global Gatekeeper assessments remained enabled; no global bypass or quarantine removal was performed to claim a passing distribution test.

## Backup and bounded release update

Before mutation, downloaded and verified the original public macOS ZIP and SHA256SUMS against GitHub's asset digests. Backed up release notes/metadata and tag metadata as well. Local backup directory:

`/Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup/release-fix-validation/backup`

The old macOS ZIP SHA-256 was `111bffb1bbf431422a250a94dba919f1b16af7cef37614336ef956d7a325e7fa`. The old SHA256SUMS file SHA-256 was `1b450dcf9ac96ccb61d32d0199e2505382997e797e786db777654129395a16bf`.

The supplied corrected ZIP was uploaded unchanged under the existing public macOS filename. Release ID `430296808`, tag object/commit, version, draft/prerelease state and existing public download URLs were preserved. No Windows, Linux, Web or Android asset was replaced: each retained its original asset ID, size and digest.

| Replaced asset | New GitHub asset ID | Bytes | SHA-256 |
| --- | --- | --- | --- |
| `DontTouchMe-v0.1.0-alpha-macos.zip` | 697336491 | 59863757 | `b7854c72f0a1389830acc5eae92db9e1c3e058a3ce5bb610333a6e2e4f4bca66` |
| `SHA256SUMS` | 697336492 | 14374 | `817eeb805dfe0625c751b335357e31453ba203f3ae0426a8d30f57fa2d65fd0b` |

SHA256SUMS retains its original CRLF formatting and historical handoff entries. Exactly one line changed: the hash for `macos/DontTouchMe-v0.1.0-alpha-macos.zip`. Historical inner/raw exports are not relabeled as new artifacts.

Release notes now describe the signing/packaging correction, Intel native testing and remaining verification warning. Their macOS package hash was updated. Other platform testing/signing caveats remain intact.

## Public and website verification

Downloaded both updated assets with anonymous curl requests, without authorization headers or GitHub CLI authentication. Both hashes match the values above. Re-read the release metadata and tag afterward; protected assets and tag were unchanged.

The [WANDIEL game page](https://wandiel.com/projects/dont-touch-me/) still links to the same [macOS download URL](https://github.com/miguelxhubgitty/dont-touch-me/releases/download/v0.1.0-alpha/DontTouchMe-v0.1.0-alpha-macos.zip). A fresh anonymous download from that exact URL also matched the corrected hash. No website source change or deployment was necessary.

Local evidence includes the original backups, before/after release JSON, anonymous downloads, semantic resource-pack comparisons and publication verification receipt under `WorkstationSetup/release-fix-validation`. Raw logs and credentials are not committed.

## Future tooling and remaining limits

A separate tooling branch/PR based on main records the design before implementation. It defaults new/migrated disabled macOS presets to built-in ad-hoc signing, preserves stronger configured signers, requires a resource seal, runs strict native codesign checks on macOS, preserves bundle bytes/permissions when packaging and invalidates only macOS's old export/package recipe. The general publisher continues refusing replacement without a separately scoped owner-approved correction.

Validation of that tooling: 22 Python regression tests passed, one existing-package check skipped because the local historical package fixture is absent; the PowerShell workflow integration suite passed 19 checks. A fresh Godot built-in-ad-hoc export and the approved corrected ZIP both passed the new guard and strict all-architecture signature verification. No gameplay or visual asset was changed to achieve these results.

Remaining limits: Developer ID trust/notarization is absent; physical iOS testing/provisioning still requires a connected trusted device; Apple Silicon native macOS execution is untested. No membership was purchased and no store submission was made. Documentation and tooling PRs require owner review and are not merged automatically.
