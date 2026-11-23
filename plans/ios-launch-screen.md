# iOS launch screen without the Godot logo

Status: owner-approved direction (2026-11-22): reuse the approved Alpha fix (PR #49). Implemented on `fix/ios-launch-screen`, draft PR, awaiting review.

## Player-visible behavior

Cold-launching the iPhone app shows a plain warm off-white screen (the game's existing background) until the first game frame. The Godot logo no longer appears. Gameplay, HUD, orientation and audio are unchanged.

## Cause

Godot 4.7.2's iOS exporter writes `Launch Screen.storyboard`, which shows `SplashImage`. When the preset's storyboard image fields are empty, the exporter fills `SplashImage` with its own 800 × 600 logo. `project.godot`'s `boot_splash/show_image=false` only controls the in-engine boot image, not this storyboard asset.

## Change (same as PR #49)

- Add `release/ios/launch-transparent.png`, copied byte-for-byte from the Alpha branch (blob `145a07d`, 1 × 1 RGBA, alpha 0).
- Set `storyboard/custom_image@2x` and `storyboard/custom_image@3x` to that PNG on the iOS preset.
- The storyboard background still comes from `boot_splash/bg_color`. `release/` has a `.gdignore` and is in the preset's exclude filter, so the PNG never enters the game PCK.

## Production preset (PR #53)

`main` currently has only the **iOS Orientation Preview** preset. The production **iOS** preset lives in draft PR #53. Both PRs append lines at the end of `export_presets.cfg`, so whichever merges second must be rebased. The new test requires the two storyboard lines on **every** iOS preset, so that rebase must add them to the production preset too. No other preset field changes.

## Edge cases

- iOS caches launch screens per install. Validate with an uninstall and reinstall, or a fresh Simulator.
- Android, Windows and Web presets are untouched.
- The Alpha (PR #46, tag `v0.1.0-alpha`) is not changed.

## Acceptance criteria

- Every iOS preset assigns the transparent PNG to both storyboard slots, and the PNG is fully transparent (`tests/test_ios_launch_screen.py`).
- In a fresh export, both `SplashImage` PNGs are 1 × 1 with zero alpha. The storyboard and the game PCK are unchanged.
- A Simulator cold launch shows no logo, then the game loads normally.
