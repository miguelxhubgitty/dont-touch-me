# Don't Touch Me — Gameplay Roadmap

Use [CURRENT_STATE.md](CURRENT_STATE.md) for implemented behavior, the review queue and public release status. Follow [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md) for design approval, topic branches and integration.

## Animation milestone

1. **[Stretch](plans/stretch-idle.md)** — An occasional 1.8-second upward stretch, squint, hold and return.
2. **[Humming](plans/humming-idle.md)** — Three 0.9-second bobs with subtle sway and relaxed eyes.
3. **[Recoil](plans/recoil-reaction.md)** — A 0.9-second startled reaction in the lowest annoyance tier.
4. **[Puffer-huff](plans/puffer-huff-reaction.md)** — A 1.35-second defensive inflation in the second tier, with a touchable body and attached visual-only spikes.

The development game supports each animation in both renderers. The idles use the shared inactivity scheduler and preserve the 18-second sleep threshold. The architecture review is the next milestone and requires its own scope.

## Deferred ideas

- Stretch vocalization and an original humming melody. Recognizable-song interpretations are deferred.
- Further sound polish, ambience and music. The audio buses and volume controls already exist, but future sound content needs separate review. See [PR #20](https://github.com/miguelxhubgitty/dont-touch-me/pull/20) for its independent candidate work.
- [Annoyance Stage 1](plans/annoyance-stage-1.md) covers poke gains, rejected-touch reductions, and the gameplay streak. Changes to sleep-stage timing and inactivity decay belong to Stage 2. Emotional stages, trust or petting, and auras remain separate designs.
- Interaction statistics, clothing, furniture and customization. Optional cosmetic monetization would require separate owner authorization and store review.

Early plans are preserved in Git and in the [internal journal](docs/INTERNAL_DEVELOPER_JOURNAL.md). This roadmap applies to development. The frozen v0.1.0-alpha stays audio-free.
