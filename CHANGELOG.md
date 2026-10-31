# Changelog

## Unreleased — reusable typography workflow

- Preserve the original `c0bfa4e` presentation snapshot and all generated artwork without regeneration; add the shared development/release workflow and guarded integration helper.
- Correct LF/CRLF source fingerprint portability without rewriting historical manifests; keep binary checks byte exact.
- Require explicit finalization flags for authoring generators. Validate current gameplay dialogue/captions against cached handwritten phrases so new text cannot silently use a fallback font.
- Leave gameplay, runtime typography settings and existing font/phrase/store image bytes unchanged.

## Unreleased — Game and artwork typography

- Use Space Grotesk Semibold for the actual in-game title and promotional title.
- Use real Ink Free for fixed intro captions, character dialogue, the NO sign and the box label, supplied as complete phrase images. Do not redistribute the Windows font or a glyph atlas.
- Share text metrics between game drawing and bubble sizing; preserve all gameplay behavior, reactions, timing, input, title and package identifiers.
- Regenerate the feature artwork and all 20 gameplay/reference captures from the actual game renderer.
- Add typography tests and source fingerprints for phrase images, font variation and text layout.
- Existing exported binaries remain historical and require a new export to include these changes.
