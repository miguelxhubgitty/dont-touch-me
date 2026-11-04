# M1 audio playback structure — alligator placeholder

Status: owner explicitly approved this pseudocode in conversation on November 3, 2026. Implemented locally and validated; no commit, packaging or publication. See audio/README.md for complete events/results.

## Verified starting point

- Current branch main at 4f2c40d; existing dirty distribution/visual/journal work preserved.
- Opportunity reference read directly from origin/docs/audio-sfx-opportunity-evaluation-2026-11-03 at b261c0b: plans/AUDIO_SFX_OPPORTUNITY_EVALUATION.md. Not present in main. No foundation, aesthetic, release or MSIX branch merged/changed.
- Existing placeholder: audio/prototypes/M1.3R_baby_alligator_call_study_NONCOMMERCIAL_CC-BY-NC-3.0.wav. SHA-256 21e128bb80c68eb261468b2f9400335bfbeaad982da8505fead02fde623ec270. Preserve byte-for-byte; no new sound generation.
- Source: MattesHaus, https://freesound.org/people/MattesHaus/sounds/334027/, CC BY-NC 3.0. Existing attribution: audio/prototypes/M1.3R_ALLIGATOR_NONCOMMERCIAL_SOURCE.md. Temporary local development use; no release/export/publication requested.
- Existing game is silent. blob.gd owns reaction selection, derived poses, sleep and completion. BOX/RUN are protected; further hits do not begin a new reaction.

## Proposed files and responsibilities

- scripts/audio_manager.gd: dedicated child controller, three bounded playback roles (contact, voice, action), event dispatch, cancellation, mute and pause handling. No gameplay RNG use.
- audio/blob_events.json: centralized independently named events, source paths, enabled flags, levels and maximum playback duration. Every event references the same existing placeholder. Optional events remain available but disabled.
- scripts/blob.gd: minimal notification hooks only, with existing behavior and pose calculations intact. Create the audio-manager child so Blob.new() tests and the main scene share the same integration.
- tests/audio.gd: all-reaction and transition checks, event trace assertions, silence/cancellation/throttling, resource decoding/player state and gameplay invariance.
- audio/README.md: each event/trigger, replacement instructions, placeholder rights and test results.
- docs/INTERNAL_DEVELOPER_JOURNAL.md: append actual implementation/validation only after approval and work.

## Central event map

Each reaction has its own enabled contact event: blink.contact, side_eye.contact, squish.contact, irritated.contact, dont.contact, seriously.contact, slide.contact, jump.contact, shake.contact, flatten.contact, turn.contact, stop.contact, sign.contact, box.contact, run.contact, wake.contact.

Contacts fire on an accepted body/peek-eye poke after selecting the new reaction, or use the current protected BOX/RUN reaction. Direct helper calls beginning an animation do not invent contact.

| Reaction | Enabled performance events / semantic triggers | Optional mapped events, initially disabled |
| --- | --- | --- |
| BLINK | Contact only | None |
| SIDE_EYE | Contact only; preserve silent stare | side_eye.voice when expression establishes |
| SQUISH | Contact only | squish.voice at compression onset; squish.rebound when compression changes from increasing to recovering |
| IRRITATED | irritated.voice when narrowed-eye expression establishes | None |
| DONT | dont.voice when bubble/expression establishes | None |
| SERIOUSLY | Contact only | seriously.voice when skeptical expression establishes |
| SLIDE | slide.move at actual horizontal departure; stop when destination reached | None |
| JUMP | jump.land only when an uninterrupted arc actually returns to baseline | jump.voice at takeoff |
| SHAKE | shake.voice once when shaking starts, never per vibration | None |
| FLATTEN | Contact only | flatten.compress when compression begins; flatten.release when held compression starts releasing |
| TURN | Contact only | turn.voice when face turns away |
| STOP | stop.voice once when protest expression establishes | None |
| SIGN | sign.raise at raising onset; silence while held | sign.settle when fully raised; sign.lower at lowering onset |
| BOX | box.raise when cardboard rises; box.lower when lowering begins | box.voice once when peek eyes become visible |
| RUN | run.depart at departure onset | run.voice once at departure; run.return when body actually reenters during return |
| WAKE | wake.voice at startle takeoff | wake.land at baseline return; wake.grumble when eyes switch to narrowed phase |

Additional enabled event: sleep.enter once on false-to-true asleep transition. It is an explicitly proposed selection of the evaluation's optional strong candidate.

Silence: awake idle, natural breathing/blinks/gaze, sleeping idle, background/misses/blocked cardboard, bubble UI itself, intro fade, app launch/resume, window resize. No user-oriented tapping/UI sounds, ambient/music, alternate animal packs or unused future mechanics.

## Pseudocode for approval

