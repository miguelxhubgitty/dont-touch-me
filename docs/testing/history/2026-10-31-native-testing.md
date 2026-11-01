> Historical snapshot from `docs/macos-native-testing-2026-10-31` at `f698f5443825bbdf5a737e5a30fd7c2b3392fd13`. See [current testing status](../README.md) for superseding results. Local paths below describe the tested workstation.

# Native macOS testing — 2026-10-31

## Source and setup

- Repository: `miguelxhubgitty/dont-touch-me`.
- Local clone: `/Users/miguelnascimento/Documents/ChatGPT/dont-touch-me`.
- Cloned `release/v0.1.0-alpha`, fetched origin with `--no-tags`, and verified local HEAD and the remote release branch both resolved to `7af0d6dc06372713ca223cfb0e02e92fd5b9f0cf`.
- Results are recorded on `docs/macos-native-testing-2026-10-31`, branched from that release commit. No release history, gameplay, source assets, or existing tags were changed. No publication or export was performed.
- Host: Intel x86_64, macOS 26.3.1 (a), build 25D771280a.
- Engine: `4.7.2.stable.official.ed1daf0bf`, matching project.godot and README requirements. Standard Universal macOS build; GDScript needs no .NET SDK.
- Engine location: `/Users/miguelnascimento/Documents/ChatGPT/Tools/Godot-4.7.2/Godot.app`.
- Download: https://godotengine.org/download/archive/4.7.2-stable/ (Standard macOS Universal), extracted with `ditto -x -k`.
- Downloaded ZIP SHA-256: `c58a24e31d720be9d62f60cb5627c4e695fb72f21b0cfe1bc9ccaa9a3b3ba63e` (local artifact identification, not an independent vendor-checksum comparison).
- Native renderer reported OpenGL 4.1 Compatibility, AMD Radeon Pro 5500M OpenGL Engine.

## Automated checks

All commands ran from the repository root using the engine executable inside `Godot.app/Contents/MacOS/Godot`.

| Check | Result |
| --- | --- |
| `--headless --path . --editor --import --quit` | Exit 0 outside sandbox; Android build-tools warning only |
| `--headless --path . --script tests/behavior.gd` | 320270 checks, 0 failures, exit 0 |
| `--headless --path . --script tests/release.gd` | 237076 checks, 0 failures, exit 0 |
| `--headless --path . --script tests/fingerprints.gd` | 17 checks, 0 failures, exit 0 |
| `--headless --path . --script tests/typography.gd` | 127 checks, 0 failures, exit 0 |
| `--headless --path . --script release/tools/validate_package.gd` | 205 checks, 0 failures, exit 0 |
| `python3 -m unittest discover -s tests -p 'test_*.py' -v` | 24 tests: 23 passed, 1 skipped; exit 0 |

The Python skip is `test_existing_packages_and_no_aab`: existing local Alpha packages are unavailable in this fresh clone. No packages were generated to satisfy it. PowerShell workflow tests were not run because `pwsh` is absent. The optional render contact-sheet generator and asset generators were not run. Browser-specific smoke testing was outside this native macOS check.

Behavior checks simulate input and advance game time; they cover animation lifecycles, tiers, transformed hitboxes, mouse/touch paths, rapid taps, relaxation, sleep/wake, and resize recovery. They do not establish physical mouse delivery, renderer quality, or perceived animation smoothness.

## Native UI observations

Launched the release project directly with the native engine, without `--headless`, and observed/interacted with the game through computer-use controls. These are agent-observed UI checks, not assertions from the automated suites or user-reported results.

| Interaction | Observation |
| --- | --- |
| Startup | Native `Don't Touch Me (DEBUG)` window opened; title, blob, eyes, shadow and typography rendered |
| Mouse input/reactions | Repeated left clicks on the blob caused visible displacement/movement; native click delivery confirmed |
| Animation | Different body shapes and positions observed across frames, including movement and wake pose; exhaustive smoothness review not performed |
| Inactivity sleep | After 30 seconds without input, eyes closed and floating Z marks appeared |
| Wake | Clicking the sleeping blob produced a changed pose and `I was DREAMING.` dialogue |
| Resize | Dragged from approximately 432 × 832 outer window to 652 × 704, then back; blob remained visible, recentered, and accepted clicks at the new location |

Native startup and the tested gameplay interactions succeeded on this Mac. No crash or rendering error appeared in the native process output during these checks. The process was left running for further inspection.

Remaining manual observation: sustained animation smoothness, every reaction's visual quality, Retina/external-display behavior, repeated focus changes, and actual macOS system suspend/resume. In this report, “sleep/wake” above refers to the blob's inactivity behavior, not system sleep. The game source pauses processing on application focus loss; that specific native transition was not independently verified here.

## Setup issues and scope

- `/usr/bin/git` could not operate because Apple Command Line Tools are missing. GitHub Desktop's bundled Git worked when `GIT_EXEC_PATH` pointed to its bundled `libexec/git-core`. Installing developer tools was unnecessary for these checks.
- An initial sandboxed Godot import could not write normal `~/Library/Application Support/Godot` and `~/Library/Caches/Godot` folders and emitted cache/settings errors. The approved run outside the sandbox succeeded; these initial permission errors are not classified as game defects.
- The editor warned `Unable to open Android 'build-tools' directory.` Android tooling is absent and is not needed to run this macOS project.
- This validates the project running in the native macOS Godot engine. It does not validate an exported macOS app, Gatekeeper distribution, signing, notarization, or an installed release package.

## Run again

```sh
"/Users/miguelnascimento/Documents/ChatGPT/Tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot" --path "/Users/miguelnascimento/Documents/ChatGPT/dont-touch-me"
```

For the editor, append `--editor` to that command, then press F5 to play. The documentation branch has the same game content as the tested release commit.
