# Recoil reaction

Owner-approved milestone item 3. Recoil lasts 0.9 seconds and joins the lowest annoyance tier. It compresses toward the poke over 0.09 seconds, hops away with widened eyes by 0.27 seconds, returns to the same anchor by 0.63 seconds, and settles by 0.9 seconds.

Use the existing elapsed time and away direction. Limit the outward displacement to available room, keeping the original direction and the vertical lift. Use native scale tracks for the authored body and the controller pose for the fallback. Apply the existing transformed body hit tests. Recoil holds no new audio cues and retains normal reaction interruption and outgoing audio cancellation.

The focused test covers both directions and both renderers at 360- and 720-pixel viewport widths, checks the displacement cap and visible body hit, and verifies completion at the original anchor.