```text
INITIALIZE:
    load central event map and existing sample, validate names and paths
    create at most one AudioStreamPlayer per contact/voice/action role
    missing/invalid audio logs an error and stays silent; never alters gameplay

ON ACCEPTED TOUCH:
    execute existing annoyance, sleep/wake and reaction selection unchanged
    notify manager of resulting reaction-specific contact
    if BOX/RUN remained active: contact only; do not restart cues or cancel their act

ON BEGIN_REACTION:
    cancel prior reaction's pending cues and its playing audio
    assign a new reaction generation ID; clear once-only cue set
    capture initial animation phase; trigger eligible start cues
    a direct helper start does not play a fake contact

ON ADVANCE:
    use the existing simulation dt, not independent timers
    compare previous/current animation phase and derived pose
    fire each eligible event once on its actual phase transition
    derive markers from existing pose formulas, not arbitrary fixed seconds
    detect crossings even if one frame steps across the event
    handle landing before existing code clears reaction at natural completion
    cancelled/interrupted movement never produces a delayed landing
    do not play queued missed events after a stall, mute or focus change
    sleep.enter only on the transition into asleep

ON INTERRUPTION / RESIZE:
    invalidate old generation; discard its pending cues
    stop its playing contact/voice/action clips (short de-click ramp if feasible)
    resize never produces a sound or completion/landing

PLAY EVENT:
    look up unique name; disabled events remain silent
    enforce contact minimum spacing 100ms, vocal starts 300ms
    rate-limit contact using existing simulation clock; never queue rejected sounds
    one stream per role; maximum three simultaneous streams, conservative mix gain
    protected BOX/RUN extra contact does not restart voice/prop
    use SAME unchanged source WAV for every assigned event
    cap contact/action snippets around 0.30s and voice around 0.45s to prevent
    the 1.99s multi-call study from repeating in full at every short cue
    continuous action clips also stop at the corresponding movement phase end
    snippet caps are playback behavior, not new audio files
    do not alter pitch randomly or consume gameplay RNG

MUTE / FOCUS / TREE PAUSE:
    a single blob-audio muted property immediately stops all sound
    no separate user SFX setting or new UI visual in this step
    losing focus/pause stops sound and suspends cue delivery
    resume/unmute silently; never replay stale events
    use Godot pause-aware nodes plus the existing focus notifications
```

Expression establishes = the same ease/hold envelope used for bubble/eye poses first reaches 0.85. Full raise = envelope first reaches its held value. Lowering/release = envelope exits its held phase. For SQUISH, rebound is the actual change in compression direction computed from its analytic shape (not an arbitrary timestamp). RUN phase boundaries follow its existing normalized phases; offscreen hold stays silent and departure sound stops before it. JUMP/WAKE landings follow their actual vertical arcs and are suppressed if interrupted. These markers and tests must remain consistent if durations change.

## Replacement procedure

Edit only the selected event's source path in audio/blob_events.json to point to a WAV/OGG under res://audio/. Keep the event name and trigger; no gameplay edit. Each event may independently set enabled, volume and maximum duration. Replace placeholder duration limits when selecting finished sounds. The same source can be shared intentionally across related families.

## Acceptance / tests after approval

- Confirm exact sample hash, Godot import/decode and AudioStreamPlayer starting/stopping.
- Every one of the 16 reaction-specific contact names, plus every enabled semantic performance event, triggers with expected count/order. Optional entries stay silent unless explicitly enabled in test configuration.
- Test before/at/after each marker with small and large time steps; ensure no frame repeats or duplicate completion markers.
- JUMP/WAKE full arcs produce one landing where enabled; interruption/resize before landing produces none.
- Protected BOX/RUN spam retains action timeline, adds only throttled contact and never restarts performance; blocked cardboard/background/release/motion inputs remain silent.
- Test sleep transition once, repeated asleep frames silent, wake and immediate re-poke cancellation.
- Rate limits, bounded player count, simultaneous cues, mute/unmute, focus/pause/resume and manager destruction leave no stale sound or queued burst.
- Compare seeded gameplay traces with audio enabled/disabled: annoyance, choices, motion, timers and sleep remain identical.
- Run existing behavior/release suites. Actual speaker playback/animation-sync review remains separate from headless event assertions; never claim physical-device or full listening validation from simulated tests.
- No branch switch/merge, artwork/font regeneration, source commit/push, packaging or publication.

## Approval scope

Approve the concrete event routing, optional/default choices, sample snippet caps and interruption rules above before implementation. The request to implement authorizes the work's scope; this checkpoint fulfills AGENTS.md's distinct requirement to present pseudocode and obtain explicit approval before meaningful system changes. If the owner wants every optional opportunity audible immediately instead, revise enabled defaults before implementation.

## Implemented validation and limits

Dedicated manager, central JSON map, minimal notification hooks and audio tests implemented. Alligator source bytes preserved. Optional events disabled as approved. Audio checks 36,658/0 failures, behavior 320,270/0 failures, release 237,076/0 failures. Windows WASAPI mixer produced nonzero samples and exact silence when muted. Saved pre-change gameplay/RNG trace matches. Natural snippet endings fade; interruption stops immediately. No settings UI was introduced; mute is a manager property. Fast-exit legacy audio cleanup warnings and absence of subjective/physical-device/browser audio validation are documented in audio/README.md. No new sounds/visuals/branch merges/releases.
