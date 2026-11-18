#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('fast', 'audio', 'animation', 'full')]
    [string]$Mode = 'fast',
    [string]$Godot = 'godot',
    [string]$AudioDriver = 'Dummy',
    [string]$Python = 'python',
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 270
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$engine = (Get-Command $Godot -CommandType Application -ErrorAction Stop).Source
$version = & $engine --version
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable(\.|$)') {
    throw "Godot 4.7.2 stable required. Found: $version"
}

$root = Split-Path -Parent $PSScriptRoot
$fast = @('behavior')
$audio = @('audio', 'audio_mute', 'audio_click_attenuation', 'audio_interruption_fades',
    'audio_volume_balance', 'audio_preview_menu_test', 'audio_voice_timing',
    'audio_variation', 'audio_volume_controls')
$animation = @('adobe_playable', 'adobe_simple', 'adobe_idle_hits', 'adobe_hit_outline_audit',
    'adobe_reactions', 'adobe_reaction_hits', 'adobe_reaction_geometry', 'adobe_next_reactions',
    'adobe_moving_reactions', 'adobe_flatten_turn_stop', 'adobe_sign_box_run', 'adobe_wake',
    'jump_unbounded', 'adobe_unbounded_game', 'adobe_bubble_render', 'adobe_reaction_render_edges',
    'stretch_idle', 'humming_idle')
$rendered = @('adobe_sign_box_run', 'adobe_bubble_render', 'adobe_reaction_render_edges')
$suites = switch ($Mode) {
    fast { $fast }
    audio { $audio }
    animation { $animation }
    full { $fast + $audio + $animation + @('release', 'fingerprints') }
}

function Invoke-GodotCheck([string]$Label, [string[]]$Arguments) {
    Write-Host "`n--- $Label ---"
    $start = [Diagnostics.ProcessStartInfo]::new($engine)
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($arg in @('--path', $root) + $Arguments) {
        $start.ArgumentList.Add($arg)
    }

    $process = [Diagnostics.Process]::Start($start)
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $exited = $process.WaitForExit($TimeoutSeconds * 1000)
        if (-not $exited) {
            $process.Kill($true)
            $process.WaitForExit()
        }
        $lines = @($stdout.GetAwaiter().GetResult() -split '\r?\n') +
            @($stderr.GetAwaiter().GetResult() -split '\r?\n')
        $lines | Where-Object { $_ } | ForEach-Object { Write-Host $_ }
        if (-not $exited) { throw "$Label timed out after $TimeoutSeconds seconds." }
        if ($process.ExitCode -ne 0) { throw "$Label exited with code $($process.ExitCode)." }
    } finally {
        $process.Dispose()
    }

    if ($lines -match '^\s*FAIL:') { throw "$Label reported a failed assertion." }

    # Godot can exit zero on script errors. Keep reported shutdown diagnostics visible.
    $errors = @($lines | Where-Object { $_ -match '^\s*(ERROR|SCRIPT ERROR):' })
    if ($errors.Count -eq 1 -and $errors[0] -match '^ERROR: \d+ resources? still in use at exit' -and
        ($lines -match '^WARNING: \d+ ObjectDB instances were leaked at exit') -and
        $Label -ne 'Import') {
        Write-Warning "$Label reported outstanding resources at test shutdown. Compare against a normal game exit before attributing a runtime leak."
    } elseif ($errors.Count) {
        throw "$Label reported a Godot error."
    }
}

# Godot keeps logs and user:// data in these per-process locations. Give each run its own profile.
$environment = @{}
$profile = Join-Path ([IO.Path]::GetTempPath()) ('dtm-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $profile | Out-Null
Push-Location -LiteralPath $root
try {
    foreach ($name in @('APPDATA', 'LOCALAPPDATA', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME')) {
        $environment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $profile, 'Process')
    }
    $reports = Join-Path $root 'test-output'
    New-Item -ItemType Directory -Path $reports -Force | Out-Null
    $ignore = Join-Path $reports '.gdignore'
    if (-not (Test-Path -LiteralPath $ignore)) {
        New-Item -ItemType File -Path $ignore | Out-Null
    }
    Invoke-GodotCheck 'Import' @('--headless', '--editor', '--import', '--quit')
    foreach ($suite in $suites) {
        $headless = $suite -notin $rendered -and ($suite -notin $audio -or $AudioDriver -eq 'Dummy')
        [string[]]$display = if ($headless) { @('--headless') } else { @() }
        $driver = if ($suite -in $audio) { $AudioDriver } else { 'Dummy' }
        Invoke-GodotCheck $suite ($display + @('--audio-driver', $driver, '--script', "tests/$suite.gd"))
    }
    if ($Mode -eq 'full') {
        $interpreter = (Get-Command $Python -CommandType Application -ErrorAction Stop).Source
        & $interpreter -B -m unittest discover -s tests
        if ($LASTEXITCODE -ne 0) { throw "Python suite failed (exit $LASTEXITCODE)." }
        & "$PSScriptRoot/workflow.ps1" -BaseRef HEAD
    }
    Write-Host "`nPASS: $Mode ($($suites.Count) Godot suites). Test profile: $profile"
} finally {
    foreach ($name in $environment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $environment[$name], 'Process')
    }
    Pop-Location
}
