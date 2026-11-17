# How to play this audio review branch

1. From your own clean Godot checkout: `git fetch origin` then `git switch --track origin/feature/audio-starter-pack-handoff-20261117`. If you already have the branch, `git switch feature/audio-starter-pack-handoff-20261117` and `git pull --ff-only`. **Preserve/stash your own uncommitted work first.**
2. Open project in Godot 4.7.2, let audio and other imports complete, then run `main.tscn` / F6 (or F5 for the project main scene).
3. The sound button remembers settings and defaults to `Sound Off`. Click **Sound Off** to turn it to **Sound On**. On fresh subsequent launches while enabled, you'll hear a short startup sound.
4. Click the blob for a soft contact sound and optional cat/dog/robot vocal reactions; miss the blob to hear a faint miss; trigger SIGN, BOX, SLIDE, RUN and JUMP for movement effects. High annoyance levels are needed for some reactions.
5. The generated sounds are review-only. The cat is real, the dog is real, the robot effect is licensed existing synthesis, and movement sounds are generated. The originally selected kitten, puppy and robot voice sources remain pending download.
6. Run tests with Godot 4.7.2: `godot --headless --path . --script tests/audio.gd` plus `tests/audio_mute.gd` and existing regression suites. **These tests were updated but not run in ChatGPT's environment**, because the Godot editor is not installed there.
7. Do not merge or publish until audible QA, platform checks, attribution/exclusion review and owner approval.

This is a playable candidate, not the final five-slider settings interface. Runtime creates five buses (UserSFX, CharacterVoice, CharacterSFX, Environment, Music), with Environment/Music silent for now. The existing global sound toggle still works.
