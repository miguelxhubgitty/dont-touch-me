# Pull / audition PR #18 — NOT MERGED

Branch: `feature/audio-starter-pack-handoff-20261117`

1. Ensure your local checkout has no unsaved work: `git status --short`.
2. `git fetch origin`.
3. First checkout: `git switch --track origin/feature/audio-starter-pack-handoff-20261117`. If the branch exists locally, `git switch feature/audio-starter-pack-handoff-20261117` then `git pull --ff-only`.
4. Open in Godot **4.7.2** and allow all imports; press F5.
5. Sound is normally muted by default: click the in-game **Sound Off** button to turn it on.
6. Trigger the different reactions to hear four different **real kitten** clips, four **real puppy** clips, existing Fupicat + servo robot-like placeholders, and generated movement/UI sounds. Deliberately silent events stay silent. Background miss and successful poke sound distinct.
7. Run existing Godot regression tests, then listen with speakers/headphones. Report import errors, playback gaps, timing errors and sound preferences before any merge.

**Do not merge or ship**: this is an owner review build; exact selected Puppy (8), Synth Voice Hello and ZapSplat originals still need to be downloaded with a logged-in website account. These are sound candidates and have not been manually auditioned or validated in-game here.
