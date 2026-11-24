# iOS handoff — Windows preparation complete, native build pending

## Current presets (November 22, 2026)

| Preset | Bundle ID | Minimum iOS | Use |
| --- | --- | --- | --- |
| **iOS** | `com.littlebutterflyproductions.donttouchme` (registered, App Store Connect app *Don't Touch Me - WANDIEL*) | 15.0 | Production exports from a reviewed `release/<version>` branch |
| **iOS Orientation Preview** | `com.littlebutterflyproductions.donttouchme.orientationpreview` | 14.0 | Development device and Simulator testing only |

## Version 0.1.1 and the existing 0.1.0 submission

- **0.1.1:** version `0.1.1`, build `2`, from the production **iOS** preset on `release/0.1.1`. Create it as a **new version** in App Store Connect.
- **0.1.0, preserved:** the App Store Connect `0.1.0` record and TestFlight build `0.1.0 (1)` stay unchanged. They come from the frozen Alpha line (draft PR #46), not from current `main`. App Review status is not recorded in this repository.
- Nothing here is published. Publication status lives in [release/distribution/platforms.json](distribution/platforms.json).

Both presets set the `manual_ios_orientation` feature (Settings → Orientation: Auto, Portrait, Landscape) and share the same resource filters, icon and iPhone-only arm64 settings. Never cross the two identifiers.

Production export on a Mac with Godot 4.7.2 and matching templates:

1. In a disposable copy or **Project > Export**, enter the Team ID `RN864V86S3` locally. Do not commit it. On `release/0.1.1`, set version `0.1.1` and build `2` (approved). Never change these on `main`.
2. Export **iOS** project-only to an ignored folder, for example `builds/ios/DontTouchMe.xcodeproj`.
3. Run `python3 release/tools/configure_ios_orientation_preview.py builds/ios/DontTouchMe/DontTouchMe-Info.plist` after every fresh export. It widens only the iPhone orientation allowlist and accepts only the two identifiers above.
4. Archive Release in Xcode. Distribution signing, Organizer validation and any upload each need explicit owner approval. Leave the existing App Store Connect 0.1.0 record and TestFlight build 0.1.0 (1) unchanged unless the owner directs otherwise.

Both presets also set `storyboard/custom_image@2x` and `@3x` to the transparent `res://release/ios/launch-transparent.png`, so the launch screen shows the warm game background instead of Godot's logo (`tests/test_ios_launch_screen.py`). Every iOS export shows the in-app Privacy Policy button (`scripts/privacy_policy_button.gd`, gated on the `ios` feature).

## Historical Windows handoff

No iOS archive, certificate, provisioning profile, or device result is claimed. The game uses GDScript, Godot's Compatibility renderer, procedural 2D drawing, a portrait expanding canvas, and native touch events. These are supported by Godot's iOS exporter; this is design compatibility, not a completed iOS test.

## Prepared files

- Source project: `project.godot`, `main.tscn`, `scripts/blob.gd`, `scripts/blob_animationplayer.gd`; 17 regular reactions plus WAKE (current `main`). The frozen Alpha had 16 reactions.
- Opaque icon: project `assets/icon_ios.png`, and `release/assets/icons/ios/AppIcon.appiconset/`.
- Warm launch background and engine splash-image setting in `project.godot`.
- iPhone launch screen: both iOS storyboard image slots use the 1 × 1 transparent `release/ios/launch-transparent.png`. Without it, Godot 4.7.2 puts its own logo in the generated `SplashImage`, even with `boot_splash/show_image=false`. The storyboard keeps the warm `boot_splash/bg_color` background. Any new iOS preset must set `storyboard/custom_image@2x` and `@3x` the same way (`tests/test_ios_launch_screen.py` enforces this). Simulator evidence: `docs/testing/ios-launch-screen/`.
- Apple-sized reference captures and their limitations: `release/assets/README.md`.
- Listing and privacy drafts in `release/`; engine/license acknowledgments in `THIRD_PARTY_NOTICES.txt`.

## Export/build steps on a Mac

1. Install Godot **4.7.2 stable**, matching export templates, and supported Xcode/macOS. Current submission rules require Xcode 26+ with iOS 26+ SDK, and an app deployment target of iOS 13+; recheck [Apple requirements](https://developer.apple.com/news/upcoming-requirements/) before publishing.
2. Clone the repository and import `project.godot`. Run the behavior/release suites with the Mac Godot executable, then launch the scene normally.
3. Sign in to Xcode with the owner's Apple Account. A free Personal Team can be used for limited personal device testing; App Store/TestFlight distribution requires a developer-program team. Obtain the real Team ID; do not invent one or commit local signing files.
4. In Godot **Project > Export**, use the existing production **iOS** preset (registered bundle ID `com.littlebutterflyproductions.donttouchme`, minimum iOS 15.0, iPhone arm64). Enter the Team ID locally and set version `0.1.1` and build `2`. Changing device families or the minimum OS needs owner approval. Set the App Store 1024-pixel icon to `res://assets/icon_ios.png`. Verify that all generated icon slots resolve correctly.
5. Include `THIRD_PARTY_NOTICES.txt` in the export; exclude `release/*`, `docs/*`, `tests/*`, `test-output/*`, `builds/*`, and Markdown. Do not ship release-package tooling or promotional graphics in the game. The application does not need extra network/privacy capabilities.
6. Export to a clean **ignored** `builds/ios/` folder, using an Xcode project filename without spaces, such as `DontTouchMe`. Open the generated `.xcodeproj` in Xcode.
7. Set the actual signing team, automatic/manual provisioning, application version/build, deployment target, and device families. Inspect Info.plist, entitlements, embedded frameworks, and PrivacyInfo.xcprivacy. Resolve required-reason API and SDK manifest/signature requirements against the actual engine archive.
8. Build and run on iPhone. Test touch hitboxes, rapid input, all reactions, rotation/resize behavior allowed by the platform, safe areas, sleep/wake, app switching, lock/unlock, memory, frame pacing, and logs. Use Simulator as an additional check; verify the prepared screenshot references or capture native replacements.
9. For distribution, select a generic/actual iOS device destination and archive the Release configuration. Validate the archive in Xcode Organizer; upload to the matching App Store Connect app record. Increase the build number before any replacement upload.
10. Complete TestFlight testing, metadata, screenshots, privacy policy/privacy answers, content ratings, export-compliance forms, and App Review. Store acceptance and legal declarations remain the owner's responsibility.

The current Windows machine already has Godot's iOS template archive, but Xcode and the iOS SDK cannot run here. No additional Windows download removes the Mac requirement.

References: [Godot iOS export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html), [Apple account/device testing](https://developer.apple.com/help/account/basics/about-your-developer-account), [build upload](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).
