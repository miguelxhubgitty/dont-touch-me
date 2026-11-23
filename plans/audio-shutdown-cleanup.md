# Audio shutdown cleanup in tests

Status: owner-approved (2026-11-23), test-only. Implemented on `fix/audio-test-shutdown`, draft PR, awaiting review. Reuses the diagnosis, helper and regression probe from draft PR #10 (`fix/audio-shutdown-cleanup`, 2026-11-04). That PR is 140 commits behind `main` and is left untouched.

## Observed behavior

Fourteen suites exited 0 but printed Godot's exit report, for example `WARNING: 55 ObjectDB instances were leaked at exit` and `ERROR: 9 resources still in use at exit`:

- behavior, release, animation_audio_cues, audio_click_attenuation;
- audio_interruption_fades, audio_variation, audio_voice_timing, audio_volume_balance;
- annoyance_stage_1, adobe_next_reactions, adobe_wake, jump_unbounded;
- animation_polish and audio_volume_controls (intermittent).

`--verbose` listed only `AudioStreamPlayback{WAV,OggVorbis,MP3}`, `OggPacketSequencePlayback` and the streams they hold.

## Cause

Godot 4.7.2 frees a stopped playback in two steps. The audio thread drops it on its next mix, then the main loop's `AudioServer` update frees it. The suites quit straight after freeing the game, so playbacks were still alive at exit.

This is not an ongoing leak. In temporary probe copies that kept running frames after the free, every observed playback retired:
- behavior: 224 playbacks in 11 frames / 66 ms;
- release: 1,765 in 9 frames / 71 ms;
- audio_variation: 18 in 4 frames / 25 ms.

The existing `await create_timer(0.3).timeout` waits did not help. In audio_variation all 18 playbacks were still alive after the timer, because startup time counts toward a headless run's first frame delta.

## Change

`tests/audio_test_cleanup.gd` (test-only):

```
attach(tree):                     # first line of run()
    on every node added: if it has event_played (an audio manager)
        remember it weakly
        on event_played: weakly record each player's and fade player's current playback

drain(tree, timeout = 2000 ms) -> bool:
    drop retired references; return true when none remain (no frame spent if empty)
    otherwise process a frame; return false once the deadline passes

finish(tree, exit_code):          # replaces the suite's final quit()
    stop_all() on watched managers still alive
    if not drain: print an error with the pending count, exit_code = 1
    quit(exit_code)
```

- **Suites:** the 14 suites above, plus `audio` and `audio_mute`, add the attach line and end with `finish`. The six fixed 0.3 s waits are removed (audio, audio_mute, audio_variation, audio_interruption_fades, audio_voice_timing, audio_volume_balance), along with `audio`'s two extra frame waits. No assertion changes.
- **`tests/audio_shutdown.gd`** (fast group) checks:
  - empty teardown spends no frame;
  - the tree hook observes a real game's playback;
  - freed-game and just-stopped playbacks drain;
  - a deliberately retained playback makes `drain()` time out with exactly that playback pending.
  - `-- --finish-timeout` runs `finish()` on the retained playback and must print the error and exit 1.
- **`tests/run.ps1`** now fails when Godot prints `^WARNING: \d+ ObjectDB instances were leaked at exit` or `^ERROR: \d+ resources? still in use at exit`. Previously it passed that pair with a warning. Other warnings are unaffected and other errors still fail as before.

## Edge cases

- **Timeout limit:** 2 s is a failure bound, not a delay. The measured worst case is 71 ms.
- **Coverage limit:** playback started outside the audio manager is not observed. No suite does that today.
- **Normal game close:** the game itself is unchanged. Closing the window mid-sound is tracked in [visible-audio-shutdown.md](visible-audio-shutdown.md).

## Acceptance criteria

- All affected suites keep their assertion counts and pass three runs with no exit-time leak report.
- The full runner passes with the stricter leak check.
- The regression's timeout mode fails visibly.
- Real audio output (CoreAudio) runs of the audio suites are also clean.

## Verification

See the PR and the journal entry "Audio shutdown cleanup in tests".
