# Changelog

## 0.1.0-alpha — GitHub public prerelease — October 31, 2026

- Publish the existing Windows, Linux, macOS, HTML5 ZIPs, debug-signed Android testing APK and unchanged SHA256SUMS with explicit owner authorization. Preserve the existing tag and all artifact bytes; exclude the unsigned AAB. Verify every public download anonymously against its SHA-256.
- Label Windows unsigned, Linux not native-tested, macOS unsigned/not notarized/not native-tested and Android testing-only. Preserve existing itch.io uploads; no gameplay, typography, graphics or new builds.
- Integrate one-approval GitHub publishing into the release command, with draft staging, tag checks, named-asset digest reuse, no replacement/deletion, safe retries, append-only attempt receipts and public-download verification. Record exact verified URLs/hashes and document future release use.


## Unreleased — development/release workflow

- Preserve `c7397822` as the basic-font gameplay restoration on `main`, and `c0bfa4e` as the original approved typography revision on `aesthetic/typography-v1`.
- Add a guarded, repeatable three-way typography integration for clean `release/<version>` branches. Reuse cached phrase graphics; never replace new gameplay with an old tree or merge presentation wholesale back to `main`.
- Defer typography/store captures to one explicit finalization pass. Authoring scripts require `--finalize-release`; normal development runs behavior/layout checks without generating marketing images.
- Make source fingerprints portable across LF/CRLF checkouts while retaining byte-exact binary checks and historical manifests. Add regression coverage and preserve existing generated assets.
- Document release validation, fresh exports, independent game versioning and annotated milestone tags without publication or history rewriting.

Historical typography work remains in commit `c0bfa4e` and the aesthetic branch; historical build/audit reports remain unchanged. No finished release or new version tag is created by this workflow change.
