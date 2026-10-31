# Don't Touch Me — Public Alpha v0.1.0-alpha

Published **October 31, 2026** (America/New_York), following the owner's explicit authorization to make the existing project public. Live URL: **https://wandiel.itch.io/dont-touch-me**. Publisher: WANDIEL; itch.io account wandiel; project ID 5273390. Page release status stays In development. Pricing is No payments: no donations, purchases or paid downloads.

| Channel | User version | Upload | Completed build | Page behavior |
|---|---|---|---|---|
| html5 | v0.1.0-alpha | 20184236 | 2263122 | Run game in browser |
| windows | v0.1.0-alpha | 20184231 | 2263119 | Windows ZIP download, Windows platform selected |

Both pre-existing uploads belong to the same listing. Nothing was uploaded again, rebuilt or regenerated for publication. No game scripts, animations, audio, counters, trust/customization mechanics, sleeping-eye behavior, fonts or release artwork were modified. Subsequent changes belong to separately versioned releases. Main and aesthetic branches are untouched.

## Verification

- Butler authenticated access and completed versions/build IDs checked. Original package checksums remain valid.
- Reviewed title, existing cover and five screenshots, Alpha description, WANDIEL branding, approved short tagline, In development, No payments and platform/embed settings. Added functioning support/privacy links and a clear browser-hosting disclosure to the store page.
- Saved Public visibility. An independent HTTP request with no login cookies returned 200, the expected game title/version and Windows file, without an owner panel or secret URL.
- Public Run game launched the same HTML5 build and visibly rendered the blob. This is a desktop hosted-browser startup check, not physical-device or exhaustive compatibility certification.
- Downloaded Windows ZIP directly from the public page without payment. ZIP integrity passed; every contained file (executable, README and both license notices) is byte-identical to the original validated package. Executable hash matches the build manifest. itch.io repackages archives, so ZIP-container hashes alone are not a valid round-trip comparison.
- Original Windows ZIP SHA-256: `42a43d68e9c0dd2af46da6dfa6f74d32b4e4c2242a68771dc046900134bcbdc9`. Windows remains unsigned; no new native runtime certification is claimed.

## Support/privacy review and outstanding issue

The existing support page https://miguelxhubgitty.github.io/dont-touch-me/, privacy page https://miguelxhubgitty.github.io/dont-touch-me/privacy.html and public GitHub issue tracker returned HTTP 200. The hosted game privacy page still says “Last updated: October 29, 2026. Applies to version 1.0.” Its native/offline description is consistent with the game, but the label predates this Alpha and does not describe itch.io browser hosting. The itch page explicitly distinguishes native offline play from itch.io hosting, links itch.io's own privacy policy, and notes the older label. Updating that hosted policy is an outstanding documentation follow-up; it was not silently changed or claimed current. Never post private support details to public GitHub issues.

The website launch link is handled separately in the private WANDIEL website repository, following its feature branch, build, preview and production-verification workflow. No DNS, email, registrar, repository-visibility or hosting-account setting change is required.

## Future uploads

The existing adapter remains a draft-only uploader. It now refuses push operations when its registry marks the listing published, even if the draft-confirmation flag is supplied. Future public updates need their own version, validation and publication authorization; never reuse a draft-confirmation flag against this live Alpha. The `draft_uploads` block is retained as historical provenance for the same channel builds. Old preparation reports describe their original unpublished snapshot, not the current live status.
