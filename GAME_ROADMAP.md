# Don't Touch Me — Gameplay Roadmap

Use [CURRENT_STATE.md](CURRENT_STATE.md) for implemented behavior, the review queue and public release status. Follow [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md) for design approval, topic branches and integration.

## Next milestone

After owner review and merge of the development tooling, plan and verify each visual change independently.

1. **Stretch idle:** a slow upward stretch, squint, brief hold and return in about 1.8 seconds.
2. **Humming and bobbing idle:** gentle rhythmic bobbing and subtle sway, with relaxed eyes and timing that can later support a melody.
3. **Recoil:** a roughly 0.9-second startled response in the lowest annoyance tier, with compression toward the touch, a jolt away, widened eyes and return.
4. **Puffer-huff:** defensive inflation with attached visual spikes. The second annoyance tier is the starting proposal. Confirm the spike touch policy before implementation.

Keep both authored and procedural visuals, existing audio, reaction timing and interruption rules, and the 18-second sleep threshold. The new idles should play occasionally during inactivity and use existing timing. Approve detailed pose/trigger plans before implementation. Review the architecture after this animation milestone.

## Deferred ideas

- Stretch vocalization and an original humming melody. Recognizable-song interpretations are deferred.
- Further sound polish, ambience and music. The audio buses and volume controls already exist, but future sound content needs separate review. See [PR #20](https://github.com/miguelxhubgitty/dont-touch-me/pull/20) for its independent candidate work.
- Changes to annoyance, emotional stages, trust or petting, and auras. These are separate designs.
- Interaction statistics, clothing, furniture and customization. Optional cosmetic monetization would require separate owner authorization and store review.

Early plans are preserved in Git and in the [internal journal](docs/INTERNAL_DEVELOPER_JOURNAL.md). This roadmap applies to development. The frozen v0.1.0-alpha stays audio-free.
