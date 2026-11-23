# Closing the game while a sound plays

Status: documented engine behavior; no game change planned. First recorded in draft PR #10 (Windows, WASAPI) and re-checked on macOS on 2026-11-23.

## Observation

The real `main.tscn` was run with processing on and closed through the window's `close_requested` signal, the same path as the OS close button. Godot 4.7.2 on Intel macOS:

| Case | CoreAudio | Dummy |
|---|---|---|
| Sound Off (the default), close at frame 10 | clean | clean |
| Sound on, close during the start sound | 2 objects, 1 resource | clean (not mixed yet) |
| Sound on, close after the start sound ended | clean | clean |
| Sound on, poke, close while the reaction sound plays | 2 objects, 1 resource | 2 objects, 1 resource |

The report is always one `AudioStreamPlayback` and the sound file it holds, and the exit code is 0. Sounds that finish or are replaced during play retire normally. The report appears only for a sound still playing at the moment of exit. It matches upstream [godotengine/godot#76745](https://github.com/godotengine/godot/issues/76745).

## Decision

Leave the game unchanged. Removing the message would require holding every quit until audio drains, which adds complexity for a harmless report at process exit. iOS and Android apps are normally suspended or killed rather than quit this way. Revisit if a later Godot version changes the behavior or a leak shows up during play.
