# iOS handoff — Windows preparation complete, native build pending

No iOS archive, certificate, provisioning profile, or device result is claimed. The game uses GDScript, Godot's Compatibility renderer, procedural 2D drawing, a portrait expanding canvas, and native touch events. These are supported by Godot's iOS exporter; this is design compatibility, not a completed iOS test.

## Prepared files

- Source project: `project.godot`, `main.tscn`, `scripts/blob.gd`; exactly 16 existing reactions.
- Opaque icon: project `assets/icon_ios.png`, and `release/assets/icons/ios/AppIcon.appiconset/`.
- Warm launch background and engine splash-image setting in `project.godot`.
- Apple-sized reference captures and their limitations: `release/assets/README.md`.
- Listing and privacy drafts in `release/`; engine/license acknowledgments in `THIRD_PARTY_NOTICES.txt`.

## Export/build steps on a Mac

1. Install Godot **4.7.2 stable**, matching export templates, and supported Xcode/macOS. Current submission rules require Xcode 26+ with iOS 26+ SDK, and an app deployment target of iOS 13+; recheck [Apple requirements](https://developer.apple.com/news/upcoming-requirements/) before publishing.
2. Clone the repository and import `project.godot`. Run the behavior/release suites with the Mac Godot executable, then launch the scene normally.
3. Sign in to Xcode with the owner's Apple Account. A free Personal Team can be used for limited personal device testing; App Store/TestFlight distribution requires a developer-program team. Obtain the real Team ID; do not invent one or commit local signing files.
4. In Godot **Project > Export**, add an **iOS** preset. Enter the Team ID, intended unique bundle ID `com.littlebutterflyproductions.donttouchme` (registration remains unverified), version `1.0.0`, build `1`, portrait orientation, and chosen iPhone/iPad families. Set minimum OS compatible with both Godot and Apple's current requirements. Set the App Store 1024-pixel icon to `res://assets/icon_ios.png`. Verify that all generated icon slots resolve correctly.
5. Include `THIRD_PARTY_NOTICES.txt` in the export; exclude `release/*`, `docs/*`, `tests/*`, `test-output/*`, `builds/*`, and Markdown. Do not ship release-package tooling or promotional graphics in the game. The application does not need extra network/privacy capabilities.
6. Export to a clean **ignored** `builds/ios/` folder, using an Xcode project filename without spaces, such as `DontTouchMe`. Open the generated `.xcodeproj` in Xcode.
7. Set the actual signing team, automatic/manual provisioning, application version/build, deployment target, and device families. Inspect Info.plist, entitlements, embedded frameworks, and PrivacyInfo.xcprivacy. Resolve required-reason API and SDK manifest/signature requirements against the actual engine archive.
8. Build and run on iPhone. Test touch hitboxes, rapid input, all reactions, rotation/resize behavior allowed by the platform, safe areas, sleep/wake, app switching, lock/unlock, memory, frame pacing, and logs. Use Simulator as an additional check; verify the prepared screenshot references or capture native replacements.
9. For distribution, select a generic/actual iOS device destination and archive the Release configuration. Validate the archive in Xcode Organizer; upload to the matching App Store Connect app record. Increase the build number before any replacement upload.
10. Complete TestFlight testing, metadata, screenshots, privacy policy/privacy answers, content ratings, export-compliance forms, and App Review. Store acceptance and legal declarations remain the owner's responsibility.

The current Windows machine already has Godot's iOS template archive, but Xcode and the iOS SDK cannot run here. No additional Windows download removes the Mac requirement.

References: [Godot iOS export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html), [Apple account/device testing](https://developer.apple.com/help/account/basics/about-your-developer-account), [build upload](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).
