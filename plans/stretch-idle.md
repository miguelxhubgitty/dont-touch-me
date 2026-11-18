# Stretch idle

Owner-approved milestone item 1. The body narrows and rises from its grounded pivot for 0.72 seconds, holds through 0.99 seconds, and relaxes by 1.8 seconds. Eyes squint while stretched and retain natural blink. The clip adds no sound.

At launch and after an accepted poke, use an independent random draw to select no special idle (20%), Stretch (40%) or the reserved Humming slot (40%). Stretch becomes eligible at 4.5 seconds plus up to 1.8 seconds of jitter. The Humming slot plays normal breathing until its own PR lands. Reuse the existing inactivity clock. Consume the opportunity when it becomes due and starts, or when insufficient time remains before sleep. A reaction, sleep, an offscreen return or a resize ends an active stretch. A background miss leaves it alone.

- **Controller:** Ease up, hold and ease down using elapsed inactivity since activation. Blend the fallback pose and its hit test around the existing anchor.
- **Authored renderer:** Sample native breathing at its usual phase and blend its scale toward the same stretched pose. Use the existing eye and transformed-outline paths.
- **Verification:** Force a deterministic opportunity in both renderers, inspect the scale/eyes and anchor, test misses and pokes at the extended silhouette, then confirm return to breathing and sleep at 18 seconds. The standard animation runner includes the focused Stretch fixture.

The later [Stretch refinement](stretch-refinement.md) sets the grounded peak to 0.72 × 1.45 and fully closes both eyes during the hold.
