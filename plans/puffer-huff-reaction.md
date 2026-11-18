# Puffer-huff reaction

Owner-approved milestone item 4. Puffer-huff lasts 1.8 seconds and joins the second annoyance tier. Eyes narrow by 0.18 seconds. The body inflates and attached spikes extend by 0.45 seconds, hold until 1.08 seconds, then retract by 1.35 seconds. The body deflates by 1.8 seconds.

Both renderers use the existing controller time and visible body transform. The shared spike drawing samples each renderer's own contour, with triangle bases overlapping the body. The same body hit test is used throughout. Spike tips outside that body remain background misses. Interruptions clear the spikes through the normal pose update. New audio cues are deferred.

The focused test checks the phase boundaries, inflated body hits, spike-tip misses, and interruption at 360- and 720-pixel widths in both renderers.

The later [Puffer-huff refinement](puffer-refinement.md) replaces the 1.8-second motion with a 1.35-second contraction, rapid inflation, hold and recovery.
