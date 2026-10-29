# Don't Touch Me

A tiny, offline comedy about a blob and its personal space. Built with **Godot 4.7.2 stable**, GDScript, procedural shapes, and the engine's bundled font. No dependencies or downloaded assets.

## Open and play

Import `project.godot` in Godot 4.7.2 stable and press **F6** in `main.tscn`, or **F5** to play the project. Click or tap the blob. Touching the background does nothing. Persistent pokes reveal increasingly dramatic reactions; leave it alone to let it relax and eventually sleep. Poking a sleeping blob wakes it with a special reaction. There are no menus or scores.

The portrait canvas uses a 720 × 1280 reference with expanding canvas stretch, including tall phones and tablets. Desktop preview is 432 × 768. Mouse and native touchscreen paths share the same silhouette hit test and do not emulate duplicate events. No sound, network access, permissions, saved personal data, ads, or purchases.

## Implementation

`main.tscn` and `scripts/blob.gd` contain the complete game. One animation clock owns pose, expressions, props, and speech; taps can interrupt short reactions while box and run reactions always finish. Annoyance is clamped to 0–100, with nonrepeating random choices in four tiers. Relaxation starts after 2.5 seconds, sleep after 24 seconds. Focus loss pauses the clock. Resizing cancels motion safely. There are 15 regular reactions plus a special wake reaction.

## Local checks

From this folder (substitute the path to your Godot executable):

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/behavior.gd
godot --path . --script tests/render.gd
```

The behavior suite checks tier boundaries, random coverage, repetition avoidance, all animation lifecycles, transformed hitboxes, visible bounds, rapid taps, escape recovery, relaxation, sleep/wake, input paths, and resizing. The rendering check produces an ignored `test-output/reactions.png` contact sheet using a real rendering window. These checks are not a substitute for testing on physical phones.

## Android / future iOS

An **unsigned**, ARM64 Android preset is included. Install matching Godot export templates and configure the Android SDK and JDK in the editor before exporting. Create `builds/android/` if needed. The application ID is `com.littlebutterflyproductions.donttouchme`; version is `1.0.0` (code 1). The vector application icon is generated locally. No signing credentials are required to open or test the project; installing an APK on a device requires a signed debug or release build. Turn signing on and configure your own debug keystore when you are ready for device testing. Keystores, local credentials, and builds are ignored by Git.

iOS uses the same GDScript/Compatibility renderer and portrait layout. An iOS export will require matching templates, macOS/Xcode and your own signing configuration. No publishing setup is included.
