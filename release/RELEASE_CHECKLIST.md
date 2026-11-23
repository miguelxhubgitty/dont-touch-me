# Release checklist — version 0.1.1

Approved by the owner on 2026-11-23. This file is the plan; it changes no version field. Versions, typography and presets are set only on `release/0.1.1`, following [BRANCH_WORKFLOW.md](../BRANCH_WORKFLOW.md).

## Publication status

| Destination | Status | Version |
| --- | --- | --- |
| GitHub Releases, itch.io, Game Jolt | **Published** | `v0.1.0-alpha` (frozen, audio-free). See [the Alpha manifest](distribution/manifest-v0.1.0-alpha.json). |
| Playgama | Public sandbox of a separate adapter build | `v0.1.0-alpha` |
| Apple App Store | **Not published.** App Store Connect record `0.1.0` and TestFlight build `0.1.0 (1)` exist. | Preserve unchanged |
| Google Play (`com.wandiel.donttouchme`) | Existing app with a code-3 `0.1.0-alpha` upload. Live track status and highest code unverified. | Verify in Play Console |
| Microsoft Store and all other destinations | Not submitted | — |

Live status is recorded only in [platforms.json](distribution/platforms.json), and only with a verified URL, version and date. A build, tag, upload or store record is not a publication.

## Scope

0.1.1 ships everything merged to `main` since the Alpha, through PR #66. Finished features are not split into smaller releases.

