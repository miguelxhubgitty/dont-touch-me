# Don't Touch Me — Versioned Game Development Roadmap

**Status:** Owner-confirmed priorities; milestone designs and implementation remain unapproved until the design-first review.
**Published baseline:** Public Alpha `v0.1.0-alpha` (preserve unchanged).
**Next milestone:** M1 — audio personality.
**Source of truth for current gameplay:** `docs/ALPHA_BEHAVIOR_SPEC.md` and the actual source. This roadmap specifies future work, not implemented behavior.

## Product direction and development principles

- The blob can be **both a comic adversary and a potential companion**. Do not force a choice or build an affection/progression system merely to settle that ambiguity.
- **Simplicity and efficiency are primary requirements.** Favor one clear controller and small local changes; no broad rewrite, generalized framework, unnecessary persistence, or excessive UI.
- Prioritize **expressiveness, comedic timing, coordinated movement/sound, and agency** over raw reaction count.
- The public Alpha visual identity is **Space Grotesk** for regular text and **Ink Free** for handwritten phrases. Main's fallback typography is development-only; never publish its artwork.
- Each milestone should have observable player-facing acceptance criteria and practical playtesting, not only automated assertions.
- Cross-platform behavior must account for mouse and touch; browser audio has user-gesture/autoplay restrictions.
- Sound priority is **not** uniform: tactile effects and the blob's voice matter first; music and ambience are optional, much later decisions.
- Preserve the blob's **cute/affectionate versus hostile/defensive dichotomy**. A cat is a useful temperament analogy, **not** a requirement for animal behavior or a single fixed player relationship.

## Operating contract for Codex

1. Read `AGENTS.md`, `BRANCH_WORKFLOW.md`, this roadmap, and the relevant current implementation and plans.
2. `M1` is next **for design**, not blanket permission to implement. For a requested milestone, create/update `plans/<milestone>.md` with current behavior, design alternatives, scoped pseudocode, tests, platform considerations, and explicit exclusions. **Present it for owner approval before writing implementation code.**
3. After approval, implement **only** that milestone's approved scope on the proper gameplay development branch. Avoid unrelated cleanup or opportunistic feature work.
4. Update tests and the internal developer journal, then report results, changed files, trade-offs, and unapproved follow-ups. Do not silently advance to the next milestone.
5. Keep `main`'s basic-font development workflow and the frozen public Alpha intact. Versioned releases follow the approved aesthetic integration and release checks. Publishing, store assets, monetization, and version tagging need separate authorization.
6. If the user says **"work on the next milestone"**, find the earliest unfinished milestone here, **propose the detailed design first**, and stop for review. Treat labels below as **tentative release targets**, not promises or implementation authorization.
7. Preserve planned ideas even when reprioritized; never mark an idea shipped without source and test evidence.

## Milestones in priority order

### M1 — Sound personality (tentative `v0.2.0-alpha`) — NEXT: DESIGN ONLY

**Purpose:** Make the blob feel alive through sound that reinforces its physical performance and comic personality.

**High priority:**
- A small, distinctive **native/default blob voice**: nonverbal surprise, suspicion, contentment, annoyance, resistance, sleepy/wake sounds. Explore contrasting cute and defensive expressions; decide the actual sonic personality with the owner.
- **Possible future personalization:** alternative audio-only suites, such as cat (purr/meow/hiss), dog (whine/bark/growl), or bird (chirp/squawk). The animal analogy applies to **sound**, not altered blob movement, behavior, relationship rules, or gameplay. Preserve the *same semantic cues* across packs so selecting a suite replaces voice clips, not mechanics. These suites are **proposals, not M1 deliverables**.
- Keep the M1 audio event mapping simple enough to support voice-suite substitution later (for example, stable meaning-based cues such as content/surprise/protest/sleep), **without** constructing an extensive configurable audio-pack framework now.
- **Tactile/action sound** synchronized to key existing animations (poke, squish, movement, sign, box, escape, sleep/wake) without constant noisy playback.
- Intentional **silence and timing**: sounds support animation beats; repeated/rapid pokes must not cause an overwhelming pileup.
- A **simple mute/volume solution** appropriate for an otherwise minimalist game. Start with minimal controls, not a five-slider mixer.
- Original or clearly licensed audio, local/offline resources, efficient playback, cross-platform checks, browser first-interaction unlock and sensible focus behavior.

**Explicitly out of scope:** background music, ambient beds, complex voice dialogue, alternate cat/dog/bird sound packs, additional reactions, progression, trust mechanics, customization UI, broad architecture rewrites, monetization.

**Before implementation:** agree on a reference sound palette, a small event-to-sound map with timing points, interruption/overlap rules, volume behavior, audio budgets, tests and a way to compare silent vs sound-on gameplay.

**Acceptance candidates:** sound fires on the intended existing actions; no incorrect overlap or abrupt/clipped peaks; mute works; gameplay still works without sound; no noticeable browser/mobile performance or load regression.

