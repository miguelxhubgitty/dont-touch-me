# Gameplay first; typography at release time

## Branch responsibilities

- `main`: the latest gameplay, Godot's bundled fallback font, fast behavior/layout checks. No Space Grotesk/Ink Free runtime resources or automatic image generation.
- `aesthetic/typography-v1`: the approved presentation snapshot originally committed at `c0bfa4e`. Tooling-only portability fixes may follow it. Preserve the original commit and artwork; do not merge future gameplay into this branch or develop gameplay here.
- `release/<version>`: fork current `main`, apply the presentation patch, finalize assets/builds, then tag this branch's finished commit. Future releases always start from `main`, not a previous release/aesthetic branch.

`c0bfa4e` is already an ancestor of `main`; `c7397822` restored the basic presentation without deleting that history. A normal merge of the aesthetic branch therefore does not reapply the fonts. Do not undo `c7397822`, copy its entire old gameplay tree, or depend on a wholesale branch merge.

## 1. Normal gameplay development

Use Godot 4.7.2 and substitute the executable path for `godot` below.

```powershell
git switch main
git fetch origin main aesthetic/typography-v1
git merge --ff-only origin/main
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/behavior.gd
godot --headless --path . --script tests/release.gd
godot --headless --path . --script tests/fingerprints.gd
```

Check every command's exit code. Commit/push focused gameplay changes normally. A rendering contact sheet (`tests/render.gd`, real renderer) is optional when poses/layout change; it is not part of the routine text/gameplay loop. Do not run either authoring generator, package screenshots or rebuild marketing assets on every edit.

Existing store images and manifests are historical snapshots. `validate_package.gd` is a release gate, not a daily gameplay test: a source-fingerprint mismatch after gameplay edits is expected until finalization. Never update a capture fingerprint by hand just to silence the gate.

## 2. Start a release from current gameplay

Finish and commit gameplay first; ensure the working tree is clean. Replace `1.0.0-beta.1` with the selected game version; use a new branch/tag name if it already exists.

```powershell
git fetch origin main aesthetic/typography-v1
git switch main
git merge --ff-only origin/main
git switch -c release/1.0.0-beta.1
pwsh -File release/tools/apply_aesthetics.ps1 -CheckOnly
pwsh -File release/tools/apply_aesthetics.ps1
git diff --cached --stat
git diff --cached -- scripts/blob.gd tests/release.gd export_presets.cfg
git commit -m "Apply typography-v1 presentation to release/1.0.0-beta.1"
```

The helper requires a clean `release/*` branch and the correct game remote. It applies a binary-capable **three-way patch**, based on the fixed basic-font integration commit `5be3a20` and the fetched aesthetic tip. This base includes shared tooling fixes; never replace it with moving `main`, since that would put later gameplay changes into the inverse side of the patch. It does not restore whole gameplay files, change app IDs/versions, copy old store captures, create commits, run generators, export or publish. Existing complete-phrase PNGs are reused immediately; copying them is not regeneration.

Review the presentation-only hunks and the aesthetic source SHA printed by the helper. New gameplay elsewhere in `blob.gd` is preserved by the merge. If future edits overlap, stop and resolve them on the release branch; preserve current gameplay and port the font/drawing/width changes into it. Do not take the entire aesthetic version of `blob.gd`, `tests/release.gd` or export settings. Preflight performs the merge in a temporary index and rejects conflicts before changing working files. On any failed apply, inspect `git status` before doing anything else; the helper never resets or discards work. `-CheckOnly` is the nonmutating preflight.

When changing workflow tools, commit them locally and run `pwsh -File tests/workflow.ps1 -AestheticRef aesthetic/typography-v1`. It creates an ignored local clone, simulates later gameplay/version changes, and verifies integration, branch/dirty-tree/reapplication guards, and untouched captures. It does not contact GitHub or generate assets.

Run behavior, release, fingerprint and typography suites after integration. If dialogue/captions changed, reconcile the authoring `PHRASES` list and typography coverage test before the finalization pass. Keep the title and sleep marks on Space Grotesk; complete phrases use Ink Free graphics. No proprietary Ink Free font file or glyph atlas belongs in Git/exports.

