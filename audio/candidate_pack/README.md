# Audio starter pack — review-only, 2026-11-17

**Status: candidate package, not approved or installed.** Existing game and frozen Alpha are unchanged.

The project owner asked for five independently mixable categories:
1. Character Voice — real kitten and puppy recordings plus existing, licensed cute robotic vocal sounds; do not categorize by emotion.
2. User SFX — accepted tap, background miss, initial game startup.
3. Character SFX — sign, box, jump/landing, slide, running and similar timed physical actions.
4. Environment — reserved, optional outdoor/nature recordings; intentionally silent initially.
5. Music — reserved, optional backing music; intentionally silent initially.

A separate downloadable artifact `DontTouchMe_Audio_Starter_2026-11-17.zip` contains **14 generated candidate WAVs** (mono PCM 16-bit, 22,050 Hz) under `audio/candidate_sfx/`, an 8.3-second audition reel, sound-file hashes, source register, event map and handoff. It must be transferred to the Codex workspace separately; the WAVs are deliberately **not** in this PR.

The generated SFX are **first-pass synthetic sounds made for this project**, not licensed field recordings. Their format and signal peaks were validated, but they have not been listened to in-game. The kitten/puppy/robot originals have **not** been downloaded; verified CC0 source pages are in `CC0_SOURCES.md`.

Current main has 43 reaction/audio events (16 contact, 14 voice, 13 action), three AudioStreamPlayers (contact/voice/action) and a sound mute button; **all 43 runtime event paths currently refer to the same noncommercial alligator study**, which is not cleared for commercial releases. Nothing in this draft changes the live event JSON.

`event_assignments.json` is a candidate configuration for review, **not** a drop-in replacement for `audio/blob_events.json`. Three extra user SFX events are proposed but do not exist as live Godot triggers yet. Ensure exactly one accepted-tap sound, without duplicate reaction contact events.

Create fresh feature PRs for runtime implementation and testing. Do not merge into `main`, remove the original Alpha, change store artifacts, publish candidate sound, or claim release clearance without separate owner approval.
