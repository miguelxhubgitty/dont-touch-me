# Responsive landscape on mobile and desktop

Reviewed `origin/main` at `2a58cfe`. The manual-orientation draft builds on the unmerged desktop Stage 1 branch.

## Current behavior

- `project.godot` already uses aspect-preserving `canvas_items` and `expand` with a 720 × 1280 design size. A wide window gets extra logical width. The desktop opens portrait and the mobile orientation is locked to portrait. Keep the existing design size and stretch settings initially. A phone rotated to landscape has less physical height, so the blob and text can look smaller even when their proportions are correct.
- `scripts/blob.gd::_resize` recenters the actor and rebuilds its pose and hit geometry. It also cancels the current reaction, audio, special idle and jump return. Existing tests intentionally expect reset on resize. Mouse and native touch already share the gameplay input path. The authored renderer and procedural fallback both use the controller.
- `scripts/sound_hud_layout.gd` and `scripts/hud_safe_area.gd` already place the Android sound controls in logical safe-area coordinates. Desktop retains the scene's original anchors. The open panel uses its measured minimum size but can overflow if the safe rectangle is too short. Intro text and speech bubbles use gameplay viewport coordinates and do not avoid the HUD. The Privacy Policy control on main is Android-only. The separate iOS Alpha export is outside the scope of this work.

## Stage 1 — Establish the landscape layout

Keep one scene and one gameplay coordinate system. Validate the current desktop window in wide and short shapes first. Keep the blob horizontally centered at its existing relative height, letting both sides provide breathing room. Leave the space empty for now. Only make presentation adjustments that a real capture shows are needed. Keep portrait placement unchanged. Keep JUMP and RUN's authored offscreen travel and use the real viewport edge for those reactions.

```text
on viewport resize:
    retain existing gameplay resize/reset behavior
    compute available HUD bounds from the existing safe-area helper on mobile
    on desktop use the visible viewport
    keep existing margins and anchors when controls fit
    measure open volume panel and keep it out of other control hit regions
    if the panel cannot fit, use a bounded scrollable panel only if the test matrix needs it
    in landscape, adjust intro or bubble placement only where measurements show clipping
        or overlap with the HUD
```

Inspect `main.tscn`, the sound HUD layout and volume panel first. If the intro or speech bubbles need changes, route both renderers through a shared placement calculation instead of two aspect-ratio branches. Change rendered and clickable bounds together. For extreme desktop sizes, prefer the smallest usable minimum window size demonstrated by the tests. Do not stretch gameplay or assign a fixed landscape canvas.

### Stage 1 capture evidence

Captured the actual main scene with the volume panel open, using Godot's rendered root window on Windows. Portrait (432 × 768), landscape (960 × 540) and ultrawide (1260 × 540) are pixel-identical before and after. The original portrait panel can cover part of the temporary intro while open. That existing presentation is preserved.

The 810 × 108 request demonstrated unreadable type and tiny input targets. A native desktop-only 540-pixel minimum height is the smallest height in the tested usable landscape set. The same request now renders at 810 × 540 with unchanged scale rules and a usable panel. The width remains resizable. The new rendered regression checks the dimensions, uniform scale, HUD containment, and the existing resize cancellation and hitbox.

[Short window before](../docs/testing/desktop-landscape/short-before.png) · [Same resize request after](../docs/testing/desktop-landscape/short-after.png)

## Stage 2 — Manual mobile orientation and desktop preview

Desktop uses the real root window at 1920 × 1080 and 3840 × 2160. Both sizes keep the same logical viewport and centered blob. Capture native renders at both sizes. Leave the side space empty. The existing launch size stays portrait.

On Android, the Volume menu includes an Orientation button that switches between fixed Portrait and Landscape. The app starts portrait, with the choice kept for the current session. Only a menu action issues a request. Native touches are consumed in the HUD, and the existing emulated-input guard applies. The existing safe-area hooks and logical resize/reset handle resulting window changes.

```text
open Volume menu:
    show Orientation only on Android
on native tap or regular activation:
    consume the UI gesture and ignore mirrored pointer events
    switch the label and request fixed Portrait or fixed Landscape
on window resize:
    retain existing game-state reset and HUD placement
```

