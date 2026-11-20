# Google Play update identity

The existing [Google Play listing](https://play.google.com/store/apps/details?id=com.wandiel.donttouchme) uses `com.wandiel.donttouchme`. Use it for both Android presets and future updates. The shared Apple identifier remains `com.littlebutterflyproductions.donttouchme` and the macOS build number remains 2.

## Scope and workflow

PR #15 proposed a dedicated Android catalog ID, an additional unsigned APK preset and validation of preset IDs. It conflicts with newer README and checklist changes and predates audio export hygiene. The replacement takes the identity split and validation intent from #15. It uses the two current presets, their existing audio filters and the current unsigned Gradle AAB route. A disposable APK validation changes only the format of the unsigned Gradle preset for the test.

1. Match the Android preset IDs and code to the release catalog. Code 4 is the lowest candidate above the verified code-3 artifact. Before release, verify the highest code in Play Console and choose the next available code.
2. Choose the next release's marketing version. Current-main review exports use the existing development version name `1.0.0`. The release command rejects building a new Android update under the historical Alpha catalog version.
3. Use the existing release workflow with matching Godot 4.7.2 templates, JDK 17 and Android SDK. Set `BUNDLETOOL` to Google's Bundletool JAR for AAB validation. The validator checks package ID, version, target API, Bundletool structure, ARM64 ELF alignment and the bundle's 16 KB APK alignment request.
4. Compare the expected upload certificate with Play Console's **App integrity → Upload key certificate**. The local signed code-2 and code-3 artifacts match each other. The signing identity for Google-distributed installs is separate. See [signing instructions](PRODUCTION_SIGNING.md).
5. Carry forward the in-app privacy link in a separate approved change before release. The code-3 line has an Android-only `PrivacyHUD` button which consumes touch and opens the published privacy URL in the browser. Main has neither the scene control nor its script. Verify the replacement does not poke the blob, and that touch, browser return, and accessibility work on a device.

Use [App bundle explorer](https://support.google.com/googleplay/android-developer/answer/9859152) to review existing codes and see the [Play update requirements](https://support.google.com/googleplay/android-developer/answer/9859350), [target API requirements](https://developer.android.com/google/play/requirements/target-sdk), and [16 KB page-size checks](https://developer.android.com/guide/practices/page-sizes).

## Verification on the PR #42 baseline

- The signed local code-3 AAB matches the recorded SHA-256. Bundletool reads `com.wandiel.donttouchme`, `0.1.0-alpha`, and code 3 from it. Keytool found the same signer SHA-256 in the local code-2 and code-3 upload AABs. A browser access rejection prevented checking the highest live code and registered upload certificate.
- Disposable code-4 AAB and APK were built unsigned with Godot 4.7.2. Both report the WANDIEL ID, development version `1.0.0`, target SDK 36, minimum SDK 24 and ARM64. Bundletool validation passed. The AAB requests `PAGE_ALIGNMENT_16K`, both artifacts' ARM64 ELF LOAD segments are aligned to 16 KB, and the APK passed Android SDK `zipalign -c -P 16 4`.
- Both archives contain the same 18 compiled production sound payloads as the Stage 4 audio hygiene baseline and the full CureJe MIT notice. The dormant candidate files and noncommercial study were absent.
- Physical-device, 16 KB runtime, and Play-delivered upgrade checks are pending. The review exports are unsigned and stay in local ignored output.
