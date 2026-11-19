# Stage 1 — Annoyance rebalancing

Status: Owner-approved pseudocode and implementation on `feature/annoyance-stage-1`.
Base: origin/main at `33e4999800c60167ab420516b43af357d62d3f5a`.

## Current behavior and scope

The controller adds 7–10 points in `touch_at()` before selecting a reaction. Normal pointer input calls that method, then handles a rejected touch as either silent cardboard or a background miss with audio feedback. Stage 1 advances the previously deferred annoyance work in the roadmap. Sleep, inactivity decay, tier cutoffs and pools, hit geometry, and audio remain governed by their current implementations. Stage 2 owns future sleep and inactivity-decay changes.

## Implementation pseudocode

Use the existing `clock` to measure time since the first accepted poke in the streak, and `idle_time` to measure time since the most recent accepted poke. Read both before the usual inactivity reset. Keep one capped counter and one start timestamp. Use the existing randomness method for the gain and reduction rolls. The gameplay streak never reads the audio manager's streak or timers.

```text
touch_at(point):
    if existing visible hit test rejects point:
        return false

    keep existing audio click registration
    if successful_poke_streak == 0
        or clock >= streak_started_at + 1.8 seconds
        or idle_time >= 1.8 seconds:
        successful_poke_streak = 0
        streak_started_at = clock
    successful_poke_streak = min(9, successful_poke_streak + 1)
    multiplier = [1, 1, 1, 1, 0.8, 0.6, 0.4, 0.2, 0][successful_poke_streak - 1]
    reset inactivity and idle scheduling as before
    annoyance = clamp(annoyance + random(1.8, 3.6) * multiplier, 0, 100)
    keep existing flash, WAKE, protected BOX/RUN and tier-selection rules
    keep existing contact audio
    return true

handle_player_touch(point):
    if touch_at(point):
        return
    if existing rejected-touch classification identifies blocked cardboard:
        annoyance = clamp(annoyance - random(1.8, 3.6), 0, 100)
        return
    annoyance = clamp(annoyance - random(0.9, 1.8), 0, 100)
    keep existing background-miss audio handling if audio manager exists
```

A streak expires 1.8 seconds after its first accepted poke, even if accepted pokes continue. It also expires after a 1.8-second gap since the last accepted poke. Check expiry on the next accepted poke, which starts a fresh window and gets the full multiplier, including at the exact boundary. The start timestamp moves only when a new streak begins. A long gap gives one fresh streak when play resumes.

A rejected touch never changes the active reaction, sleep state, inactivity clock, count, or streak start. This keeps the direct `touch_at()` hit-and-accept contract for existing callers and applies reductions through ordinary mouse and screen-touch input. Peek eyes and exposed body remain successful pokes. A successful poke at the 100-point cap or the ninth-poke plateau still resets inactivity and goes through the normal reaction path. Time follows the existing gameplay clock, including its pause and focus behavior. Audio attempts, cooldowns, silence on cardboard, and the 0.45-second audio streak remain as before.

## Verification

- Use seeded rolls and fixture times for all nine streak positions, zero gains for subsequent pokes inside the window, and clamping at both ends. Test with and without audio enabled.
- Keep tapping successfully at intervals below 0.45 seconds. Assert zero gain after the ninth poke just before 1.8 seconds from the first poke. At the exact boundary, assert full gain even though the previous poke was recent. Repeat across multiple windows to verify each starts at its first accepted poke.
- Exercise resumed play just below and exactly at a 1.8-second gap after one accepted poke, then after a longer gap. A gap of 1.8 seconds necessarily also expires the window because the first poke precedes or equals the last. Check the observable result, a new streak, without requiring an isolated inactivity-only expiry.
- Drive rejected mouse and screen touches through normal input. Cover cardboard, if possible a flap, and a true miss at nonzero annoyance. Assert that misses and blocks neither advance nor refresh the successful-poke streak. Verify a cardboard touch stays silent and a miss still attempts its usual cue.
- Exercise zero-gain reaction selection, protected BOX/RUN timing, sleep/wake, and the existing tier cutoffs. Start at zero and reach each tier through repeated successful pokes across consecutive windows without a 1.8-second pause. Keep deterministic control of existing idle and motion fixtures.
- Update the audio test that currently asserts unchanged annoyance on a background miss. Preserve its checks for no reaction and real miss dispatch. Check both directions of independence: the audio streak resets at 0.45 seconds while the gameplay streak continues, and the gameplay window expires during rapid taps while audio remains attenuated.
- Run the relevant Godot gameplay, animation, audio, and workflow checks. Update current-state documentation, the roadmap, and the journal after verification. Keep historical Alpha documentation intact.

## Discovery risk

The first eight accepted pokes in a window add 10.8–21.6 points before gains reach zero, with an expected increase of 16.2 if all eight fit in the window. Tier two requires more than 20 points, so the first window may stay in tier one. Continued successful tapping restores full gain on the first poke of each new window. Players can reach all tiers without learning a pause cadence. Actual discovery speed still depends on successful hits, misses, and reaction availability. Keep thresholds and decay as specified.
