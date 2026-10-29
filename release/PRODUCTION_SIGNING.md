# Production Android upload key — owner-run procedure

**No production credentials were created by this task.** These instructions are for the owner to execute on a trusted machine. The existing Android Debug key and debug APK are not production signing identities.

## Choose ownership first

Use the developer account and legal publisher that will own this app. For Google Play, distinguish the **upload key** you retain from the **app signing key** managed by Play App Signing. Decide the signing setup in Play Console before the first upload, and confirm the package ID belongs to you. Do not reuse the public/default debug key.

## Generate outside the repository

Open a fresh PowerShell window on your trusted PC with JDK 17 configured. The following commands are examples to run yourself; they have **not** been executed here. Use a private folder outside the checkout and outside automatically shared/synchronized directories.

```powershell
$signingDir = Join-Path $env:USERPROFILE 'AppSigning\DontTouchMe'
New-Item -ItemType Directory -Force -Path $signingDir | Out-Null
$uploadKey = Join-Path $signingDir 'play-upload.p12'
& "$env:JAVA_HOME\bin\keytool.exe" -genkeypair -v `
  -keystore $uploadKey -storetype PKCS12 -alias donttouchme-upload `
  -keyalg RSA -keysize 3072 -validity 10000
```

Stop if a key with that path/alias already exists; verify and reuse the intended identity instead of casually replacing it. Enter your own strong unique password **at the prompt**, and enter accurate owner/organization details. Certificate subject details are public certificate metadata. Do not put passwords in commands, shell history, source files, this chat, screenshots, or shared notes. The 10,000-day validity exceeds Google's recommended 25-year minimum. Use the same store/key password when PKCS12/Godot requires it.

To inspect the key and export only its **public certificate** when Play Console asks for it:

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -list -v `
  -keystore $uploadKey -alias donttouchme-upload
& "$env:JAVA_HOME\bin\keytool.exe" -exportcert -rfc `
  -keystore $uploadKey -alias donttouchme-upload `
  -file (Join-Path $signingDir 'play-upload-certificate.pem')
```

Record the alias, certificate SHA-256 fingerprint, package ID, and account ownership in your private release records. A `.pem` certificate exported this way is public; the `.p12` keystore and its password are private.

## Sign the existing bundle without rebuilding the game

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

Run from the project folder, choose a fresh output filename if one already exists, and provide passwords only at prompts. `apksigner` is for APKs; AABs use JAR signing. Check the resulting certificate fingerprint against your intended upload certificate and Play Console, then run Google's `bundletool validate` on the signed copy. A self-signed certificate is normal for Android app signing; distinguish certificate-chain warnings from a failed signature. Play Console's actual upload validation is still required. If the existing app record already has a version-code-1 upload, a new version code/build is required later; do not attempt to reuse it blindly.

For future builds, use a separate store-upload preset with signing enabled and configure the owner's release key **locally**. Keep the shared **Android AAB Unsigned** preparation preset unsigned. Never paste release passwords into the committed preset. Godot credentials/local exports are already ignored by this repository; verify `git status` and `git check-ignore` before each commit.

## Secure storage and recovery

1. Keep the working keystore in a private access-controlled location. Make at least two encrypted backups in independent locations, with one offline; avoid unencrypted email/chat/public cloud links.
2. Store the password and recovery instructions in a password manager, separate from the backup media. Restrict access to the responsible release owner; protect developer accounts with strong authentication and recovery arrangements.
3. Test restoring a backup to a trusted temporary location: open it with `keytool -list` and compare the certificate SHA-256 fingerprint. Do not distribute restored keys or leave them in the source checkout.
4. Retain signing identity across updates. A Play-installed build generally cannot update a debug-signed installation with the same package ID; remove the test installation first if Android reports a signature mismatch.
5. If an upload key is lost or compromised, follow Play App Signing's upload-key reset process. Do not assume an app-signing key and an upload key have identical recovery procedures. Treat Apple signing as a separate team/certificate process on the Mac.

Official guidance checked 2026-10-29: [Android signing and key security](https://developer.android.com/studio/publish/app-signing), [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756). No key creation, signing of a production artifact, account change, or app submission is authorized by merely reading this document.
