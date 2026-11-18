# Audio polish v2 — sound-design candidates

**Status:** Sound design only; original deterministic generator committed here. No audio event remapping, gameplay code, reaction selection, or releases changed.

The files for audition were generated separately and provided to the owner as a four-WAV pack. The WAV binaries are **not committed yet**; after the owner selects a miss cue, Codex should run the generator and commit the selected WAV files together with the wiring.

## Candidate sounds

| Generated WAV | Purpose | Length |
|---|---|---|
| `user/tap_miss_tough_luck_v2.wav` | Preferred soft descending two-note “tough luck” cue | 0.265 s |
| `user/tap_miss_little_sigh_alt.wav` | Alternative sagging “wah-wah” cue | 0.295 s |
| `character/box_raise_cardboard_v2.wav` | Low rough cardboard fold, rustle, hollow pops | 0.295 s |
| `character/box_lower_cardboard_v2.wav` | Cardboard fold, scrape and muted closing thump | 0.290 s |

All original procedurally synthesized PCM WAV; no third-party samples or licensing dependencies. These are approximated textures, not authentic field recordings.

Regenerate with only the Python standard library from repository root:

```sh
python audio/candidate_pack/generate_audio_polish.py
```

Output is `audio/candidate_sfx/{user,character}/`. Existing asset names are not overwritten.

## Codex work after review

- Map **one** preferred missed-click candidate to `user.tap_miss` in `audio/blob_events.json`, and increase the current `max_seconds: 0.145` to roughly **0.275** for the preferred short version or **0.300** for the alternate.
- Map `box.raise` and `box.lower` to the new cardboard files. Keep sign events and source files untouched.
- Implement *audio-only* spam attenuation, preserving the original files, annoyance, and mute logic: clicks **1–4 0 dB; 5 −6 dB; 6 −12 dB; 7 −18 dB; 8 −24 dB; 9+ −30 dB**. Reset to 0 dB after **1.8 s without clicking**. Count all hits and misses; blocked cardboard produces no sound. Apply attenuation to click-associated contact, action, and voice cues.
- Keep the already merged **18-second sleep threshold**.
- Run Godot 4.7.2 audio/mute tests and audition; do not edit frozen PR #14 or ship anything without owner approval.

No changes to annoyance point calculations or behavior selection belong in this audio PR.
