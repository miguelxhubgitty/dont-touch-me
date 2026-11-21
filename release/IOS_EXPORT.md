# iPhone Alpha handoff

The iOS candidate starts from historical runtime commit `9788e0343cb888a31ea9092f7409e2455a961261`. It keeps the audio-free Alpha, its approved visuals, and the existing Android presets. The additions are a project-only iOS preset and an iOS-only Privacy Policy control. The frozen tag and published builds are independent of this worktree.

| Setting | Prepared value |
| --- | --- |
| Godot preset | iOS Alpha |
| Bundle ID | `com.littlebutterflyproductions.donttouchme`, confirm on the approved Apple team |
| Marketing version / build | `0.1.0` / `1`, provisional until App Store Connect history is checked |
| Device family | iPhone only, arm64, original portrait setting |
| Minimum deployment target | iOS 14.0, verify against the chosen Xcode/toolchain |
| App Store icon | Existing opaque `assets/icon_ios.png` (1024 × 1024) |
| Privacy / support | [Privacy Policy](https://miguelxhubgitty.github.io/dont-touch-me/privacy.html) and [Support](https://miguelxhubgitty.github.io/dont-touch-me/) |
| Team and signing | Intentionally unset in Git |

## 1. Transfer and check the Mac

Unzip the source handoff into a new folder, or clone the review branch if you need Git history.

```sh
git clone --single-branch --branch release-prep/ios-alpha-0.1.0 \
  https://github.com/miguelxhubgitty/dont-touch-me.git DontTouchMe-iOS-Alpha
cd DontTouchMe-iOS-Alpha
```

Install official Godot 4.7.2 stable and its matching export templates. Open Xcode 26 or later once so its components are ready. The selected Xcode needs the iOS 26 SDK or later.

```sh
xcode-select -p
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --version
"$GODOT" --headless --path "$PWD" --editor --import --quit
"$GODOT" --headless --path "$PWD" --script tests/behavior.gd
"$GODOT" --headless --path "$PWD" --script tests/ios_privacy_policy.gd
```

If Xcode's selected tools point at Command Line Tools instead of Xcode, choose the installed Xcode under **Xcode → Settings → Locations → Command Line Tools**. The Godot test substitutes the browser request and checks synthetic input. It does not prove iPhone behavior.

## 2. Export the Xcode project

1. Confirm the approved Developer Program team and the exact bundle record in Apple Developer and App Store Connect. Use the existing record if present. If registration or a version/build change is needed, resolve that with the owner before export. Verify that the published policy describes this candidate.
2. Open `project.godot` in Godot. In **Project → Export → iOS Alpha**, enter the actual ten-character **App Store Team ID** locally. Leave **Export Project Only** enabled and **Export Method Release** on **App Store**. Confirm iPhone, arm64, minimum iOS, the icon, and the version/build above. Keep the Team edit and any provisioning details local.
3. Export to a new empty directory beneath `builds/ios/`. Use `DontTouchMe` as the export filename stem. This preset should produce `DontTouchMe.xcodeproj` and resources without building or signing an archive.
4. Open that project in Xcode. Confirm **Signing & Capabilities** and the Release target's bundle ID, iPhone device family, arm64, version/build and deployment target. Inspect the generated Info.plist and PrivacyInfo.xcprivacy, including the engine's required-reason APIs. Verify entitlement and embedded SDK requirements and decide export-compliance answers against the real build. The offline source supports a provisional **Data Not Collected** response, subject to archive review.

After export on an Intel Mac, set `ARCHS[sdk=iphonesimulator*] = x86_64` in the generated project while keeping device `ARCHS = arm64`. For this permission-free Alpha, remove the empty `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, and `NSPhotoLibraryUsageDescription` keys from its generated Info.plist. Do not add invented permission purposes. These are local generated-project adjustments; keep team/signing details outside Git. Godot 4.7.2 templates require iOS 14.0 even though Apple permits deployment targets from iOS 13.0.

## 3. Test and prepare the archive after authorization

1. Run the candidate in an iPhone Simulator. Validate the intended typography and layout, touch, reaction variety, 24-second sleep, wake and the policy control. On a physical iPhone, also verify cutouts and the home indicator, one Safari launch, return to the game, and stability. A local physical-device run needs existing development signing and provisioning. Alternatively use authorized internal TestFlight for the first physical test.
2. Use existing authorized distribution signing and provisioning. In **Signing & Capabilities** choose the confirmed team and existing profile/identity as appropriate. Stop if Xcode needs to create a certificate or profile and obtain approval before giving it permission. Keep keys, profiles, passwords and account data outside Git.
3. Select **Any iOS Device (arm64)** and **Product → Archive** in Release configuration. In **Window → Organizer → Archives**, inspect the archive and run **Validate App**. Review the binary's identity, version/build, iPhone family, entitlements, privacy manifest, and embedded SDKs.
4. Only after upload approval, use **Organizer → Distribute App → App Store Connect → Upload**. Choose ordinary App Store Connect distribution so the build can also be submitted for review. After processing, in **App Store Connect → Apps → Don't Touch Me → TestFlight → Internal Testing**, add the build to an internal group and install it on an iPhone. Complete the physical checks and capture an accepted iPhone screenshot from the candidate.
5. With separate submission approval, attach the same verified build to the App Store version. Provide the screenshot, final metadata, privacy/support URLs, content rights and review contact. Complete the age rating, App Privacy and export compliance. Select manual release if approved, then **Add for Review → Submit for Review**.

Windows verification with Godot 4.7.2 passed the gameplay, release, fingerprint, typography, package validation and synthetic privacy suites plus a 180-frame startup smoke. A disposable iOS resource ZIP contained the Alpha runtime, iOS privacy script and both notices. It contained no gameplay audio or development files. This handoff contains source, tests and export settings. Mac export, Simulator run and unsigned arm64 archive now pass; see [native Mac validation](../docs/ios/ALPHA_MAC_VALIDATION_2026-11-21.md). Business signing, physical-device testing, upload and submission remain pending.

[Godot iOS exporter](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html) · [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/) · [TestFlight internal testing](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/) · [App Review submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
