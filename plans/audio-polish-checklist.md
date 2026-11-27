# Don't Touch Me — Audio Polish Checklist

Target: v0.1.1 candidate audio pass. This is a working inventory, not a commitment to add every sound.

**Status:** Existing = enabled in the reviewed audio map; Disabled = candidate already defined but disabled; Proposed = potential sound with no dedicated enabled cue identified. Check off each item after auditioning it and deciding to keep, replace, add, or intentionally leave silent. Record the decision beside the item. Verify against the current local source before implementation.

## 1. Player interactions

- [ ] Successful poke — Existing (`*.contact`)
- [ ] Missed poke — Existing (`user.tap_miss`)
- [ ] Cardboard box tap — Proposed; currently silent
- [ ] Poke during sleep — Existing (`wake.contact`)
- [ ] Poke during yawn / startled interruption — Proposed dedicated cue; ordinary reaction audio may cover it

## 2. Character reactions

### Blink
- [ ] Blink / surprise — Proposed

### Side-eye
- [ ] Disapproving grunt — Disabled (`side_eye.voice`)

### Squish
- [ ] Compression / vocal squeak — Disabled (`squish.voice`); separate compression sound optional
- [ ] Rebound — Disabled (`squish.rebound`)

### Recoil
- [ ] Startled squeak — Existing (`recoil.voice`)
- [ ] Recoil movement / settling — Proposed

### Irritated
- [ ] Annoyed whine — Existing (`irritated.voice`)

### Don't
- [ ] Vocal protest — Existing (`dont.voice`)

### Seriously
- [ ] Exasperated sigh — Disabled (`seriously.voice`)

### Slide
- [ ] Sliding — Existing (`slide.move`)
- [ ] Stopping — Proposed

### Puffer-huff
- [ ] Inflation / huff — Existing (`puffer_huff.action`)
- [ ] Spikes extending — Proposed
- [ ] Deflation — Proposed

### Jump
- [ ] Takeoff — Proposed
- [ ] Airborne movement / vocalization — Disabled voice (`jump.voice`); movement cue proposed
- [ ] Landing — Existing (`jump.land`)
- [ ] Return glide / settling — Proposed

### Shake
- [ ] Frustrated vocalization — Existing (`shake.voice`)
- [ ] Physical shaking — Proposed

### Flatten
- [ ] Compression — Disabled (`flatten.compress`)
- [ ] Expansion — Disabled (`flatten.release`)

### Turn
- [ ] Body rotation — Proposed
- [ ] Dismissive grunt — Disabled (`turn.voice`)

### Stop
- [ ] Vocal protest — Existing (`stop.voice`)

### Sign
- [ ] Raising / swinging — Existing raise (`sign.raise`); separate swing optional
- [ ] Settling — Disabled (`sign.settle`)
- [ ] Lowering — Disabled (`sign.lower`)

### Box
- [ ] Raising — Existing (`box.raise`)
- [ ] Cardboard flaps moving — Proposed
- [ ] Peeking / hidden vocalization — Disabled (`box.voice`)
- [ ] Lowering — Existing (`box.lower`)

### Run
- [ ] Departure — Existing (`run.depart`)
- [ ] Running / exertion — Disabled voice (`run.voice`); movement cue proposed
- [ ] Return — Disabled (`run.return`)
- [ ] Stopping — Proposed

### Wake
- [ ] Startled voice — Existing (`wake.voice`)
- [ ] Landing — Disabled (`wake.land`)
- [ ] Grumbling — Disabled (`wake.grumble`)

## 3. Idle and sleep

- [ ] Breathing — Proposed
- [ ] Natural blinking — Proposed
- [ ] Looking around — Proposed
- [ ] Stretching — Existing (`idle.stretch`)
- [ ] Humming — Existing (`idle.humming`)
- [ ] Yawning — Proposed
- [ ] Microsleep — Proposed
- [ ] Fighting sleep — Proposed
- [ ] Falling asleep — Existing (`sleep.enter`)
- [ ] Sleeping / snoring — Proposed
- [ ] Sleep twitch — Proposed

## 4. Interface

- [ ] Game launch — Existing (`user.game_start`)
- [ ] Button press — Proposed
- [ ] Settings opening — Proposed
- [ ] Settings closing / back — Proposed
- [ ] Volume adjustment — Proposed
- [ ] Sound toggling — Proposed
- [ ] Orientation selection — Proposed
- [ ] Intro text disappearing — Proposed
- [ ] Privacy policy selection — Proposed

## 5. Environment and music

- [ ] Ambient room tone — Proposed
- [ ] Background music — Proposed

## 6. Overall audio polish

- [ ] Review consistency of the blob's vocal identity (existing kitten, puppy, robotic and other cues).
- [ ] Review variation, volume balance and timing of existing sounds.
- [ ] Preserve spam-click attenuation, interruption fades, mute and category volume behavior.
- [ ] Audition selected cues in the existing audio preview scene (`tests/audio_preview_menu.tscn`).
- [ ] Verify audio tests and release audio export/provenance requirements before v0.1.1 packaging.

## Suggested first-pass priorities (not approved changes)

Cardboard box tap; yawn; sleeping/snoring; puffer-huff inflation and deflation; jump takeoff; squish compression and rebound; sign movement; run return; consistent character voice.

## Source references

- [Audio event map](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/audio/blob_events.json)
- [Gameplay controller](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/scripts/blob.gd)
- [Audio manager](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/scripts/audio_manager.gd)
- [Current game state](https://github.com/miguelxhubgitty/dont-touch-me/blob/main/CURRENT_STATE.md)

Baseline: reviewed GitHub development source contains 50 defined audio events (35 enabled, 15 disabled). Shared contact cues are grouped above instead of repeated for each reaction. Unpublished local experiments were not inspected. Proposed cues are design candidates, not confirmed implementation requirements.
