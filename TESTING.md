# Validation — 2026-10-29

## Final free-preparation follow-up

See [release/FINAL_AUDIT.md](release/FINAL_AUDIT.md): privacy/support Pages published and verified; existing APK/AAB audited without rebuilding; all 39 original graphics inspected; 237,076 focused desktop release checks and 179 package checks passed. The existing APK also installed and ran in BlueStacks Pie64 (Android 9) at two display profiles; tap reactions, dialogue, sleep/wake and portrait presentation were observed. Original emulator display/security settings were restored/preserved and the test instance closed. No physical device, newer Android OS, iOS build or production credential was used. The game/source/binary hashes are unchanged.

## Complete publishing-package pass

The latest executed results are in [release/BUILD_REPORT.md](release/BUILD_REPORT.md): all original suites rerun, 179 additional package checks passed (557,525 combined assertions), actual store-sized gameplay renders inspected, final Windows release and signed Android test APK rebuilt, and an unsigned release-mode AAB generated and validated with Google's bundletool. Gameplay code and the 16 reactions are unchanged in this packaging pass. Native mobile tests, production signing, and store submission remain pending.

## Final version 1.0 review

Release candidate for physical-device testing; not a claim of store readiness. Original 16 reactions preserved.

- Fixed a reproduced box hit-test bug: cardboard could be tapped through to the hidden body, and visible peek eyes were not touchable. Drawing and hit testing now share the flap geometry. All three regression assertions pass.
- Final behavior suite: **320,270 checks, 0 failures**. Additional release suite: **237,076 checks, 0 failures** (total **557,346**). The latter dispatches input through real Godot viewports, samples all reactions at four logical phone/tablet aspect ratios, exercises the full 16 × 16 interruption matrix, focus pause/resume, decay/sleep thresholds, and three deterministic mixed-input sessions of 6,000 frames each.
- Windows renderer: reran and visually inspected all 18 intro/reaction/sleep states and four independent logical aspect ratios (720×1280, 720×1600, 960×1280, 720×1920). Dialogue and poses fit the rendered layouts.
- Windows x86-64 release executable generated with embedded game data and application/version resources (`Don't Touch Me`, `1.0.0.0`). Interactive desktop check using computer-use mouse input observed tap responses, rapid input, sliding, hiding, recovery, inactivity sleep, and waking. This was a short desktop session, not a complete manual test of every reaction.
- Final rebuilt Windows executable also completed a 120-frame headless smoke run with exit 0 and no runtime errors. A portable Windows ZIP and local SHA-256 artifact manifest were generated under the ignored `builds/` folder.
- Android debug APK generated directly through the signing-enabled preset with the existing local debug key. Verified v2/v3 signatures, 16 KB ZIP alignment, and all LOAD segment alignments in both shipped ARM64 native libraries. These are static packaging checks, not a 16 KB device execution test.
- APK manifest: expected name/package/version, portrait, minimum SDK 24, target SDK 36, ARM64 only, no requested permissions. APK contains no tests, generated builds, or Markdown documentation. Main/adaptive icons and warm startup background configured; opaque 1024-pixel iOS icon prepared.
- Project import, script loading, export logs, and final automated runs complete without GDScript/runtime errors. Generated output and signing materials are excluded from Git.

Still untested: Android installation/play, mobile frame rate/memory/thermal behavior, device safe areas, iOS build/signing/install, release AAB, and store validation. See `RELEASE_CHECKLIST.md` for the exact remaining steps. No release credentials or device results were invented.

## Initial implementation checks (historical)

Engine: `4.7.2.stable.official.ed1daf0bf`, Windows, OpenGL Compatibility renderer on NVIDIA GeForce RTX 3080.

- Headless editor import and GDScript loading: passed, exit 0. The editor reported missing Android SDK build-tools; no project or script errors remained.
- Automated behavior suite: **320,266 checks, 0 failures**, exit 0. Includes all 16 reactions, tier boundaries and random coverage, repetition exclusion, animation completion, silhouette hitboxes, pose visibility at center and movement edges, tap spam, escape completion, relaxation, sleep/wake, mouse/touch handler paths, release rejection, and portrait/tablet resizing.
- Actual main scene: ran 180 frames using the Windows OpenGL renderer and exited 0 without errors.
- Rendered 18 states (intro, 15 normal reactions, wake, sleep) using the actual Windows renderer. Generated and visually inspected the contact sheet; speech, sign, box, eyes, squash/stretch, jump and offscreen peek rendered correctly.
- Git whitespace validation: passed before commit.

Not tested: manual desktop playthrough, physical touchscreen interaction, Android APK export/install, or iOS export. Automated input tests exercise the same game handlers but do not establish physical device usability. Android requires local SDK/JDK/templates and a signed debug build for installation. iOS export requires macOS/Xcode and signing configuration.

No known gameplay or GDScript errors remain from these checks.

## Android toolchain follow-up — 2026-10-29

Installed and configured on the development PC: Temurin OpenJDK 17, Android command-line tools, Platform-Tools, SDK Platform and Build-Tools 35 and 36, NDK r28b, CMake 3.10.2, and Godot 4.7.2 stable export templates. Java, command-line tools, and template archives were verified against official SHA-256 checksums. The installed Godot template targets Android SDK 36, so matching SDK 36 packages were added beyond the versions listed by the online setup guide.

The first Android export identified a required project setting: `rendering/textures/vram_compression/import_etc2_astc`. Enabled it and successfully exported an ARM64 Android debug APK. Package metadata confirms the correct application name and ID, version 1.0.0, minimum SDK 24, target SDK 36, and no requested permissions. A standard local debug key is used for the installable test copy; signing credentials and APKs remain outside Git. Physical Android installation/play and iOS export remain untested.