- **Audio** (the Alpha had none): kitten, puppy and robot voices and effects, off by default with a saved choice. Five saved volume categories, rapid-tap attenuation, interruption fades and subtle variation.
- **Animation:** authored AnimationPlayer renderer with the procedural fallback. Recoil and Puffer-huff reactions. Stretch and Humming idles. Yawn, Microsleep, Fighting Sleep and Sleep Twitch. Smoothed sleeping eyes and the Yawn startled blink.
- **Gameplay:** sleep after 18 seconds (the Alpha used 24). Rebalanced annoyance streak and exact decay. Movements finish under touches without teleporting, and every locked poke has its contact sound (#65, #66).
- **Platform and UI:** Settings menu (volume; orientation on Android and iOS). Landscape and short-window layout, Android safe areas. Privacy Policy button on Android and iOS. iOS launch screen without the Godot logo.
- **Release presentation:** the reviewed `aesthetic/typography-v1` integration, plus Space Grotesk on the HUD (see below).

Not included: PR #20 (sound candidates), PR #46 (frozen-Alpha iPhone wrapper), and documentation PRs #4, #13, #15 and #16.

## Versions

| Target | Version | Build | Notes |
| --- | --- | --- | --- |
| All (`project.godot`, release catalog) | `0.1.1` | — | |
| iOS | `0.1.1` | `2` | A new App Store Connect version. Never alter the 0.1.0 record or TestFlight build. |
| macOS | `0.1.1` | `3` | Unsigned and not notarized; label it clearly, as for the Alpha. The preset must be restored on the release branch. |
| Android | `0.1.1` | Highest Play Console code + 1 (at least 4) | Verify the highest code in App bundle explorer before building. |
| Windows | `0.1.1.0` | — | Unsigned; label it. |
| Microsoft MSIX | `0.1.1.0` | — | Built from the same verified Windows export. |
| Web, Linux | `v0.1.1` | — | Release and file names only; no version field. The presets must be restored on the release branch. |

Application identifiers stay unchanged. The Alpha's sideloaded APK used `com.littlebutterflyproductions.donttouchme`; 0.1.1 uses the Play ID, so it cannot upgrade that APK in place. The release notes must say so.

## Common requirements (every platform)

- [ ] Create `release/0.1.1` from current `main` and run `release/tools/apply_aesthetics.ps1 -CheckOnly`, then apply it. Review the staged hunks. (A preflight against `680d474` applied without conflicts.)
- [ ] **HUD typography (approved, needs visual review):** apply Space Grotesk to the Sound, Settings, Volume, Orientation and slider-label text. This is release presentation work on the release branch only, outside the reviewed typography patch. Check the HUD at portrait, landscape and 4K fullscreen for clipping and safe-area fit, and get the owner's visual sign-off.
- [ ] Restore the Web, Linux and macOS export presets from the `v0.1.0-alpha` settings, adjusted to current filters. Review them; never copy old preset blocks wholesale.
- [ ] Set the versions above on the release branch only.
- [ ] Run the full test suite once, plus the release, fingerprint and typography checks.
- [ ] Finalization pass on the Windows authoring machine with licensed Ink Free: audit cached phrases against the 4× standard, check actual 3840 × 2160 fullscreen, render only phrases that fail, refresh store captures once, and refresh `assets-inventory.json` (keep the previous one under `release/history/`).
- [ ] Fresh exports for every target, package validation, and include `THIRD_PARTY_NOTICES.txt`, the Space Grotesk OFL notice and the CureJe MIT notice. Record SHA-256, engine, source commit and signing status.
- [ ] Changelog and release notes: the new features, the 18-second sleep and the Android ID change.
- [ ] Create the annotated `v0.1.1` tag only after both tag checks show it doesn't exist. Pushing a tag doesn't publish anything.
- [ ] Separate owner approval for each publication destination.

## Platform-specific requirements

### Google Play

- [ ] Open `com.wandiel.donttouchme` in Play Console. Confirm the highest version code in App bundle explorer and across tracks, then set a greater code.
- [ ] Confirm publisher/legal identity, name/content rights, audience, countries and pricing. Use support@wandiel.com for support/review contact and hello@wandiel.com for business. Approve the privacy, Data safety and content-rating answers in the prepared documents. Privacy URL: https://miguelxhubgitty.github.io/dont-touch-me/privacy.html. Support URL: https://miguelxhubgitty.github.io/dont-touch-me/.
- [ ] Compare the earlier upload signer with Play Console's **Upload key certificate**. After approval, sign with that existing key and keep the unsigned AAB intact. Follow [PRODUCTION_SIGNING.md](PRODUCTION_SIGNING.md).
- [ ] On a physical device, verify the in-app Privacy Policy button (on `main` since PR #44): native touch, browser return and accessibility.
- [ ] Test on physical phones and tablets: all reactions, touch precision, safe areas, orientation, app switching/lock, audio, performance and update/signing behavior. (An Android 9 BlueStacks session passed for the Alpha; physical devices are still untested.)
- [ ] Upload to internal testing after authorization. Review the SDK, generated APK, 16 KB compatibility and pre-launch reports. Verify installation and upgrade on a 16 KB configuration and a representative device.
- [ ] Confirm store assets and declarations, submit for review, and approve rollout separately.

### Apple App Store

- [ ] Mac with supported macOS, Godot 4.7.2 and templates, and current Xcode (presently Xcode 26+ / iOS 26+ SDK). Use the owner's Apple Developer team; enter the Team ID locally only.
- [ ] Export the production **iOS** preset as version `0.1.1`, build `2`, following [IOS_EXPORT.md](IOS_EXPORT.md). Resolve archive validation, entitlements, privacy manifests, required-reason APIs and export compliance against the actual binary.
- [ ] Test on iPhone: safe areas, touch, orientation, lifecycle, audio and performance. Replace or verify the Windows reference renders with native captures.
- [ ] Add version 0.1.1 to the existing App Store Connect app. Leave the 0.1.0 record and TestFlight build `0.1.0 (1)` unchanged. Confirm identity, rights, age rating, pricing, privacy answers and a real review contact. Don't select the Kids Category without that audience decision.
- [ ] Upload the validated archive, complete TestFlight testing, provide native iPhone screenshots, and make the review submission and publication decision yourself.

### macOS

- [ ] Export `0.1.1` build `3`, unsigned and not notarized, and label it as such (as the Alpha was). Native-test startup, input, audio, sleep/wake and resizing on a Mac. Developer ID signing and notarization ([MACOS_SIGNING_DESIGN.md](MACOS_SIGNING_DESIGN.md)) are out of scope for 0.1.1.

### Windows and Microsoft Store

- [ ] Export `0.1.1.0`, run the 120-frame headless smoke check, and label the ZIP unsigned.
- [ ] For the Microsoft Store, build the MSIX `0.1.1.0` from that same verified export following [MSIX.md](MSIX.md). Supply the exact Partner Center identity, run certification checks, and submit only with owner approval.

### Linux

- [ ] Export `v0.1.1` and label it not native-tested unless a native Linux check is done.

### Web

- [ ] Export `v0.1.1` with `index.html` at the ZIP root. In a real browser, check that audio starts only after a tap, that sound defaults to off, and that the HUD, input and resizing work. The Playgama adapter build is a separate update.

## Preserved Alpha

`v0.1.0-alpha`, its tag `d61c865`, its published artifacts and checksums, its manifest, the Playgama sandbox and the Apple 0.1.0 record stay unchanged. 0.1.1 is a new release beside them.
