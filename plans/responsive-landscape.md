# Responsive landscape on mobile and desktop

Reviewed `origin/main` at `2a58cfe`. Stage 1 is implemented for review. Stage 2 remains a proposal.

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

## Stage 2 — Enable and validate mobile rotation

After layout checks pass, enable device-driven portrait and both landscape directions for the development project. Inspect each generated Android manifest and future development iOS orientation list instead of assuming the project setting reaches both exports. Keep Android tap/drag capture, Privacy Policy behavior, app identifiers and signing settings intact. Extend safe-area handling to the existing audio HUD on mobile where the platform reports insets. Keep the frozen Alpha and its submitted iOS build outside the change.

Preserve the current reset on a logical size change for this first implementation. If rotations must preserve in-flight animations, propose that as a separate decision. It needs a state rebase design covering movement endpoints, offscreen return, timing, hit geometry and already-fired audio cues. The current tested reset should remain until that behavior is approved.

## Acceptance checks

- Use the normal scene in a real root window with production stretch settings. Compare the 432 × 768 portrait baseline, a tall phone, 16:9 and tall-phone landscape, a tablet-shaped window, and a short desktop window. Supplement with synthetic scaled/offset inset rectangles for left and right notches and bottom navigation. Assert uniform scale, legible text, panel containment, and no overlapping interactive HUD bounds.
- Exercise matching painted hitboxes and mouse/native touch in both renderers. Verify wide bounds for JUMP, RUN and RECOIL, BOX and SIGN readability, dialogue, idle/sleep/WAKE, and a HUD gesture that stays out of gameplay. Run the existing fast, audio and animation suites.
- Rotate or resize during idle and active reactions, with the volume panel open and while dragging. Confirm the current resize reset leaves a valid pose, reachable hitbox and usable HUD, with no late audio cue. Check real Android and iPhone rotation in both directions for cutouts, safe areas, native touch and focus events. Desktop tests and injected events do not establish device behavior.

[Godot viewport scaling and orientation](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
