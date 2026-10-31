# Typography update

The actual game now uses Space Grotesk Semibold for its title, and real Ink Free complete-phrase graphics for captions, speech, the NO sign and box label. The original game name, package IDs, gameplay and animation timings are unchanged. Sleep marks use Space Grotesk.

`scripts/typography.gd` is shared by the game and release-art generator. All 20 gameplay/reference captures and the feature graphic were regenerated directly from the revised renderer. `release/assets/manifest.json` fingerprints the gameplay script, typography helper, title font/variation, phrase metrics and ten phrase images. Apple images remain Windows-rendered references, not native iOS captures.

The Ink Free font file is not distributed, nor is it converted to an individual-glyph bitmap font. The installed font is used only in the Windows authoring step to create complete words/phrases. Microsoft's guidance explicitly permits complete-phrase graphic files in games: https://learn.microsoft.com/en-us/typography/fonts/font-faq . Space Grotesk is bundled under SIL OFL; its licence text is explicitly included by all export presets.

Validation:

- Behavior: 320,270 checks, zero failures.
- Release/input/layout: 237,076 checks, zero failures.
- Typography: 108 checks, zero failures.
- Release graphics/metadata/source fingerprints: 193 checks, zero failures.
- Real renderer: 18 reaction states and four phone/tablet aspect ratios inspected for text fit.

The prior audit reports describe prior build artifacts and remain historical. Existing APK/AAB/Windows binaries were not rebuilt and must not be presented as containing these font changes. The earlier asset inventory is retained in `release/history/assets-inventory-2026-10-29.json`; the current inventory describes the regenerated graphics.
