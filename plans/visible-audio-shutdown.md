# Visible game quit during active audio

Status: open engine-level investigation. Separate from the approved automated-test teardown fix.

On Godot 4.7.2 official ed1daf0bf, Windows WASAPI, a visible game scene paced at 60 FPS exited with code 0 when a scripted SceneTree.quit() occurred during an active alligator cue. The verbose log reported two leaked objects, one AudioStreamPlaybackWAV and the WAV resource it retained. Muted, idle and just-stopped windowed runs in that matrix were clean. A plain AudioStreamPlayer reproduced the same retained objects when quitting immediately after playback start or stop on both Dummy and WASAPI.

Reproduce with the diagnostic scenario described in plans/audio-shutdown-cleanup.md. Start a cue, wait for playback to reach the mixer, then quit while it is playing. Compare with a muted run. The original visible probe used scripted quit. OS window-close behavior and other platforms still need independent checks.

A future investigation should check engine versions and decide whether to file a minimal upstream reproduction or propose app-level shutdown coordination. The test helper operates only in test scripts. This case remains open.
