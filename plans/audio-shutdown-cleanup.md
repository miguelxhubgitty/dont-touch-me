# Audio shutdown cleanup diagnosis

Status: owner approved the test teardown proposal. Implemented and validated on the fix branch. Branch: fix/audio-shutdown-cleanup, based on protected main at 7a76e73e5ff7c4fd72bc70e603e5409d30800157. Windows, Godot 4.7.2 stable official ed1daf0bf, Compatibility renderer. The evidence below was collected before changing the test teardown.

## Reproduction and evidence

Import with Godot 4.7.2, then run the existing tests with --headless --verbose --audio-driver Dummy --script tests/behavior.gd. Repeat with tests/release.gd and with WASAPI for comparison. Capture stderr and exit code. Logs from this worktree are in ignored test-output/. The driver, frame pacing, and timing relative to the mixer affect the counts.

| Run | Exit | Assertions / state | WAV playback objects | Total leaked objects | Resources still in use |
| --- | ---: | --- | ---: | ---: | ---: |
| Existing behavior, headless Dummy | 0 | 320,270 passed | 48 | 49 | 1 |
| Existing release, headless Dummy | 0 | 237,076 passed | 56 | 57 | 1 |
| Existing audio, headless Dummy | 0 | 381 passed | 0 | 0 | 0 |
| Existing behavior, release, audio, headless WASAPI | 0 each | Same assertion counts | 0 | 0 | 0 |
| Plain AudioStreamPlayer, active at quit, both drivers | 0 each | Playback submitted to mixer | 1 each | 2 each | 1 each |
| Plain AudioStreamPlayer, immediate stop and quit, both drivers | 0 each | playing=false, weak ref alive | 1 each | 2 each | 1 each |
| Plain player, stop/free and await reference retirement, both drivers | 0 each | Retired after 7 frames/42 ms Dummy and 4 frames/21 ms WASAPI | 0 | 0 | 0 |
| Visible main scene at 60 FPS, WASAPI, muted | 0 | No cue started | 0 | 0 | 0 |
| Visible main scene at 60 FPS, WASAPI, sound on but idle | 0 | No cue started | 0 | 0 | 0 |
| Visible main scene at 60 FPS, WASAPI, active cue | 0 | playing=true at quit | 1 | 2 | 1 |
| Visible main scene at 60 FPS, WASAPI, stop just before quit | 0 | playing=false, weak ref alive at stop | 0 | 0 | 0 |

The visible runs used the actual game scene, a scripted cue, and an ordinary SceneTree.quit() at normal frame pacing. They did not simulate clicking the OS close button or use force termination. The same WAV was used in the plain-player control without instantiating the game or its audio manager.

Exact lines from the Dummy behavior run:

    WARNING: 49 ObjectDB instances were leaked at exit (run with `--verbose` for details).
    Leaked instance: AudioStreamWAV:9223372064218416599 - Reference count: 48
    Leaked instance: AudioStreamPlaybackWAV:9223372067607414234 - Reference count: 1
    Resource still in use: res://audio/prototypes/M1.3R_baby_alligator_call_study_NONCOMMERCIAL_CC-BY-NC-3.0.wav (AudioStreamWAV)
    ERROR: 1 resources still in use at exit.

The release run reported 57 total and the same resource warning. The windowed active run reported 2 total, one playback and its WAV resource. The object IDs are per process.

## Diagnosis

This is an engine playback retirement race at process exit. The existing fast suites queue scene removal and immediately quit. The manager already stops its players on tree exit. A plain player still reproduces the warning, so the manager is unnecessary to trigger it. The plain-player weak reference stays live after stop and node free, then clears while the mixer and main loop continue. The WAV resource is retained by outstanding playback handles. The tests do not show an ongoing leak after retirement. A clean single WASAPI run does not establish that the driver is immune.

Godot 4.7.2 AudioServer::stop_playback_stream marks the playback for deletion. The mix step removes it, with destruction deferred to the main thread. AudioServer::update performs the deferred cleanup. This explains why a stopped player or freed node is insufficient evidence that its playback handle has retired. Source: https://github.com/godotengine/godot/blob/4.7.2-stable/servers/audio/audio_server.cpp#L1289 and https://github.com/godotengine/godot/blob/4.7.2-stable/servers/audio/audio_server.cpp#L1630

## Condition-based teardown experiment

Diagnostic copies of behavior.gd and release.gd observed unique playback handles with WeakRef after event_played. They stopped audio, freed the scene and continued processing only while handles remained. A two-second monotonic deadline was a failure bound. All original assertions passed. No shutdown warning in any of the four runs.

| Suite / driver | Tracked | Pending after scene free | Pending at quit | Wait observed | Exit |
| --- | ---: | ---: | ---: | ---: | ---: |
| Behavior / Dummy | 197 | 19 | 0 | 96 ms | 0 |
| Release / Dummy | 1,533 | 1,533 | 0 | 40 ms | 0 |
| Behavior / WASAPI | 197 | 12 | 0 | 14 ms | 0 |
| Release / WASAPI | 1,533 | 1,533 | 0 | 19 ms | 0 |

## Proposed smallest fix

Use a shared test-only cleanup helper for suites that start playback. Keep production playback and window-close handling as-is for this task. Replace the fixed waits in the audio-focused test suites where the helper can track their playback as well. The visible active-close reproduction is separate evidence for an upstream engine report or a separately approved application shutdown change.

    on each played event:
        capture weak references to each available player playback
        deduplicate by object ID, retaining no strong references
        drop retired handles as appropriate

    at teardown:
        stop active players
        free test scene
        process frames while any observed playback handle is alive
        if a bounded monotonic deadline expires:
            print remaining count and fail the suite
        otherwise quit with original assertion result

Test the active and just-stopped cases using a real player and verify that the helper waits only when needed. Test muted and never-played cases for immediate completion. Run existing suites under Dummy and WASAPI and check the verbose logs for leaked playback, resource errors, assertion failures, and nonzero exits. Keep the plain-player probe as a reproducible control. Test a timeout path with a deliberately retained reference so a failure stays visible. No fixed sleep and no warning suppression.

Scratch probes, source excerpt and raw logs are under ignored test-output/. The approved regression and teardown changes are now in tests/.

## Implementation and verification

The shared test helper observes unique playback objects by weak reference. Suites stop and free their scenes before awaiting retirement. The helper returns immediately when its set is empty, otherwise it processes frames until the references clear or a two-second monotonic deadline expires. A timeout reports the remaining count and makes the suite fail. The two previous 300 ms sleeps were removed.

Godot 4.7.2 on Windows, headless with verbose output. Each of Dummy and WASAPI passed behavior (320,270 checks), audio (381 checks), release (237,076 checks), mute, and the new shutdown regression, all with exit 0 and no leaked-playback or retained-resource warnings. The optional saved pre-audio baseline was absent. The mute suite intentionally triggers one failed-save warning. The deliberate retained-reference run reports one pending playback and exits 1 under both drivers, after releasing the reference and draining it.

The visible application case is tracked separately in plans/visible-audio-shutdown.md.
