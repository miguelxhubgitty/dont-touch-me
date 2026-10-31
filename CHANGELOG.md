# Changelog

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
