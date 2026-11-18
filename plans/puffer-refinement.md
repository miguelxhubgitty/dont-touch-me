# Puffer refinement

Owner approved the pose plan. Merge review is separate.

The current reaction expands slowly to 1.18 and lasts 1.8 seconds. Contract both axes to 0.81 by 0.18 seconds, inflate both axes to 1.35 by 0.27 seconds, hold through 0.90 seconds, then retract and deflate by 1.35 seconds. Author those same body keys in the native scene and use the existing reaction elapsed time for the procedural pose and spikes. Spike extension stays zero during contraction, rises with inflation, and retracts during recovery. Use the body-only hit transform for both renderers, including at 360 pixels wide. Test both pose extrema, hold, recovery, and body versus spike touches.