### M2 — Animation continuity + comic timing (tentative `v0.2.1-alpha`)

**Purpose:** Improve quality and timing of the existing 16 reactions, **not** quantity.

- Investigate and fix reported **sleeping-eye jitter**, reconciling the conflicting eye-visibility/placement ideas in `plans/sleep-eye-jitter.md` only after choosing a desired sleeping expression.
- Prevent visible **position/pose snapping** when reactions interrupt one another; test movement and idle-to-reaction transitions.
- Design and compare **short protected punchline beats**, ordinary interruption, and funny interruption-aware responses. Choose the smallest solution that feels responsive and delivers the joke.
- Coordinate sound event timing with the action; adjust the M1 timing map if the approved design calls for it.
- Validate visual behavior on multiple aspect ratios and mouse/touch; preserve hit detection and reaction rules unless specifically approved.

**Implementation guidance (not a prescribed fix):** The scene and gameplay variables already persist; `_update_pose()` reconstructs a deterministic visual pose each frame. Do **not** replace this with an accumulating permanent transform/state by default. Investigate capturing the outgoing pose and briefly blending into the next animation, or small localized timing guards. Prefer the simplest tested approach, avoiding state drift and a giant animation state machine.

### M3 — Independent blob / richer idle life (tentative `v0.3.0-alpha`)

**Purpose:** Let the blob initiate some comedy so the player isn't responsible for every funny moment.

- Add a **small number of distinct passive behaviors**: looking around, fidgeting, showing suspicion, anticipating a poke, a false-start escape, responding to being left alone, or sleep variations.
- Explore surprises that arise **without more input buttons**, progress bars, counters, or persistent saves.
- Keep surprises infrequent and legible; protect the quiet/negative-space presentation and allow natural pauses.
- Give those actions appropriate sounds *only where useful*, reusing the simple M1 audio system.

**Acceptance candidates:** idle behavior reads as independent personality rather than random noise; mobile/web parity; does not interfere with existing touch/hitbox/sleep mechanics.

### M4 — Reaction selection and discoverability (tentative `v0.3.1-alpha`)

**Purpose:** Preserve the four-tier escalation while reducing missed content and repetitive high-annoyance loops.

- Compare a minimal adjustment to tier pools/weights/cooldowns with the current replacement-only pools.
- Make reactions easier to encounter without a checklist, compulsory unlocking or obvious gameification.
- Test expected escalation, repeat prevention and session variety; avoid increasing total reaction count in this milestone.

### M5 — Trust / potential petting (tentative `v0.4.0-alpha`) — EXPERIMENTAL

**Purpose:** Explore a richer relationship while preserving the blob's ability to resist.

- Prototype whether patience, distance or respectful behavior can change the interaction, and **whether petting is the right payoff at all**.
- Keep adversary and companion readings compatible; avoid making `don't touch` a puzzle with one required solution.
- Start with session-only/simple state unless the owner approves persistence. Do not require hover (unavailable to touch-only players).
- Define the actual player gesture and clear testable behaviors before implementation.

**Status:** Concept is welcomed, **not** a signed-off mechanic. Do **not** add an unused `trust` variable, save format, or scaffolding as part of M1. Define how trust is earned, lost and expressed, and whether it should persist, before authorizing even minimal state.

## Later idea backlog — not active milestones

Listed for retention, **not authorization**. Reorder or discard through discussion:

1. More persistent emotional continuity/personality between reactions, **only if** M2–M5 demonstrate a real need; avoid duplicating the existing annoyance/idle state.
2. Other interaction types (holding, dragging, slow approaches, etc.), designed for both mouse and touch; no assumed new controls.
3. Optional counters/statistics. **Assessment:** Lightweight per-session counters may later help discovery or testing, but define an actual use and what counts (touches, completed reactions, unique reactions) before adding them; don't build dormant counters or player-facing score incentives by default.
4. Outfits, furniture, environmental customization and UI, if they add value without crowding the character.
5. Expanded soundscape: **ambience, background music**, additional mixing/accessibility controls when a clear atmosphere is chosen. These are deliberately **not part of M1**.
6. **Additional reactions and dialogue — very last.** Prioritize timing, animation quality, independence and existing content discovery first.

**Separate deferred business idea:** Optional cosmetic monetization was historically proposed but is **not** part of the currently free, no-payments game, and is not authorized for development.

## Milestone status tracking

| Milestone | Status | Owner design approval | Implemented | Released |
| --- | --- | --- | --- | --- |
| M1 — Sound personality | **Next: design pending** | No | No | No |
| M2 — Animation + timing | Planned | No | No | No |
| M3 — Independent idles | Planned | No | No | No |
| M4 — Reaction selection | Planned | No | No | No |
| M5 — Trust / petting | Experimental | No | No | No |

Each milestone's final behavior, implementation details and release number require a separate owner-reviewed plan. This document intentionally does **not** freeze creative decisions or authorize autonomous development.
