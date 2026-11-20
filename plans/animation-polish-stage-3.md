# Stage 3 — Sleep-eye rendering and animation handoffs

Status: diagnosis and pseudocode for owner approval. Baseline: GitHub `origin/main` at `a0e5e5f`, including merged Stage 2 PR #40. The approval branch contains planning documentation only.

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

## Option B — Preserve the outgoing pose briefly on actual Yawn interrupts (recommended)

After an accepted poke interrupts Yawn, carry the displayed Yawn mouth forward for up to 0.09 seconds while it closes vertically. Let the selected reaction and all its audio start immediately. In the procedural path only, blend from the outgoing rendered position, angle, scale and eye pose toward the reaction pose over that same short interval. Evaluate each blend against the live intended reaction pose at that elapsed time. Use the already sampled entry keys for the authored body and eyes. The transition mockup shows this specific interruption only. Keep the mouth attached to the same body transform throughout.

The brief overlap means the mouth may be visible for a few frames of the reaction. If that reads as two expressions competing, keep the body blend and retain the hard cut for the mouth. Scope the first implementation to the demonstrated Yawn interruption. Ordinary Stage 2 clip completion, authored track timing, reaction asset keys, and WAKE stay as approved.

```text
on accepted poke while Yawn is active:
    snapshot outgoing displayed pose and current local mouth
    start the selected reaction and audio immediately using the existing path
    remember the snapshot and reaction instance for its entry

while this reaction instance is in its first 0.09 seconds:
    weight = 1 - smoothstep(0, 0.09, reaction_elapsed)
    render the existing mouth vertically closing by weight in body space
    if using procedural renderer:
        blend displayed pose from outgoing snapshot to today's sampled reaction pose
        use this displayed body transform in hit testing

when weight expires, another reaction starts, or resize cancels:
    clear the temporary state

when eligibility thresholds change:
    keep current Stage 2 clip completion and handoff rules
```

## Verification after approval

- Record steady sleep and Sleep Twitch at half-scale, normal logical scale and a narrow viewport in both settings. Compare white coverage change, eye centroid movement and emitted color. Confirm eye movement follows breathing without altering the body silhouette or hit boundaries. Check settling into sleep and the original immediate WAKE expression.
- Verify the observed Yawn interruption with mouse and synthetic touch in both settings. Compare first displayed pose, intervening frames, and the first frame at or beyond 0.09 seconds with the unmodified reaction. Check fresh pokes during the blend, misses, resize, mute, and reaction audio timing. Confirm collision geometry follows the blended visible body.
- Recheck Stretch and Humming completion, Humming beyond 18 seconds, Fighting Sleep into full sleep, normal reaction exits and WAKE. Run the full Godot regression suite with existing WASAPI and rendered-edge coverage. Report physical-device coverage separately.
- Keep Stage 1 point and streak rules, Stage 2 clocks and probabilities, approved animation/audio files, and frozen releases intact.

Owner approval requested for the two scoped defaults: keep the sleeping eyes and smooth their coverage, and add the 0.09-second Yawn-only interruption bridge shown in the mockup.
