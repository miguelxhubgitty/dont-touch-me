# Changelog

## 0.1.1 — release candidate on `release/0.1.1` — not published

- Everything merged to `main` since the Alpha through PR #66: audio (off by default, five saved volumes), Recoil and Puffer-huff, Stretch and Humming plus Stage 2 sleep idles, 18-second sleep, streak-based annoyance with gradual decay, movement continuity, Settings (volume; orientation on Android and iOS), landscape and short-window layout, the Privacy Policy button on Android and iOS, and the iOS launch screen. See [release notes](release/catalog/RELEASE_NOTES.md).
- Release presentation: typography-v1 (Space Grotesk and cached Ink Free phrases), Space Grotesk on the HUD, and a Settings panel styled in the game's palette. "STOP." re-rendered at 180 px to meet the 4x density standard.
- Versions: game 0.1.1; Windows/MSIX 0.1.1.0; macOS 0.1.1 (3); iOS 0.1.1 (2); Android 0.1.1 (version code 4, verified in Play Console). Web, Linux and macOS presets restored.
- The Android app ID changes to the Play ID `com.wandiel.donttouchme`, so the Alpha's sideloaded test APK does not upgrade in place.
- Web: the authored eyes and mouth are drawn with `draw_colored_polygon` instead of `Polygon2D`, avoiding a Godot 4.7.2 WebGL index-buffer bug ([godotengine/godot#124726](https://github.com/godotengine/godot/issues/124726)) that flooded the console with `INVALID_OPERATION` warnings and dropped index updates. Rendering is pixel-identical.

## 0.1.0-alpha — GitHub public prerelease — October 31, 2026

- Publish the existing Windows, Linux, macOS, HTML5 ZIPs, debug-signed Android testing APK and unchanged SHA256SUMS with explicit owner authorization. Preserve the existing tag and all artifact bytes; exclude the unsigned AAB. Verify every public download anonymously against its SHA-256.
- Label Windows unsigned, Linux not native-tested, macOS unsigned/not notarized/not native-tested and Android testing-only. Preserve existing itch.io uploads; no gameplay, typography, graphics or new builds.
- Integrate one-approval GitHub publishing into the release command, with draft staging, tag checks, named-asset digest reuse, no replacement/deletion, safe retries, append-only attempt receipts and public-download verification. Record exact verified URLs/hashes and document future release use.


## Unreleased — development/release workflow

- Preserve `c7397822` as the basic-font gameplay restoration on `main`, and `c0bfa4e` as the original approved typography revision on `aesthetic/typography-v1`.
- Add a guarded, repeatable three-way typography integration for clean `release/<version>` branches. Reuse cached phrase graphics; never replace new gameplay with an old tree or merge presentation wholesale back to `main`.
- Defer typography/store captures to one explicit finalization pass. Authoring scripts require `--finalize-release`; normal development runs behavior/layout checks without generating marketing images.
- Make source fingerprints portable across LF/CRLF checkouts while retaining byte-exact binary checks and historical manifests. Add regression coverage and preserve existing generated assets.
- Document release validation, fresh exports, independent game versioning and annotated milestone tags without publication or history rewriting.

Historical typography work remains in commit `c0bfa4e` and the aesthetic branch; historical build/audit reports remain unchanged. No finished release or new version tag is created by this workflow change.
