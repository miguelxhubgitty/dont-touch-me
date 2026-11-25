# iOS Alpha packaging correction design — 2026-11-21

Reviewed starting commit: bfbea0e84bd16d14d86ed25ca7d1982092c13e91 (PR #46).

The first native Simulator build and unsigned arm64 archive succeed, but the linker reports that Godot 4.7.2 and MoltenVK objects require iOS 14.0 while the preset declares 13.0. Advertising iOS 13 support is therefore unsupported by these templates.

Change only the iOS Alpha minimum deployment target to 14.0 and update the handoff. Do not alter frozen gameplay, artwork, Android presets, identifiers or provisional version/build. Team selection stays in the external local scratch copy. Keep the simulator-only x86_64 architecture override in the generated local Xcode project, not in game source.

Validation: re-export with the existing preset, build for Intel iPhone Simulator and archive arm64 without signing or provisioning updates. Check the compiled bundle minimum OS, version, privacy manifest and icon. Require zero deployment-target mismatch warnings. Existing behavior, release, fingerprints, typography, package and privacy suites must pass. Native interaction results are reported separately from synthetic tests. An unsigned archive is a compilation result, not an upload-ready or Apple-validated distribution.

The generated Info.plist also contains empty camera, microphone and photo usage strings. The frozen app does not request these permissions. Remove only these empty, unused keys from the generated local project before the final local build; document the reproducible post-export step. Do not invent permission purposes. Record remaining signing, Apple records and physical-device blockers without creating external records.
