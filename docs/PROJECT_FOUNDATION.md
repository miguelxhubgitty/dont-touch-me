# Don't Touch Me — Foundational Project Context & Decision History

**Handoff date:** 2026-11-02. **Purpose:** let a new ChatGPT/Codex conversation reconstruct this game's premise, design decisions, development path, published-versus-planned state, and the correct next small task without re-reading the original chat.

> This is an **owner-discussion history and continuity guide**, not an automatic authorization to code, modify public listings or advance a milestone. For facts that can change, re-check the current source, branches, plans, test outputs and distribution receipts. Some decisions below are newer than `main`'s older `GAME_ROADMAP.md` and were discussed in a draft roadmap PR; do not mistake an unmerged plan for current implementation.

## Permanent branch isolation — NEVER merge into `main`

- **This document and its documentation branch are permanently separate from `main`.** Do not open or merge a pull request targeting `main` for this foundation or its related context-only updates.
- Maintain and revise this context **only on the dedicated documentation branch** (`docs/foundation-context-2026-11-02`), or a distinct documentation-only successor branch explicitly approved by the owner.
- Never cherry-pick, squash, rebase, copy, or otherwise transfer these documentation-branch commits or files into `main` as a workaround. Never merge gameplay/release/website changes into this reference branch.
- When a new ChatGPT/Codex session needs history, **read this branch explicitly**. Do not infer that these files exist on `main`.
- Updating this reference does not authorize implementation, releases, deployments, or edits to `main`. Changes to production code or its own operational documents require separate explicit instructions.
- This is a **project policy recorded in text**, not an automatic GitHub branch protection rule. Keeping the branches separate still depends on not merging them.

## Read order for a new session

1. **This document** — concept, scope, owner intent, choices, proposed next steps.
2. `AGENTS.md` — binding design-first approval and journal policy. `BRANCH_WORKFLOW.md` — binding basic-font development, release/aesthetic isolation.
3. `README.md`, `scripts/blob.gd`, `main.tscn`, `project.godot` — implemented game. `docs/ALPHA_BEHAVIOR_SPEC.md`, `docs/ALPHA_SOURCE_AUDIT.md`, `docs/INTERNAL_DEVELOPER_JOURNAL.md` — detailed audited explanation.
4. `GAME_ROADMAP.md`, `plans/`, any open PR proposing to change them — **proposals**; use current branch and review state to determine authority. If an older roadmap contradicts a more recent owner statement in this document, reconcile the roadmap via a scoped, owner-reviewed planning update rather than treating both as approved code tasks.
5. `release/README.md`, `release/catalog/game.json`, `release/distribution/platforms.json`, release-specific receipts and approvals — publishing records. Check actual file existence and platform state.
6. Company/website context lives in private `miguelxhubgitty/wandiel/docs/PROJECT_FOUNDATION.md`; business records in private `miguelxhubgitty/wandiel-otto-llc`. **Never put private company material into this public repository.**

## Original premise, chosen scope, and philosophy

- Inspired by the physical **Useless Box/Useless Machine**, but the owner selected the **character-based** version: a creature actively resists being touched, rather than a literal switch simulation.
- Name: **Don't Touch Me**. Basic loop: open, see a black rounded blob with expressive white eyes, poke it, discover a response; repeated pokes escalate resistance; leaving it alone allows relaxation and sleep.
- **Minimalist interactive comedy/toy**, not initially a score-driven or level-based game. The entertainment is reactions, personality, discovery, absurd escalation and timing.
- A simple black blob was selected primarily for **ease of implementation and animation** in Godot, portability, and a tiny polished first release. Warm off-white background, portrait canvas, procedural art, sparse UI.
- The key personality contrast is **adorable / contented / possibly affectionate one moment, defensive / hostile the next**. The owner used a *cat* as an emotional analogy, **not** a command to give the blob literal cat behaviors or exclusively make it a companion. It may be both comic adversary and potential friend; don't force either interpretation.
- **Simplicity and efficiency take precedence** over elaborate architecture, many disconnected reactions, gratuitous features and constant asset regeneration. Strong continuous expressions, independence and good timing matter more than increasing the reaction count.
- Early scope was free, playable offline, with no user accounts, servers, ads, in-app purchases, gameplay currency, paid dependencies or online features. Keep those constraints unless the owner explicitly changes them.

