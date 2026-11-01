> Historical snapshot from `docs/distribution-diagnostics-2026-11-01` at `921188827c764588efb7c7831a98a98865e93e15`. See [current testing status](../README.md) for superseding results. Local paths below describe the tested workstation.

# Local macOS and iOS distribution diagnostics — 2026-11-01

## Scope and source

Design recorded first in `DISTRIBUTION_DIAGNOSTICS_DESIGN.md`. All exports use a `git archive` copy of release commit `7af0d6dc06372713ca223cfb0e02e92fd5b9f0cf`, outside the repository. No game code, artwork, typography, release preset, published build, release tag or release history was changed. No push, merge, store submission, membership purchase, notarization submission, or publication was performed.

Host: Intel MacBookPro16,1, macOS 26.3.1 (a); Xcode 26.6 build 17F113; Godot `4.7.2.stable.official.ed1daf0bf`; matching 4.7.2 export templates.

Working files, generated projects and raw logs: `/Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup/distribution-lab` (not committed). Documentation branch: `docs/distribution-diagnostics-2026-11-01`.

## macOS cause investigation

The published ZIP still hashes to:

`111bffb1bbf431422a250a94dba919f1b16af7cef37614336ef956d7a325e7fa`

This matches the existing published checksum. ZIP CRC validation passes and the executable retains mode `100755`. The executable inside the published app is byte-for-byte identical to `macos_template.app/Contents/MacOS/godot_macos_release.universal` in the installed official Godot template. Both executable SHA-256 hashes are:

`6135ad137facbb26cd73a5f7f7d541d334a84fc81650e870ef075cdd14a129cd`

Verified outside the execution sandbox:

| Object/check | Result |
| --- | --- |
| Standalone extracted template executable, `codesign --verify --strict --verbose=3` | Valid on disk, satisfies designated requirement |
| Published app executable inside its app bundle | Fails: `code has no resources but signature indicates they must be present` |
| Published app bundle, `codesign --verify --deep --strict` | Same resource-seal failure |
| Fresh export using unchanged signing-disabled macOS preset | Reproduces invalid exported-bundle signature |
| Fresh export with Apple codesign ad-hoc signing | Passes strict verification for all architectures |

An initial sandboxed check misleadingly reported the standalone template signature invalid; outside-sandbox verification establishes that the template executable itself is valid. The exported app inspection shows the template identifier `godot_macos_release`, an unbound Info.plist, and no sealed-resource manifest. The repository's macOS preset and release-tool preset generator both specify `codesign/codesign=0` and `notarization/notarization=0`.

**Conclusion:** the signing-disabled export retains the engine-template signature without producing a valid signature/resource seal for the finished app bundle. This is an export-signing configuration failure. The outer ZIP is not shown to corrupt the app: executable bytes and permissions are preserved, CRC checks pass, and the same invalid bundle is reproduced before publication. Lack of trusted Developer ID signing/notarization is a separate Gatekeeper trust issue; it does not by itself explain the observed malformed app-bundle signature.

## Corrected local macOS candidate

Added a separate scratch-only `macOS Local Adhoc` preset: `codesign/codesign=3`, `codesign/identity="-"`. Exported with:

```sh
godot --headless --path /Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup/distribution-lab/project --export-release 'macOS Local Adhoc' /Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup/distribution-lab/exports/local-adhoc.zip
```

The corrected app has identifier `com.littlebutterflyproductions.donttouchme`, an ad-hoc signature, bound Info.plist entries, and a version-2 sealed-resource manifest. `codesign --verify --all-architectures --deep --strict --verbose=3` passes. Its PCK, icon and privacy resources are byte-identical to the fresh unsigned reproduction. No gameplay/asset changes were needed.

Repackaged the app with the existing license notices and an explicit local-candidate README, preserving all app entry bytes and permissions. Extracted that ZIP and verified its signature again successfully.

Candidate:

`/Users/miguelnascimento/Documents/ChatGPT/WorkstationSetup/distribution-lab/exports/DontTouchMe-v0.1.0-alpha-macos-local-adhoc.zip`

SHA-256:

`b7854c72f0a1389830acc5eae92db9e1c3e058a3ce5bb610333a6e2e4f4bca66`

| Test | Result and evidence type |
| --- | --- |
| ZIP CRC + extracted app signature | Automated pass |
| Corrected executable `--headless --quit-after 120` | Automated pass, exit 0, Godot 4.7.2 startup |
| Local unquarantined corrected app launch | Native process and game window observed; blob renders and responds with changed poses after repeated clicks |
| Quarantined corrected-candidate launch | User reported **“Apple could not verify”**, replacing the original **“damaged”** warning |
| `spctl --assess --type execute --verbose=2` | Rejected, as expected for an ad-hoc/non-notarized app |
| Global Gatekeeper status | `assessments enabled` |

Copied the existing browser download's quarantine attribute onto the corrected candidate ZIP, then extracted it for the quarantine test. Did not remove quarantine, re-sign the published app, approve a Gatekeeper override, or disable protections. Ad-hoc signing corrects integrity for local testing; this candidate is **not a trusted/notarized distribution replacement**. Suitable Developer ID signing and notarization remain unresolved under the no-paid-membership constraint. No published asset was overwritten.

## Simulator installation diagnosis

Before retrying, inspected `xcrun simctl list runtimes`, `xcrun simctl runtime list`, disk space and recent Apple installation logs outside the sandbox. The prior background Xcode Components installation had finished: **iOS 26.5 build 23F77**, Universal arm64/x86_64, runtime disk image status **Ready**. No new download retry or cache deletion was needed this turn.

