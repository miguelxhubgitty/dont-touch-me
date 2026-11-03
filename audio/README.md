# Blob audio playback â€” development placeholder

Implemented November 3, 2026 after explicit approval of plans/audio-playback-placeholder.md. The opportunity evaluation was read from docs/audio-sfx-opportunity-evaluation-2026-11-03 at b261c0b; no branch was merged.

## Replace a sound

Edit the individual event in `audio/blob_events.json`: change its `stream` to a WAV/OGG path such as `res://audio/my_sounds/jump_landing.wav`. Keep the event name, role and marker. The game code does not change. Open/reload the game after changing the JSON; it loads once at startup. Each entry independently controls `enabled`, `volume_db` and `max_seconds`. Increase max_seconds when replacing the short development snippet with a longer final clip. Import the new sound in Godot before running. Missing/invalid files report an error and stay silent.

Every entry currently uses the exact existing alligator study. It is a multi-call 1.99-second WAV, so playback stops after 0.30 seconds for contact/action or 0.45 seconds for voice. No edited/derived audio files were generated. The same sample for every event is an explicitly approved temporary exception to the final reaction-dependent sound textures. Event IDs already distinguish every reaction.

Placeholder source: MattesHaus, https://freesound.org/people/MattesHaus/sounds/334027/ . **CC BY-NC 3.0; development placeholder only, not cleared for a commercial release.** Full attribution and changes: `prototypes/M1.3R_ALLIGATOR_NONCOMMERCIAL_SOURCE.md`. WAV SHA-256: `21e128bb80c68eb261468b2f9400335bfbeaad982da8505fead02fde623ec270`. Replace/review rights before a future release. No packaging, uploads or published artifacts changed.

## Playback and mute

Run the normal main scene in Godot 4.7.2. Blob._ready creates a dedicated child named BlobAudio, including when tests instantiate Blob.new(). No approved artwork or main scene nodes were changed.

One player each for contact, voice and action: maximum three simultaneous clips. Contact starts are limited to one per 100ms; voice starts one per 300ms. All levels are conservative and constant, with no random pitch/gain or gameplay RNG use. Event trace is opt-in and capped at 512 entries. No delayed sound queue.

Mute API: `game.audio_manager.muted = true` (false to unmute). In Godot Remote Inspector, select DontTouchMe/BlobAudio and enable script-variable display to inspect state; a script can set the property directly. This approved step adds no settings UI or new visual controls. Mute/focus loss/tree pause stop all players. Unmute/resume never replays consumed cues. No separate user-oriented SFX suite or second mute setting exists.

Interruption/resize stops old clips immediately and discards old reaction cues. Normal snippet endings fade over their final 25ms of simulation time. Immediate cancellation favors silence over a delayed tail; a physical-speaker de-click/listening review remains pending. Protected BOX/RUN hits emit only rate-limited own-contact sounds and do not restart their performance.

## Semantic trigger definitions

| Marker | Trigger |
| --- | --- |
| contact | Accepted visible-body/peek-eye hit, after selecting reaction; existing protected BOX/RUN keep their own contact. Direct helper animation starts never invent contact. |
| start | Actual beginning of reaction; used by WAKE voice. |
| motion | First positive animation progress; compression/prop/escape motion begins. |
| expression | Raising smoothstep envelope first reaches 0.85, derived analytically from the same pose equation. |
| held | Pose raising envelope first reaches full hold (normalized 1/7). |
| release | Pose exits hold and starts lowering/recovering (normalized 6/7). |
| squish_rebound | Analytic maximum of current damped squash: atan(PI)/(1.5*PI); recovery starts. |
| slide_stop | Horizontal destination reached (normalized 2/3). |
| offscreen | RUN enters its offscreen hold (normalized 0.23). |
| return | RUN changes from peek phase to return-to-center (normalized 0.7). |
| end | Uninterrupted JUMP returns to baseline at normalized 1, before reaction state is cleared. |
| wake_land | WAKE vertical hop returns to baseline (normalized 0.5). |
| wake_narrow | WAKE switches to narrowed eyes (normalized 0.55). |
| sleep | asleep changes false to true; once, not every sleeping frame. |

