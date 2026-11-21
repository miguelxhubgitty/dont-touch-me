# iOS Alpha Mac validation — 2026-11-21

## Result and scope

PR #46 starting commit `bfbea0e84bd16d14d86ed25ca7d1982092c13e91` was cloned separately on the Mac. The frozen Alpha builds and runs in an iPhone Simulator. A corrected, unsigned arm64 Release archive also builds. Neither archive is signed for distribution or validated by App Store Connect. No upload, submission, merge, tag change, Apple record creation, certificate creation, or provisioning-profile creation was performed.

The original clone and local branches were left alone. All 152 tracked files in the reviewed commit were checked against the scratch source: only local team selection and the iOS minimum changed. Frozen `scripts/blob.gd` and artwork match the historical base `9788e0343cb888a31ea9092f7409e2455a961261`; Android configurations are unchanged. The reviewed Privacy Policy wrapper remains unchanged.

## Workstation

- Intel x86_64 MacBook Pro; macOS 26.3.1(a), build 25D771280a; approximately 237 GiB free at audit.
- Xcode 26.6 (17F113), selected at `/Applications/Xcode.app/Contents/Developer`; iOS/device and Simulator SDK 26.5.
- Official Godot `4.7.2.stable.official.ed1daf0bf`; matching 4.7.2 stable iOS export template present.
- iOS 26.5 runtime available. iPhone 17 Pro used for interaction checks. Additional installed models: 17 Pro Max, 17e, Air, 17 and several iPads; not an exhaustive layout matrix.
- No physical iPhone appeared in Xcode's connected-device inventory.

## Packaging correction and build results

1. Existing `iOS Alpha` preset exported an Xcode project successfully. First Simulator build and unsigned device archive succeeded but exposed libraries built for iOS 14 while the preset promised iOS 13.
2. Design was recorded before changing the preset. Set only `application/min_ios_version` to `14.0`. No gameplay, visual, audio, Android, identifier or version change.
3. In the generated local Xcode project only, add `ARCHS[sdk=iphonesimulator*] = x86_64` for this Intel Mac, retaining arm64 for devices. The initial arm64-only scheme could not resolve the Intel destination. Build used a generic Simulator destination and explicit x86_64 architecture.
4. Remove only the empty, unused camera/microphone/photo usage-description keys from the generated local Info.plist. This permission-free Alpha does not request these capabilities. Do not invent purpose strings.
5. Final Debug Simulator build: **BUILD SUCCEEDED**, x86_64, code signing disabled. Installed and launched in iPhone 17 Pro, iOS 26.5.
6. Final Release arm64 device archive: **ARCHIVE SUCCEEDED**, code signing disabled. MinimumOSVersion 14.0, bundle `com.littlebutterflyproductions.donttouchme`, version `0.1.0`, build `1`, iPhone-only family `[1]`, portrait; device SDK `iphoneos26.5`. dSYM present.
7. Final builds contain zero newer-OS linker mismatch warnings and zero empty permission-description warnings. Remaining template warnings: `#pragma once in main file` and skipped App Intents extraction because this app has no AppIntents dependency.

