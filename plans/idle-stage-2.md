# Stage 2 — Inactivity behavior and annoyance decay

Owner approved the pseudocode and tuning. Implementation is on `feature/idle-stage-2`. Baseline is GitHub main at `9408fdd0fec03b290ca19a32f75954a4b3e98816`, with Stage 1 merged through PR #39.

## Approved behavior and current code

| Inactivity | Stage | Base behavior | Eligible clips |
| --- | --- | --- | --- |
| [0, 3) s | Settling in | Existing breathing, blinking and looking around | None |
| [3, 9) s | Awake | Existing breathing, blinking and looking around | Stretch, Humming |
| [9, 12) s | Sleepy | Breathing with heavier lids and smaller glances | Stretch, Humming, Yawn, Microsleep |
| [12, 18) s | Falling asleep | Lower lids, a slight droop and restrained gaze | Humming, Yawn, Microsleep, Fighting Sleep |
| [18, ∞) s | Fully asleep | Existing sleeping breath, closed eyes and sleep marks | Sleep Twitch |

The thresholds govern when a new behavior can start. An animation that starts before a threshold can finish afterward. Actual sleep begins at the first free handoff at or after 18 seconds. Microsleep and Fighting Sleep can close the eyes before that handoff while the blob remains awake for input purposes.

On current main, `scripts/blob.gd` rolls once per inactivity period, limits Stretch and Humming to scheduled windows, and skips clips whose predicted end would pass 18 seconds. Its separate sleep check can take priority over idle playback, and its old decay subtracts four points per second after 2.5 seconds. Replace the one-shot scheduler and the sleep/deadline checks with a single stage-aware choice at free boundaries. Preserve the existing `clock` and `idle_time`, both Stage 1 streak resets, point rolls, tiers and reaction selection, protected BOX/RUN behavior, and JUMP return timing. Preserve the Stage 1 distinction between successful pokes, blocked cardboard and misses.

## Proposed selection and pacing

These are initial weights per eligible roll. A base result means continuing the stage's base behavior. If the previous special clip is in the table, transfer its weight to Base, so avoiding a repeat does not make other clips more frequent.

| Stage | Base | Stretch | Humming | Yawn | Microsleep | Fighting Sleep | Sleep Twitch |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Awake | 20 | 40 | 40 | — | — | — | — |
| Sleepy | 25 | 15 | 15 | 25 | 20 | — | — |
| Falling asleep | 20 | — | 15 | 20 | 20 | 25 | — |
| Fully asleep | 80 | — | — | — | — | — | 20 |

- First roll at 4.5 seconds. Each later awake-through-falling-asleep roll waits 0.9–1.8 seconds after a special clip completes or Base is selected. The wait only governs the next roll. A threshold can change the eligible pool during that wait, and is never a cue to roll twice.
- Sleep gets its own cooldown on entry. Wait 3.6–5.4 seconds before each sleep roll, measured from sleep entry, the previous Base result, or the end of the last Twitch. That gap governs repeated Twitches because there is only one sleep clip.
- Use the existing idle-only RNG for selections and cooldowns. Keep the last special clip through Base results and stage changes within an inactivity period. Reset it on an accepted poke. Roll once at a free opportunity, using the latest stage and actual start time. A long frame never backfills missed rolls.
- Stretch keeps its current 1.8-second motion and cue. Humming keeps its 2.7-second motion, all three bobs, soft squint, and cue. During a clip, breathing can be the underlying motion where the approved pose uses it. Eye tracks with authored expressions take precedence over idle blinks and glances.

## New clips and rendering

| Clip | Duration | Reference and motion |
| --- | ---: | --- |
| Yawn | 1.98 s | Owner-approved `stage-2-idle-previews/yawn-smaller-mouth/yawn-smaller-mouth.gif`. Pink `#D98E9A` fill, no separate lip layer, fixed local corners, narrow proportion from the approved audition and a 42 × 62 px rendered peak in its review viewport. Peak at 0.63 s. Five gentle whole-body oscillations through 1.13 s, with the mouth fully open. Start closing at 1.17 s. Close back to the thin line and settle. Outside Yawn, restore the normal face without a mouth. |
| Microsleep | 1.35 s | One slow droop, a brief closed-eye pause and a quick return to the stage's resting expression. |
| Fighting Sleep | 2.43 s | Two uneven nods, with a sharper first recovery. If sleep is due on completion, settle closed at the handoff. Otherwise return to the falling-asleep expression. |
| Sleep Twitch | 0.54 s | Small squash and rebound over the existing sleep pose. Eyes stay shut and the blob remains asleep. |