Markers follow animation progress/pose equations, not fixed timestamps. If animation equations change later, marker semantics and boundary tests must change with them. Large skipped intervals consume crossed cues and retain only the latest currently relevant cue per role; expired motion phases stay silent.

## Complete event map

| Event | Enabled | Role | Trigger | Stop with phase |
| --- | --- | --- | --- | --- |
| `blink.contact` | Yes | contact | contact | snippet cap |
| `side_eye.contact` | Yes | contact | contact | snippet cap |
| `squish.contact` | Yes | contact | contact | snippet cap |
| `irritated.contact` | Yes | contact | contact | snippet cap |
| `dont.contact` | Yes | contact | contact | snippet cap |
| `seriously.contact` | Yes | contact | contact | snippet cap |
| `slide.contact` | Yes | contact | contact | snippet cap |
| `jump.contact` | Yes | contact | contact | snippet cap |
| `shake.contact` | Yes | contact | contact | snippet cap |
| `flatten.contact` | Yes | contact | contact | snippet cap |
| `turn.contact` | Yes | contact | contact | snippet cap |
| `stop.contact` | Yes | contact | contact | snippet cap |
| `sign.contact` | Yes | contact | contact | snippet cap |
| `box.contact` | Yes | contact | contact | snippet cap |
| `run.contact` | Yes | contact | contact | snippet cap |
| `wake.contact` | Yes | contact | contact | snippet cap |
| `irritated.voice` | Yes | voice | expression | snippet cap |
| `dont.voice` | Yes | voice | expression | snippet cap |
| `shake.voice` | Yes | voice | motion | snippet cap |
| `stop.voice` | Yes | voice | expression | snippet cap |
| `wake.voice` | Yes | voice | start | snippet cap |
| `side_eye.voice` | No (optional) | voice | expression | snippet cap |
| `squish.voice` | No (optional) | voice | motion | snippet cap |
| `squish.rebound` | No (optional) | action | squish_rebound | snippet cap |
| `seriously.voice` | No (optional) | voice | expression | snippet cap |
| `slide.move` | Yes | action | motion | slide_stop |
| `jump.voice` | No (optional) | voice | motion | snippet cap |
| `jump.land` | Yes | action | end | snippet cap |
| `flatten.compress` | No (optional) | action | motion | held |
| `flatten.release` | No (optional) | action | release | snippet cap |
| `turn.voice` | No (optional) | voice | expression | snippet cap |
| `sign.raise` | Yes | action | motion | held |
| `sign.settle` | No (optional) | action | held | snippet cap |
| `sign.lower` | No (optional) | action | release | snippet cap |
| `box.raise` | Yes | action | motion | held |
| `box.lower` | Yes | action | release | snippet cap |
| `box.voice` | No (optional) | voice | expression | snippet cap |
| `run.depart` | Yes | action | motion | offscreen |
| `run.voice` | No (optional) | voice | motion | snippet cap |
| `run.return` | No (optional) | action | return | snippet cap |
| `wake.land` | No (optional) | action | wake_land | snippet cap |
| `wake.grumble` | No (optional) | voice | wake_narrow | snippet cap |
| `sleep.enter` | Yes | voice | sleep | snippet cap |

Total: 43 independently named events; 28 enabled, 15 optional disabled.

Deliberately silent: misses/background, blocked cardboard/flaps, natural blink/gaze/breathing, sleeping idle, bubble UI, intro fade, launch/resume and resize. No sounds for hypothetical trust/petting/counters.

## Validation and limits

