# Version 1.0 commercial release checklist

Prepared 2026-10-29. **Release package prepared; public-store submission remains pending.** All 16 existing reactions are preserved. The AAB preparation file is unsigned. Apple-sized images are genuine Godot renders, not verified iOS captures.

## Completed automatically

- [x] Existing game source inspected; no gameplay changes or extra reactions in this packaging task.
- [x] Validated store text in `STORE_LISTING.md` / `listing.json`.
- [x] Master/Play/iOS icons, Android launcher resources, feature graphic, and five gameplay situations at Play/iPhone/iPad sizes in `assets/`. Provenance/limitations in `assets/README.md`.
- [x] Code-based privacy, Data safety, App Privacy, and rating drafts. No invented support email, publisher legal identity, certificates, or production keys.
- [x] Static support/privacy pages under `docs/`; free hosting instructions supplied, hosting not activated.
- [x] Package `com.littlebutterflyproductions.donttouchme`, version `1.0.0`, code `1`, minimum SDK `24`, target SDK `36`, ARM64, portrait.
- [x] Windows, signed Android debug APK, and explicitly unsigned AAB presets. Release material excluded from exports; builds/Gradle templates/secrets ignored by Git.
- [x] Godot/bundled-component notices generated from actual engine metadata and included in exports. Original game IP licensing remains the owner's decision.
- [x] Executed test/build results and limitations recorded after execution in `BUILD_REPORT.md`.

## Requires manual testing

- [ ] Install the signed APK on ordinary physical ARM64 Android hardware (API 24+). Check all reactions, accurate tapping, rapid inputs, idle/sleep/wake, escape recovery, first launch, app switching, and lock/unlock.
- [ ] Check phones/tablets for safe areas/cutouts, readability, launcher/launch graphics, frame pacing, memory, heat/battery use, and crashes. Static 16 KB alignment checks do not replace device/emulator execution.
- [ ] Test iPhone and iPad if supported. Compare or replace the prepared Apple reference renders with native captures of the actual signed app.
- [ ] Test fresh installation and updating with the intended persistent release signing identity. Rebuild/retest the exact submission artifacts.
- [ ] Confirm name/trademark availability, content ownership/licenses, audience, regional classifications, privacy/export-compliance declarations, publisher legal identity, countries, and pricing. Supply a monitored support/review email. No legal clearance is claimed.
- [ ] Approve the privacy policy; enable/verify its public HTTPS page using `PUBLISH_PRIVACY.md` before entering the actual URL in either console.

## Requires developer account — Google Play upload sequence

1. Create/use a verified Play Console account, select the appropriate individual/organization type, complete verification, and create a **game** record. Confirm ownership of the package ID before its first upload.
2. Authorize creation of a production **upload key**, securely back it up, configure it locally, and set up Play App Signing. No production key was created here. Never commit paths/passwords through a shared credentials file.
3. Duplicate/rename **Android AAB Unsigned** for store submission. Enable signing and configure the actual upload key. Keep Gradle/AAB, ARM64, target SDK 36 or the newer required level, version `1.0.0`, code `1` for first upload; increment the code on replacement uploads. Export with **debug disabled**. Validate the release-signed AAB again. The unsigned preparation bundle and debug APK are not production uploads.
4. In **Test and release > Testing > Internal testing**, create a release and upload the signed AAB. Inspect package/signing acceptance, generated device APKs, 16 KB compatibility, and pre-launch reports.
5. In **Grow users > Store presence > Main store listing**, copy the Google fields from `STORE_LISTING.md`. Upload `assets/icons/google-play-512.png`, `assets/google-play-feature-1024x500.png`, and all five raw files in `assets/screenshots/google-play/`. Enter a real support email and the verified support/privacy URLs.
6. Complete **App content**: Data safety (`DATA_SAFETY.md`), ads = none, app access = all game features usable without login, rating (`CONTENT_RATING.md`), and the actual target audience. Complete every other required Console declaration truthfully.
7. Meet account-specific testing/production access requirements. For personal accounts created after 2023-11-13, the current minimum is 12 opted-in closed testers continuously for 14 days before applying for production access. These tests have not been performed here.
8. Choose the tested release, countries, price, and rollout; review all disclosures; submit for review and publish after approval and the owner's release decision.

## Requires macOS/Xcode and developer account — Apple upload sequence

1. Follow `IOS_EXPORT.md` on a Mac with compatible macOS, Godot 4.7.2/templates, Xcode 26+ and iOS 26+ SDK (current rules; recheck). Set minimum iOS 13+ and intended device families. No native iOS build exists from this Windows task.
2. Enroll/use the intended Apple Developer Program team for App Store/TestFlight distribution. Register/confirm the bundle ID, create the matching App Store Connect record, enter the real Team ID, and configure local signing/provisioning.
3. Set version `1.0.0`, build `1` (increment for replacement uploads), portrait support, and the prepared opaque 1024 icon. Export the Xcode project, inspect Info.plist/entitlements/frameworks/privacy manifests and signatures, resolve required-reason API declarations, and test on devices.
4. Archive **Release**, validate in Xcode Organizer, and upload to App Store Connect. Resolve archive validation and export-compliance questions based on the actual shipped binary.
5. Complete TestFlight testing. Copy Apple fields from `STORE_LISTING.md` into the version listing. Upload native-verified screenshots in accepted size groups. Prepared reference folders are `iphone-medium-reference` (1179×2556), `iphone-large-reference` (1320×2868), and `ipad-reference` (2064×2752). If iPad is enabled, supply that required device family too. See the exact replacement-capture instructions in `assets/README.md`.
6. Enter verified support/privacy URLs and real review contact. Complete App Privacy (`APP_STORE_PRIVACY.md`), age rating/content rights (`CONTENT_RATING.md`), pricing, countries, and remaining required forms. Do not select Kids Category without explicitly reviewing that audience choice.
7. Select the tested build, give review notes explaining tap/idle interaction and no login, submit to App Review, and release only after approval and the owner's decision.

## Requires payment

- [ ] Google Play registration: current US$25 one-time fee unless already covered by an account. No payment made.
- [ ] Apple Developer Program distribution: current US$99/year; regional prices/eligible waivers vary; may already be covered by a team. No payment made.
- [ ] Access to a suitable Mac if unavailable. No hardware/rental/service purchase performed. The game and local tools remain free to build.

## Requires store review or approval

- [ ] Play account verification, production access where applicable, policy checks, and app review.
- [ ] Apple enrollment/signing access, TestFlight review where applicable, archive processing, and App Review.
- [ ] Resolve any requested quality, minimum-functionality, privacy, or metadata findings. Local builds and prepared material do not guarantee approval.

## Official requirements checked 2026-10-29

[Google target SDK](https://support.google.com/googleplay/android-developer/answer/11926878), [Play setup/fees](https://support.google.com/googleplay/android-developer/answer/6112435), [closed testing](https://support.google.com/googleplay/android-developer/answer/14151465), [16 KB compatibility](https://developer.android.com/guide/practices/page-sizes), [AAB format](https://developer.android.com/guide/app-bundle), [Apple requirements](https://developer.apple.com/news/upcoming-requirements/), [Apple enrollment/fees](https://developer.apple.com/programs/enroll/), [build upload](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [Apple screenshot sizes](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

Recheck live deadlines, accepted image/device groups, fees, and account-specific tasks when submitting.
