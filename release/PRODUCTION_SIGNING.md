# Production Android upload key — owner-run procedure

**No production credentials were created by this task.** These instructions are for the owner to execute on a trusted machine. The existing Android Debug key and debug APK are not production signing identities.

## Verify the existing upload key

Open the existing `com.wandiel.donttouchme` record. Compare the SHA-256 of its **Upload key certificate** in App integrity with the authorized local key and the prior upload AAB signer. Play App Signing uses a separate app signing key for delivery to users. Stop before signing if the fingerprints differ or the key cannot be found. Keep credentials in private storage outside the repository and enter passwords only at the local prompt.

```powershell
$uploadKey = Join-Path $env:USERPROFILE 'AppSigning\DontTouchMe\google-play-upload.p12'
& "$env:JAVA_HOME\bin\keytool.exe" -list -v `
  -keystore $uploadKey -storetype PKCS12
```

Record the alias, certificate SHA-256 fingerprint, package ID, and account ownership in your private release records.

## Sign the existing bundle without rebuilding the game

**0.1.1 and later:** run `pwsh -File release/tools/sign_android_upload.ps1` from the project folder. It lists the keystore aliases, signs a copy of `builds/v<version>/android/raw-android-aab/dont-touch-me-unsigned.aab` as `builds/v<version>/android/DontTouchMe-v<version>-vc<code>-google-play-upload.aab`, verifies the signature, and deletes the copy unless its certificate SHA-256 is the Play upload certificate `45:50:16:B1:…:3B:77` (verified 2026-11-24; the vc2/vc3 uploads used the same key, alias beginning `DONTTOUC`). Passwords are typed only at keytool/jarsigner prompts. The manual steps below remain valid.


The existing `builds/android/dont-touch-me-unsigned.aab` is release-mode and non-debuggable, but has no upload signature. Copy it before signing so the audited unsigned original stays intact:

```powershell
$unsignedBundle = 'builds\android\dont-touch-me-unsigned.aab'
$uploadBundle = 'builds\android\dont-touch-me-upload.aab'
Copy-Item -LiteralPath $unsignedBundle -Destination $uploadBundle
& "$env:JAVA_HOME\bin\jarsigner.exe" -keystore $uploadKey `
  -sigalg SHA256withRSA -digestalg SHA-256 `
  $uploadBundle donttouchme-upload
& "$env:JAVA_HOME\bin\jarsigner.exe" -verify -verbose -certs $uploadBundle
```

Run from the project folder, choose a fresh output filename if one already exists, and provide passwords only at prompts. `apksigner` is for APKs; AABs use JAR signing. Check the resulting certificate fingerprint against your intended upload certificate and Play Console, then run Google's `bundletool validate` on the signed copy. A self-signed certificate is normal for Android app signing; distinguish certificate-chain warnings from a failed signature. Play Console's actual upload validation is still required. Check App bundle explorer across tracks and use a version code greater than any previously uploaded code before building the update.

For future builds, use a separate store-upload preset with signing enabled and configure the owner's release key **locally**. Keep the shared **Android AAB Unsigned** preparation preset unsigned. Never paste release passwords into the committed preset. Godot credentials/local exports are already ignored by this repository; verify `git status` and `git check-ignore` before each commit.

## Secure storage and recovery

1. Keep the working keystore in a private access-controlled location. Make at least two encrypted backups in independent locations, with one offline; avoid unencrypted email/chat/public cloud links.
2. Store the password and recovery instructions in a password manager, separate from the backup media. Restrict access to the responsible release owner; protect developer accounts with strong authentication and recovery arrangements.
3. Test restoring a backup to a trusted temporary location: open it with `keytool -list` and compare the certificate SHA-256 fingerprint. Do not distribute restored keys or leave them in the source checkout.
4. Retain signing identity across updates. A Play-installed build generally cannot update a debug-signed installation with the same package ID; remove the test installation first if Android reports a signature mismatch.
5. If an upload key is lost or compromised, follow Play App Signing's upload-key reset process. Do not assume an app-signing key and an upload key have identical recovery procedures. Treat Apple signing as a separate team/certificate process on the Mac.

Official guidance checked 2026-10-29: [Android signing and key security](https://developer.android.com/studio/publish/app-signing), [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756). No key creation, signing of a production artifact, account change, or app submission is authorized by merely reading this document.