- Godot 4.7.2 audio suite: **36,658 checks, zero failures**; all 16 reactions and all 42 reaction cue IDs exercised (optional entries enabled only for tests), plus sleep transition. Marker boundary/repeat, interrupt/resize, protected contact, cooldown, cap, mute/focus/pause and large-step checks.
- Saved exact pre-change controller compared against the new controller over 3,600 seeded frames: hit acceptance, annoyance, reaction, sleep/timers, body position/scale, gaze/eyes and RNG state agree. Snapshot lives in ignored `builds/audio-playback-baseline/blob.gd`; future runs without it explicitly report this optional comparison skipped.
- Existing behavior suite: **320,270 checks, zero failures**. Existing release suite: **237,076 checks, zero failures**.
- Actual Windows WASAPI mixer probe captured 8,704 nonzero output frames, peak 0.048226, and 7,680 muted frames with zero peak. It exercises real audio mixing without saving a new audio file. Audio suite with WASAPI and cleanup drain exits cleanly.
- Fast Dummy-driver tests and immediate-exit legacy release tests can report pending AudioStreamPlaybackWAV/resource cleanup at exit; the release suite still does so (8 playback objects in the last run). The audio suite drains the mixer before quit and has no warning. This is documented rather than claimed clean for every legacy test.
- Initial editor import logged sandbox user-directory warnings; test runs use workspace-local APPDATA and absolute log paths. Audio imports and all scripts load successfully.
- No subjective speaker/headphone quality pass, physical touch-device playback, browser autoplay/export, or rendered frame-by-frame animation/audio review is claimed. Event timing, audio-resource/player state and actual Windows mixed output were verified.
- No new sound generation or sound-file edits; existing alligator hash unchanged. Other local work, foundation/MSIX/release branches and visuals preserved.

Run `Godot --headless --audio-driver WASAPI --path . --script tests/audio.gd` for audio regression tests. On restricted Windows environments, set APPDATA to an ignored writable build folder and supply an absolute --log-file path. Running tests plays the placeholder briefly when a real audio driver is selected.

## Files created or modified by this implementation

| File | Change |
| --- | --- |
| scripts/audio_manager.gd | New dedicated playback/cancellation/phase-routing controller. |
| audio/blob_events.json | New centralized 43-event map: 28 enabled, 15 optional disabled. |
| scripts/blob.gd | Added manager creation and lifecycle/contact/advance notifications; existing pose/selection math retained. |
| tests/audio.gd | New event/player/transition regression suite and optional pre-change invariance audit. |
| audio/README.md | This event-by-event report and replacement/validation instructions. |
| plans/audio-playback-placeholder.md | Marked explicit owner approval, implementation and validation status. |
| docs/INTERNAL_DEVELOPER_JOURNAL.md | Appended this scoped implementation, reasoning and test evidence. |

Godot also generated script UID/audio import metadata while importing existing WAVs. These are resource metadata, not newly generated sounds. Existing prototype WAV bytes were not modified. The baseline controller and mixer probe are ignored local test evidence under builds/audio-playback-baseline/, not gameplay files. No main.tscn/project.godot/visual asset/export preset changes.

## Dedicated GitHub branch validation

Branch: `feature/audio-playback-placeholder`, based directly on main 4f2c40d. Only audio-specific changes are included. The sound-opportunity reference is copied from documentation commit b261c0b with trailing Markdown whitespace normalized; no foundation/documentation/MSIX/aesthetic/release branch was merged.

From this independently populated worktree with no previous .godot cache: Godot 4.7.2 imported the committed alligator WAV and loaded all scripts; the normal main scene ran 180 rendered frames with the NVIDIA/OpenGL Compatibility renderer and exited 0. The audio suite passed **381 checks** without any ignored baseline snapshot; the optional historical comparison was explicitly skipped. Behavior passed **320,270**, release passed **237,076**. Legacy release shutdown again logged pending audio playback cleanup (7 objects), while all assertions passed. Editor import logged an environment safe-save warning and missing Android build-tools; neither prevented Windows project import or scene startup. No subjective listening/device certification claim.

After creating the optional pre-audio baseline from main 4f2c40d, the extended audio suite passed **36,658 checks** including seeded gameplay/RNG invariance. The optional comparison can be reproduced by saving `git show 4f2c40d:scripts/blob.gd` as `builds/audio-playback-baseline/blob.gd` before running tests/audio.gd; it is test evidence only, not required to open/play the game. Godot-generated unrelated icon import metadata is not included in this review branch. Original dirty checkout files remain preserved in place.
