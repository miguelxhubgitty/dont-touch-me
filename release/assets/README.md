# Release graphics and capture provenance

Generated with Godot 4.7.2 from the existing SVG icon and the unmodified game renderer. No downloaded artwork or AI-generated imagery is used. `manifest.json` records every PNG's dimensions, format intent, and source script hash.

## Upload files

| Purpose | File/folder | Specification |
| --- | --- | --- |
| Master icon | `icons/master-1024.png` | 1024 × 1024, opaque RGB, square background |
| Google Play store icon | `icons/google-play-512.png` | 512 × 512, RGBA PNG, below 1 MB; no baked corner mask or rank/price badges |
| Android launcher resources | `android/res/` | Legacy 48/72/96/144/192 px icons; adaptive 108/162/216/324/432 px foregrounds and monochrome masks; adaptive-icon XML and warm background color |
| iOS icon | `icons/ios/AppIcon.appiconset/` | Opaque 1024 × 1024 PNG and Xcode single-icon asset catalog metadata; original live Godot icon also remains at `assets/icon_ios.png` in the project |
| Google Play feature graphic | `google-play-feature-1024x500.png` | 1024 × 500 opaque RGB PNG, character and title |
| Google Play phone screenshots | `screenshots/google-play/` | Five 1080 × 1920 opaque RGB PNGs, portrait 9:16 |
| iPhone medium references | `screenshots/iphone-medium-reference/` | Five 1179 × 2556 opaque RGB PNGs, an accepted current Apple screenshot size |
| iPhone large references | `screenshots/iphone-large-reference/` | Five 1320 × 2868 opaque RGB PNGs, an accepted current Apple screenshot size |
| iPad references | `screenshots/ipad-reference/` | Five 2064 × 2752 opaque RGB PNGs, an accepted 13-inch iPad screenshot size |

Each screenshot set includes calm, annoyed ("Seriously?"), angry ("STOP."), hiding, and sleeping. Files are ordered `01`–`05`. No captions, frames, extra UI, fake status bars, or fabricated gameplay are composited onto them. The feature graphic is promotional artwork and is clearly separate from the raw screenshots.

## What the screenshots establish

These are **actual renders of the current gameplay Node2D on Windows**, captured directly from Godot SubViewports at the output resolutions. The script uses the game's normal expanding reference-canvas scaling. Each reaction is deterministically positioned at a reachable instant; sleep is reached by advancing the actual idle logic. The captured images are saved directly without resizing or stretching afterward.

**Apple-sized files are dimension-ready reference renders, not verified iOS device/simulator captures.** No iOS build has run. Before final store use, compare them with the signed iOS app, and capture replacements through Xcode Simulator or an iPhone if the platform presentation differs. They do not establish iPhone compatibility, safe-area handling, launch behavior, or store acceptance. Google files likewise establish genuine game rendering and dimensions, not physical Android testing.

## Mac capture steps if replacement is needed

1. Follow `release/IOS_EXPORT.md`, build the game in Xcode, and run on the intended simulator/device family.
2. On an iPhone simulator with a natively accepted screenshot resolution, use actual taps to reach the five situations. Wait at least 24 seconds for sleep. Use Simulator **File > Save Screen** (or the current equivalent screenshot command); inspect the saved pixel dimensions.
3. Capture gameplay without development overlays. Keep the original aspect ratio; do not stretch, fabricate OS frames, or place nonexistent features in the image.
4. Choose an accepted native size from Apple's live specification. If supporting iPad, also supply the required iPad display family. Compare the final native images with these references and upload the images that truthfully represent the release build.

## Reproduce and validate

Run this only on a finalized `release/<version>` branch, after applying the aesthetic layer. Follow [BRANCH_WORKFLOW.md](../../BRANCH_WORKFLOW.md) for phrase generation/import, validation and inventory refresh. During gameplay development these images remain historical snapshots; do not regenerate them on each edit.

```text
godot --path . --script release/tools/generate_assets.gd -- --finalize-release
godot --headless --path . --script release/tools/validate_package.gd
```

Android's existing Godot preset references the original vector launcher sources; the density resources here are portable release deliverables, not an additional plugin. The iOS export should use `assets/icon_ios.png` through Godot's icon field; the Xcode catalog is an alternative handoff asset. The launch background is already configured warm off-white and the default engine splash image disabled. Verify native launch behavior on the Mac/phone before submission.

Official requirements checked 2026-10-29: [Google Play graphics](https://support.google.com/googleplay/android-developer/answer/9866151), [Google Play icon design](https://developer.android.com/distribute/google-play/resources/icon-design-specifications), [Apple screenshot dimensions](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). Recheck the chosen device groups and upload validation in the actual store console.