## Technical foundation — existing Alpha, not future promises

| Aspect | Repository-documented implementation |
| --- | --- |
| Engine | Godot **4.7.2 stable**, GDScript; one main scene and principal blob controller (`main.tscn`, `scripts/blob.gd`) |
| Rendering/input | Procedural black blob, white eyes, shape-aware click/touch hit test, 720 × 1280 portrait reference; desktop, Android and future iOS/exportable desktop/web targets |
| Loop | Accepted blob hits increase hidden annoyance; background taps don't; tier-based randomized reactions; identical back-to-back selection avoided |
| Reactions | **15 regular + 1 special wake** = 16; four escalation tiers |
| Idle | Breathing, blinking, eye movements, relaxation when not touched; sleep after extended inactivity; special poke/wake reaction |
| Current mechanics | No persistent cross-launch relationship, counter display, trust meter, content unlock economy, alternate gesture vocabulary or completed audio system |
| Audio | **Absent from the baseline Alpha/game documentation**; M1 aims to change this in a later release only |

### The 16 existing reactions

- Calm: **blink, side-eye, squish**.
- Annoyed: **irritated/narrowed eyes, “Don't.”, “Seriously?”, slide away**.
- Angry: **jump, shake, flatten, turn away, “STOP”, “NO” sign**.
- Furious: **hide behind a box, run offscreen/return**; high-tier selection may also reuse some defensive actions.
- Special: **wake from sleep** (historically says “I was DREAMING.”).

Source-audited older behavior figures: annoyance 0–100; accepted tap +7 to +10; after about 2.5 seconds idle it decays around 4 points/second; sleep at 24 seconds of inactivity, once a reaction completes; focus loss pauses simulation. **Re-check `scripts/blob.gd` and the behavior spec before relying on exact timing, values or wording after later commits.**

## Development history and why it took this shape

1. **One-pass initial game:** owner used Windows and initially had no Apple/Google developer account budget. Codex created the core Godot game and automated tests; publishing was deferred rather than forcing paid enrollment or a Mac.
2. **Feature-complete small candidate:** 16 reactions plus idle/sleep/wake were judged enough for a first release; store approval and real-device behavior were separately unverified.
3. **Release package:** store descriptions, privacy and rating drafts, icons, screenshots, Windows/Android preparation, packaging/test scripts were added. Tests and generated materials are not proof of native device tests.
4. **Branch efficiency:** repeated generation of the licensed handwritten text art and screenshots during every gameplay edit was too costly/slow. The owner directed separation of normal gameplay and approved release styling.
5. **Typography identity:** approved **Space Grotesk** for general text/titles and **Ink Free** for handwritten reaction phrases. Never use an unapproved Showcard/fallback font in release graphics. Ink Free is rendered into complete phrase art where licensed; do not commit or distribute its proprietary font file.
6. **Public Alpha:** v0.1.0-alpha was prepared as a free limited-scope release, with website/itch.io/GitHub release work and subsequent platform experiments. Preserve the immutable Alpha; new features require new development/release versions.
7. **Distribution automation:** platform-specific adapter and asset workflow exploration surfaced real limitations (e.g. Playgama catalog criteria) and a near-miss using an incorrectly styled promotional file. This led to version-pinned, owner-approved graphics and fingerprint checks being required.
8. **Design review:** the owner asked for an **independent, collaborative** design critique, not an AI that independently chooses what the game becomes. Review emphasized reaction continuity, animation jitter, idle personality, selection, timing, and future relationship possibilities.
9. **Prioritized milestones:** the owner moved **audio to the very next milestone**, brought idle/independent behavior forward, kept trust/petting exploratory, and moved additional reactions, more interaction types, and many polish/extra features later.
10. **Latest active design discussion:** distinct organic/native and fictional/abstract voice mockups were generated for M1.1; a sound-event map is still being discussed. The owner's latest specific instruction: **poke contact sounds depend on the reaction**.

