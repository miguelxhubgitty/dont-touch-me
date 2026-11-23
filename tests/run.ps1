#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('fast', 'audio', 'animation', 'full')]
    [string]$Mode = 'fast',
    # Run only these suites instead of a mode: Godot suite names (tests/<name>.gd),
    # 'python' or 'workflow'. Accepts an array or a comma-separated string.
    [string[]]$Suite = @(),
    # Print one PASS line per check; print full output only for a failing check.
    [switch]$Quiet,
    [string]$Godot = 'godot',
    [string]$AudioDriver = 'Dummy',
    [string]$Python = 'python',
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 270
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$root = Split-Path -Parent $PSScriptRoot
$fast = @('behavior', 'annoyance_stage_1', 'idle_stage_2', 'animation_polish', 'android_privacy_policy', 'ios_privacy_policy', 'audio_shutdown')
$audio = @('audio', 'audio_mute', 'audio_click_attenuation', 'audio_interruption_fades',
    'audio_volume_balance', 'audio_preview_menu_test', 'audio_voice_timing',
    'audio_variation', 'audio_volume_controls', 'animation_audio_cues', 'manual_landscape')
$animation = @('adobe_playable', 'adobe_simple', 'adobe_idle_hits', 'adobe_hit_outline_audit',
    'adobe_reactions', 'adobe_reaction_hits', 'adobe_reaction_geometry', 'adobe_next_reactions',
    'adobe_moving_reactions', 'adobe_flatten_turn_stop', 'adobe_sign_box_run', 'adobe_wake',
    'jump_unbounded', 'adobe_unbounded_game', 'adobe_bubble_render', 'adobe_reaction_render_edges',
    'stretch_idle', 'humming_idle', 'recoil_reaction', 'puffer_huff_reaction', 'animation_sleep_eye_render', 'desktop_landscape',
    'movement_continuity')
$rendered = @('adobe_sign_box_run', 'adobe_bubble_render', 'adobe_reaction_render_edges', 'animation_sleep_eye_render', 'desktop_landscape')
$releaseChecks = @('release', 'fingerprints')
$godotNames = $fast + $audio + $animation + $releaseChecks
$otherNames = @('python', 'workflow')

# PowerShell variable names are case-insensitive: $Suite is the parameter, so loops
# below use $testName and the selection is $godotSuites, never $suite.
if ($Suite.Count -gt 0) {
    if ($PSBoundParameters.ContainsKey('Mode')) { throw 'Use either a mode or -Suite, not both.' }
    $requested = @($Suite | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($requested.Count -eq 0) { throw '-Suite needs at least one suite name.' }
    $selection = [Collections.Generic.List[string]]::new()
    foreach ($name in $requested) {
        # Map to the canonical spelling: Godot script paths are case-sensitive on Linux.
        $canonical = @($godotNames + $otherNames) | Where-Object { $_ -eq $name } | Select-Object -First 1
        if (-not $canonical) {
            throw "Unknown suite '$name'. Known: $(($godotNames + $otherNames) -join ', ')."
        }
        if (-not $selection.Contains($canonical)) { $selection.Add($canonical) }
    }
    $godotSuites = @($selection | Where-Object { $_ -in $godotNames })
    $runPython = $selection.Contains('python')
    $runWorkflow = $selection.Contains('workflow')
    $runLabel = $selection -join ','
} else {
    $godotSuites = switch ($Mode) {
        fast { $fast }
        audio { $audio }
        animation { $animation }
        full { $fast + $audio + $animation + $releaseChecks }
    }
    $runPython = $runWorkflow = $Mode -eq 'full'
    $runLabel = $Mode
}

if ($godotSuites.Count -gt 0) {
    # Get-Command lists every PATH match; use the first, as the shell would.
    $engine = (Get-Command $Godot -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $version = & $engine --version
    if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable(\.|$)') {
        throw "Godot 4.7.2 stable required. Found: $version"
    }
}

# Runs one check as a child process and fails it on a nonzero exit or timeout. Godot
# checks also fail on assertion, leak and error lines. Quiet mode prints the captured
# output only when the check fails.
function Invoke-Check([string]$Label, [string]$Executable, [string[]]$Arguments, [switch]$GodotCheck) {
    $timer = [Diagnostics.Stopwatch]::StartNew()
    if (-not $Quiet) { Write-Host "`n--- $Label ---" }
    $start = [Diagnostics.ProcessStartInfo]::new($Executable)
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($arg in $Arguments) {
        $start.ArgumentList.Add($arg)
    }

    $process = [Diagnostics.Process]::Start($start)
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        # Only Godot invocations have a time limit, as before.
        $exited = $process.WaitForExit($(if ($GodotCheck) { $TimeoutSeconds * 1000 } else { -1 }))
        if (-not $exited) {
            $process.Kill($true)
            $process.WaitForExit()
        }
        $lines = @($stdout.GetAwaiter().GetResult() -split '\r?\n') +
            @($stderr.GetAwaiter().GetResult() -split '\r?\n')
        $exitCode = $process.ExitCode
    } finally {
        $process.Dispose()
    }

    $failure = if (-not $exited) {
        "$Label timed out after $TimeoutSeconds seconds."
    } elseif ($exitCode -ne 0) {
        "$Label exited with code $exitCode."
    } elseif ($GodotCheck -and $lines -match '^\s*FAIL:') {
        "$Label reported a failed assertion."
    } elseif ($GodotCheck -and ($lines -match '^WARNING: \d+ ObjectDB instances were leaked at exit' -or
            $lines -match '^ERROR: \d+ resources? still in use at exit')) {
        # Suites drain stopped audio playbacks before quitting (tests/audio_test_cleanup.gd),
        # so Godot's exit-time leak report now means something was really left alive.
        "$Label leaked objects or resources at exit. Rerun it with --verbose to list them."
    } elseif ($GodotCheck -and $lines -match '^\s*(ERROR|SCRIPT ERROR):') {
        # Godot can exit zero on script errors.
        "$Label reported a Godot error."
    }

    if ($Quiet -and $failure) { Write-Host "`n--- $Label (FAILED) ---" }
    if (-not $Quiet -or $failure) {
        $lines | Where-Object { $_ } | ForEach-Object { Write-Host $_ }
    }
    if ($failure) { throw $failure }
    if ($Quiet) { Write-Host ('PASS: {0} ({1:N1}s)' -f $Label, $timer.Elapsed.TotalSeconds) }
}

