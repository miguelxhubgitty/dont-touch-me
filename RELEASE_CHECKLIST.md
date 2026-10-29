# Don't Touch Me — version 1.0 release checklist

Reviewed 2026-10-29 with Godot **4.7.2.stable.official.ed1daf0bf**.

**Status: version 1.0 release candidate for device testing; not yet ready for store submission.** The original 15 regular reactions and special wake-up reaction are preserved. Automated and Windows checks pass. Android packaging is verified, but the APK has not been installed on a device. No iOS build has been produced on this Windows PC.

## Completed locally

- [x] Godot import and GDScript validation; all behavior/release/rendering tests pass (see `TESTING.md`).
- [x] All 16 reaction lifecycles, four annoyance tiers, nonrepetition, buildup/decay, idle/sleep/wake, rapid input, interruptions, escape recovery, focus pause/resume, and resizing checked automatically.
- [x] Mouse and native touch events dispatched through actual Godot viewports; emulation disabled to prevent duplicate taps.
- [x] Phone/tablet logical aspect ratios checked and rendered; speech fits the tested layouts.
- [x] Windows x86-64 executable generated with embedded game data, correct application/version metadata, and local interactive play check.
- [x] ARM64 Android debug APK generated with the existing local debug key; signature and 16 KB ZIP/ELF alignment verified.
- [x] APK manifest checked: `Don't Touch Me`, `com.littlebutterflyproductions.donttouchme`, version `1.0.0`, code `1`, minimum SDK `24`, target SDK `36`, portrait, no requested permissions.
- [x] Main and adaptive Android icons use the blob; an opaque 1024 × 1024 iOS icon is prepared at `assets/icon_ios.png`. Warm startup background replaces the default engine splash image.
- [x] Generated builds, test output, keys, provisioning profiles, and credentials excluded from Git. Tests, build outputs, and Markdown docs excluded from exports. No plugins, network code, accounts, ads, purchases, or placeholders in the game.

## Device acceptance — required before either store

- [ ] Install the final candidate on ordinary Android hardware and an iPhone. Check actual touch accuracy, all reactions, readable dialogue, edge/cutout/home-indicator areas, and pause/resume after lock/unlock and app switching.
- [ ] Run a sustained tapping/idle session; observe frame pacing, memory, battery/temperature, and crash logs. Desktop rendering and automated simulation do **not** verify mobile performance.
- [ ] Test tall phones and a tablet, including resize/orientation behavior supported by each platform. Android large-screen behavior can differ from a phone's portrait lock.
- [ ] Check that the launcher, launch screen, adaptive icon masks, and iOS icon display the blob rather than an engine placeholder.
- [ ] Complete a fresh-install check and an update check with the same signing identity. Confirm there are no unexpected permission prompts.
- [ ] Fix any device findings, rerun the relevant automated checks, rebuild, and test the exact artifacts intended for submission.

## Google Play — exact remaining sequence

1. Create or use a verified Play Console developer account. Confirm ownership of the existing package ID before creating its app record. Registration and verification are account tasks; none has been performed here.
2. Create and securely back up your own **release/upload keystore**. Configure its path and credentials locally, outside Git, and configure Play App Signing. The existing debug key is for testing only.
3. In Godot, install the Android Gradle build template (`Project > Install Android Build Template`, or the equivalent Android build setup action in the installed editor). Enable Gradle build in the Android preset and select **AAB** as the export format. Keep ARM64 enabled and verify the current Play target SDK requirement. Preserve `1.0.0` / code `1` for the first upload; use a higher version code for each later build uploaded to Play.
4. Export a **release-signed AAB** with debug export disabled. An AAB has not been generated or validated in this task. Upload it to internal testing; inspect Play's bundle, signing, device-support, and pre-launch reports. Verify 16 KB compatibility for the delivered bundle as well as on an appropriate device/emulator; the local APK checks are only part of that validation.
5. Supply the app title, descriptions, support contact, store icon/graphics, and genuine device screenshots. Complete privacy policy URL, Data safety, content rating, target audience, ads declaration, app access, and any other required Console forms. Confirm declarations against the final game and engine; do not blindly reuse answers from another app.
6. Complete required testing and apply for production access. For personal accounts created after 2023-11-13, the current rule is at least **12 opted-in testers continuously for 14 days**, followed by a production-access application. Organization accounts and account-specific requirements differ; follow your Console.
7. Review the final listing and release artifact, submit for review, and publish only after approval and your release decision.

Official references (recheck at submission time): [account setup](https://support.google.com/googleplay/android-developer/answer/6112435), [AAB requirement](https://developer.android.com/guide/app-bundle), [testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465), [16 KB compatibility](https://developer.android.com/guide/practices/page-sizes), [Godot Android export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).

## Apple App Store — exact remaining sequence

1. Use a Mac with compatible macOS, Godot 4.7.2, matching export templates, and Apple's supported Xcode/iOS SDK. Current submission requirements call for Xcode 26 or later and the iOS 26 SDK or later; recheck them before submitting. The current Windows PC cannot produce the required iOS build.
2. Enroll in or join an Apple Developer Program team for distribution, and set up App Store Connect access. No membership or signing identity is assumed. Individual and organization enrollment requirements differ.
3. Clone this repository on the Mac, import the project, and add an iOS export preset. Enter your actual Apple Team ID and register/confirm the bundle identifier (`com.littlebutterflyproductions.donttouchme` is the intended identifier, not a verified Apple registration). Set version `1.0.0`, build `1`, portrait support, intended device families, minimum iOS 13 or later (the current App Store floor), and the iOS icon from `assets/icon_ios.png`. Keep certificates and provisioning profiles outside Git.
4. Export the Xcode project; configure your own signing team and provisioning in Xcode. Build and run on an iPhone, inspect launch behavior, safe areas, app lifecycle, memory/performance, and logs. Simulator checks can supplement physical testing.
5. Create the matching App Store Connect app record. Archive a **Release** build in Xcode, validate the archive, and upload it. Resolve validation issues, including required privacy manifests/SDK declarations and export-compliance questions based on the actual shipped binary.
6. Complete TestFlight testing, then supply real screenshots, store description, support and privacy-policy URLs, age rating, App Privacy answers, content rights, and review information. Even a game that collects no data needs a privacy-policy URL.
7. Select the tested build, complete all submission checks, submit for App Review, and release after approval and your release decision. Approval has not been requested and is not guaranteed.

Official references: [Godot iOS export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html), [Apple enrollment](https://developer.apple.com/programs/enroll/), [current submission requirements](https://developer.apple.com/news/upcoming-requirements/), [uploading builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/), [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

## Local test builds

- Windows: `builds/windows/DontTouchMe.exe` (standalone, unsigned), and `builds/windows/DontTouchMe-Windows-1.0.0.zip` (portable copy). Run the executable and click the blob.
- Android: `builds/android/dont-touch-me-debug.apk` (debug signed). Transfer it to an ARM64 Android device running Android 7.0/API 24 or later and install for testing.
- These artifacts exist only on the development PC and are ignored by Git. A repository clone contains source, not these downloads. No store upload or external binary distribution was performed.