## Git branching and approved visuals — do not undo

- `main` is for gameplay with **basic Godot fallback font**. It isn't supposed to look exactly like the published release. Regular code/tests should be fast and must not rebuild all images.
- `aesthetic/typography-v1` preserves the approved typography/presentation snapshot; don't turn it into another gameplay branch.
- For a release, branch **`release/<version>` from updated main**; use `release/tools/apply_aesthetics.ps1` according to `BRANCH_WORKFLOW.md`, review the patch, and preserve current gameplay.
- Only after gameplay/text freeze, run final typography and screenshot generators **once for the release** using explicit finalization flags and checks. Check hashes, phrase coverage, typography and package provenance.
- Do **not** merge an aesthetic or release branch wholesale into main, copy outdated `blob.gd` over current gameplay, rewrite tags, force-push, or use old asset images just because dimensions match.
- Approved Alpha graphics are version-specific. Promotional asset approval requires **source/provenance, exact release, typography, content, hash, visual review and owner sign-off**. A hash/dimension alone proves integrity, not aesthetic approval.
- The conversation records owner approval of **nine Microsoft Store images** tied to Alpha artwork/commit `d61c865`. That is image approval, **not** evidence that a Microsoft product was published; verify the manifest and current Partner Center status before acting.

## Publishing and distribution — status must be checked

| Destination | Historical status from owner discussion / repo | Next verification |
| --- | --- | --- |
| itch.io | **Public Alpha live**, browser play and Windows download: https://wandiel.itch.io/dont-touch-me | Confirm present URL/version/assets and publishing receipt before updates |
| GitHub Releases | Alpha at https://github.com/miguelxhubgitty/dont-touch-me/releases/tag/v0.1.0-alpha | Confirm binaries/checksums and platform limitations |
| Playgama | **Public sandbox** uploaded with isolated Bridge adapter; **main catalog not submitted** due platform criteria (plays, playtime, ad metrics, download size) | Don't claim main catalog access or enable ads merely to pass criteria |
| Game Jolt | Owner supplied a **published** Public Alpha report: https://gamejolt.com/games/dont-touch-me/1114418; Windows/Linux/corrected macOS and HTML5 listed | Future fully automatic updates **not verified**; browser poke/wake QA incomplete in supplied report |
| Microsoft Store | Business verification discussion and nine approved visuals; submission workflow explored | Don't call it shipped; inspect Partner Center and approval/publishing record |
| Google Play / Apple App Store | Developer enrollment, D-U-N-S/name questions and device testing discussed; **deferred rather than permanently excluded** | Verify actual account/identity status, signing, costs, device testing, store rules |
| Steam / Epic | **Long-term deferred** | Owner decision and store requirements later |
| Armor Games | **Rejected**; no resubmission | Keep excluded |
| Other listed platforms | Platform registry includes candidates/deferred/manual destinations | Never infer they are live from registry entries alone |

Platform policy has been revised multiple times. The last owner-provided taxonomy had itch.io/GitHub Releases/Playgama public sandbox **active**, Game Jolt **published candidate for future update automation**, Google/Apple/Microsoft/Steam/Epic **deferred**, Armor Games **rejected**. Read the latest registry and receipts for final truth. An account, uploaded draft, built package, successful sandbox upload and verified public listing are different states.

**Business/publishing limits:** WANDIEL is the outward brand. Published Alpha remains free: no in-game ads, payments, donations, exclusivity or partner distribution. External platform page ads are not in-game monetization. Never alter seller/legal identity or publish a new version based only on this history.

## Design-first collaboration is mandatory