## 3. One finalization pass, after gameplay/text freeze

Use a Windows authoring machine with a licensed installed Ink Free font and a working real Godot renderer. Update release version/build numbers, listing/privacy/support metadata and intended targets before capturing. Keep application identifiers stable unless an explicit migration is required.

```powershell
# These two commands need a real renderer, not --headless.
godot --path . --script release/tools/generate_typography.gd -- --finalize-release
godot --headless --path . --editor --import --quit
godot --path . --script release/tools/generate_assets.gd -- --finalize-release
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/behavior.gd
godot --headless --path . --script tests/release.gd
godot --headless --path . --script tests/fingerprints.gd
godot --headless --path . --script tests/typography.gd
godot --headless --path . --script release/tools/validate_package.gd
```

Stop on any failure. The first generator renders complete handwritten phrases; the second captures actual current gameplay and fingerprints its source plus typography. Both require the explicit authoring flag. Reuse cached phrases when wording/font treatment is unchanged; no need to regenerate them merely because unrelated gameplay changed. Refresh store captures once for the final gameplay revision. A genuine late visual/text change requires a new finalization pass; never pretend stale assets match.

Refresh `release/assets-inventory.json` **after** captures and metadata are final. Preserve the previous inventory under `release/history/` when establishing a new release. For each existing inventory entry, recompute SHA-256 using its declared mode (`utf8-lf` = UTF-8 text with CRLF converted to LF; `binary` = raw bytes), reconcile new/removed files, then run `pwsh -File release/tools/verify_inventory.ps1`. Do not rewrite historical reports or claim native iOS captures from Windows renders.

New capture manifests declare `text-lf-binary-raw-v1`: source text is hashed with LF endings and binary assets byte-for-byte. Legacy raw LF/CRLF source hashes remain verifiable without altering the saved captures. Actual content changes still fail validation.

## 4. Export, validate and tag the finished release

Create the ignored output directories, then export fresh artifacts from this release branch. For the existing Windows preset:

```powershell
New-Item -ItemType Directory -Force builds/windows
godot --headless --path . --export-release "Windows" builds/windows/DontTouchMe.exe
```

Verify the actual preset name in `export_presets.cfg` before running. Run the Windows executable's automated 120-frame smoke check (`DontTouchMe.exe --headless --quit-after 120`), package it with current play instructions and `THIRD_PARTY_NOTICES.txt`, and also include the Space Grotesk OFL notice. Record artifact SHA-256, engine version, source commit and signing status in ignored build metadata. Android release builds need authorized upload signing and platform validation; the unsigned preparation preset is not a production upload. Do not present historical APK/AAB/EXE files as current.

Commit the finalized source/assets, changelog and validation report first. Set `$version` to the approved game version and check the tag locally and remotely before creating it:

```powershell
$version = '1.0.0-beta.1'
git status --short
git show-ref --verify "refs/tags/v$version"
git ls-remote --tags origin "refs/tags/v$version" "refs/tags/v$version^{}"
# Only continue if the tree is clean and BOTH tag checks confirm no existing tag.
git tag -a "v$version" -m "Don't Touch Me $version"
git push -u origin "release/$version"
git push origin "v$version"
git ls-remote origin "refs/heads/release/$version" "refs/tags/v$version" "refs/tags/v$version^{}"
```

Pushing a branch/tag is version control, not authorization to create a public GitHub Release, upload binaries, deploy a site, or submit to stores. Check any future CI automation before pushing tags. Keep signed artifacts/credentials outside Git.

Backport genuine release bug fixes to `main` as focused basic-font changes, and rerun gameplay checks. Do not merge the release branch wholesale into `main`. Keep the aesthetic snapshot as a reusable reference. Use a new `aesthetic/typography-v2` for a materially changed treatment and explicitly review/update the integration allowlist/base; never move the old branch history or tags to hide changes.
