<# Integration regression: local clone only, no network, generation or publication.
   Run when the workflow helper changes, not on every gameplay edit. #>
[CmdletBinding()]
param([string]$AestheticRef = 'origin/aesthetic/typography-v1')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$checks = 0
function Assert-Workflow([bool]$Condition, [string]$Message) {
    $script:checks++
    if (-not $Condition) { throw $Message }
}
function Invoke-Git([string[]]$Arguments) {
    $result = & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($Arguments -join ' ')" }
    return $result
}
function Assert-Rejected([scriptblock]$Action, [string]$Reason) {
    $rejected = $false
    try { & $Action | Out-Null } catch {
        if ($_.Exception.Message -match $Reason) { $rejected = $true } else { throw }
    }
    Assert-Workflow $rejected "Expected guard: $Reason"
}
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $repoRoot
try {
    $main = Invoke-Git -Arguments @('rev-parse', 'main')
    $aesthetic = Invoke-Git -Arguments @('rev-parse', '--verify', '--end-of-options', "$AestheticRef^{commit}")
    $out = Join-Path $repoRoot 'test-output'
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    # Prevent the main project's importer scanning the nested fixture project.
    [IO.File]::WriteAllText((Join-Path $out '.gdignore'), '')
    $fixture = Join-Path $out ('workflow-fixture-' + [guid]::NewGuid().ToString('N'))
    Invoke-Git -Arguments @('clone', '--quiet', '--no-hardlinks', '--branch', 'main', $repoRoot, $fixture)
    Push-Location -LiteralPath $fixture
    try {
        Invoke-Git -Arguments @('remote', 'set-url', 'origin', 'https://github.com/miguelxhubgitty/dont-touch-me.git')
        Invoke-Git -Arguments @('config', 'user.name', 'Workflow verification')
        Invoke-Git -Arguments @('config', 'user.email', 'workflow@example.invalid')
        Invoke-Git -Arguments @('config', 'commit.gpgsign', 'false')
        Assert-Workflow ((Invoke-Git -Arguments @('rev-parse', 'HEAD')) -eq $main) 'Fixture starts at current main'
        Assert-Rejected { & ./release/tools/apply_aesthetics.ps1 -AestheticRef $aesthetic -CheckOnly } 'release/'
        Invoke-Git -Arguments @('switch', '--quiet', '-c', 'release/workflow-verification')
        $readme = [IO.File]::ReadAllBytes((Join-Path $fixture 'README.md'))
        [IO.File]::AppendAllText((Join-Path $fixture 'README.md'), "`nUncommitted fixture probe.`n")
        Assert-Rejected { & ./release/tools/apply_aesthetics.ps1 -AestheticRef $aesthetic -CheckOnly } 'clean index'
        [IO.File]::WriteAllBytes((Join-Path $fixture 'README.md'), $readme)

        # Simulate later gameplay and version changes. Only this disposable clone
        # receives these fixture commits; no source branch/ref is changed.
        [IO.File]::AppendAllText((Join-Path $fixture 'scripts/blob.gd'), "`nconst WORKFLOW_FUTURE_GAMEPLAY := 42`n")
        $project = Join-Path $fixture 'project.godot'
        [IO.File]::WriteAllText($project, ([regex]::Replace([IO.File]::ReadAllText($project), '(?m)^config/version="[^"]+"', 'config/version="99.0.0-workflow-fixture"')))
        $presets = Join-Path $fixture 'export_presets.cfg'
        [IO.File]::WriteAllText($presets, ([regex]::Replace([IO.File]::ReadAllText($presets), '(?m)^version/code=\d+', 'version/code=987654')))
        Invoke-Git -Arguments @('add', 'scripts/blob.gd', 'project.godot', 'export_presets.cfg')
        Invoke-Git -Arguments @('commit', '--quiet', '-m', 'Fixture: simulate future gameplay and version changes')
        $projectHash = (Get-FileHash -LiteralPath $project).Hash
        $beforeIndex = Invoke-Git -Arguments @('write-tree')
        & ./release/tools/apply_aesthetics.ps1 -AestheticRef $aesthetic -CheckOnly
        Assert-Workflow ((Invoke-Git -Arguments @('write-tree')) -eq $beforeIndex) 'CheckOnly preserves index'
        Assert-Workflow (-not (Invoke-Git -Arguments @('status', '--porcelain'))) 'CheckOnly preserves working tree'
        & ./release/tools/apply_aesthetics.ps1 -AestheticRef $aesthetic
        $blob = [IO.File]::ReadAllText((Join-Path $fixture 'scripts/blob.gd'))
        Assert-Workflow ($blob.Contains('WORKFLOW_FUTURE_GAMEPLAY := 42')) 'New gameplay survives integration'
        Assert-Workflow ($blob.Contains('Typography.BODY_FONT')) 'Runtime typography is applied'
        Assert-Workflow ((Get-FileHash -LiteralPath $project).Hash -eq $projectHash) 'Project metadata is not overwritten'
        Assert-Workflow ([IO.File]::ReadAllText($presets).Contains('version/code=987654')) 'New export version survives'
        Assert-Workflow ([IO.File]::ReadAllText($presets).Contains('assets/fonts/OFL-Space-Grotesk.txt')) 'Font license reaches exports'
        Assert-Workflow (-not (Invoke-Git -Arguments @('diff', '--name-only', 'HEAD', '--', 'release/assets', 'release/assets-inventory.json'))) 'No old captures/manifests copied or regenerated'
        Assert-Workflow (-not (Invoke-Git -Arguments @('diff', '--name-only', $aesthetic, '--', 'assets/fonts', 'assets/typography', 'scripts/typography.gd'))) 'Approved font, phrase and runtime resources preserved'
        Invoke-Git -Arguments @('diff', '--cached', '--check')
        Invoke-Git -Arguments @('commit', '--quiet', '-m', 'Fixture: verify staged typography integration')
        Assert-Rejected { & ./release/tools/apply_aesthetics.ps1 -AestheticRef $aesthetic -CheckOnly } 'already present'
        Assert-Workflow (-not (Invoke-Git -Arguments @('status', '--porcelain'))) 'Fixture ends clean'

        # A real overlapping font edit must be rejected before touching files,
        # including when the caller omits CheckOnly.
        Invoke-Git -Arguments @('switch', '--quiet', '-c', 'release/workflow-conflict', $main)
        $blobPath = Join-Path $fixture 'scripts/blob.gd'
        [IO.File]::WriteAllText($blobPath, [IO.File]::ReadAllText($blobPath).Replace('font = ThemeDB.fallback_font', 'font = SystemFont.new()'))
        Invoke-Git -Arguments @('add', 'scripts/blob.gd')
        Invoke-Git -Arguments @('commit', '--quiet', '-m', 'Fixture: simulate overlapping font edit')
        $beforeIndex = Invoke-Git -Arguments @('write-tree')
        $blobHash = (Get-FileHash -LiteralPath $blobPath).Hash
        Assert-Rejected { & ./release/tools/apply_aesthetics.ps1 -AestheticRef $aesthetic } 'Git failed'
        Assert-Workflow ((Invoke-Git -Arguments @('write-tree')) -eq $beforeIndex) 'Conflict preflight preserves real index'
        Assert-Workflow ((Get-FileHash -LiteralPath $blobPath).Hash -eq $blobHash) 'Conflict preflight preserves gameplay file'
        Assert-Workflow (-not (Invoke-Git -Arguments @('status', '--porcelain'))) 'Rejected conflict leaves tree clean'
        Assert-Workflow (-not (Test-Path -LiteralPath 'scripts/typography.gd')) 'Rejected conflict leaves no partial typography resources'
        Write-Output "Workflow: $checks checks passed; local fixture retained at $fixture"
    } finally { Pop-Location }
} finally { Pop-Location }
