# Animation audio cues

Status: four source WAVs approved. Owner approved the integration pseudocode. Development base `a51490d`.

The controller already owns actual idle activation and reaction start. The audio manager already supports start markers, bus routing, click-streak attenuation, and a 35 ms interruption fade. Reuse those paths.

| Event | Approved file | Role and bus | Trigger and cap |
| --- | --- | --- | --- |
| `idle.stretch` | `01-vowel-lift.wav` | Voice / Character Voice | Idle activation, 1.80 s |
| `idle.humming` | `01-pocket-melody.wav` | Voice / Character Voice | Idle activation, 2.70 s |
| `recoil.voice` | `01-curled-eep.wav` | Voice / Character Voice | Reaction start, 0.90 s |
| `puffer_huff.action` | `01-air-valve.wav` | Action / Character SFX | Reaction start, 1.35 s |

Puffer-huff's contraction starts with the clip and its puff is embedded at sample 12,960 of the 48 kHz WAV. Start that file once at reaction activation so the accent meets the 0.27 s inflation snap. Recoil starts its file at activation, including the file's built-in anticipation. Preserve the files at 1.0× speed to retain their internal timing. Start with 0 dB event gain for the three voice cues and −3 dB for Puffer-huff, then verify perceived balance against the existing mix.

```text
when _update_special_idle actually promotes next_idle to active_idle:
    keep current scheduling and set special_idle_started as today
    if no other cue owns the voice slot:
        play_event(idle cue, click_attenuation_db())

when a special idle is interrupted outside the usual reaction start:
    if its cue still owns the voice slot:
        use the existing interruption fade for that slot
    keep current idle reset and pose handling

when begin_reaction runs:
    keep the existing 35 ms cancellation and click attenuation snapshot
    let the existing start-marker dispatcher fire Recoil or Puffer-huff once

when an animation finishes normally:
    let the existing playback cap and clip taper finish the cue

when muted, unfocused, paused, resized or exiting:
    rely on the existing playback guards and stop paths
    consume suppressed cues at their scheduled time
```

A poke that starts a reaction already cancels the previous idle voice through the existing reaction path. For other idle exits, use one event-scoped fade helper so cleanup only affects the matching idle cue. A missed tap keeps playing its own existing feedback and leaves the idle and its voice running. A busy voice slot, existing voice cooldown, mute, or loss of focus can suppress a cue. Suppressed cues stay silent for the rest of that animation. A rapid restart uses the existing bounded fade players. There is no new timer or audio player.

After approval, add only the four selected WAVs and their provenance to the development branch. Keep the eight alternatives at their current candidate paths and outside the active event map. Leave the frozen Alpha and existing cue records alone.

## Verification

- Add one focused audio suite to the standard runner. Assert each idle dispatches exactly once at actual activation, with no idle cue on selection, an ineligible start, or a repeat frame. Cover misses and accepted pokes.
- Check once-per-start dispatch for both reactions, the Puffer waveform's 0.27 s accent, and real-time audiovisual sync in a WASAPI playtest with both renderers. Check Humming against all three bobs.
- Verify event-scoped fades, no orphaned playback or duplicate cues during rapid restarts, and silent behavior on mute, pause, focus loss and resize. Confirm interrupted cues never resume on regain/unmute. Test the existing buses, voice cooldown, click-streak gain and pitch at 1.0×.
- Run focused, audio and animation checks, plus gameplay and workflow regressions. Use isolated player settings. Report manual mix and timing observations separately from automated results.

## Implementation

The four files use explicit lossless PCM import settings. The first focused run exposed Godot's compressed default, which could obscure sample-level timing. Both renderers pass the focused 116-check suite with the lossless imports. See the PR for combined regression results and the WASAPI check.
