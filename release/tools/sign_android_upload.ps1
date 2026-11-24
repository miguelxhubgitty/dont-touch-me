#Requires -Version 7.0
<#
.SYNOPSIS
Owner-run: sign a COPY of the approved unsigned AAB with the existing Google Play upload key.

Passwords are typed only at keytool/jarsigner's own prompts; this script never reads,
stores or logs them. The unsigned AAB is left untouched. The signed copy is kept only
if its certificate SHA-256 equals the verified Play Console upload certificate.
See release/PRODUCTION_SIGNING.md.
#>
[CmdletBinding()]
param(
    [string]$Bundle,
    [string]$Keystore = (Join-Path $env:USERPROFILE 'AppSigning\DontTouchMe\google-play-upload.p12'),
    [string]$Alias,
    # Play Console > App integrity > App signing > Upload key certificate (verified 2026-11-24).
    [string]$ExpectedSha256 = '45:50:16:B1:96:F4:A6:4E:4F:A1:01:4E:91:FA:34:68:3D:73:2A:F5:B6:F8:92:68:1C:19:FB:04:1E:41:3B:77'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$catalog = Get-Content (Join-Path $root 'release/catalog/game.json') -Raw | ConvertFrom-Json
$version = $catalog.version
$code = $catalog.android_version_code
if (-not $Bundle) { $Bundle = Join-Path $root "builds/v$version/android/raw-android-aab/dont-touch-me-unsigned.aab" }
$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin' } else { Split-Path (Get-Command java).Source }
$keytool = Join-Path $java 'keytool.exe'
$jarsigner = Join-Path $java 'jarsigner.exe'
foreach ($path in $Bundle, $Keystore, $keytool, $jarsigner) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Not found: $path" }
}
$output = Join-Path (Split-Path -Parent (Split-Path -Parent $Bundle)) "DontTouchMe-v$version-vc$code-google-play-upload.aab"
if (Test-Path -LiteralPath $output) { throw "Refusing to overwrite $output; move it aside first." }

if (-not $Alias) {
    Write-Host "`nKeystore entries (type the keystore password at keytool's prompt):" -ForegroundColor Cyan
    & $keytool -list -storetype PKCS12 -keystore $Keystore
    if ($LASTEXITCODE -ne 0) { throw 'keytool could not open the keystore.' }
    $Alias = Read-Host 'Alias of the upload key (the PrivateKeyEntry above; not a password)'
}

Copy-Item -LiteralPath $Bundle -Destination $output
try {
    Write-Host "`nSigning a copy (type the keystore password, and the key password if asked):" -ForegroundColor Cyan
    & $jarsigner -storetype PKCS12 -keystore $Keystore -sigalg SHA256withRSA -digestalg SHA-256 $output $Alias
    if ($LASTEXITCODE -ne 0) { throw 'jarsigner failed.' }
    # No -strict: a self-signed upload certificate always warns; the fingerprint check below is the gate.
    & $jarsigner -verify $output | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Signature verification failed.' }
    $certificate = & $keytool -printcert -jarfile $output | Select-String 'SHA256:' | Select-Object -First 1
    $actual = ($certificate -replace '.*SHA256:\s*', '').Trim().ToUpperInvariant()
    if ($actual -ne $ExpectedSha256.ToUpperInvariant()) { throw "Signer $actual is not the Play upload certificate $ExpectedSha256." }
} catch {
    Remove-Item -LiteralPath $output -ErrorAction SilentlyContinue
    throw
}
Write-Host "`nSigned upload AAB: $output" -ForegroundColor Green
Write-Host "Upload certificate matches Play Console. SHA-256 (file): $((Get-FileHash -LiteralPath $output).Hash.ToLowerInvariant())"
Write-Host 'Nothing was uploaded. Validate it, then upload to internal testing yourself.'
