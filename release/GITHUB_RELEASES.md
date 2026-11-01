# GitHub Releases — existing artifacts, one approval

Follow BRANCH_WORKFLOW.md, WORKFLOW_VALIDATION.md and RELEASE_SYSTEM.md. GitHub publication is a separate explicit owner action; neither source/tag pushes nor `prepare`/website deployments publish binaries. Preserve the basic-font main/aesthetic/release separation. Never merge release presentation into main.

## Prepare and approve

1. Finalize a new version normally, with the existing local release system. This adapter does not export, regenerate, repackage, sign or alter files.
2. Use an existing immutable version tag. Check its remote commit against `builds/v<version>/manifest.json` → `repository_commit`. Never move or replace it.
3. Run `python release/tools/github_release.py prepare`. It derives the version from the canonical catalog; checks saved manifest hashes, original SHA256SUMS entries and ZIP/APK integrity; and selects every available built Windows/Linux/macOS/Web ZIP and Android debug APK. Unavailable formats are skipped. Failed/invalid formats stop the operation. Unsigned AABs are never selected.
4. Obtain **one explicit release approval** covering this complete artifact list and public visibility. No additional platform execution is required by the publisher; preserve the existing validation/signing limitations honestly. Approval is not inferred from a command or a source push.

From the corresponding reviewed `release/*` branch, run one command:

```powershell
python release/tools/release.py github-release --approval "actual owner approval reference for this version and all packages" --expected-tag-commit FULL_EXISTING_TAG_COMMIT
```

The underlying `python release/tools/github_release.py publish` command accepts the same flags. Tooling can be reviewed on a focused branch based on the release, then merged back normally. Carry only tooling/docs/tests/configuration into future gameplay/release workflows; never copy old gameplay or artwork. Existing Alpha tag stays at `d61c86568b40c23a291db7aa2757ffe82e1896e8` even as later documentation/tooling commits are added.

## Authentication and safety

Uses GitHub's official REST release/asset API with standard-library Python. Uses existing Git Credential Manager authentication, or `GH_TOKEN`/`GITHUB_TOKEN` from the local environment. Never print, store or commit tokens. Repository must already be public; this adapter never changes visibility. Authenticated calls are restricted to GitHub API/upload hosts; authorization is stripped on redirects. GitHub's ordinary source-code archives are provided automatically, not additional generated game builds.

The adapter creates a draft prerelease against the existing tag, uploads all selected artifacts and the **unchanged original SHA256SUMS**, verifies GitHub SHA-256 digests/sizes, checks the tag again, then makes it public with `prerelease: true` and `make_latest: false`. An existing conflicting release or different asset bytes stops safely; no asset deletion, replacement or tag mutation exists. Do not treat an unsuccessful command as proof nothing was uploaded/published: inspect receipts and resume.

## Retry and verification

Rerun the **same command with the same approval** after a partial failure. Matching named remote assets are reused after digest/size verification; missing assets upload once. Mismatches, unexpected assets, incomplete uploads and duplicate names stop for inspection rather than overwrite. A network timeout after acceptance is reconciled using the same release/tag and asset names. There are no blind upload retries or automatic new tags.

After publication every file is downloaded anonymously and hashed byte-for-byte. Only then is `builds/v<version>/github/publication.json` written. `github/attempts.jsonl` is append-only evidence of attempts, uploads, reuse and verification; keep it ignored. A public release can exist even if later anonymous verification fails: report that state and retry, never recreate it. Public notes include the package checksums and explain that original SHA256SUMS uses local subdirectory paths and also lists local handoff files not uploaded.

After successful verification, update `release/distribution/platforms.json` → `github-releases.publication` from the receipt (URL, exact version, date, tag/commit, asset URLs/hashes). Commit a non-secret publication report and changelog normally. Only verified public URLs belong on the website. GitHub availability is independent of itch.io; existing itch channels/page/pricing are untouched.

## Labels and test boundaries

- Windows: unsigned ZIP; retain recorded exported-executable smoke evidence.
- Web: HTML5 ZIP, not a directly executable desktop game; host via HTTP(S). Existing itch.io browser play remains separate.
- Linux: cross-exported ZIP, **not native-tested**.
- macOS: **unsigned, not notarized, not native-tested** universal ZIP.
- Android: **debug-signed testing APK**, not a production/store-signed build; no new device testing claimed.
- Android unsigned AAB: excluded, not an installable game. iOS: no existing distributable artifact.

Run `python -m unittest discover -s tests -p test_github_release.py` and the existing `test_distribution.py` suite. Publishing tests exercise approval/tag guards, checksum/archive preparation, matching-asset reuse, verification and refusal to replace different bytes. They do not claim new native platform testing.

Official references: https://docs.github.com/en/rest/releases/releases and https://docs.github.com/en/rest/releases/assets.
