# Movement continuity

Target release: 0.1.1. Status: design approved by the owner on 2026-11-23 (decisions A, B and C as recommended; D revised as below). Implemented on `fix/movement-continuity-0.1.1` and merged to `main` in [PR #65](https://github.com/miguelxhubgitty/dont-touch-me/pull/65) (merge commit `2c99276`). A follow-up adds the missing RECOIL contact sound; see Status.

## Problem

Every pose comes from one controller clock in `scripts/blob.gd`. Both renderers share its `body_position`: the authored renderer (`scripts/blob_animationplayer.gd`) only adds scale, rotation and eye tracks. An accepted touch called `begin_reaction`, which:

- took the current x, clamped to `190 … width − 190`, but always the floor height `anchor.y`. A touch in mid-air dropped the blob to the floor in one frame: up to 175 px for JUMP, 100 px for WAKE and 18 px for RECOIL;
- cut SLIDE and the offscreen JUMP return glide short, and the clamp could pull the blob sideways in one frame;
- cancelled the outgoing reaction's audio, so a cut-off jump never played `jump.land`.

The clamp also teleported a blob at rest. A free jump from the centre of a 720-pixel screen lands at x = 590, outside the band, so the next touch moved it to 530 before the reaction started. At logical widths below 380 the band is inverted (`190 > width − 190`). There, every reaction started 10 px from the centre, and SLIDE and procedural JUMP destinations were inconsistent.

## Design

1. **Physical movement completes and settles.** SLIDE, JUMP (both variants), RECOIL and WAKE run their full duration. Each one's body deformation continues until its final frame: SLIDE's stretch, JUMP's landing squash, RECOIL's landing squash and WAKE's landing squash plus slow recovery. This holds in the procedural envelopes and in the authored scale tracks (authored WAKE returns to rest between 1.3 and 1.65 s). None of these four has an expression-only tail, so the lock covers the whole reaction. The offscreen JUMP return glide is also locked until it reaches the centre. RUN and BOX keep their existing protection.
2. **Touches stay responsive and nothing is queued.** During a lock, an accepted touch still counts: annoyance, the poke streak, the idle reset, intro dismissal, the touch flash, click registration and the reaction's contact sound all happen exactly as for RUN today. Only the choice of a new reaction is skipped. No reaction is queued for later.
3. **Audio layers stay separate.** The contact sound answers every accepted touch. The ongoing reaction's own cues keep playing, so `jump.land` plays once on a real landing. Resize and focus loss still cancel as before.
4. **Expression-only reactions stay interruptible** (BLINK, SIDE_EYE, SQUISH, IRRITATED, DONT, SERIOUSLY, SHAKE, FLATTEN, TURN, STOP, SIGN, PUFFER_HUFF).
5. **No horizontal teleport.** A new reaction starts at the blob's actual x. Only SLIDE and procedural JUMP destinations are clamped, to a stage band that collapses to the centre when the screen is narrower than 380 logical pixels. When the start is outside the band, the facing direction follows the actual travel.

Unchanged: resize cancels everything, including a lock. Touches during sleep start WAKE. Box blocking and peek hits, tiers, decay, sleep timing, `last_reaction`, RUN's path and the free jump's ballistic flight are also unchanged.

Out of scope: on-the-spot wobble (SHAKE, STOP, YAWN beat, SLEEP_TWITCH, HUMMING bob) still hands its small current offset to the next reaction, and HUMMING's up-to-9 px lift still drops to the floor. The same goes for pose crossfades and reaction queuing.

## Pseudocode

```text
PHYSICAL_MOVEMENT = [SLIDE, JUMP, RECOIL, WAKE]     # deformation lasts to the final frame

reaction_locked():
    return jump_returning or reaction in [RUN, BOX] or reaction in PHYSICAL_MOVEMENT

touch_at(point):
    if not visible hit: return false            # unchanged
    register click, streak, annoyance, flash, intro   # unchanged
    if asleep: begin_reaction(WAKE)
    elif not reaction_locked(): begin_reaction(choose_reaction())
    idle_time = 0; reset special idle
    audio.contact(reaction)                     # the current reaction's contact sound
    return true

stage_x(x):
    margin = min(190, width / 2)
    return clamp(x, margin, width - margin)

begin_reaction(which, touch):
    origin = (body_position.x, anchor.y)        # actual x; the body is on the floor whenever a touch can get here
    direction = +1 if touch.x <= origin.x else -1
    if which is JUMP and free jump: destination.x = origin.x + direction * 230   # unchanged
    elif which is SLIDE or JUMP:
        destination.x = stage_x(origin.x + direction * 155)
        if |destination.x - origin.x| < 35: reverse direction; destination.x = stage_x(origin.x + direction * 155)
        if destination.x != origin.x: direction = sign(destination.x - origin.x)
    RECOIL and RUN: unchanged
```

## Edge cases

- **Rapid clicking during a lock:** every hit adds annoyance with the existing streak multipliers. The contact sound's 0.1 s cooldown and click attenuation still apply. One reaction plays, and the next one is chosen at the raised tier on the first hit after the lock.
- **Screen edges:** a jump that lands inside the screen but outside the band rests there, and the next reaction starts there. An offscreen landing glides back while locked. RECOIL travel stays limited by the room to the edge.
- **Narrow widths (below 380 logical px):** the band collapses to the centre. SLIDE and procedural JUMP move toward the centre or stay put, and nothing jumps sideways.
- **Sleep and idle:** a blob can't fall asleep during a reaction or the glide (unchanged). WAKE is now locked for its 1.65 s, and the next hit after it interrupts normally.
- **Authored renderer:** the entry pose is captured only when a reaction really starts. Hits in mid-air use each renderer's displayed outline, so a hit on the arcing body counts and a touch beside it misses.
- **Direct `begin_reaction` calls** (the all-pairs release matrix, fixtures) bypass the lock, as they bypass the RUN/BOX protection today.

## Tests

New `tests/movement_continuity.gd` (animation group). It covers both renderers at 300, 360, 720 and 1280 logical pixels wide:

- For each locked movement, mouse and touch hits at many points keep the reaction, elapsed time and path identical to an untouched twin. Annoyance and the contact sound still respond.
- The free jump plays `jump.land` exactly once despite hits. Hits during the return glide keep the glide. Resizing during a lock cancels it with no landing.
- Rapid tapping during a lock starts no extra reaction.
- After each movement, the next hit starts a reaction at the same x with no vertical or horizontal step, including a rest position outside the band and widths below 380.
- At every width, SLIDE and procedural JUMP destinations stay inside the stage band, and every reaction starts exactly at the body's position.
- Expression reactions remain interruptible.

Existing assertions that expected a hit to interrupt a movement are updated: `adobe_reaction_hits.gd` edge hits and `adobe_wake.gd` phase interrupts.

## Status

- [x] Design approved (2026-11-23)
- [x] Implementation and regression tests (fix/movement-continuity-0.1.1; affected suites pass locally on Windows)
- [x] Owner review and merge (PR #65, `2c99276`, 2026-11-23)
- [ ] Follow-up in review on `claude/recoil-contact-0.1.1`: RECOIL had no `recoil.contact` cue, so locked pokes during RECOIL were silent, contrary to design item 3. It now reuses `tap_success.wav` with `slide.contact`'s settings. The new check also found that pokes during the offscreen return glide were silent: `reaction` is already NONE there. `touch_at` now plays `jump.contact` while `jump_returning`. `movement_continuity` asserts the contact sound for every locked movement and runs in the fast group.