- For a meaningful audio, animation, gameplay or systems change, use **Proposal → Pseudocode → Owner approval → Implementation → Testing → Internal journal update → Release preparation** (`AGENTS.md`). One approved subtask does **not** approve the next.
- **Be an independent critic, not an autonomous creative director.** Present alternatives with strengths/trade-offs; challenge weak ideas; the owner makes creative decisions.
- Keep **idea / discussed / proposed / explicitly approved / implemented / tested / published / rejected** separate. Do not present a Codex prompt, draft PR or sound sample as an approved shipping feature.
- Create/update a narrowly scoped `plans/` entry before implementation, include player-visible behavior, event timing, pseudocode, failure modes, tests, and approval checkpoint. Commit planning separately from gameplay.
- Small steps are preferred for credit/time efficiency: each milestone is broken into reviewable, independently testable checkpoints. Don't quietly start M2 or change unrelated systems while working on sound.
- Maintain the detailed technical `docs/INTERNAL_DEVELOPER_JOURNAL.md`; **do not publish private technical notes** as public devlogs. Game public posts are under Butter Boy and currently paused under the WANDIEL website policy.

## Roadmap — latest owner priorities (design intent, not automatic code authorization)

| Order | Focus | Intent / constraint |
| --- | --- | --- |
| **M1 — NEXT** | **Audio makes the blob feel alive** | Native/default vocal identity, reaction-sensitive contact noises, selective action/reaction SFX, modest mixing/mute. **No music or ambient score in M1.** Small independent owner approvals. |
| M2 | Animation stability | Investigate sleep-eye jitter and pose snapping on interrupts; favor continuity via a simple current-pose/transition strategy, not an oversized permanent state machine. Investigate before changing or hiding eyes. |
| M3 | Independent idle life | More expressive idles; suspicion, anticipation, spontaneous behavior and surprises without requiring a poke. Keep lightweight and funny. |
| M4 | Reaction selection/discovery | Improve how existing tiers reveal behaviors, randomness and nonrepetition without immediately adding a larger library. |
| M5 | Trust/petting **prototype** | Explore respectful approach and whether affection / antagonism coexist; decide gestures, state, persistence and meaning **before** coding. |
| Later | Additional gesture types, customization, stats/counters, extended soundtrack/ambience, emotional continuity and fine timing | Proposals; their exact order/design needs renewed approval. Some timing/continuity may be evaluated as part of M2. |
| Last | More reactions/dialogue | Explicitly deprioritized: improve depth, animation and sound first. |

The owner's response did **not** mandate an immediate binary identity between companion and antagonist; it favors ambiguity. It also asked to defer a general reaction-count expansion, new input gestures, and extra systems, and to prioritize simplicity/efficiency.

### M1: split into small checkpoints, audio only

**M1.1 — Voice prototypes / review.** Two WAV mockups appeared in the source discussion: `M1.1_blob_native_voice_contented_then_defensive.wav` (organic/native direction) and `M1.1_blob_fictional_voice_contented_then_defensive.wav` (strange fictional voice). These are **conversation attachments**, not confirmed committed game assets, and their final selection has **not been recorded as approved**. Evaluate their emotion range, texture, duration, volume, clarity and whether both cute and hostile expressions feel possible. Request explicit preference/approval.

**M1.2 — Sound event map / review.** Before integration, enumerate **what actually needs sound** and what should remain silent. Suggested categories for discussion:

| Event category | Mapping question | Design constraint |
| --- | --- | --- |
| Successful poke/contact | Which reaction is being selected? Does it call for soft squish, dull bump, swat, startled squeak, etc.? | **Owner decision: contact sound depends on the reaction. No single generic universal poke noise.** |
| Non-contact/background tap | Should it be silent? | Do not undermine hit testing or imply the blob was touched |
| Blob vocalization | Contented / curious / surprised / irritated / defensive / sleepy / waking | Emotive, brief; avoid repetitive saturation; voices must match actual emotional state |
| Movement/prop | Slide, jump, shake, flatten, turn, sign, box, run | Trigger at meaningful animation moments only; preserve comedy and silence |
| Rest/sleep/wake | Breathing, snore, sleep entry, abrupt waking | Space sounds; avoid loops that annoy the player |
| Fast repeated pokes / reaction interrupts | Cancel, duck, overlap or queue? | No stacks of simultaneous loud clips; consistent behavior with visual interruption |
| App focus / audio settings | Pause/resume, one mute/master control initially | Accessible levels; no sudden spikes |

**M1.3 — Approved spec/pseudocode.** Only after M1.1/M1.2 decisions, define minimal Godot audio-event routing tied to the selected reaction and existing animation clock; allow reusable voice/SFX definitions, deterministic test points and simple level control. Avoid architecture that assumes future pet/trust mechanics already exist.

