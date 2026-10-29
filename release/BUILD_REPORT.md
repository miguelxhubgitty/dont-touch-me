# Version 1.0 release-package verification

Executed 2026-10-29 on Windows using **Godot 4.7.2.stable.official.ed1daf0bf**. Rendering used the Compatibility/OpenGL renderer on NVIDIA GeForce RTX 3080. This is a local-build report, not a store approval or physical-device result.

## Game preservation and audit

The gameplay script and scene are unchanged in this packaging pass. There are 15 regular reactions plus the special wake-up reaction. Gameplay script SHA-256: `1092a56ec887a26f583507271484a59285995a62678e68b62f882a27efffc7ec`.

A final launcher-resource audit found the optional Android themed/monochrome icon still contained the default Godot logo. Added an explicit blob monochrome source and matching launcher density resources; both Android presets now reference it. This changes the launcher asset, not the character design or gameplay.

The complete shipped script, scene, project settings, export presets, and final Android manifests were inspected. No network or account service, advertising, analytics, billing, persistent player storage, or user-content transmission was found. The APK and AAB request no permissions. Engine-local technical logs/cache remain possible and are disclosed in the policy; no packet-capture or full native-engine source audit is claimed. See `DATA_SAFETY.md` for scope and declaration limits.

## Executed tests

| Check | Observed result |
| --- | --- |
| Headless editor import/script loading | Passed, exit 0; no project/GDScript errors |
| `tests/behavior.gd` | **320,270 checks; 0 failures** |
| `tests/release.gd` | **237,076 checks; 0 failures** |
| `release/tools/validate_package.gd` | **179 checks; 0 failures** |
| Combined automated assertions | **557,525 passed** |
| `tests/render.gd`, real Windows renderer | Rendered 18 states and four mobile aspect ratios; exit 0 |
| `release/tools/generate_assets.gd` | Generated **39 PNGs**, including 20 direct gameplay captures; no save failures |
| Graphics inspection | Feature graphic, selected full-size captures, and all 20 captures in a QA contact sheet inspected; no clipping observed |
| Metadata validation | Google short 65/80; Google full 789/4000; Apple subtitle 30/30; promo 137/170; description 812/4000; keywords 77/100 characters and ASCII bytes |
| Final Windows release runtime | 120-frame headless smoke run, exit 0, no runtime errors |
| Policy HTML sanity checks | Disclosure sections present; no scripts, forms, or frames; hosting not activated |

The behavior suites exercise all reaction lifecycles, tier boundaries and random coverage, nonrepetition, escalation/decay, sleep/wake, transformed and occluded hitboxes, rapid input, the 16×16 interruption matrix, recovery, focus pause/resume, actual viewport mouse/touch dispatch, and multiple logical aspect ratios. The assertion count includes repeated geometry samples; it is not a count of independent human playthroughs.

## Successful generated builds

All files below are local under the ignored `builds/` folder. They are not committed binaries or automatically downloadable through GitHub.

| Artifact | Approximate size | Result / signing |
| --- | --- | --- |
| `windows/DontTouchMe.exe` | 104.23 MiB | Windows x64 release export, embedded game data, unsigned Windows executable; correct name/version resources |
| `windows/DontTouchMe-Windows-1.0.0.zip` | 37.50 MiB | Portable executable, play instructions, third-party notices |
| `android/dont-touch-me-debug.apk` | 27.01 MiB | Installable-format ARM64 APK, signed with the existing **debug** key; no device installation performed |
| `android/dont-touch-me-unsigned.aab` | 25.25 MiB | Gradle **release-mode unsigned** AAB; structurally validated, not a signed Play-ready upload |

Android metadata in both final formats: package `com.littlebutterflyproductions.donttouchme`, version `1.0.0`, code `1`, minimum SDK `24`, target SDK `36`, ARM64, portrait. Current Google Play target-API documentation requires API 36 for new phone-app submissions; recheck before submitting.

### Android artifact validation actually executed

- APK v2/v3 signature verification passed using Android Build-Tools `apksigner`.
- APK 16 KB ZIP alignment check passed using `zipalign -c -P 16 4`.
- Every LOAD segment of both packaged ARM64 native libraries in **both APK and AAB** had alignment of at least 16 KB, inspected with `llvm-readelf`.
- Google's official **bundletool 1.18.3** validated the final AAB with exit 0. Its metadata declares `PAGE_ALIGNMENT_16K`.
- Bundle manifest extraction confirmed expected version/SDK/orientation and no requested permissions. `jarsigner -verify` confirmed the preparation AAB is **unsigned**; absence of a JAR signature manifest is expected for this unsigned file, not absence of Android's manifest.
- ZIP contents confirmed `THIRD_PARTY_NOTICES.txt` is included and release graphics/docs/tests/generated build folders are excluded from both Android formats.
- Initial Gradle-template installation completed with editor shutdown warnings (scan cancellation/ObjectDB instance) and kept a Gradle daemon alive. Stopping that task-created daemon and disabling persistent Gradle daemons for the local template allowed clean subsequent export completion. The **final** Windows, APK, and AAB export logs contain no errors or warnings. No gameplay crash or logic failure was found in this pass.

The Gradle template/dependency downloads are build-time tools only; they are not an in-game online dependency. No production upload key, certificate, developer account, paid service, or payment was created. A release-signed AAB cannot be completed without the owner's authorized signing identity.

## Not verified / requires action

- Physical Android installation, sustained mobile performance, safe areas, app lifecycle, update paths, and 16 KB device execution.
- Android device inventory was checked with `adb devices -l`; no test device was attached. The corrected themed icon was extracted from the final APK and visually checked as the blob rather than the Godot logo.
- iOS export/archive/signing, iPhone/iPad/Simulator execution, native screenshots, and native privacy manifests. Apple-sized images are honest Windows Godot reference renders, not native-device screenshots.
- Production signing, Play internal/closed testing, TestFlight, store validation/review, name/IP clearance, legal declarations, final content ratings, target audience, support email, pricing, and countries.
- Live privacy/support hosting. Ready-to-host files exist, but GitHub Pages was not enabled and the suggested URLs were not claimed live.

Use `RELEASE_CHECKLIST.md` for the exact remaining sequence. Supporting local logs are ignored under `test-output/package-*`; build checksums are recorded under `builds/artifact-sha256.json`.