- Reuse `SpecialIdle` and its controller-owned start time. Give each clip one duration and sample its pose from elapsed time. Extend the existing pose and rendering functions with only the fields the new clips need. Keep the current authored AnimationPlayer breathing, Stretch/Humming and reaction tracks. Apply the new idle offsets through the existing authored renderer and use the same sampled motion with procedural drawing. Keep fully asleep and Sleep Twitch on the existing procedural sleep path. Use the approved local mouth curves and attach the mouth and eyes to the same body transform during the Yawn shudder. Use the matching rendered-body hit geometry in both paths, including the sleeping body during a Twitch.
- At a free stage handoff, blend the outgoing eye and body pose into the next base pose over about 0.27 seconds where needed. Measure from the outgoing clip's final pose. During a clip, its expression stays in control even after a threshold. In settling and awake, keep existing blinks and gaze. In sleepy and falling asleep, narrow the default lids and reduce gaze amplitude. Keep sleep gaze anchored and return to the existing WAKE entry pose through the normal reaction path. Include a continuity check where authored idle hands off to procedural sleep.

## Runtime pseudocode for review

```text
advance(delta):
    previous_idle = idle_time
    idle_time += delta
    annoyance = clamp(annoyance - (decay_at(idle_time) - decay_at(previous_idle)), 0, 100)
    advance existing reaction, return motion, audio, gaze and blink clocks
    update_idle()
    draw the sampled pose and any short visual handoff blend

decay_at(t):
    after_grace = max(0, t - 3.0)
    return 0.45 * after_grace * after_grace

update_idle():
    if reaction active or JUMP return active:
        return

    if special clip active:
        if elapsed < duration:
            return
        sample its terminal pose
        clear active clip
        schedule next roll after the stage-appropriate cooldown

    latest = stage_for(idle_time)  # 18, 12, 9, 3, then settling
    if latest differs from the displayed stage:
        begin visual handoff from current or terminal pose
        apply latest stage
        if entering fully asleep:
            mark asleep
            attempt existing sleep.enter cue once
            schedule first sleep roll from this entry time

    if before next roll or still settling:
        return
    choice = weighted roll from latest pool after repetition filter
    if choice is Base:
        schedule next roll after cooldown
        return
    latch clip and start time
    record it as the last selected clip
    attempt existing cue if this clip is Stretch or Humming

accepted poke:
    hit-test the pose currently visible on screen
    remember whether the blob is actually asleep
    interrupt any special clip and use its current pose for reaction entry
    keep Stage 1 gain, streak, idle reset and normal reaction rules
    choose existing WAKE path only if actually asleep
    restart Stage 2 scheduling at settling in

miss or blocked cardboard:
    apply existing Stage 1 point and audio behavior
    leave idle time, stage, current clip and next roll alone
```

The interval difference integrates the approved instantaneous rate `0.9 * max(0, idle_time - 3.0)` exactly over each gameplay step, including a step straddling 3 seconds. Treat decay as loss accrued in that interval so later point changes are independent. Keep the current gameplay clock's pause, focus and delta-cap semantics. At 9, 12 and 18 seconds, cumulative losses before clamping are 16.2, 36.45 and 101.25 points respectively.

Thresholds never interrupt a clip, including Humming crossing 18 seconds. Actual touches retain the existing immediate interruption rules. On an accepted poke, use the existing interruption handling and ownership check for the clip's voice slot. A miss during Humming can play its existing feedback but leaves Humming's sound alone. Preserve mute, cooldown, audio click attenuation and lack of replay after suppression. New clips are proposed silent. Preserve existing resize cancellation and focus/pause policy, including existing suppression on those transitions. Sleep entry fires once at the actual handoff and Sleep Twitch plays no entry cue.

## Verification and review

- Add focused tests using seeded rolls and direct elapsed samples at 3, 9, 12 and 18 seconds, including large steps, active reactions, JUMP return, no catch-up rolls, cooldowns, repetition and no selection RNG calls during an active clip. Test Humming across 9, 12 and 18, Stretch across 12, Fighting Sleep across 18, and direct handoff to the latest eligible stage after a long clip.
- Assert exact clip lengths and Yawn markers. Compare representative rendered poses against the approved GIF in Godot 4.7.2. Audit the pink mouth contour, fixed local width, shudder hold, pose continuity, closed-eye Twitch, and moving hit geometry on both renderers. Measure durations from the clip clock.
- Verify the analytic decay at 3, 9, 12 and 18 seconds, with several tick partitions of the same elapsed interval. Cover straddling the grace period, saturation at zero, and subsequent successful, blocked and missed inputs. Rerun the Stage 1 suite to confirm accepted pokes and the independent audio streak are preserved.
- Test a poke in each new clip, including immediately before real sleep, during sleeping and during Sleep Twitch. Verify only actual sleep enters WAKE. Test continuous BOX/RUN protection, resize cancellation, focus changes and mute. Assert Humming and Stretch play once, finish normally across thresholds, and fade correctly when interrupted. A miss must not fade either cue. Test single sleep-entry dispatch even when playback is suppressed.
- Run the full standard Godot, audio, animation, rendered-edge and workflow suite. Include normal-scene mouse checks and report physical touch separately if unavailable. Update the roadmap, current-state documentation and internal journal after implementation and validation. Keep frozen Alpha records intact.

The approved initial weights and cooldowns appear above. The handoff blend runs for up to 0.27 seconds where the pose changes. Settling and awake share a pose and breathing phase. The four new clips are silent.
