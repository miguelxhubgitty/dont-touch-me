# Sound design v3 — updated listening review

Owner feedback: the prior BOX and SIGN candidates sounded too static-heavy. This pass removes the scratchy treble and separates their characters:

- `sign_raise_air_swing_v3.wav` — smooth airy whoosh of a sign swinging up, 0.400 s
- `sign_lower_air_swing_v3.wav` — a softer whoosh on the return, 0.370 s
- `box_raise_soft_cardboard_v3.wav` — low-mid board friction, folding and dull pops, 0.410 s
- `box_lower_soft_cardboard_v3.wav` — rounded friction and soft hollow closing thump, 0.430 s

Original synthetic source (NumPy, SciPy and soundfile): `audio/candidate_pack/generate_audio_polish_v3.py`.

From repository root:
```sh
python audio/candidate_pack/generate_audio_polish_v3.py
```
The script writes to `audio/candidate_pack/generated_v3/character`. Copy the approved WAV assets into `audio/candidate_sfx/character/` and map their paths in `audio/blob_events.json` only **after** owner listening approval. A six-file v3 review ZIP (4 new effects, 2 previous missed-click options) was provided separately in the conversation.

## Codex later integration
- Preferred **v3** sign and box sounds override prior v2 sign/box recommendations. Map sign.raise, sign.lower, box.raise and box.lower as applicable.
- New clips run ~0.37–0.43s; the current `max_seconds: 0.3` would truncate them. If approved, adjust to about 0.45s where applicable.
- The two v2 missed-click candidates remain available pending owner's selection. Current miss event cap `0.145` also needs update when mapping the chosen sample.
- Keep sounds and code in a single **audio-only** feature PR. No annoyance system, reaction selection, idle animations, frozen Alpha, or release changes.
- Audio-only spam-click attenuation design remains: full through clicks 1–4, progressively quieter on 5–9, reset after 1.8 seconds idle; do not touch annoyance calculations.
- Do not merge or ship until owner approves sound takes and Godot tests pass.
