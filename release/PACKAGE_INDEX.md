# Release handoff index

Version 1.0.0; exactly 16 original reactions. This handoff preserves the existing game and binaries. See `FINAL_AUDIT.md` for the latest audit; `BUILD_REPORT.md` records their original generation.

| Use | Location |
| --- | --- |
| Owner's remaining tasks, by store | `RELEASE_CHECKLIST.md` |
| Existing support and privacy URLs | https://miguelxhubgitty.github.io/dont-touch-me/ and https://miguelxhubgitty.github.io/dont-touch-me/privacy.html |
| Production key/signing/backup procedure, not executed | `PRODUCTION_SIGNING.md` |
| Store field copy and validated source | `STORE_LISTING.md`, `listing.json` |
| Master, store, iOS, Android launcher/adaptive/themed icons | `assets/icons/`, `assets/android/res/` |
| Feature graphic | `assets/google-play-feature-1024x500.png` |
| Five Google Play gameplay captures | `assets/screenshots/google-play/` |
| Five captures for each Apple reference size | `assets/screenshots/iphone-medium-reference/`, `iphone-large-reference/`, `ipad-reference/` |
| Dimensions/provenance and file-integrity inventories | `assets/README.md`, `assets/manifest.json`, `assets-inventory.json` |
| Privacy, Data safety, App Privacy, rating drafts | `PRIVACY_POLICY.md`, `DATA_SAFETY.md`, `APP_STORE_PRIVACY.md`, `CONTENT_RATING.md` |
| Mac export/capture instructions | `IOS_EXPORT.md`, `assets/README.md` |
| Policy publication/maintenance and source HTML | `PUBLISH_PRIVACY.md`, project `docs/` |
| Engine licenses shipped in the app | Project `THIRD_PARTY_NOTICES.txt` |

## Local build files (ignored by Git)

- `builds/windows/DontTouchMe.exe` and `builds/windows/DontTouchMe-Windows-1.0.0.zip` — existing Windows x64 executable and portable package.
- `builds/android/dont-touch-me-debug.apk` — existing debug-signed test APK. Not a production upload.
- `builds/android/dont-touch-me-unsigned.aab` — existing non-debuggable, unsigned release-mode bundle. Follow the signing instructions before store upload.
- `builds/artifact-sha256.json` — hashes of these original build files; producer source commit remains `ecdb9bb`.
- `builds/DontTouchMe-Source-1.0.0.zip` — source/material archive refreshed after the documentation commit.
- `builds/DontTouchMe-Complete-1.0.0.zip` — refreshed source/material archive plus the unchanged Windows portable ZIP, APK, unsigned AAB, and artifact hashes. Extract the Windows portable ZIP to play without Godot.

The source/assets are available from the GitHub repository. Binaries/complete local archive are still on the build PC, not uploaded to GitHub Releases. Use your existing remote-PC file-transfer facility to retrieve them; no external binary distribution was added by this task.

No production key, password, certificate secret, store-account credential, app submission, or paid service is included. Do not treat Apple reference renders as device-test evidence.
