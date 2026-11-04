# Audio / SFX opportunity evaluation — Don't Touch Me.

**Status:** Design reference and asset-shopping/creation checklist only. **No sound assets or integration are approved by this document.**
**Prepared:** 2026-11-03
**Baseline examined:** `scripts/blob.gd` on `main`, `docs/ALPHA_BEHAVIOR_SPEC.md`, `GAME_ROADMAP.md`, and the isolated foundation document.
**Owner's current preferences:** an **adorable-animal-like**, nonverbal blob; cuteness even when furious; reaction-dependent contact sounds; selective silence. The owner will select/produce SFX manually.

## Purpose

This is a list of **where sounds could improve the game**, not a specification that every event must make noise. Use it as a checklist while recording, creating, auditioning, or sourcing sounds. Prefer the joke and readability over the number of effects.

**Legend:** **Core** = a strong candidate for the first audio pass; **Optional** = audition only if it noticeably improves the scene; **Quiet** = silence is probably best. Roles are **contact** (the blob's body being touched), **voice** (the creature reacting), and **action/prop** (movement or an object).

## Existing behavior that affects sound decisions

- **16 reactions:** 15 ordinary reactions selected from four annoyance tiers, plus WAKE when touched while sleeping. This is existing gameplay, not an audio feature.
- Accepted touches currently add annoyance and reset idle. A miss/background touch does not count. When BOX is active, cardboard/flaps block touch, but exposed body/peek eyes can be touched.
- A touch can replace most active reactions, but BOX and RUN are protected: accepted hits during them **do not restart or replace** their active animation.
- After about 24 seconds of inactivity, a completed/resting reaction can transition into sleep. Natural breathing, eye blinks, and eye direction occur during idle.
- Text bubbles, the NO sign, cardboard box, and motion are **drawings/animation**, not pre-existing playable audio events. Where this document mentions cue timing, it is a proposed audio opportunity, not an implemented sound hook.
- The inspected `main` gameplay has no integrated audio. Two earlier M1.1 prototype WAVs exist in the owner's local work according to the recent Codex audit; neither is an approved final asset. Local uncommitted files may differ from the remote baseline.

## 1. The 16 reactions — opportunity checklist

For all successful blob contacts: the contact texture should be **chosen according to the reaction** (or the protected reaction already playing). Avoid a universal tap clip. Contact/voice/action are **separate possible layers**; do not automatically play all three.

| Existing reaction | Contact / body sound opportunity | Creature voice opportunity | Action / prop opportunity | Recommendation |
| --- | --- | --- | --- | --- |
| **BLINK** (calm) | Very small cushion-like `pup` / soft body tap | None | None; the instantaneous surprise is the joke | **Core** contact, **Quiet** elsewhere |
| **SIDE_EYE** (calm) | Little dry/damped body nudge | Perhaps a nearly inaudible questioning nasal puff | No eye movement swish or gaze click | **Core** contact; voice **Optional** |
| **SQUISH** (calm) | Supple soft rubber compression (not a wet splat) | Tiny surprised/pleased chirp | Light elastic rebound when the squash visibly releases | **Core** contact; voice/rebound **Optional** |
| **IRRITATED** (annoyed) | More resistant, muted bump | Minuscule offended grumble / closed-mouth protest | None for the tiny body oscillation | **Core** contact + voice |
| **DONT** (annoyed) | Damped, decisive bump | Short animal-like complaint; do **not** speak the bubble text | No text pop/ding | **Core** contact + voice |
| **SERIOUSLY** (annoyed) | Slightly hollow compression | Small rising, skeptical squeak | No question-mark music sting | **Core** contact; voice **Optional** |
| **SLIDE** (annoyed) | Quick bump/release | Usually none | Very soft short friction swish, ending as sliding stops (movement reaches its destination before the reaction ends) | **Core** contact + movement |
| **JUMP** (angry) | Compressed springy bump | Tiny startled squeak at the start | Soft landing when the body **actually visually touches down**; never after the reaction was interrupted | **Core** landing + contact; voice **Optional** |
| **SHAKE** (angry) | Soft wobbly impact | One shaky, high-strung animal protest | Do **not** play a sound for each vibration cycle | **Core** voice + contact |
| **FLATTEN** (angry) | Wider, air-pressed compression; distinguish from SQUISH | Usually none; the visual/text is enough | Small optional stretch on flattening and light elastic release as it returns | **Core** contact; action **Optional** |
| **TURN** (angry) | Small muted, withdrawn tap | Tiny dismissive snort/puff | No large turning whoosh | **Core** contact; voice **Optional** |
| **STOP** (angry/furious) | Firm but still rounded `pop`, not a slap | Emphatic **small** squeaky protest, sounding serious *to itself*, not scary to the player | No extra text sting or repetitive shake chatter | **Core** contact + voice |
| **SIGN** (angry/furious) | Restrained compressed bump | Prefer none | Tiny object-handling shuffle as the NO sign rises; maybe a light settling tick; silence during held sign | **Core** sign handling + contact; **Quiet** voice |
| **BOX** (furious) | Soft hollow body bump; extra touches to exposed body/peek eyes use quiet BOX-specific contact | Optional muffled mini-grumble | Gentle cardboard lift/shuffle, subtle lower/settle; no sound for hits on blocked cardboard because those are misses | **Core** cardboard + contact; voice **Optional** |
| **RUN** (furious) | Quick recoiling spring-like body contact; additional accepted touches should not restart escape audio | One indignant animal squeak when it departs | Soft retreat shuffle, possibly extremely subtle return shuffle; **no continuous footstep loop** and quiet while fully offscreen | **Core** departure + contact; other effects **Optional** |
| **WAKE** (asleep → awake) | Airy sleepy compression / small startled contact | Tiny startled animal chirp, perhaps one softer offended sleepy grumble later | Optional cushioned landing as the wake-up hop visually returns to ground | **Core** contact + first voice; second voice/landing **Optional** |

**Timing details grounded in the current animation:** SLIDE reaches its destination at roughly two-thirds of its 0.90-second reaction. JUMP finishes its vertical arc at the end of its 1.05-second reaction; avoid scheduling a landing at or beyond the exact completion frame, where the reaction may already have reset. WAKE's initial vertical hop returns to its baseline around halfway through its 1.65-second reaction; its narrowed-eye phase begins slightly afterward. RUN has departure, offscreen hold, peek, and return phases across 4.10 seconds. Match sounds to **visible state changes**, and verify against the actual rendered animation rather than adopting guessed fixed timestamps.

## 2. Non-reaction opportunities

| Event | What could sound good | Assessment |
| --- | --- | --- |
| **Entering sleep** | One extremely soft settling exhale / tiny sleepy sigh | **Optional / strong candidate**; fire only at transition, not every frame asleep |
| **Sleeping idle** | Very occasional tiny sleepy breath if there is a good reason | **Quiet** for M1. No audible breathing or snoring loop |
| **Idle while awake** | Perhaps a tiny voluntary chirp in a **future** expanded idle behavior system | **Quiet** for M1; current procedural breathing/gaze needs no audio |
| **Natural blink** | Nothing | **Quiet**; not the same as the BLINK reaction |
| **Poke hit confirmation** | Use the selected reaction's **body contact sound** | **Core**, but it must remain part of blob audio, **not** an extra generic user-tap effect |
| **Background tap / missed input** | Nothing for the blob | **Quiet** now; the separate future user-interface SFX suite may handle user-side tapping independently |
| **Box flap/cardboard tap (blocked)** | Nothing from the blob | **Quiet** now: current logic rejects this touch; adding a cardboard-knock requires its own new design approval |
| **Speech bubble appears** | Generally nothing; emotion should come from voice and animation | **Quiet**; avoid identical UI pings on all reactions |
| **Introduction text fades** | Nothing | **Quiet** |
| **App launch/resume** | No mandatory chime; only optional later when app has a fuller UI | **Quiet** now |
| **Resizing window** | Nothing; may cancel an animation | **Quiet** |
| **App loses focus/pauses** | Stop/quiet audio gracefully; no decorative sound | **Core behavior requirement**, not an SFX asset |
| **Future petting, trust, counters, extra gestures** | Likely new body textures and emotional responses | **Out of scope**; do not create placeholder sounds for mechanics that do not exist |

## 3. Later, separate USER-oriented SFX suite (do not build yet)

**Owner's new idea:** a standalone category for sounds that respond to **the person's inputs**, such as tactile tap feedback, buttons, navigating menus, selections, or confirmation actions. This is **not** the same as the blob's reaction-dependent body contact sounds.

Examples to evaluate later:

- A light player-side tap feedback sound (including the possibility of non-blob/background touches, if deliberately chosen).
- UI button hover/press/selection, especially when a real settings menu exists.
- Mute/unmute or other setting confirmation sound, if useful rather than confusing.
- Accessibility/interaction confirmation cues when corresponding UI exists.

**Separate setting:** an independent **User SFX On/Off** control, apart from blob voice/contact/action sounds. An input could eventually trigger both systems, so prevent redundant double clicks. Do not implement this suite, new UI, or a second setting in the initial M1 pass. For now keep a simple master audio mute in the design.

## 4. Suggested asset families for manual creation

These are **sound categories**, not requests to create one WAV per row. A few distinctive, expressive recordings plus subtle variations may cover many reactions; avoid making the game sound like a repetitive sample library.

| Family | Candidate recordings / textures | Likely uses |
| --- | --- | --- |
| Soft body contacts | airy `pup`, warm bump, hollow dent, cushioned snap | BLINK, SIDE_EYE, IRRITATED, DONT, SERIOUSLY, TURN, STOP |
| Elastic body | compression, stretch, boing, recovery | SQUISH, FLATTEN, JUMP, RUN launch |
| Cute animal voice — positive/neutral | short chirp, delighted peep, sleepy breath, startle | SQUISH, JUMP, WAKE, sleep entry |
| Cute animal voice — skeptical/annoyed | little huff, nasal puff, questioning squeak, tiny grumble | IRRITATED, DONT, SERIOUSLY, TURN |
| Cute animal voice — furious-but-cute | small squealy protest, trembling offended noise, barely-contained indignation | SHAKE, STOP, RUN, BOX |
| Soft motion | slide swish, displacement shuffle, cushioned landing | SLIDE, JUMP, RUN, WAKE |
| Props | cardboard lift/rustle, small NO-sign handling / settle | BOX, SIGN |

**Character rule:** "animal-like" refers to warmth, personality and expressiveness, not necessarily literal cat/dog/bird vocal mimicry. Cat/dog/bird **alternate sound packs** were separately discussed for the future; they are *not* M1 deliverables.

### Lightweight source-file worksheet

When you create or find a file, track it outside gameplay first. A simple entry like this is enough:

| Event / intended role | Filename / location | Source or original creator | Rights / license | Duration | Your verdict |
| --- | --- | --- | --- | --- | --- |
| Example: soft elastic compression | `audio/candidates/squish_soft_01.wav` | Original recording | Owned | _to measure_ | Audition |
| Example: fierce tiny protest | _not selected_ | _not selected_ | _verify_ | _to measure_ | Pending |

Avoid committing unreviewed or unlicensed sample packs to the repository. Keep a recognizable naming style, for example `blob_contact_soft_01.wav`, `blob_voice_offended_01.wav`, `blob_prop_cardboard_lift_01.wav`.

## 5. Evaluation and playback checklist

- [ ] Does every **core** sound make the blob more adorable or the joke clearer?
- [ ] Are the animal-like sounds nonverbal and consistent enough to belong to **one creature**?
- [ ] Do STOP/RUN/BOX feel **more indignant**, rather than simply much louder or more menacing?
- [ ] Are contact sounds **reaction-dependent**, with some differences in texture, timing, or treatment?
- [ ] Can SQUISH and FLATTEN be heard as related body material without sounding identical?
- [ ] Does any sound spoil SIDE_EYE, SIGN, FLATTEN, TURN, or the silent offscreen RUN beat?
- [ ] Are multiple sounds on the same moment necessary, or is one expressive sound enough?
- [ ] Do rapid pokes avoid machine-gun audio? No queued bursts after silence, focus changes, or lag.
- [ ] If a reaction is interrupted, are its pending landing/prop/voice sounds cancelled appropriately?
- [ ] During protected BOX/RUN, do extra accepted pokes play only modest contact without restarting the act?
- [ ] Do taps on blank background or blocked cardboard correctly remain **blob-audio silent**?
- [ ] Is the sound pleasant at low speaker volume and on phone speakers, not just headphones?
- [ ] Does master mute stop game sound; is unmute free of stale queued effects?
- [ ] Have audio rights, filenames, source, and intended use been recorded?

**Practical first audition:** begin with a **soft contact**, **elastic squish**, **cute startled peep**, **offended grumble**, **tiny furious protest**, **short swish**, **soft landing**, and **cardboard shuffle**. These eight rough candidates are enough to judge the direction. You do **not** need sixteen finished recordings before reviewing the character's sound identity.

## 6. Boundaries and next steps

1. This file is a **creative evaluation**. None of the sound suggestions are implemented, approved final samples, or a command to generate audio.
2. Owner personally creates/sources samples and records candidates with usage rights.
3. Review which sounds improve the humor, trim anything repetitive, and approve the chosen asset shortlist.
4. **Only after review**, propose the smallest Godot event routing / pseudocode for the approved sounds, then seek separate implementation approval under `AGENTS.md`.
5. Keep routine gameplay development on `main` with basic fonts. Release visuals are added only on a fresh `release/<version>`. Do not merge the isolated foundation branch into `main`, and do not touch unrelated MSIX/website/distribution work.

### Repo pointers

- [Actual reaction code](../scripts/blob.gd)
- [Alpha behavior reference, including exact reaction phases](../docs/ALPHA_BEHAVIOR_SPEC.md)
- [Audio and feature roadmap](../GAME_ROADMAP.md)
- [Branch and visual-release workflow](../BRANCH_WORKFLOW.md)
- The long-term [project foundation document](https://github.com/miguelxhubgitty/dont-touch-me/blob/docs/foundation-context-2026-11-02/docs/PROJECT_FOUNDATION.md) remains on its **own permanent branch**, intentionally unmerged.
