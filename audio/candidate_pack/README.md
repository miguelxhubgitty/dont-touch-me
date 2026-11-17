# Audio starter pack — PLAYABLE DRAFT (updated 2026-11-17)

The branch now **includes playable candidate WAVs and provisional real-animal and robot clips**. This replaces the earlier docs-only status. The live event JSON has been updated on this **feature branch only**. Nothing was merged to `main` or any release.

See `PLAY_THIS_BRANCH.md` to pull and play, `SOURCE_REGISTRY.md` for provenance, and `event_assignments.json` for the original 46-slot proposal (the playable implementation uses 45 slots because the successful tap reuses existing reaction contact triggers rather than duplicating them).

The 14 independently regenerated SFX are **not byte-identical** to the ZIP from the previous ChatGPT turn. The actual playable sound files are committed as `audio/candidate_sfx/` on this branch.

The attached ZIP remains useful as a separate original audition/backup, but is **not required to play the PR branch**. Cat is actual cat, dog is actual dog, robot source is an existing MIT-licensed servo effect; preferred specific Freesound kitten/puppy/robot samples still need manual login download.

**No Godot test run has occurred in this ChatGPT session; this is a first playable review build, not release-cleared.**
