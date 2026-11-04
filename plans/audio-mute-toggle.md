# Audio mute toggle proposal

Status: owner approved implementation. Implemented and tested locally. Branch: feature/audio-mute-toggle, based on merged main e2ca928 (PR #8). A future implementation PR requires its own merge approval.

Add one quiet, high-contrast button in the top-right corner of a small HUD. Label it “Sound Off” or “Sound On” so the current state is readable without interpreting an icon. Use the development font and a rounded button with a generous tap area. Check the existing title and blob composition at narrow and wide sizes.

Keep the preference in a dedicated Godot ConfigFile at user://audio_settings.cfg, under audio/muted. Treat a missing file, missing key, invalid value, or load failure as muted. Apply the loaded setting to the existing BlobAudio manager before gameplay receives input. Keep the setting UI separate from the manager's playback and event logic.

## Pseudocode

    after BlobAudio is created:
        load settings
        muted = saved boolean if valid, otherwise true
        audio_manager.muted = muted
        initialize HUD button with manager and current label

    on mouse or keyboard button activation:
        toggle sound once

    on native touchscreen input inside button:
        consume touch press and drag before gameplay input
        track one finger until release
        on release inside button, toggle once
        cancel on release outside or focus loss

    toggle sound:
        audio_manager.muted = inverse of current value
        update button label
        save new boolean locally
        on save failure, keep current session choice and log the error

Use a GUI control that consumes pointer events in its bounds. Handle native touch explicitly because the project disables touch-to-mouse emulation. Keep the existing muted setter responsible for stopping playback. Unmute allows future eligible cues and never replays consumed cues. The button itself is silent.

## Tests to add after approval

- Load missing, corrupt, missing-key, nonboolean, and valid settings in an isolated test location. Assert first launch defaults to off and a saved choice survives a new game instance.
- Activate once with mouse and once with native screen touch through a viewport. Assert exactly one toggle per gesture, including release outside, and confirm the blob's annoyance, reaction and idle state do not change on button input.
- Start playback, mute, and assert all players stop immediately. Advance across a cue while muted, then unmute and assert that cue stays consumed and later eligible cues can play.
- Verify a save failure preserves the current session choice. Run existing audio, behavior and release suites. Inspect the button on desktop and narrow portrait layouts and check touch target placement.
