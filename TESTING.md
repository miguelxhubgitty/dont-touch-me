# Validation — 2026-10-29

Engine: `4.7.2.stable.official.ed1daf0bf`, Windows, OpenGL Compatibility renderer on NVIDIA GeForce RTX 3080.

- Headless editor import and GDScript loading: passed, exit 0. The editor reported missing Android SDK build-tools; no project or script errors remained.
- Automated behavior suite: **320,266 checks, 0 failures**, exit 0. Includes all 16 reactions, tier boundaries and random coverage, repetition exclusion, animation completion, silhouette hitboxes, pose visibility at center and movement edges, tap spam, escape completion, relaxation, sleep/wake, mouse/touch handler paths, release rejection, and portrait/tablet resizing.
- Actual main scene: ran 180 frames using the Windows OpenGL renderer and exited 0 without errors.
- Rendered 18 states (intro, 15 normal reactions, wake, sleep) using the actual Windows renderer. Generated and visually inspected the contact sheet; speech, sign, box, eyes, squash/stretch, jump and offscreen peek rendered correctly.
- Git whitespace validation: passed before commit.

Not tested: manual desktop playthrough, physical touchscreen interaction, Android APK export/install, or iOS export. Automated input tests exercise the same game handlers but do not establish physical device usability. Android requires local SDK/JDK/templates and a signed debug build for installation. iOS export requires macOS/Xcode and signing configuration.

No known gameplay or GDScript errors remain from these checks.
