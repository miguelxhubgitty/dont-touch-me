# Changelog

## 0.1.0-alpha — GitHub public prerelease — October 31, 2026

- Publish the existing Windows, Linux, macOS, HTML5 ZIPs, debug-signed Android testing APK and unchanged SHA256SUMS with explicit owner authorization. Preserve the existing tag and all artifact bytes; exclude the unsigned AAB. Verify every public download anonymously against its SHA-256.
- Label Windows unsigned, Linux not native-tested, macOS unsigned/not notarized/not native-tested and Android testing-only. Preserve existing itch.io uploads; no gameplay, typography, graphics or new builds.
- Integrate one-approval GitHub publishing into the release command, with draft staging, tag checks, named-asset digest reuse, no replacement/deletion, safe retries, append-only attempt receipts and public-download verification. Record exact verified URLs/hashes and document future release use.

## 0.1.0-alpha — itch.io public release — October 31, 2026

- Publish the existing same-project HTML5 and Windows Alpha builds with explicit owner approval; retain In development and No payments. Verify anonymous access, browser startup and downloaded Windows file bytes without rebuilding or changing gameplay/artwork.
- Record public URL, date, channel/upload/build IDs and privacy/support review. The hosted policy's older version label remains documented; the store page now explains itch.io browser hosting and links both policies/support.
- Preserve draft-upload history and make the draft-only adapter refuse pushes to a published listing. Future game changes require subsequent versioned updates.

## Unreleased — itch.io draft automation

- Verify the existing Windows upload without duplicating it; enable its missing Windows platform tag, preserve HTML5 browser play and record package checksum/download configuration on the same free draft listing.
- Add an explicit official-Butler adapter for existing validated Windows/html5 packages, four reusable channels, local checksum/provenance guards and append-only attempt receipts. Reject Linux/macOS uploads until native runtime validation passes.
- Prepare draft page material from the shared catalog, document No payments/draft review, credential handling, channel verification and separate public approval. Preserve Alpha binaries, graphics, fonts and gameplay.
- Verify Butler v15.32.0 authentication as wandiel and create draft project 5273390 with existing artwork and No payments. Initial upload was rejected by itch.io pending account-email verification; no accepted build or public publication is claimed.
- After owner email verification, upload and verify completed Windows build 2263119 and HTML5 build 2263122 at v0.1.0-alpha; enable private browser play and Windows download. Preserve Draft/No payments and remove the requested risk phrase from the itch-specific tagline. No public release occurred.

## 0.1.0-alpha — Public Alpha (prepared, not published)

- Create `release/v0.1.0-alpha` from gameplay main and apply the reviewed typography layer without changing gameplay or application identifiers.
- Centralize free-release descriptions, publisher/content/privacy information, branding, notes and notices; add a 25-platform distribution registry with explicit prerequisites and unpublished state.
- Add reusable local validation, six-format export, packaging, provenance/checksum, cache reuse and upload-checklist tooling. Record iOS as unavailable without Mac/Xcode/signing prerequisites.
- Finalize shared real-game captures once and add the 315:250 itch cover, reusing approved phrase graphics.
- Prepare Windows/Web ZIPs, Android debug APK and unsigned AAB, Linux ZIP and unsigned Universal macOS ZIP. Validate Windows and Web runtime smoke checks; retain honest native/signing/store limitations.
- Backport only focused shared tooling to main; preserve basic-font development. No binaries uploaded, accounts changed or stores submitted.

See `release/ALPHA_REPORT.md` for artifact paths, validation and remaining prerequisites.

## Unreleased — development/release workflow

- Preserve `c7397822` as the basic-font gameplay restoration on `main`, and `c0bfa4e` as the original approved typography revision on `aesthetic/typography-v1`.
- Add a guarded, repeatable three-way typography integration for clean `release/<version>` branches. Reuse cached phrase graphics; never replace new gameplay with an old tree or merge presentation wholesale back to `main`.
- Defer typography/store captures to one explicit finalization pass. Authoring scripts require `--finalize-release`; normal development runs behavior/layout checks without generating marketing images.
- Make source fingerprints portable across LF/CRLF checkouts while retaining byte-exact binary checks and historical manifests. Add regression coverage and preserve existing generated assets.
- Document release validation, fresh exports, independent game versioning and annotated milestone tags without publication or history rewriting.

Historical typography work remains in commit `c0bfa4e` and the aesthetic branch; historical build/audit reports remain unchanged. No finished release or new version tag is created by this workflow change.