**M1.4 — Implementation/test.** Only after **explicit approval** of M1.3, add scoped audio to normal development `main`, test event selection, silence, simultaneous events, interruption, focus and basic Windows/browser/Android constraints as supported. Document what was tested versus only simulated. Preserve Alpha and approved aesthetics. Stop for owner review before proceeding to M2 or making a release.

### Optional future sound suites — **do not implement in M1**

- **Native/default**: original blob squeaks/grumbles/nonverbal expressions, designed first.
- **Cat**: possible meow/purr/hiss/growl skin; **Dog**: whine/bark/growl; **Bird**: chirp/whistle/squawk.
- These are **alternate audio palettes for the same emotional and animation events**, not animal transformations or a new gameplay identity. Make them swappable later if that can be achieved with minimal design overhead now; don't author optional suites, settings menus or packs prematurely.
- Music, ambience and a complex multi-bus/options screen were explicitly lower-priority than responsive voices and reaction/contact sounds.

### Counters and trust — design for compatibility, not phantom functionality

- The owner asked whether basic counter/trust fields should exist now without being connected. The evaluation was **simple purposeful counters may be worthwhile; implementing unused trust now is premature**.
- **Current direction:** document future concepts; no placeholder trust system, persistent relationship model, fake stat screens or unused global state unless a specific later design makes them necessary.
- Touches or distinct reactions could be counted in a future deliberate feature, but beware that visible poke counts may encourage exactly the harassment the character resists. Define what a metric does before implementing.
- For trust/petting, first decide player behavior, slow approach (not currently supported as a gesture), emotional meaning, persistence, thresholds, testing and whether petting changes the premise.

## Known critiques and open design questions (not fixes yet)

- Sleep eye jitter/misalignment was reported. A suggestion to hide the eyes conflicts with other expectations that they remain expressive; investigate root cause and approve an intended visual outcome before changing it.
- Interruptions can snap from a rebuilt pose rather than smoothly continuing from the currently displayed pose. Prefer a simple sampled-pose/transition solution over a wholesale rewrite until evidence demands complexity.
- Players may perceive only disconnected reaction clips, not lasting emotion; more continuous expression could help, but this was moved later for deliberate design review rather than silently patched.
- Pokes during punchlines can interrupt timing. Explore comedic timing only within a scoped approved animation task; many timing concerns were deliberately moved later.
- Waiting mostly causes quiet decay/sleep. More funny independent idle behaviors are desired without conventional progression.
- Four tiers can skip reactions during rapid escalation; rethink sampling/discovery before simply adding content.
- Bigger features (trust, outfits, furniture, gestures, soundtrack, monetization) can alter the game's identity; they remain explorations.
- Counts of automated assertions are regression evidence, **not** proof of actual player appeal, device coverage, sound quality, platform approval or publication.

## Continuation prompt for a new coding conversation

> Read `AGENTS.md`, `docs/PROJECT_FOUNDATION.md`, `GAME_ROADMAP.md`, the relevant `plans/` document, current code and any existing milestone PR. Determine the newest **approved** design and current implementation status from exact branches/commits. Focus ONLY on the next open, owner-authorized M1 audio subtask. Start with a short event/voice proposal and pseudocode when relevant; identify trade-offs and stop for approval before editing gameplay. Do not change visuals, reactions, trust, counters, distribution or published Alpha. Record an approved implementation and tests in the internal journal before any release preparation.

## Maintenance rules

- Update this context after material owner decisions, with **date, status and source/reference**, without rewriting historical reasons.
- The source conversation is **not** automatically synchronized with GitHub. Audio mockup files must be checked/added separately if the owner wants them committed; this document records only their names and discussion.
- Use live repositories, approved manifests and receipts for exact present-day technical/build/distribution facts. Clarify contradictions rather than guessing.
- Never commit credentials, private company records, licensed proprietary font files, signing keys or undisclosed personal information.
- New chats should be able to answer: **what game is this, why was it designed this way, what is live, what is only proposed, what is next, and what must be approved first?**