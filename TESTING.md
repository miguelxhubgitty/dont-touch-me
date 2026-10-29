# Validation — 2026-10-29

Engine: `4.7.2.stable.official.ed1daf0bf`, Windows, OpenGL Compatibility renderer on NVIDIA GeForce RTX 3080.

- Headless editor import and GDScript loading: passed, exit 0. The editor reported missing Android SDK build-tools; no project or script errors remained.
- Automated behavior suite: **320,266 checks, 0 failures**, exit 0. Includes all 16 reactions, tier boundaries and random coverage, repetition exclusion, animation completion, silhouette hitboxes, pose visibility at center and movement edges, tap spam, escape completion, relaxation, sleep/wake, mouse/touch handler paths, release rejection, and portrait/tablet resizing.
- Actual main scene: ran 180 frames using the Windows OpenGL renderer and exited 0 without errors.
- Rendered 18 states (intro, 15 normal reactions, wake, sleep) using the actual Windows renderer. Generated and visually inspected the contact sheet; speech, sign, box, eyes, squash/stretch, jump and offscreen peek rendered correctly.
- Git whitespace validation: passed before commit.

Not tested: manual desktop playthrough, physical touchscreen interaction, Android APK export/install, or iOS export. Automated input tests exercise the same game handlers but do not establish physical device usability. Android requires local SDK/JDK/templates and a signed debug build for installation. iOS export requires macOS/Xcode and signing configuration.

No known gameplay or GDScript errors remain from these checks.

## Android toolchain follow-up — 2026-10-29

Installed and configured on the development PC: Temurin OpenJDK 17, Android command-line tools, Platform-Tools, SDK Platform and Build-Tools 35 and 36, NDK r28b, CMake 3.10.2, and Godot 4.7.2 stable export templates. Java, command-line tools, and template archives were verified against official SHA-256 checksums. The installed Godot template targets Android SDK 36, so matching SDK 36 packages were added beyond the versions listed by the online setup guide.

The first Android export identified a required project setting: `rendering/textures/vram_compression/import_etc2_astc`. Enabled it and successfully exported an ARM64 Android debug APK. Package metadata confirms the correct application name and ID, version 1.0.0, minimum SDK 24, target SDK 36, and no requested permissions. A standard local debug key is used for the installable test copy; signing credentials and APKs remain outside Git. Physical Android installation/play and iOS export remain untested.
