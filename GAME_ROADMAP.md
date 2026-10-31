# Don't Touch Me — Gameplay Roadmap

Planning document; proposals are not commitments to the current Public Alpha. Gameplay changes belong on `main`; release typography and final artwork are applied later through `BRANCH_WORKFLOW.md`.

## Audio — future update (currently absent)

**Goal:** Give the blob a recognizable sonic personality without overwhelming a simple, quiet interaction game.

- **Input / interaction SFX:** taps and clicks, successful blob touches, distinct UI/selection sounds if controls are added later.
- **Blob vocalizations:** nonverbal squeaks, grumbles, surprised noises, annoyed protests, sleepy sounds, and happy/trusting responses if that system is implemented.
- **Action / reaction SFX:** squishes, hops, hiding/box movement, sign appearing, dramatic exits, sleep and wake transitions; map individual effects to animations and avoid noisy repetition.
- **Ambience:** subtle room/background environmental texture that suits the scene; allow quiet moments.
- **Background music:** unobtrusive looping theme(s), with options to fade or mute during particular reactions.
- **Mixing / accessibility:** separate master, music, ambience, voice, and SFX volume controls; mute option; consistent levels; no sudden spikes; respect app focus/pause.
- **Implementation:** use Godot audio buses, event-driven sounds, and reusable audio definitions; prefer small, optimized, properly licensed/original clips; verify looping, browser autoplay restrictions, and Android/Desktop behavior.
- **Release discipline:** design/test audio on `main`, keep approved aesthetics separate, validate audio and licensing before inclusion in a future release. Do not add sound retroactively to v0.1.0-alpha without creating a new release.

## Other possible future expansions

- More idle animations and reactions.
- Counters/statistics for interactions.
- Outfits, furniture, and environmental customization.
- A trust/relationship mechanic: extremely slow, respectful approaches could eventually earn the blob's trust and allow petting.
- Optional cosmetic monetization later; retain free core gameplay and determine store-compliant payments before implementation.

## Next audio design decisions

Choose whether the atmosphere is mostly quiet, ambient, or musical; define the blob's vocal style; build an event-to-sound map; select or create original/licensed assets; then implement and test incrementally. No audio assets or audio implementation have been created by this planning document.
