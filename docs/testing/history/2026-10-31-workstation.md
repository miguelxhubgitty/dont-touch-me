> Historical snapshot from `docs/macos-ios-workstation-2026-10-31` at `d4ebe8f37d00cac470582e039e4df91e9becea3b`. See [current testing status](../README.md) for superseding results. Local paths below describe the tested workstation.

# macOS and iOS workstation preparation — 2026-10-31

This report records local preparation for WANDIEL's Don't Touch Me. It does not authorize publishing or claim App Store readiness.

## Repository and boundaries

- Project: `/Users/miguelnascimento/Documents/ChatGPT/dont-touch-me`.
- Documentation branch: `docs/macos-ios-workstation-2026-10-31`, based on the previous native-testing documentation commit `f698f5443825bbdf5a737e5a30fd7c2b3392fd13`.
- Release source remains `7af0d6dc06372713ca223cfb0e02e92fd5b9f0cf` on `release/v0.1.0-alpha`.
- No gameplay, assets, release export presets, tags, published builds, or GitHub Releases were changed. No merge, push, submission, membership purchase, or publication was performed.
- Downloads, extracted apps, tools, and the isolated iOS probe are outside the repository under `/Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup` and `Tools`.

## Audit and installed tools

| Item | Result |
| --- | --- |
| Hardware | MacBook Pro, MacBookPro16,1, Intel x86_64 |
| macOS | 26.3.1 (a), build 25D771280a |
| Storage | About 266 GiB free initially; about 241 GiB free at final check |
| Full Xcode | Installed 26.6, build 17F113, `/Applications/Xcode.app` |
| Active developer directory | `/Applications/Xcode.app/Contents/Developer` |
| First launch | User accepted the Xcode/SDK agreement and completed system-component authorization; `xcodebuild -checkFirstLaunchStatus` exited 0 |
| Command-line tools | Available through full Xcode: Apple Git, clang, Swift, xcrun and simctl. Standalone CommandLineTools package is not installed or required alongside full Xcode |
| Apple Git | 2.50.1 (Apple Git-155) |
| GitHub Desktop bundled Git | 2.56.0; usable fallback before Xcode installation |
| GitHub CLI | 2.103.3, official Intel macOS ZIP; authenticated as `miguelxhubgitty`, verified via GitHub API |
| Godot | 4.7.2.stable.official.ed1daf0bf, Standard Universal build |
| Godot export templates | Installed `4.7.2.stable`, including `ios.zip` and `macos.zip` |
| Xcode Apple Account | User signed in; Personal Team visible, 0 provisioned devices. No organization/distribution team was shown |
| Apple signing identities | 0 valid local code-signing identities found; no credentials exported |
| Provisioning profiles | No profiles found in the standard legacy or Xcode UserData profile directories |
| Connected physical devices | `xcrun devicectl list devices --hide-headers`: no devices found |

Xcode was absent initially, and system Git could not run. Downloaded **Xcode 26.6 Universal.xip** after the user signed in to Apple's official developer downloads. `pkgutil --check-signature` reported signed Apple Software. Expanded it with `xip --expand`, installed it in Applications, and verified the app signature. Xcode selected its developer directory during first-launch setup; no redundant `sudo xcode-select --switch` was necessary.

