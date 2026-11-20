# Stage 3 — Sleep-eye rendering and animation handoffs

Status: owner-approved and implemented on `feature/stage-3-animation-polish`. Baseline: GitHub `origin/main` at `a0e5e5f`, including merged Stage 2 PR #40.

## Reproduction and findings

Godot 4.7.2 Compatibility renderer. Used the actual main scene at a 360 × 640 output with a 720 × 1280 logical canvas. Compared the normal authored setting and the forced procedural setting. Sampled 120 steady sleeping frames per setting at 60 gameplay steps per second, plus frame sequences around Humming completion, sleep entry, a poke interrupting Yawn, and a poke waking the sleeper. The captures are local, under ignored `test-output/stage-3-review/`.

- **Historical gaze jumps:** pre-Stage-2 source let periodic random gaze changes reach the sleeping eyes. Current Stage 2 pins sleeping gaze to zero in `blob.gd::_apply_stage_idle_pose()`. I did not reproduce that positional step on current main. Both settings route fully asleep through the procedural renderer, including Sleep Twitch. Awake authored eye nodes are not displayed during sleep.
- **Current sleep shimmer:** the remaining artifact comes from pixel coverage. The white sleeping eye is an un-antialiased filled polygon with a two-logical-pixel vertical-radius floor. Body breathing moves that thin fill over subpixels. Both settings produced the same sample, with one eye changing from 14 to 24 white pixels and one to three raster rows. Its geometric center moved smoothly, at most 0.034 output pixels per frame, and gaze stayed zero. Quantizing its position would introduce a real jump and break the natural movement with the body.
- **Humming → drowsy rest / Humming → sleep:** no visible snap in these samples. At the sampled handoffs vertical eye-center steps were under 0.05 output px. The late Humming started at 16.2 seconds, ran beyond the 18-second threshold, and only entered sleep on completion. Keep the existing scheduler and handoff.
- **Yawn → a poke selecting BLINK:** the mouth vanishes on the first sampled reaction frame in both settings. The procedural renderer also replaces the stretched idle pose with the reaction's first pose. The eye center moved vertically by 6.18 output px on that step, versus 1.39 in authored mode, where entry keys already inherit the displayed body pose. `blob.gd::begin_reaction()` clears the idle, then `_update_pose()` rebuilds the shape. The authored adapter snapshots scale, roll and eyes, but does not carry the Yawn mouth into the next frame. BLINK's authored return to idle looked continuous in this sample.
- **Sleep → WAKE:** the sampled immediate eye opening is the approved surprise expression. Do not soften it. WAKE activates at the accepted poke and its authored entry uses the displayed sleeping scale. Preserve the existing wake arc, hit behavior and cue timing.

## Option A — Keep sleeping eyes with localized coverage smoothing (recommended)

Keep the current resting expression, breathing transform and sleep marks. In the procedural draw path, smooth coverage only for the two sleeping eye polygons. Use the existing ellipse contour and fill, with a small transparent antialias fringe expressed in screen pixels. Build it from the rendered eye transform so the fringe stays about one output pixel across viewport scales. The coverage-smoothed option in the comparison is a supersampled eye-only visual mockup, not production Godot output from that method.

Hiding the eyes eliminates the shimmer and the work to draw the two shapes. It makes the blob faceless until WAKE, so it relies entirely on the floating sleep marks to communicate sleep. The hidden comparison shows this tradeoff. I recommend keeping the eyes and solving the coverage issue. If hiding is chosen, hide only after true sleep starts, fade through the existing handoff, and reveal at the original WAKE frame.

```text
draw procedural face:
    compute eye center and ellipse radii as today
    if actually asleep:
        draw same eye at same location with subpixel coverage at the contour
    else:
        use existing eye draw
    keep same body breathing, Sleep Twitch and hit transform
```

## Option B — Startled blink on an accepted Yawn poke

Replace the earlier 0.09-second body-and-mouth blend with a 0.18-second face-only overlay. The reaction, its movement, hit geometry and audio start through the normal path at the poke. The overlay uses the displayed Yawn eyes and mouth as its first sample. It does not blend or write a new body pose.

| Time after the poke | Eyes | Mouth |
| --- | --- | --- |
| 0–0.036 s | Interpolate from the Yawn aperture to a wide startled expression | Close the current pink shape vertically to zero over the same interval, then hide it |
| 0.036–0.072 s | Close both eyes completely in a quick clearing blink | Hidden |
| 0.072–0.180 s | Reopen into the live focused reaction expression | Hidden |

The audition uses smoothstep with the requested phase boundaries, a wide aperture of 1.35 times the normal eye height, and no extra closed-eye hold. Evaluate the visible eye aperture continuously, including below the usual procedural minimum; complete closure means zero visible area. Preserve the reaction's eye placement and sample its current expression for the final reopening target. Use the same normalized timing in both renderers. At exactly 0.18 seconds the overlay contributes nothing, so the normal authored or procedural eye pose continues from the same value. Keep WAKE and non-Yawn entries as sampled on main.

~~~text
on accepted Yawn poke:
    snapshot displayed eye apertures and the pink mouth in body-local coordinates
    activate the selected reaction and audio immediately
    associate a face overlay with this reaction instance

while overlay belongs to current reaction:
    t = current reaction elapsed seconds
    live_target = sampled reaction eye apertures
    if t < 0.036:
        eyes = ease from outgoing aperture to wide at t
        mouth = outgoing mouth with eased vertical closure at t
    else if t < 0.072:
        eyes = ease from wide to fully shut at t
        mouth = hidden
    else if t < 0.180:
        eyes = ease from fully shut to live_target at t
        mouth = hidden
    else:
        clear overlay and use the live reaction face
    draw the face using the existing body transform

on a newly accepted reaction or resize:
    discard overlay from the previous reaction
on a miss or an inactivity threshold:
    keep existing Stage 2 behavior
~~~

The comparison shows the previous 0.09-second transition and the new sequence for the same Yawn poke in both settings. The test-only scene samples real geometry and reaction activation at 120 Hz for the new version. The review GIF slows both versions equally so the three phases remain readable. The previous mockup used a body blend in procedural mode, so the silhouette can move differently. This audition leaves normal body motion in control and changes only the face.

## Verification after approval

- Record steady sleep and Sleep Twitch at half-scale, normal logical scale and a narrow viewport in both settings. Compare white coverage change, eye centroid movement and emitted color. Confirm eye movement follows breathing without altering the body silhouette or hit boundaries. Check settling into sleep and the original immediate WAKE expression.
- Verify the observed Yawn interruption with mouse and synthetic touch in both settings. Sample all three phase boundaries and the live reaction pose at 0.18 seconds. Confirm the mouth closes by 0.036 seconds, the eyes fully close by 0.072 seconds, and the face matches the live reaction on release. Compare movement, hit-test results and audio dispatch against an unmodified reaction. Check fresh pokes during the overlay, misses, resize and mute.
- Recheck Stretch and Humming completion, Humming beyond 18 seconds, Fighting Sleep into full sleep, normal reaction exits and WAKE. Run the full Godot regression suite with existing WASAPI and rendered-edge coverage. Report physical-device coverage separately.
- Keep Stage 1 point and streak rules, Stage 2 clocks and probabilities, approved animation/audio files, and frozen releases intact.

The owner approved keeping the sleeping eyes with softened coverage and using the revised Yawn-only startled blink. Production uses an antialiased contour around the existing filled eye. The runtime comparison is separate from the pre-approval mockups and uses the same captured scenes from the baseline and feature branch.
