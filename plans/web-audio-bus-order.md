# Planned fix: silent sound on Web

**Status:** Planned / not implemented. Fix verified in a scratch export only.
**Type:** Audio bug (Web only)
**Priority:** Blocks the 0.1.1 Web package. Desktop, Android and the published Alpha (which has no audio) are unaffected.
**Reported:** 2026-11-24

## Observation

In the approved 0.1.1 Web package (built from `5660a2e`), turning Sound On and poking the character starts the expected sounds. No sound reaches the speakers in Firefox 159 or Chromium 159. Nothing is logged: there are no errors and no WebGL warnings.

## Investigation (source-grounded)

- The authored sounds play: each `AudioBufferSourceNode` has real samples (peak 0.12–0.23), and the per-sound mixer output peaks at 0.035–0.12.
- `AudioManager._ensure_preview_buses()` (`scripts/audio_manager.gd`) creates the five category buses at runtime with `AudioServer.add_bus()`, which uses the default position −1.
- In the Godot 4.7.2 web audio library, `add_sample_bus(-1)` runs `GodotAudio.Bus.addAt(-1)`. That calls `Bus.move(id, -1)`, which runs `splice(toIndex - 1, …)` = `splice(-2, …)`. Each new bus is therefore inserted *before* Master, at index 0.
- The engine's bus indices and the browser's bus order no longer match. The engine's `set_bus_send(index, "Master")` then rewires the browser's Master into a category bus, closing a loop: Master → bus → bus → Master. Nothing is connected to the speakers any more. Web Audio outputs silence for a loop without a delay node.
- Passing an explicit end position, `add_bus(AudioServer.get_bus_count())`, does not help: the loop remains, so the engine evidently still forwards −1.
- `AudioServer.set_bus_count(count + 1)` goes through `Bus.setCount`, which appends with `Bus.create()`, so the order stays correct.

## Proposed change (one line)

```gdscript
# scripts/audio_manager.gd, _ensure_preview_buses()
-		AudioServer.add_bus()
+		AudioServer.set_bus_count(AudioServer.get_bus_count() + 1)
```

The following lines (set the name, send to `Master`) stay unchanged. On desktop and Android, both calls append one bus at the end, so behavior there is identical.

## Verification already done (scratch export from `fdc078e` + the change; nothing committed or packaged)

- Firefox 159 and Chromium 159 headless, approved test script: Master connects to the speakers, a poke peaks at 0.124 with Sound On and 0 with Sound Off, 0 errors, 0 WebGL warnings.
- `tests/run.ps1 audio`: all 11 suites pass.

## Acceptance criteria

- Sound is audible on Web after Sound On in Firefox, Chromium/Edge and Safari; it stays silent before the first tap and when muted.
- The browser bus graph has exactly one path from Master to the speakers and no loops.
- Volume sliders and per-category muting behave as on desktop.
- The fast and audio test groups pass; add a regression check that the web bus order matches `AudioServer` order where testable.

## Release impact (owner decision needed)

The change touches a runtime file, so the publication safeguard rejects packages built before it. Shipping a working Web build means re-exporting every 0.1.1 package from the fixed commit (identical behavior off-Web) and rebuilding the unsigned AAB and the MSIX. The alternative is to leave Web out of 0.1.1.

**Planning-only change:** This file does not authorize implementation, a rebuild or publication.
