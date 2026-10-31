<#
.SYNOPSIS
Apply the reviewed typography layer to a clean release branch, without generating images.
.DESCRIPTION
Run after fetching origin. CheckOnly changes neither the working tree nor index.
The patch contains presentation integration, fonts, cached phrases and authoring
tools, not old gameplay snapshots, marketing captures, manifests or documentation.
Changes are staged for review, never committed, pushed, exported or published here.
#>
[CmdletBinding()]
param(
    [string]$AestheticRef = 'origin/aesthetic/typography-v1',
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-CheckedGit {
    param([string[]]$Arguments)
    $result = & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed: git $($Arguments -join ' ')" }
    return $result
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location -LiteralPath $repoRoot
$patchPath = $null
try {
    $remote = Invoke-CheckedGit -Arguments @('remote', 'get-url', 'origin')
    if ($remote -notmatch '^(https://github\.com/|git@github\.com:)miguelxhubgitty/dont-touch-me(?:\.git)?$') {
        throw 'Run this only in the miguelxhubgitty/dont-touch-me repository.'
    }
    $branch = Invoke-CheckedGit -Arguments @('branch', '--show-current')
    if ($branch -notmatch '^release/.+') { throw 'Create and switch to release/<version> from main first.' }
    $dirty = Invoke-CheckedGit -Arguments @('status', '--porcelain', '--untracked-files=normal')
    if ($dirty) { throw 'Commit or preserve existing work first; a clean index and working tree are required.' }
    if (Test-Path -LiteralPath 'scripts/typography.gd') { throw 'Typography is already present; review it instead of applying twice.' }

    # c0bfa4e is the reviewed presentation revision, based on f902ddf.
    # Its parent is a patch base, NOT the gameplay source for the new release.
    $reviewed = 'c0bfa4e18b8d4050c810518d48df66bfa76acc22'
    $base = Invoke-CheckedGit -Arguments @('rev-parse', '--verify', "$reviewed^1")
    $tip = Invoke-CheckedGit -Arguments @('rev-parse', '--verify', '--end-of-options', "$AestheticRef^{commit}")
    Invoke-CheckedGit -Arguments @('merge-base', '--is-ancestor', $reviewed, $tip)
    # Keep this allowlist narrow. Never add project.godot/main.tscn or whole
    # release/assets folders: those would overwrite current gameplay/metadata.
    $paths = @(
        'scripts/blob.gd', 'scripts/typography.gd', 'scripts/typography.gd.uid',
        'assets/fonts', 'assets/typography', 'export_presets.cfg',
        'tests/release.gd', 'tests/typography.gd', 'tests/typography.gd.uid',
        'release/tools/generate_assets.gd', 'release/tools/generate_typography.gd'
    )
    $patchPath = [IO.Path]::GetTempFileName()
    Invoke-CheckedGit -Arguments (@('diff', '--no-ext-diff', '--binary', '--full-index', "--output=$patchPath", $base, $tip, '--') + $paths)
    if ((Get-Item -LiteralPath $patchPath).Length -eq 0) { throw 'No aesthetic changes found.' }
    Invoke-CheckedGit -Arguments @('apply', '--3way', '--check', $patchPath)
    if ($CheckOnly) {
        Write-Output "Typography integration preflight passed: $tip -> $branch. No files or index entries changed."
        return
    }
    Invoke-CheckedGit -Arguments @('apply', '--3way', $patchPath)
    Write-Output "Applied typography from $tip to $branch; changes are staged for review."
    Write-Output 'No images were regenerated. Review git diff --cached, preserve current gameplay, then commit.'
    Write-Output 'Store captures/manifests remain historical until the single finalization pass. See BRANCH_WORKFLOW.md.'
} finally {
    if ($patchPath -and (Test-Path -LiteralPath $patchPath)) { Remove-Item -LiteralPath $patchPath }
    Pop-Location
}
