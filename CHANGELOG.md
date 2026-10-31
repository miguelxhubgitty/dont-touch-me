# Changelog

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
