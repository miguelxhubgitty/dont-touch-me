# Audio source shortlist — Freesound and ZapSplat

This is research for the owner's own audition and future substitutions. The 2026-11-17 playable preview PR already has a real cat, dog whimper, and licensed robot/servo candidate. **These linked originals have not been downloaded or added to the branch.**

## Freesound: preferred replacements (CC0 1.0)
- [Kitten Meowing.wav — lolamadeus](https://freesound.org/people/lolamadeus/sounds/196251/) — uploader identifies a kitten 6–7 weeks old; 8.616s stereo WAV. Use a short meow excerpt.
- [Puppy (8) — johnnypanic](https://freesound.org/people/johnnypanic/sounds/728029/) — genuine puppy whines, 1.446s WAV.
- [Synth Voice Hello — Fupicat](https://freesound.org/people/Fupicat/sounds/538153/) — pre-existing cute robotic vocal effect, 0.904s WAV. Not WALL-E audio.
- [Sad Synth — Fupicat](https://freesound.org/people/Fupicat/sounds/538150/) — another CC0 robotic vocalization.
- [Complete — Fupicat](https://freesound.org/people/Fupicat/sounds/538145/) — pre-existing robotic voice texture.

A logged-in Freesound account downloads originals. The user's login does not automatically give ChatGPT access to those private browser sessions; no credentials or passwords should be copied into this repo.

## ZapSplat alternatives (check license per sound)
- [Small cute robot beeping vocalisation](https://www.zapsplat.com/music/small-cute-robot-beeping-vocalisation/) — **Standard License**, usually free tier MP3 with ZapSplat attribution.
- [Multiple puppies whining](https://www.zapsplat.com/music/multiple-puppies-whining/) — **Standard License**, usually free tier MP3 with attribution.
- [Cat, kitten, meow 1](https://www.zapsplat.com/music/cat-kitten-meow-1/) — verify license on downloaded item; do not assume CC0.
- [Cardboard box flap, movement, open 1](https://www.zapsplat.com/music/cardboard-box-flap-movement-open-1/) — **Standard License**, potentially useful for BOX.
- [Closing cardboard box](https://www.zapsplat.com/music/closing-cardboard-box/) — specifically marked **CC0 1.0** and suited to BOX lower/close.
- [Sci-fi robot, small cute beep, chirp](https://www.zapsplat.com/music/sci-fi-robot-small-cute-beep-chirp-version-1/) — verify license before using.

ZapSplat's free account terms require attribution for **Standard License** downloads; a sound explicitly labeled CC0 is different. Do not silently strip or omit credits. Free-tier MP3 downloads are generally available after login; original WAV may require Gold or a separate purchase.

## Replacement process
1. Audition clips on the logged-in source site. Download only sounds with commercial-use rights, saving the original downloaded file.
2. For each, record page URL, license, creator, filename and SHA-256. Trim/convert a new WAV/OGG to a short effect, preserving the original in a local source archive.
3. Place your chosen clip under `audio/voice/` (or `audio/candidate_sfx/`) and change only the matching `stream` paths in `audio/blob_events.json`.
4. Listen in Godot, verify all triggers and noncommercial-artifact exclusion, then review in a separate PR. No Codex handoff has been initiated.
