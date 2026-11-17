# Implementation and acceptance plan for Codex

## Initial status / protection
- Start from checked-out approved `main` in a new feature branch after checking `git status`; preserve all uncommitted changes and existing branches.
- Existing `main`: new Adobe AnimationPlayer reaction integration and placeholder playback already merged.
- Historical Alpha and releases remain byte-for-byte unchanged. No store uploads.

## Assets
- Import the owner's separate artifact `DontTouchMe_Audio_Starter_2026-11-17.zip`: 14 original synthetic, **candidate** foley/UI WAVs plus a manifest and preview. Never assume the ZIP is already in the repository.
- Obtain original CC0 kitten, puppy, robot recordings from `CC0_SOURCES.md` with Freesound login or ask owner to supply originals. Do not use unlicensed/imitation material.
- Trim/normalize to consistent conservative peaks with clicks/fades checked; preserve hashes/links/license and make every sound swappable independently through paths in a central map.
- Until originals exist, keep voice events silent/disabled. Do not ship or re-map the old CC BY-NC alligator, including optional events.

## Proposed functional changes
- Use five separate Godot buses with Master and per-bus volume, mute and persisted user settings; keep environment and music empty/silent for now.
- On successful body/peek tap, emit one User SFX hit, independent of character voice/action. The 16 legacy `*.contact` slots should not cause duplicate tap sounds; decide to repurpose them or disable them.
- A missed background tap produces a user-side miss SFX, not a blob vocalization or a touch. Clarify BOX blocked-flap semantics separately.
- Emit one user startup SFX when game starts, not each time focus resumes.
- Character voice: select kitten/puppy/robot clips without emotional labels. Keep quiet interactions possible and avoid chattering every tap.
- Action effects must track actual Adobe/procedural visual phases: sign show/settle/lower, box show/lower, slide, jump landing and RUN departure/return. The pack also includes an optional jump takeoff clip.
- Stop interrupted movement, mute, focus-loss, and pause audio promptly. Rate limit contacts to avoid excessive overlap.

## Tests
- Verify every one of 16 reactions (15 + WAKE), audio/mute/settings behavior, accepted and missed taps, BOX/RUN protection, sleep/wake, fast tapping, interrupted JUMP landing, window resize, and procedural fallback.
- Test physical listening, timing and mix; Windows first, Web/Android when possible.
- Run all existing Godot suites and add regression tests for the new user events/bus routing/settings.
- Search all release-bound files/assets and event maps for the alligator file, confirm no CC BY-NC file is bundled into any commercial build.
- Open draft PR with manual listening checklist and test results. Owner reviews/approves separately. Do not auto-merge.

See `event_assignments.json` for the complete proposal.