Godot 4.7.2's Android backend forwards the orientation request to Android. Android 16 may disregard orientation locks on API-36 apps on displays at least 600 dp wide. Native phones still need testing. On iOS, Godot's API documents an initial sensor-mode requirement for runtime orientation. Changing the shared project setting would weaken the manual-only guarantee before the lock is applied. Keep iOS locked to portrait in this draft. Before enabling its menu, verify supported orientations, cold launch, and fixed orientation requests with an iPhone build. No release presets, frozen Alpha or submitted build are part of this experiment. [Android 16 adaptive layout rules](https://developer.android.com/about/versions/16/behavior-changes-16#adaptive-layouts) · [Godot DisplayServer API](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html#class-displayserver-method-screen-set-orientation)

[1920 × 1080 capture](../docs/testing/manual-landscape/1920x1080.png) · [3840 × 2160 capture](../docs/testing/manual-landscape/3840x2160.png)

## iPhone manual orientation preview

This follow-up stacks on the Android selector. The Godot 4.7.2 API note mentions a sensor-mode prerequisite. The tagged iOS implementation sets the fixed orientation and asks UIKit to update geometry. Its view controller disables automatic rotation for fixed modes. Separately, the exporter writes the supported-orientation list from the portrait project setting. The preview therefore keeps the runtime project fixed to Portrait and widens only the generated iPhone Info.plist. The existing Volume button requests a single fixed orientation at a time. The preview requests the portrait lock at startup and uses the existing mobile safe-area layout.

1. On Mac, open the development project with Godot 4.7.2 and matching templates. In **iOS Orientation Preview**, set the local Apple Team ID and export project-only to a disposable directory as `DontTouchMePreview`. This preset has its own preview bundle identifier.
2. From the development checkout run `python3 release/tools/configure_ios_orientation_preview.py /path/to/DontTouchMePreview/DontTouchMePreview-Info.plist`. Repeat after every fresh export. The script accepts only the preview identifier and changes only the iPhone orientation allowlist.
3. On an iPhone Simulator, build Debug using Xcode. Cold-launch while simulated hardware is in landscape and confirm the game starts portrait. In Volume, select Landscape and then Portrait. Between selections, rotate the simulated hardware and confirm that the game stays in the selected mode. Check the safe area, volume sliders, and touches on the blob before and after resizing.
4. Repeat on a physical iPhone before enabling this in a shipping preset. Check cold launch with the phone held sideways, orientation lock while turning the handset, system rotation lock, background/resume and cutout clearance. Simulator results alone cannot settle all of those.

[Godot 4.7.2 iOS orientation setter](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/apple_embedded/display_server_apple_embedded.mm#L614) · [Godot 4.7.2 iOS orientation masks](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/apple_embedded/godot_view_controller.mm#L288)

Windows verification generated a project-only preview with the official template and confirmed that the script changes only the plist orientation array. The exported PCK reports fixed Portrait and the expected preview feature. Five fast and eleven audio suites passed, including the synthetic Portrait → Landscape → Portrait menu requests, landscape safe bounds and input isolation. Existing test-shutdown warnings recurred. No iOS Simulator or hardware run was available.

## Acceptance checks

- Use the normal scene in a real root window with production stretch settings. Compare the 432 × 768 portrait baseline, a tall phone, 16:9 and tall-phone landscape, a tablet-shaped window, and a short desktop window. Supplement with synthetic scaled/offset inset rectangles for left and right notches and bottom navigation. Assert uniform scale, legible text, panel containment, and no overlapping interactive HUD bounds.
- Exercise matching painted hitboxes and mouse/native touch in both renderers. Verify wide bounds for JUMP, RUN and RECOIL, BOX and SIGN readability, dialogue, idle/sleep/WAKE, and a HUD gesture that stays out of gameplay. Run the existing fast, audio and animation suites.
- Select each orientation from the Volume menu during idle and active reactions. Confirm the current resize reset leaves a valid pose, reachable hitbox and usable HUD, with no late audio cue. On a device, rotate it without choosing a mode to verify that physical rotation alone does not switch modes. Check cutouts, safe areas, input and focus on Android and repeat on iOS when its implementation is validated. Desktop tests and injected events do not establish device behavior.

[Godot viewport scaling and orientation](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
