# Remaining-free-work audit — 2026-10-29

No game rebuild, feature change, credential creation, payment, account creation, or application submission was performed. Existing build files still match every SHA-256 in `builds/artifact-sha256.json`; they were produced from game-source commit `ecdb9bb`. This audit updates publishing configuration and documents only.

## Published policy

GitHub Pages was enabled using existing repository-administrator authentication, source **main /docs**, with HTTPS enforcement. Both URLs returned HTTP 200 without authentication:

- Support: https://miguelxhubgitty.github.io/dont-touch-me/
- Privacy: https://miguelxhubgitty.github.io/dont-touch-me/privacy.html

The public policy HTML matches `docs/privacy.html` after newline normalization. The existing policy was published as requested; no new contact details or legal identity were invented. These URLs can now be used in the store forms. Legal/publisher and audience declarations still need the owner's confirmation.

## Android artifact reinspection — no rebuild

| Item | Existing debug APK | Existing release-mode AAB |
| --- | --- | --- |
| Package / name | `com.littlebutterflyproductions.donttouchme` / Don't Touch Me | Same |
| Version / code | `1.0.0` / `1` | Same |
| Minimum / target SDK | 24 / 36 | Same |
| Architecture / orientation | ARM64 / portrait | Same |
| Requested permissions | None | None |
| Debuggable | Yes, expected for testing | Attribute absent, Android default **false** |
| Signature | APK v2/v3 verified; certificate `CN=Android Debug, O=Android, C=US` | **Unsigned**, confirmed with `jarsigner`; not ready for production upload |
| Format validation | `apksigner` and 16 KB `zipalign` passed | Official bundletool 1.18.3 validation passed |

The existing unsigned AAB can be signed later without rebuilding using the owner-run procedure in `PRODUCTION_SIGNING.md`. No production key was created. Prior native ELF checks and AAB `PAGE_ALIGNMENT_16K` evidence remain applicable because the artifact hashes are unchanged; those lengthy inspections were not repeated. They do not establish execution on a 16 KB device.

## Available Android emulator and focused simulations

- The standard SDK Android Emulator, system images, and AVDs were absent. Initial `adb devices -l` listed no device. A broader installed-app check found **BlueStacks 5.22.210.1035, Pie64**, an existing Android 9 emulator image; no new emulator/image was downloaded. Vendor mapping: [Pie64 / Android 9](https://support.bluestacks.com/hc/en-us/articles/4406032772877-How-to-use-Pie-64-bit-on-BlueStacks-5).
- Installed the existing unchanged debug APK using BlueStacks' registered APK installation command, without signing into a store or altering security settings. The real app icon appeared and the game launched in portrait.
- Tested base display profiles **1600×900** and **1280×720**, with the portrait app rotating the display (corresponding portrait profiles 900×1600 and 720×1280). Profile values were verified in the emulator's display UI/configuration; no ADB framebuffer query was performed. Observed correct title, blob, touch response, rapid taps, narrowed eyes, jumping, dialogue, idle recovery, sleep after inactivity, and the special wake response; at the second profile checked relaunch, tap response and readable "Don't." dialogue. No visible crash/freeze or clipping occurred during this short session.
- Restored the original 1600×900 / 240 DPI configuration and closed the instance launched for testing. The test game remains installed. The existing `enable_adb_access=0` setting was preserved; no Android logs/network trace were collected through ADB.
- Only the existing **Android 9** image was available. No newer Android version, 16 KB runtime environment, physical phone/tablet, mobile thermal/battery behavior, or iOS runtime was tested. BlueStacks ARM translation and desktop hardware do not establish native mobile performance or a full manual pass through every reaction.
- Ran the focused existing desktop release simulation: **237,076 checks, zero failures**. It covers four logical layouts (720×1280, 720×1600, 960×1280, 720×1920), viewport input, interruptions, focus lifecycle, sleep/wake and long sessions. These are Windows simulations, separate from the Android emulator session.
- Ran existing metadata/graphics checks: **179 checks, zero failures**. The full historical behavior suite, game exports and original 18-state render generation were not needlessly repeated.

## Complete graphics inspection

All **39 existing PNGs** were checked for readable image data, declared dimensions, intended RGB/RGBA format, naming, and consistency with the unchanged gameplay source. Visually inspected all 20 gameplay captures in a QA sheet, all 19 remaining icon/feature images in a second sheet, and the feature graphic at full size. No clipping, wrong character, rank/price badge, misleading UI, or inconsistent artwork was found. Small launcher icons were also considered at their intended native density; enlarged QA thumbnails are not replacement assets.

Google assets are 512×512 RGBA icon (<1 MiB), 1024×500 opaque feature graphic, and five 1080×1920 opaque phone captures. Apple references are five each at 1179×2556, 1320×2868, and 2064×2752, with no alpha. The master/iOS icons are opaque 1024×1024. Themed Android masks use the blob. All images remain unchanged.

Apple-sized images remain **Windows Godot reference renders**, not verified iPhone/iPad captures. Native comparison/replacement is still required before upload. A file passing dimension checks alone is not a guarantee of store acceptance.

## Current official requirements versus materials

| Requirement checked | Audit conclusion / remaining obligation | Official source |
| --- | --- | --- |
| Play target SDK | Target 36 matches the phone-app submission requirement effective 2026-08-31. Recheck when actually uploading. | [Target API rules](https://support.google.com/googleplay/android-developer/answer/11926878) |
| Play bundle signing | AAB must receive the owner's upload signature; debug APK is testing only. | [Android app signing](https://developer.android.com/studio/publish/app-signing) |
| Play graphics | Supplied phone icon/feature/screenshots satisfy the checked file specifications; claims/content still subject to review. | [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) |
| Play listing limits | Name 14/30, short 65/80, full 789/4000. No keyword stuffing or unimplemented features identified. | [Listing setup](https://support.google.com/googleplay/android-developer/answer/9859152) |
| Play testing | New personal accounts subject to the 12-testers/14-continuous-days closed-test rule and production-access application. No such account testing occurred. | [Testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465) |
| No-collection disclosure | A public policy URL and truthful Data safety/App Privacy answers are still needed. Policy URL is now live; owner confirms final declarations. | [Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), [Apple App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/) |
| Apple SDK / deployment | Current upload rules require Xcode 26+ / iOS 26+ SDK and deployment iOS 13+. Windows preparation cannot satisfy native archive validation. | [Apple requirements](https://developer.apple.com/news/upcoming-requirements/) |
| Apple images | Prepared dimensions are accepted reference sizes; required iPhone medium family and iPad 13-inch family (if iPad supported) must be native-verified. | [Screenshot specs](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) |
| Apple metadata | Subtitle 30/30, promo 137/170, description 812/4000, keywords 77/100 ASCII bytes/characters. | [Product page guidance](https://developer.apple.com/app-store/product-page/) |

No native iOS archive or embedded privacy manifest has been validated. The source-based privacy drafts remain conditional on the final engine archive, SDKs, account choices, and owner declarations. Store account verification, signing identity, target audience, legal classifications, real support email, release testing, and submission decisions cannot be certified automatically here.

## Handoff

`PACKAGE_INDEX.md` maps every deliverable. `RELEASE_CHECKLIST.md` now contains **only owner actions**, split into Google Play and Apple. `PRODUCTION_SIGNING.md` gives prompt-based key creation, backup, signing, and verification instructions. Existing game/build hashes are preserved; documentation and hosting status are the only changes in this pass.
