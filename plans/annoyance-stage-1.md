# Stage 1 — Annoyance rebalancing

Status: Owner-approved behavior. Implementation pseudocode awaits review.
Base: origin/main at `33e4999800c60167ab420516b43af357d62d3f5a`.

## Current behavior and scope

The controller adds 7–10 points in `touch_at()` before selecting a reaction. Normal pointer input calls that method, then handles a rejected touch as either silent cardboard or a background miss with audio feedback. Stage 1 advances the previously deferred annoyance work in the roadmap. Sleep, inactivity decay, tier cutoffs and pools, hit geometry, and audio remain governed by their current implementations. Stage 2 owns future sleep and inactivity-decay changes.

## Implementation pseudocode

Use the existing `idle_time` as elapsed gameplay time since the last accepted poke. Only an accepted poke currently zeroes it in normal gameplay. Read it before the existing reset. Add one capped gameplay streak counter and use the existing randomness method for the gain and reduction rolls. Do not read the audio manager's streak or timers.

```text
touch_at(point):
    if existing visible hit test rejects point:
        return false

    keep existing audio click registration
    if idle_time >= 1.8 seconds:
        successful_poke_streak = 0
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

A rejected touch never changes the active reaction, sleep state, or inactivity clock. This keeps the direct `touch_at()` hit-and-accept contract for existing callers and applies reductions through ordinary mouse and screen-touch input. Peek eyes and exposed body remain successful pokes. A successful poke at the 100-point cap or the ninth-poke plateau still refreshes the streak and goes through the normal reaction path. An exact 1.8-second gameplay gap starts a new streak. Time follows the existing gameplay clock, including its pause and focus behavior. Audio attempts, cooldowns, silence on cardboard, and the 0.45-second audio streak remain as before.

## Verification

- Use seeded rolls and fixture times for all nine streak positions, continued spam, clamp at both ends, and reset just below and at 1.8 seconds. Test with and without audio enabled.
- Drive rejected mouse and screen touches through normal input. Cover cardboard, if possible a flap, and a true miss at nonzero annoyance. Assert that misses and blocks neither advance nor refresh the successful-poke streak. Verify a cardboard touch stays silent and a miss still attempts its usual cue.
- Exercise zero-gain reaction selection, protected BOX/RUN timing, sleep/wake, and the existing tier cutoffs. Start at zero and reach each tier using streaks separated by at least 1.8 seconds and less than 2.5 seconds. Keep deterministic control of existing idle and motion fixtures.
- Update the audio test that currently asserts unchanged annoyance on a background miss. Preserve its checks for no reaction and real miss dispatch. Check that the audio streak can reset at 0.45 seconds while the gameplay streak continues.
- Run the relevant Godot gameplay, animation, audio, and workflow checks. Update current-state documentation, the roadmap, and the journal after verification. Keep historical Alpha documentation intact.

## Discovery risk

A single uninterrupted streak can add only 10.8–21.6 points before gains reach zero, with an expected increase of 16.2. Tier two requires more than 20 points. Continuous poking from zero may therefore stay in the lowest tier indefinitely. Repeated short bursts separated by a 1.8-second pause can still reach every tier without triggering passive decay, which starts after 2.5 seconds. Whether players discover that cadence needs playtesting. Keep thresholds and decay as specified.
