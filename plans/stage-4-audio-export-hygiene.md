# Stage 4 — Audio export hygiene

Owner approved the first Stage 4 release-readiness change. This change preserves the development event map, cue settings and audio files.

1. Compare enabled stream paths with the reviewed production list and confirm each source hash and license. A changed or newly enabled stream requires review and a manifest update before exporting.
2. Generate notices from Godot's bundled notices and the verified CureJe MIT text. Compare generated content with the checked-in notice before recording release validation.
3. Derive the preset exclusions from the approved list. Keep the runtime event map and exclude candidate metadata, dormant samples and their imports. In a pack, absent disabled samples are expected. Missing enabled samples remain startup errors.
4. Audit a disposable Godot resource ZIP using the target preset before the release export. Verify the event map, notices, and the import mapping and payload for each approved stream. Reject unexpected audio. Include the audit result in the export receipt.
5. Fingerprint audio, scenes and policy inputs. A changed fingerprint invalidates validation and prevents reuse of older export receipts.

## Export evidence

All resource ZIPs were produced by Godot 4.7.2. The baseline was `origin/main` at `abb8306`.

| Resource ZIP | Shipped audio streams | Candidate assignment file | Complete CureJe MIT notice |
| --- | ---: | --- | --- |
| Windows before | 31 | Present | Missing |
| Windows after | 18 | Absent | Present once |
| Android after | 18 | Absent | Present once |
| Android AAB Unsigned after | 18 | Absent | Present once |

All 18 after-export payloads have the same SHA-256 as the corresponding compiled streams in the baseline Windows ZIP. The event map is unchanged. The 13 removed streams and their imports are five dormant generated action effects (`jump_takeoff`, `run_return`, `sign_lower`, `sign_settle`, `squish`), seven unused voice samples (adult cat meow, dog whimper, kitten alternates 2–4, puppy alternates 2–3), and the noncommercial alligator study. The editor keeps those files available.

The release workflow audits a temporary ZIP produced from the requested target preset, then records the audited stream hashes and notice hash alongside the export receipt. The audio exclusions also apply to checked-in presets used directly from the editor. The typography helper adds its font notice to current include filters so it preserves the audio policy and platform settings. The Windows checks cover a disposable unsigned executable and resource ZIP. The Android checks cover Godot resource ZIPs for both presets. Native Android/iOS installation and other final store package checks remain separate.

## Source and license evidence

- The CureJe servo matches upstream `mech.wav` byte for byte. The committed notice matches the upstream LICENSE text, including the copyright and full MIT terms. [Asset register](https://github.com/CureJe/sedentary-reminder/blob/main/assets/audio/README.md) · [License](https://github.com/CureJe/sedentary-reminder/blob/main/LICENSE)
- The four CC0 effects match the local provenance register's redistributed kitten, puppy, chihuahua and notification files byte for byte. The original source pages identify CC0. The edited/denoised/trimmed derivatives' transformation histories rely on the redistributors' source credits. [Local source register](../audio/candidate_pack/SOURCE_REGISTRY.md)
- The other thirteen shipped streams are nine locally generated interaction effects and four original synthesized animation cues. The [release audio manifest](../release/audio-manifest.json) records every shipped source path, license and SHA-256.

To refresh notices after an approved source change, run `godot --headless --script release/tools/generate_notices.gd`. Pass `-- --check` to compare without writing. Run the release `sync` step on the release branch to refresh the export presets. To audit a disposable ZIP from a project checkout with Python, call `release.tools.release.inspect_audio_pack(path)` after `godot --headless --export-pack` with the target preset.
