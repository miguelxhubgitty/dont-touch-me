# Public Alpha v0.1.0-alpha — prepared, not published

Prepared October 31, 2026 on Windows with Godot `4.7.2.stable.official.ed1daf0bf`. No store upload/submission, GitHub Release, website deployment, account change, payment or DNS change was performed.

The release started at main `7ea86fc`, applying approved typography from `d5a2874` through the existing three-way workflow. Gameplay/typography runtime is unchanged from the approved `c0bfa4e` presentation. Exported artifacts were built from clean source commit `9788e0343cb888a31ea9092f7409e2455a961261`; later commits correct shared tooling and document validation without changing runtime content. Main receives only focused tooling/catalog commits and retains its basic fonts and original gameplay/export settings.

## Finished local handoff

Game-repository-relative location: **`builds/v0.1.0-alpha/`** (ignored by Git). It contains format-grouped artifacts, one shared store-material bundle, 25 upload checklists, `manifest.json`, `prerequisites.json`, `validation.json`, `REPORT.md` and `SHA256SUMS`. Binaries are deliberately not committed to source control. The manifest records source commits, actual engine version/hash, raw/package SHA-256, signing and validation scope.

| Format | Package / size | Verification | Reuse / remaining work |
|---|---|---|---|
| Windows x86_64 | `windows/DontTouchMe-v0.1.0-alpha-windows.zip` — 36.92 MiB | PE structure, ZIP integrity and exported executable's 120-frame headless smoke, including execution from its standalone output directory | itch.io, Game Jolt, GitHub download; Steam/Epic can reuse binaries with depot/tooling/account work. Unsigned. Microsoft Store still needs its GDK/MSIXVC adapter/certification. |
| Web single-thread | `web/DontTouchMe-v0.1.0-alpha-web.zip` — 10.40 MiB | Root `index.html`, JS/Wasm/PCK, ZIP integrity, actual WebGL browser startup, rendered canvas, desktop click, mobile-sized touch/resize, no runtime errors | itch.io, Game Jolt, Newgrounds and separately authorized hosting. Browser portals require acceptance and their SDK/viewport requirements; no ads/payment SDK added. |
| Android ARM64 debug APK | `android/raw-android-apk/dont-touch-me-debug.apk` — 27.58 MiB | APK signature, version name/code, 16 KB ZIP alignment and native ELF alignment | Local alpha testing only; default debug signing is not a production identity. Current physical-device execution unverified. |
| Android ARM64 unsigned AAB | `android/raw-android-aab/dont-touch-me-unsigned.aab` — 25.81 MiB | Archive/manifest presence, ARM64 native libraries, ELF alignment and absence of production signature | Release-mode preparation input. Owner-controlled upload signing, account/Play App Signing, actual delivered-device/platform validation and declarations required. Not upload-ready. |
| Linux x86_64 | `linux/DontTouchMe-v0.1.0-alpha-linux.zip` — 27.74 MiB | ELF architecture, ZIP integrity and executable mode preserved | Reusable direct-download/depot input. Native Linux runtime unverified on this host. |
| macOS Universal | `macos/DontTouchMe-v0.1.0-alpha-macos.zip` — 57.53 MiB | `.app` structure, executable modes and ZIP integrity preserved | Cross-exported, unsigned and not notarized; requires Mac runtime/signing/notarization review. No native-Mac or App Store readiness claim. |
| iOS | `ios/STATUS.json`; no fabricated IPA/archive | Recorded unavailable | Requires Mac/Xcode, Team ID, provisioning, signing and native validation; follow `IOS_EXPORT.md`. |

All destinations remain `not_published`; live URLs and last successfully published versions remain null. Shared branding now includes an actual-renderer 630×500 itch cover. Apple-sized screenshots remain Windows reference renders. The local privacy draft is updated for this alpha; existing hosted policy/support/website readiness must be reviewed before submission. Intended audience, official age ratings, publisher rights and account verification require owner confirmation.

## Validation and reuse evidence

- Behavior: **320,270 checks passed**; input/layout/release: **237,076 passed**; source fingerprints: **17 passed**; typography: **127 passed**; release package: **205 passed**.
- New distribution regression suite: **14 tests passed**, covering free-policy enforcement, false publication state, duplicate/unknown references, invalid versions, raw-artifact tampering, unchanged-package reuse, notice changes, executable modes, unavailable exports and stale shared-asset validation.
- Updated basic-font main passed the same behavior/layout/fingerprint suites, the 14 distribution tests and **19 branch-integration assertions**; no runtime aesthetics or gameplay changes were backported.
- Browser evidence: `logs/web-smoke.json`, `web-desktop.png`, `web-mobile.png`; desktop 432×768, mobile-sized 390×844, installed Chromium-based browser with software WebGL. This is not mobile-device performance certification.
- One store-art finalization pass regenerated current captures and the cover; approved handwritten phrase graphics were reused. Repeating finalization reported reuse without rendering.
- A second export/package run explicitly reused **all six existing exports and all four ZIP packages** without re-exporting or regenerating graphics. Complete handoff checksums passed.
- Android's initial completed Gradle export left a task-owned daemon keeping the console launcher open. Only that identified daemon was stopped. Shared tooling now disables persistent Gradle daemons; the earlier existing Godot process was not touched. Template shutdown warnings are retained in the export log, not presented as a gameplay/device result.

## Before external distribution

Use the destination's generated checklist, not a blanket “all stores ready” assumption. Confirm free/no-payments settings, legal seller identity, rights, audience/rating, policy/contact URLs, account status and any required signing/SDK/adapter/review. F-Droid remains blocked by current original-code/art licensing; Amazon's record concerns Fire devices, not its discontinued generic Android-phone store.

See [RELEASE_SYSTEM.md](RELEASE_SYSTEM.md) for repeatable commands and [distribution/platforms.json](distribution/platforms.json) for the editable registry. Source pushes and the annotated source milestone tag do not publish these binaries.