function Invoke-GodotCheck([string]$Label, [string[]]$Arguments) {
    Invoke-Check $Label $engine (@('--path', $root) + $Arguments) -GodotCheck
}

# Godot keeps logs and user:// data in these per-process locations. Give each run its own profile.
$environment = @{}
$testProfile = Join-Path ([IO.Path]::GetTempPath()) ('dtm-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testProfile | Out-Null
Push-Location -LiteralPath $root
try {
    foreach ($name in @('APPDATA', 'LOCALAPPDATA', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME')) {
        $environment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $testProfile, 'Process')
    }
    $reports = Join-Path $root 'test-output'
    New-Item -ItemType Directory -Path $reports -Force | Out-Null
    $ignore = Join-Path $reports '.gdignore'
    if (-not (Test-Path -LiteralPath $ignore)) {
        New-Item -ItemType File -Path $ignore | Out-Null
    }
    if ($godotSuites.Count -gt 0) {
        Invoke-GodotCheck 'Import' @('--headless', '--editor', '--import', '--quit')
    }
    foreach ($testName in $godotSuites) {
        $headless = $testName -notin $rendered -and ($testName -notin $audio -or $AudioDriver -eq 'Dummy')
        [string[]]$display = if ($headless) { @('--headless') } else { @() }
        $driver = if ($testName -in $audio) { $AudioDriver } else { 'Dummy' }
        Invoke-GodotCheck $testName ($display + @('--audio-driver', $driver, '--script', "tests/$testName.gd"))
    }
    $extras = @()
    if ($runPython) {
        $interpreter = (Get-Command $Python -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
        Invoke-Check 'python' $interpreter @('-B', '-m', 'unittest', 'discover', '-s', 'tests')
        $extras += 'Python'
    }
    if ($runWorkflow) {
        $shell = (Get-Process -Id $PID).Path
        Invoke-Check 'workflow' $shell @('-NoProfile', '-NonInteractive', '-File', (Join-Path $PSScriptRoot 'workflow.ps1'), '-BaseRef', 'HEAD')
        $extras += 'workflow'
    }
    $summary = @("$($godotSuites.Count) Godot suites") + $extras
    Write-Host "`nPASS: $runLabel ($($summary -join ', ')). Test profile: $testProfile"
} finally {
    foreach ($name in $environment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $environment[$name], 'Process')
    }
    Pop-Location
}
