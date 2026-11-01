# Don't Touch Me

Local multi-platform release preparation is documented in [release/RELEASE_SYSTEM.md](release/RELEASE_SYSTEM.md). Shared store data lives in `release/catalog/game.json`; the 25-platform registry is `release/distribution/platforms.json`. Nothing is uploaded by these tools.

A tiny, offline comedy about a blob and its personal space. Built with **Godot 4.7.2 stable**, GDScript, procedural shapes, and the engine's bundled font. No dependencies or downloaded assets.

## Open and play

Import `project.godot` in Godot 4.7.2 stable and press **F6** in `main.tscn`, or **F5** to play the project. Click or tap the blob. Touching the background does nothing. Persistent pokes reveal increasingly dramatic reactions; leave it alone to let it relax and eventually sleep. Poking a sleeping blob wakes it with a special reaction. There are no menus or scores.

The portrait canvas uses a 720 × 1280 reference with expanding canvas stretch, including tall phones and tablets. Desktop preview is 432 × 768. Mouse and native touchscreen paths share the same silhouette hit test and do not emulate duplicate events. No sound, network access, permissions, saved personal data, ads, or purchases.

## Implementation

`main.tscn` and `scripts/blob.gd` contain the complete game. One animation clock owns pose, expressions, props, and speech; taps can interrupt short reactions while box and run reactions always finish. Annoyance is clamped to 0–100, with nonrepeating random choices in four tiers. Relaxation starts after 2.5 seconds, sleep after 24 seconds. Focus loss pauses the clock. Resizing cancels motion safely. There are 15 regular reactions plus a special wake reaction.

## Local checks

Gameplay development stays on `main` with the engine's basic font. The approved release typography is preserved on `aesthetic/typography-v1`; integrate it into a fresh `release/<version>` only when gameplay is ready. See [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md) for the exact procedure. Do not regenerate typography/store images during routine development.

Current branch/integration results: [WORKFLOW_VALIDATION.md](WORKFLOW_VALIDATION.md).

From this folder (substitute the path to your Godot executable):

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/behavior.gd
godot --headless --path . --script tests/release.gd
godot --headless --path . --script tests/fingerprints.gd
```

The behavior suite checks tier boundaries, random coverage, repetition avoidance, all animation lifecycles, transformed hitboxes, visible bounds, rapid taps, escape recovery, relaxation, sleep/wake, input paths, and resizing. Optional `godot --path . --script tests/render.gd` produces an ignored contact sheet when pose/layout changes need review; it is not a routine image-generation step. Package validation is a final release gate, since existing store captures intentionally remain historical while gameplay changes. These checks are not a substitute for testing on physical phones.

## Android / future iOS

An ARM64 Android preset is included, with signing enabled. Install matching Godot export templates and configure the Android SDK, JDK, and local debug keystore in the editor before exporting a debug APK. Create `builds/android/` if needed. The application ID is `com.littlebutterflyproductions.donttouchme`; version is `1.0.0` (code 1). Main and adaptive launcher icons are generated locally. No credentials are required to open or play the project in the editor. Release signing requires your own release/upload key; none is included. Keystores, local credentials, and builds are ignored by Git.

iOS uses the same GDScript/Compatibility renderer and portrait layout. An iOS export will require matching templates, macOS/Xcode and your own signing configuration. No publishing setup is included.

A Windows x86-64 preset exports `builds/windows/DontTouchMe.exe` with embedded game data and version 1.0.0 metadata. Create `builds/windows/` before exporting. No Godot installation is needed to run the exported executable. On the development PC, current test artifacts are `builds/windows/DontTouchMe.exe` and `builds/android/dont-touch-me-debug.apk`; these files are local and are not downloadable from the source repository.

See [TESTING.md](TESTING.md) for observed results and [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) for the remaining store submission steps. Version 1.0 keeps the original 16 reactions; release preparation does not add gameplay.

## Complete publishing package

Public Alpha v0.1.0-alpha downloads are available at [GitHub Releases](https://github.com/miguelxhubgitty/dont-touch-me/releases/tag/v0.1.0-alpha), alongside existing [itch.io browser play and Windows download](https://wandiel.itch.io/dont-touch-me). See [release/GITHUB_RELEASES.md](release/GITHUB_RELEASES.md) for the explicit-approval publishing command and [publication evidence](release/GITHUB_PUBLICATION_v0.1.0-alpha.md). Linux is not native-tested; macOS is unsigned/not notarized/not native-tested; Android is a debug-signed testing APK. These are the existing Alpha packages, not rebuilt binaries.

[release/README.md](release/README.md) indexes all store graphics, actual gameplay renders, copyable store listings, code-based privacy/rating drafts, policy-hosting pages, and the Mac/Xcode handoff. Release materials are excluded from game exports.

The **Android AAB Unsigned** preset prepares a release-mode bundle with Gradle, target SDK 36, and no production signature. Install the Gradle template using Godot's Android build-template setup (or `--install-android-build-template` with the export command). An unsigned AAB is not ready to upload to Google Play: configure your own upload key, enable signing in a store-upload preset, and validate the signed result. No production key is included or generated.

Engine and bundled-component acknowledgments are in `THIRD_PARTY_NOTICES.txt`, generated using Godot's license metadata. This file is explicitly included in game exports and should accompany the portable Windows build. It does not license the original game's code/art.
