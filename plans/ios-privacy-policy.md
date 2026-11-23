# iOS in-app Privacy Policy button

Status: shipped on `main` via #54/#56. Follow-up (owner-approved 2026-11-23): single-touch fix for both platforms on `fix/privacy-button-single-touch`, draft PR, awaiting review.

## Player-visible behavior

On iPhone, the same flat **Privacy Policy** label that Android shows appears in the bottom-right of the safe area, with the same 24-unit margins. Tapping it opens `https://miguelxhubgitty.github.io/dont-touch-me/privacy.html` in the system browser. Desktop and Web stay hidden, unchanged.

## Current behavior (source)

`scripts/privacy_policy_button.gd` returns from `_ready()` unless `_is_android()` (`OS.has_feature("android")`). On Android it:
- loads the release font when present;
- connects `pressed`;
- positions itself from `HudSafeArea.from_window` and repositions on resize and focus-in;
- shows its `PrivacyHUD` canvas layer.

A native press opens the policy. Drags and emulated mouse events are consumed so neither reaches the `BaseButton` path or gameplay. `PrivacyHUD` starts hidden in `main.tscn`.

The frozen Alpha used a separate iOS-only script (PR #46, `release-prep/ios-alpha-0.1.0`). It is not on `main` and is not changed here.

## Pseudocode

```
_ready():
    if not (_is_android() or _is_ios()): return        # was: if not _is_android()
    ...unchanged Android setup...

_is_android(): return OS.has_feature("android")         # unchanged
_is_ios():     return OS.has_feature("ios")             # new; independent of manual_ios_orientation
```

No other code path changes. Placement, input filtering, font and URL are shared.

## Edge cases and trade-offs

- **Gate on `ios`, not on the orientation feature.** Every iOS export of `main` shows the button, whatever its preset.
- **Repeated native press (fixed in the follow-up).** PR #46 found that a second native press before the first one's release opened the policy twice, and the shared script did the same on Android and iOS. The button now reuses the mute button's single-touch tracking (`touch_index`). The first native touch-down opens the policy once, and other fingers are ignored until that touch is released or canceled. Focus loss or hiding also resets the tracking, so a lost release cannot lock the button. Both privacy tests cover extra fingers, cancellation, focus loss, hiding and a later tap.
- **HUD layout.** The button sits apart from the top Settings/Sound HUD; there's no overlap at the tested portrait, landscape and narrow sizes.
- **Accessibility.** The visible text "Privacy Policy" is the button's accessible name. The 200 × 58 target exceeds Apple's 44 pt minimum at the project scale.

## Acceptance criteria

- With iOS simulated, the button is visible with the same label, footprint and safe-area placement as Android. Native press opens once. Drag, emulated and canceled touches don't open it. Gameplay, annoyance and audio are untouched, and an adjacent background tap still counts as a miss.
- The Android checks pass unchanged; desktop stays hidden and disconnected.
- A Mac iOS export contains the updated script. Native Safari handoff, return to the game and VoiceOver reading need an iPhone check.
