# Don't Touch Me

Local multi-platform release preparation is documented in [release/RELEASE_SYSTEM.md](release/RELEASE_SYSTEM.md). The approved Windows export can also be packaged into Microsoft Store desktop MSIX using [release/MSIX.md](release/MSIX.md), only at final release time. Shared store data lives in `release/catalog/game.json`; the 25-platform registry is `release/distribution/platforms.json`. Nothing is uploaded by these tools.

A tiny offline comedy about a blob and its personal space, built with Godot 4.7.2 stable and GDScript. See [CURRENT_STATE.md](CURRENT_STATE.md) for the development baseline, pending work and release boundaries.

## Open and play

Import `project.godot` in Godot 4.7.2 stable and press **F5**. Click or tap the blob to see a reaction. Background taps make a sound and leave annoyance unchanged. Repeated pokes escalate the blob's responses. Leave it alone to relax and sleep after 18 seconds, then tap it to wake it.

Use **Sound On/Off** for master mute and **Volume** for the five saved category levels. Sound starts off for a fresh profile. The main scene uses authored AnimationPlayer visuals with a procedural fallback and a 720 × 1280 portrait reference.

## Develop and test

Use a dedicated branch and follow [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md). Development uses Godot's basic font. Approved release typography lives on `aesthetic/typography-v1` and is applied only during authorized release finalization.

Run `pwsh -File tests/run.ps1 fast -Godot <path-to-Godot-console-executable>` from the repository root. [TESTING.md](TESTING.md#development-test-runner) lists all four modes and device-test limits. The editor-only audition scene is `tests/audio_preview_menu.tscn`. Open it and press **F6** to audition individual cues.

Current Android/export settings are in `export_presets.cfg`. Platform exports require matching templates and the relevant SDK, signing or Xcode setup. Use [the release system](release/RELEASE_SYSTEM.md) for separately approved packaging.

## Complete publishing package

Public Alpha v0.1.0-alpha downloads are available at [GitHub Releases](https://github.com/miguelxhubgitty/dont-touch-me/releases/tag/v0.1.0-alpha), alongside existing [itch.io browser play and Windows download](https://wandiel.itch.io/dont-touch-me). See [release/GITHUB_RELEASES.md](release/GITHUB_RELEASES.md) for the explicit-approval publishing command and [publication evidence](release/GITHUB_PUBLICATION_v0.1.0-alpha.md). The [versioned Alpha manifest](release/distribution/manifest-v0.1.0-alpha.json) records exact hashes, validation and distribution limits. The GitHub Android artifact is a debug-signed testing APK. The corrected macOS artifact has recorded Intel validation and lacks Developer ID signing and notarization.

[release/README.md](release/README.md) indexes all store graphics, actual gameplay renders, copyable store listings, code-based privacy/rating drafts, policy-hosting pages, and the Mac/Xcode handoff. Release materials are excluded from game exports.

The **Android AAB Unsigned** preset prepares a release-mode bundle with Gradle, target SDK 36, and no production signature. Install the Gradle template using Godot's Android build-template setup (or `--install-android-build-template` with the export command). An unsigned AAB is not ready to upload to Google Play: configure your own upload key, enable signing in a store-upload preset, and validate the signed result. No production key is included or generated.

Engine and bundled-component acknowledgments are in `THIRD_PARTY_NOTICES.txt`, generated using Godot's license metadata. This file is explicitly included in game exports and should accompany the portable Windows build. It does not license the original game's code/art.