Apple currently requires Xcode 26+ and an iOS 26+ SDK for uploads; this toolchain meets that requirement. Apple's allowed minimum target of iOS 13 does not override the actual engine libraries' iOS 14 requirement. [Apple requirements](https://developer.apple.com/news/upcoming-requirements/).

## Automated checks (Mac host, not physical iPhone tests)

All ran with Godot 4.7.2 against the final scratch source; exit status 0:

| Suite | Checks | Failures |
| --- | ---: | ---: |
| behavior | 320270 | 0 |
| release | 237076 | 0 |
| fingerprints | 17 | 0 |
| typography | 127 | 0 |
| iOS Privacy Policy synthetic input | 17 | 0 |
| release package | 208 | 0 |

180-frame headless host startup also exited 0. Synthetic privacy tests substitute the browser request; they verify input consumption, duplicate/mirrored press handling, release/cancel/focus recovery and original blob input. They do not prove real hardware or Safari tab-count behavior. A read-only exported-PCK inspection confirmed runtime scripts and both notices, with no audio or development/release folders.

## Simulator interactions observed by the agent

- Startup renders the frozen blob and lower-right Privacy Policy control.
- Taps and repeated taps change pose/position and reaction text; observed examples include “Seriously?” and wake text “I was DREAMING.” Animation changes across frames.
- Leaving the game untouched long enough produces closed eyes and floating Z marks; tapping wakes it. Exact 24-second timing is covered by source tests, not stopwatch-certified here.
- Policy tap opens Safari at the published policy; the page loads successfully. Return-to-app link resumes the game and touch remains responsive. A fresh policy tap after returning opens Safari again. No claim of exhaustive native multitouch or duplicate-tab certification.
- Portrait content and policy control clear the simulated cutout and bottom inset. Rotating the simulated hardware preserves portrait-only app orientation; returning to portrait retains layout.
- Sleep/Wake toolbar actions were exercised and the app remained usable afterward, but no independent lock-screen capture was obtained. Physical lock/unlock remains unverified.
- No crash was observed in this short interaction session. Captured app stderr showed OpenGL ES 3 context setup, without a game script exception. This is not a performance, memory, thermal or long-duration soak certification.

## Archive inspection

- Final device executable is arm64. Unsigned by design; no embedded provisioning profile. It is not installable on a physical iPhone or upload-ready as produced.
- Generated entitlements file is empty; final signed entitlements still need inspection after authorized signing.
- App icon source is opaque RGB, 1024 × 1024; asset catalog compiled and app icon references appear in final Info.plist.
- `PrivacyInfo.xcprivacy` is included in the archive, tracking false. Required-reason declarations cover file timestamps (`DDA9.1`, `C617.1`), system boot time (`35F9.1`), and disk space (`E174.1`, `85F4.1`). Owner review and Apple's archive validation remain pending; manifest presence is not acceptance.
- `ITSAppUsesNonExemptEncryption = false` is the exported value. Owner must confirm export-compliance answers for the real signed archive.

## Apple configuration checked read-only

The signed-in business team is **ONE TRU THING ONLY LLC**, enrolled as an Organization in the Apple Developer Program, renewal November 19, 2027. The business team is also visible in Xcode. Actual Team ID is configured only in external local scratch files and the private local receipt, not committed here.

App Store Connect showed **No Apps** for this business. Developer portal showed no registered App IDs, certificates or provisioning profiles. Xcode showed zero provisioned devices. The existing local development identity predates this business-team setup; no matching business distribution identity was available. Do not reuse the Personal Team for App Store distribution.

There is no existing app/build history in the inspected business account; `0.1.0 (1)` remains a proposed initial version/build until the approved app record is created and checked. Global bundle-ID registration and app-name availability have not been tested by creating records.

The live policy loads but explicitly says “Applies to version 1.0.” Confirm or correct its coverage for this 0.1.0 Alpha before upload; no website changes were made. App Store Connect also displayed the EU trader-status requirement; distribution regions and compliance declarations need owner review.

## Exact next steps to TestFlight

1. Review the PR #46 iOS-only minimum-target correction and this report. No merge is required to test the candidate, and no merge was performed.
2. Authorize registration of the explicit bundle ID on the verified business team and creation of the App Store Connect app (iOS, Don't Touch Me, approved primary language and SKU). Confirm ownership/name/version/build and privacy-policy coverage before creation. None of these records were created in this session.
3. Approve the required business-team signing certificates/profiles separately. Only then enable authorized provisioning or select existing matching distribution signing. For direct device tests, connect/unlock/trust an iPhone, enable Developer Mode if requested, and approve device registration/development signing as needed.
4. Test physical touch/multitouch, all reaction rendering, safe areas, Safari single-open/return, backgrounding and lock/unlock, offline behavior, frame pacing, memory and stability. No connected hardware was available in this session.
5. Create a signed Release device archive using the reviewed source plus documented local export adjustments. Inspect final entitlements/profile, privacy manifest, icon, version/build and dSYM. Use Xcode Organizer to validate the signed archive against the matching App Store Connect app. The current unsigned archive cannot satisfy this step.
6. With explicit upload approval, upload through Organizer to App Store Connect. After processing and export-compliance answers, add the build to an internal TestFlight group and install it on an iPhone. This session stops before upload. App Review submission remains separately authorized.

[Apple upload workflow](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/). No new membership purchase is required for the verified active organization.

## Local evidence

Separate checkout: `dont-touch-me-ios-alpha-0.1.0` under the user's ChatGPT project folder. External evidence directory: `WorkstationSetup/ios-alpha-2026-11-21/` in that folder. It contains initial/final build logs, six final suite logs, automated-results.json, local-build-receipt.json, exported-pack.json, generated projects, Simulator app and unsigned archives. Local receipt contains the actual team selection; keep it outside Git. Generated projects and signing details are not part of this PR.
