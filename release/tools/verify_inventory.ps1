$ErrorActionPreference = 'Stop'
$releaseRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$inventory = Get-Content -LiteralPath (Join-Path $releaseRoot 'assets-inventory.json') -Raw | ConvertFrom-Json
foreach ($record in $inventory.files) {
    $path = Join-Path $releaseRoot $record.file
    if ($record.hash_mode -eq 'utf8-lf') {
        $content = [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
        $bytes = [Text.Encoding]::UTF8.GetBytes($content)
        $hasher = [Security.Cryptography.SHA256]::Create()
        try { $actual = [Convert]::ToHexString($hasher.ComputeHash($bytes)).ToLowerInvariant() }
        finally { $hasher.Dispose() }
    } else {
        $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    if ($actual -ne $record.sha256) { throw "Release asset mismatch: $($record.file)" }
}
Write-Output "$($inventory.files.Count) release assets verified; PNG hashes are raw, text hashes use UTF-8/LF normalization."
