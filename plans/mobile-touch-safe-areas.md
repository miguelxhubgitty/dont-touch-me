# Stage 4 — Mobile touch and safe areas

Phase 1 audit and proposal. Baseline `origin/main` at `afd7bfc`. Awaiting implementation approval.

## Confirmed findings

- In the real main scene on Godot 4.7.2, all five sliders reported **50 → 50 → 50** after a native touch at 50%, a drag to 90%, and a drag/release beyond the right edge. `audio_volume_controls.gd::_slider_touch` applies a value on touch-down and only consumes drags. Its desktop drag signals do not run for native touch. The current volume test verifies taps and uses direct assignment for later values, which misses this defect.
- HUD gestures in the probe left annoyance, inactivity, reaction, click streak and audio trace unchanged. The blob processes press events in `_unhandled_input`, after GUI controls can consume them. Godot's GUI routes drag and release back to the control that received the finger's press, even after it leaves the slider. Native GUI ownership can therefore handle this fix without an input hook on the blob or a global touch router.
- Both emulation settings are disabled in `project.godot`. An explicitly injected `DEVICE_ID_EMULATION` mouse press/release after a native tap caused a second toggle on both Volume and Sound. This is a confirmed synthetic duplicate path, with no evidence of it occurring in the shipping Android event stream. Privacy already suppresses that duplicate locally.
- In a synthetic 720 × 1280 viewport whose safe rectangle began at (54, 84), Volume remained at (20, 20), Sound at (538, 20), and the panel at (20, 108). All three extended outside that safe rectangle. The Android Privacy button already converts physical display safe areas using scaling and origins, and adjusts on viewport resize and focus return. Audio HUD positions use scene offsets and panel placement without safe-area awareness.

## Proposed implementation

### Native slider input

Use one active native finger and slider for the panel and keep Godot's existing mouse and keyboard handling. Update the existing slider value; the current value-change handler continues applying its existing bus and mute rules. Batch native saves like the existing desktop drag saves.

```text
on native slider press:
    consume the event
    if an uncanceled finger can take ownership, remember finger and slider
    update the slider from the local horizontal position

on native slider drag:
    consume the event
    if the finger owns this slider:
        set value from clamp(local_x / slider_width, 0, 1)

on matching release, cancellation, panel hide or focus loss:
    clear ownership and save once if the value changed
    keep the last applied value on cancellation

on value changed:
    apply existing bus gain / mute logic
    persist immediately only outside native and desktop drag transactions
```

Consume native touch and drag over the Volume button, panel background and sliders before gameplay. Keep Volume's native activation on press and Sound's activation on its existing valid release. Suppress device-tagged emulated pointer events at those controls, as Privacy already does. Preserve real mouse, keyboard and native touch activation. Additional slider fingers cannot move or release the owned slider. Fingers starting outside the HUD keep their existing gameplay path.

### Android HUD placement

Reuse the Privacy button's safe-area transform by extracting just the rectangle conversion. Run audio repositioning only on Android. React to viewport size changes and focus return, and recheck the safe rectangle when opening the panel. Keep desktop layout, Android orientation, and the gameplay viewport untouched.

```text
safe_hud_rect = visible_viewport intersect
    inverse(viewport_to_window) * (display_safe_rect - window_origin)
if conversion yields no usable overlap, use the visible viewport
keep normal audio margins where they fit
shift Volume and Sound inward to clear top and side insets
place the panel just below Volume and clamp horizontally to the safe rectangle
try above Volume only if below cannot fit and above can
```

Measure full panel bounds after its container minimum size is known. Keep the current controls and panel size. If a representative Android safe rectangle cannot fit the panel at the current size, bring that case back for review before adding scrolling or shrinking touch targets.

## Expected files

| File | Proposed scope |
| --- | --- |
| `scripts/audio_volume_controls.gd` | Native finger ownership, value updates, save batching, local input filtering and panel placement |
| `scripts/audio_mute_button.gd` | Reject emulated pointer events at the button |
| `scripts/hud_safe_area.gd` | Shared physical-to-logical safe rectangle calculation extracted from Privacy |
| `scripts/sound_hud_layout.gd`, `main.tscn` | Small Android-only layout hook for the existing audio HUD |
| `scripts/privacy_policy_button.gd` | Reuse the rectangle conversion with the same button placement and activation |
| `tests/audio_volume_controls.gd`, `tests/audio_mute.gd`, `tests/android_privacy_policy.gd` | Extend the existing suites. The runner already includes them |

## Proposed regression tests

1. Route presses, drags and releases through a viewport in the real game scene. Assert 50% → 90% on each bus and clamp at 100% and 0% with a finger outside the track. Verify gain changes during dragging and existing behavior while master mute is active.
2. Exercise a second finger, cancellation, focus out, panel close/reopen and a fresh scene. Verify only the owning finger changes the slider, ownership clears, persistence happens once per changed gesture, and existing mouse and keyboard paths still work.
3. Route taps through the buttons, slider tracks, panel padding and labels. Assert no change to reaction, annoyance, idle timer, gameplay/audio click counters or audio trace. Assert one activation when injecting paired emulated input and normal behavior just outside HUD bounds.
4. Exercise full-screen, portrait, wide and landscape-sized synthetic layouts with asymmetric cutouts and bottom navigation insets, fractional scaling, content translation, and nonzero window origin. Verify all controls fit representative safe areas, the desktop rectangles match the original scene, and the Privacy footprint is unchanged. Check fallback for an empty safe rectangle.
5. Run focused suites and the standard fast and audio suites after implementation. Use isolated settings for all tests.

## Limits

The probe and proposed regressions validate synthetic Godot events and geometry. Android's actual insets, gesture navigation, cutouts, OS cancellation, and background/foreground input delivery still need a device. The audit changes no production code, project settings, or release artifacts.

References: [Godot Control input routing](https://docs.godotengine.org/en/stable/classes/class_control.html) · [Godot Viewport touch routing](https://github.com/godotengine/godot/blob/master/scene/main/viewport.cpp) · [Godot DisplayServer safe area](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area) · [Android 16 edge-to-edge](https://developer.android.com/about/versions/16/behavior-changes-16#edge-to-edge)
