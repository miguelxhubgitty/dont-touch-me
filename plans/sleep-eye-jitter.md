# Planned fix: sleeping eye jitter

**Status:** Planned / not implemented
**Type:** Animation bug
**Priority:** Next gameplay patch (not retroactive to v0.1.0-alpha)
**Reported:** 2026-10-31

## Observation
During the sleeping/breathing animation, the blob's eyes visibly jump at small intervals, as if they are attempting to hold their position while the body moves. The motion looks unstable rather than smooth.

## Preferred proposed solution

Hide the eyes entirely during the fully sleeping state while retaining the body's breathing animation. Restore them cleanly when waking, with no flicker or snapping. Validate that the result still looks asleep. If the hidden-eye appearance is unsuitable, investigate smooth eye anchoring as an alternative.

## Investigation and implementation plan
1. Reproduce and record several uninterrupted sleep/breathing cycles before changing code.
2. Examine how eye positions and body deformation/transforms are calculated, including any per-frame rounding, discrete steps, independent animation clocks, and transitions.
3. Identify the actual root cause; do not assume a particular coordinate bug without evidence.
4. Keep eye movement continuous and anchored appropriately to the animated body, preserving existing sleeping expression, breathing and silhouette.
5. Check whether the same issue occurs in other character animations; make only necessary, focused fixes.
6. Run behavior/layout/fingerprint checks and visually inspect multiple complete sleeping cycles, including different aspect ratios.
7. Implement gameplay-only changes on `main` with the default font; do **not** regenerate typography or store images during development. Include the fix in a subsequent versioned release through the standard branch workflow.

## Acceptance criteria
- No visible incremental snapping/jumps in the eyes throughout repeated sleep/breathing cycles.
- Body breathing remains smooth and the intended eye placement/expression stays intact.
- Other reactions, hitboxes, and input behavior remain unchanged.
- Automated checks pass and visual evidence is recorded.

**Planning-only change:** This file does not authorize immediate implementation, release rebuild or publication.