[Apple's compatibility table](https://developer.apple.com/xcode/system-requirements/) lists Xcode 26.6 for macOS 26.2–26.x. The Universal package includes Intel support; Xcode 27 requires macOS 26.6 or later and was not selected for this host.

SDK audit reports iOS/iOS Simulator 26.5 and macOS 26.5, plus DriverKit 25.5, tvOS/watchOS/visionOS 26.5 SDKs. SDK availability is distinct from an installed Simulator runtime.

Godot templates came from the [official 4.7.2 download service](https://godotengine.org/download/archive/4.7.2-stable/) and were installed at `~/Library/Application Support/Godot/export_templates/4.7.2.stable`. No engine source compilation, .NET SDK, Homebrew, or paid dependency was needed.

GitHub CLI ZIP SHA-256 matched its official release checksum file:

`a2f86418f4350ae6e9ec60d5000bdf7665728436946a97fc27fe50e6ae752682`

Installed `godot` and `gh` links in `Documents/ChatGPT/Tools/bin` and appended that directory to `~/.zprofile`. A fresh `/bin/zsh -lc` resolves both commands. Existing terminal sessions may need to run `source ~/.zprofile`.

## Published macOS Alpha validation

- Downloaded the existing [v0.1.0-alpha release](https://github.com/miguelxhubgitty/dont-touch-me/releases/tag/v0.1.0-alpha) asset `DontTouchMe-v0.1.0-alpha-macos.zip` and its published `SHA256SUMS`.
- ZIP SHA-256: `111bffb1bbf431422a250a94dba919f1b16af7cef37614336ef956d7a325e7fa`.
- Exact match to the checksum entry `macos/DontTouchMe-v0.1.0-alpha-macos.zip`.
- Extracted to `WorkstationSetup/macos-alpha/Don't Touch Me.app` without rebuilding or re-signing.
- Bundle ID: `com.littlebutterflyproductions.donttouchme`; version 0.1.0, build 2.
- Executable is Universal x86_64 + arm64; only Intel execution was tested on this Mac.

**Native UI observations:** Launch Services opened the exported app. The blob rendered and slept with closed eyes/Z marks. Clicking woke it with “I was DREAMING.” Repeated clicks caused a movement reaction. Resizing from approximately 432 × 832 to 652 × 704 outer dimensions kept the blob visible and recentered. These were agent-observed UI interactions, not user reports or automated assertions. No crash was observed. Exhaustive animation smoothness, every reaction, physical trackpad behavior, external displays, and actual macOS suspend/resume were not established.

**Automated exported-app smoke test:** Ran the existing app executable with `--headless --quit-after 120`; exit 0, Godot 4.7.2 startup output, no runtime error. This confirms bounded startup only, not interaction or signing readiness. Earlier source-project regression results remain separately recorded in `MACOS_NATIVE_TESTING.md`; they were not represented as exported-app tests.

**Signing/Gatekeeper issue:** `codesign --verify --deep --strict` fails. `spctl --assess --type execute --verbose=2` outside the sandbox also fails with “code has no resources but signature indicates they must be present.” Signature inspection shows identifier `godot_macos_release`, no sealed resources and an unbound Info.plist, consistent with an inherited engine signature rather than valid app-level publisher signing. This interpretation does not establish publisher identity or notarization. No signature was repaired and no quarantine attribute was removed. No security protection was disabled.

The terminal-downloaded copy has no quarantine attribute and launched without a Gatekeeper warning. Separately downloaded the same ZIP through Chrome: its SHA-256 also matches, and the extracted app retains quarantine metadata. A normal `open -n` attempt produced a **“Don't Touch Me is damaged”** popup, reported by the user. The browser copy did not establish a running game process; only the original unquarantined runtime-test process remained. Gatekeeper assessments are enabled, and the quarantined copy also fails `spctl` with the resource-signature error above. Thus the checksum-correct published ZIP is **not ready for normal macOS distribution** in this state. No per-app or global bypass was performed. A future separately authorized release needs valid app signing/notarization and a fresh browser-download test; this task leaves the existing release untouched.

## iOS export readiness

The game uses GDScript and GL Compatibility. [Godot's iOS export documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html) requires macOS, Xcode, matching export templates, a bundle identifier, and a real App Store Team ID; the Simulator supports the Compatibility renderer. Inspected the installed iOS template XCFramework metadata: the core debug/release libraries include arm64 device slices and arm64/x86_64 Simulator slices, so this Intel host is supported at the template level.

The repository currently has **no iOS export preset**. It has an established macOS bundle identifier, `com.littlebutterflyproductions.donttouchme`. That identifier was reused only in the local probe; availability under an Apple team is unverified.

Prepared `WorkstationSetup/ios-readiness-project`, a separate source copy with generated caches excluded. Added a local-only `iOS Readiness` preset to this copy, with the existing bundle identifier and an intentionally blank Team ID. Imported the scratch project and attempted:

```sh
godot --headless --path /Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup/ios-readiness-project --export-debug 'iOS Readiness' /Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup/ios-export/DontTouchMe.ipa
```

Export exited 1 with **“App Store Team ID not specified.”** The matching iOS template is present, but a completed Xcode project was not produced. No dummy Team ID, signing identity, provisioning profile, or production signing detail was invented.

Before exporting/building for a physical device:

1. The user signed in to Xcode Settings > Apple Accounts during setup. A Personal Team is visible with 0 provisioned devices. Confirm that this is the intended team for local testing; no organization team was shown. Local identity/profile audit was read-only; no certificate or profile was created.
2. Confirm that the existing bundle identifier belongs to or is available to that team. Use the team's actual 10-character Team ID in a local development preset or authorized development branch.
3. Configure signing in Xcode for the intended development team and provisioning profile. Do not copy private keys or profile contents into Git.
4. Connect and trust an iPhone/iPad, enable Developer Mode as prompted, and ensure its OS version is supported by this Xcode/device support. No physical device was connected during this audit.
5. Re-run export and build/install locally; separately verify touches, orientation, safe areas, suspension/resume and performance on the device.

No Apple Developer Program membership was purchased. No App Store submission or distribution readiness is claimed.

## Simulator and final status

Requested Apple's iOS 26.5 Universal Simulator (23F77) with `xcodebuild -downloadPlatform iOS -architectureVariant universal`. The first attempt stalled at 99.6% for several minutes. Cancelled and retried once using Apple's downloader; it resumed at 99.6% and ended with exit 70, “Download was cancelled” / MobileAsset download failure. Started the platform installation through Xcode Settings > Components instead. That download also reached 10.57 GB of 10.6 GB and stalled at 99.6% (rounded to 100% by the UI). Left Xcode's Components screen and its download visible for the user; it was not cancelled or declared installed.

Final `xcrun simctl list runtimes` remains empty. Simulator executable/tooling and SDKs exist, but **no usable iOS runtime is installed and no Simulator boot was verified**. Historical iOS 15.5/tvOS/watchOS device entries are unavailable and do not establish usable runtimes. Apple's current direct-download catalog did not provide an iOS 26.5 Simulator installer as a fallback. The precise download-stall cause was not established; disk space remained ample. Retry/finish the Universal iOS runtime in Xcode Settings > Components, then confirm it appears in `xcrun simctl list runtimes` and boot an iPhone before claiming Simulator readiness.

macOS native development tools and exported-app runtime checks are ready. Apple Git successfully read the remote release branch with `git ls-remote`, and the release SHA remains unchanged. The existing published app has a signing/Gatekeeper defect. iOS project export is blocked on the real Team ID/signing setup; Simulator runtime installation and physical-device testing are still pending. A final identity/profile recheck after Xcode sign-in still found 0 valid signing identities and 0 provisioning profiles. No paid service was purchased.
