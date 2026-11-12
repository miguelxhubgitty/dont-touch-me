# Android identity and signing

The default application ID for all Android APK and AAB presets is
`com.wandiel.donttouchme`. The release catalog's `android_application_id`
sets the ID during release sync. Its separate `application_id` continues
to supply the Apple identifier. Godot's generated Gradle project is local
output and is regenerated from the preset.

Use **Android APK Unsigned** or **Android AAB Unsigned** for review builds.
Export to a new ignored output folder. Verify the embedded package ID,
version name and code, SDK levels, ABI, assets and signature state before
handing off. The legacy Android preset is for locally authorized debug
testing. A build with the old `com.littlebutterflyproductions.donttouchme`
ID belongs to a different application and cannot be updated to the WANDIEL
ID in place. Keep the original Alpha tag, packages and receipts intact.

## Before the first store upload

- Google Play: confirm the package record and its highest accepted version
  code. Match the upload certificate to Play Console and record the separate
  Play App Signing certificate. Check in-app privacy access before submission.
- Samsung: check for an existing app record under either ID. For the standalone
  APK, use the established seller signing identity if there is one. For a new
  record, choose the signing approach before the first upload. The Godot AAB
  uses an install-time asset pack, so prefer the standalone APK for Samsung.
- Amazon: check for an existing app record under either ID and its upload and
  delivered signing certificates. Verify the resulting install/update on a
  supported ARM64 Fire tablet. An Android bundle with install-time assets is
  an available route, subject to console validation.

Store certificates and version histories are not assumed to match. If stores
deliver different certificates for the same package ID, users cannot update
across those stores without replacing the installed copy. Use a version code
above each store's accepted history on updates, and record certificate SHA-256
fingerprints and codes per destination. Keep signing secrets outside Git.