The exact cause of the earlier 99.6% progress stall was not established. The earlier command-line retry had reported MobileAsset cancellation; that does not prove corruption, insufficient storage or an architecture mismatch. The final evidence supersedes the previous report's incomplete-runtime status. Initial sandboxed `simctl` connection errors were permission-related and did not reflect the outside-sandbox runtime state.

Booted iPhone 17 Pro (`CD38FB90-290D-4225-962A-EC84FE622D30`) with `simctl boot` and `simctl bootstatus -b`. Boot completed successfully after first-boot data migration (about 100 seconds). The Simulator home screen appeared. Its wallpaper initially showed visual artifacts; the game's own rendered screen was subsequently clear in the observed screenshot. This is not evidence of a game rendering defect.

## Free development signing

Inspected the signed-in Xcode Personal Team. It had 0 provisioned devices and initially no local certificates; the manual Apple Development creation menu was disabled. Read only team metadata from Xcode's local `IDEProvisioningTeamByIdentifier` settings: actual team ID **7GDZ32Y6JW**, `isFreeProvisioningTeam=true`, type Personal Team. No account tokens, private keys, or profile contents were displayed or committed.

Configured the scratch iOS export with that real Team ID, bundle identifier `com.littlebutterflyproductions.donttouchme`, development export method, Apple Development identity, and project-only export. Godot export completed, producing `distribution-lab/ios/DontTouchMe.xcodeproj` with automatic signing settings.

Ran an authorized free automatic-provisioning attempt:

```sh
xcodebuild -project ios/DontTouchMe.xcodeproj -scheme DontTouchMe -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath ios-device-derived -allowProvisioningUpdates CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=7GDZ32Y6JW build
```

Xcode created a usable **Apple Development** identity; final identity audit reports **1 valid identity**. The device build exited **65** because the team has no registered devices from which to generate a provisioning profile, and no matching iOS App Development profile was available. This is partial signing readiness, not a successful device build. No physical device was registered, no distribution identity was created, and no paid membership was purchased.

## Local iOS Simulator build and launch

The Godot-generated Xcode project hard-codes arm64. The first destination-specific build could not match the Intel iPhone Simulator. An x86_64 command-line attempt then stalled in Apple Interface Builder tooling. A process sample showed `ibtool` waiting on its worker pipe; logs included MobileAsset query and SkyLight connection errors. Cancelled that attempt and tried Xcode's normal GUI build to separate launch-context/tool initialization from game-source problems. The GUI build compiled resources but selected arm64 and failed with **Undefined symbol: _main** for arm64. That does not establish the same failure for x86_64.

The explicit Intel build using Xcode's warmed build cache **succeeded, exit 0**:

```sh
xcodebuild -project ios/DontTouchMe.xcodeproj -scheme DontTouchMe -configuration Debug -sdk iphonesimulator -destination 'id=CD38FB90-290D-4225-962A-EC84FE622D30' -derivedDataPath /Users/miguelnascimento/Library/Developer/Xcode/DerivedData/DontTouchMe-drkmucmctklhllcdsiuygikwtmpn ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

Installed with `simctl install` and launched with `simctl launch --terminate-running-process`; launch returned process **6822**. Native UI observation confirmed the game's title, blob, shadow and typography in the iPhone Simulator. Repeated simulated touches changed the blob's position/pose. This validates a local Intel Simulator build and launch, not a physical iPhone, signing profile, App Store build, exhaustive reaction review or performance qualification.

Kept device architectures standard and added a scratch-only `ARCHS[sdk=iphonesimulator*]=x86_64` override for this Intel Mac. **Normal Xcode Run then succeeded:** Xcode reported `Running DontTouchMe on iPhone 17 Pro`, with an active debugger. The runtime console reports OpenGL ES 3.0 Compatibility, Apple Software Renderer. Subsequent UI observation confirmed inactivity sleep (closed eyes and Z marks), followed by simulated-touch wake with `I was DREAMING.` dialogue and a changed/jumping pose. The Simulator game was left running under Xcode.

Runtime warnings observed in Xcode: `mouse_get_position(): Mouse is not supported by this display server`, CoreMotion preference-file absence, `AddInstanceForFactory: No factory registered`, and repeated `HALC_ProxyIOContext ... skipping cycle due to overload`. No explicit mouse-position call was found in the game's scripts; the trigger of the engine warning was not traced. These did not prevent the observed launch/touch/sleep/wake checks. Do not treat the software-rendered Simulator or its audio-overload messages as a physical-device performance result.

Raw logs include `unsigned-export.log`, `adhoc-export.log`, `ios-export.log`, `ios-simulator-build.log`, `ios-simulator-build-intel.log`, `ios-link-diagnostic.log`, `ios-device-signing.log`, and `ibtool-sample.txt` under the lab folder. They are local diagnostic evidence, not repository assets.

## Remaining gates

- Normal Xcode Run is verified with the local Intel override; ARM Simulator linking and physical-device execution are not verified.
- Connect/trust a physical iPhone or iPad and enable Developer Mode as prompted; then retry free automatic provisioning and device testing. Profile creation and identifier authorization are not established until that succeeds.
- Validate safe areas, touch behavior, suspension/resume, performance and all reactions on physical iOS hardware.
- The corrected macOS candidate still lacks trusted Developer ID signing/notarization. Do not replace the existing release or claim Gatekeeper-ready distribution without a separately authorized release process.
- No full gameplay regression rerun was necessary because protected game source/assets were unchanged; previous automated source checks remain separately documented. The new automated checks here are export/signature/ZIP validation, startup smoke, Xcode build and Simulator install/launch. UI interactions are identified separately above.

References: [Godot 4.7 macOS export/signing](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html), [Godot iOS export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html), and the [official 4.7.2 Apple exporter implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_apple_embedded.cpp).
