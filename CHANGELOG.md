# Changelog

## Unreleased — development/release workflow

- Preserve `c7397822` as the basic-font gameplay restoration on `main`, and `c0bfa4e` as the original approved typography revision on `aesthetic/typography-v1`.
- Add a guarded, repeatable three-way typography integration for clean `release/<version>` branches. Reuse cached phrase graphics; never replace new gameplay with an old tree or merge presentation wholesale back to `main`.
- Defer typography/store captures to one explicit finalization pass. Authoring scripts require `--finalize-release`; normal development runs behavior/layout checks without generating marketing images.
- Make source fingerprints portable across LF/CRLF checkouts while retaining byte-exact binary checks and historical manifests. Add regression coverage and preserve existing generated assets.
- Document release validation, fresh exports, independent game versioning and annotated milestone tags without publication or history rewriting.

Historical typography work remains in commit `c0bfa4e` and the aesthetic branch; historical build/audit reports remain unchanged. No finished release or new version tag is created by this workflow change.
