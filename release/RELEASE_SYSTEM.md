# Local multi-platform release system

The core system prepares free Public Alpha artifacts offline. The separately invoked [itch.io Butler adapter](ITCH_PUBLISHING.md) can upload verified packages to an operator-reviewed draft; it never publishes a page. Follow `../BRANCH_WORKFLOW.md` first: current gameplay from main, a fresh `release/v<version>` branch and the reviewed aesthetic patch. Never merge release presentation into main.

## Canonical editable information

- `catalog/game.json`: version/build numbers, publisher, free/no-payments policy, descriptions, asset references, content/rating information, privacy/support, notices and branding. Keep the current legal name until an approved rename. Ratings and developer-account verification are not claimed complete.
- `catalog/RELEASE_NOTES.md`: player-facing notes.
- `distribution/platforms.json`: 25 destinations, official submission/portal URLs, accepted formats, references to shared material, platform-only overrides, prerequisites, publication status/live URL and last successfully published version. Unknown console details remain explicitly unverified.
- `assets/`: shared real-game screenshots and icon/feature files, generated once near finalization. `catalog/branding/` supplies the 315:250 itch cover. Apple-sized images are reference renders, not native iOS captures.
- Existing `listing.json` and `STORE_LISTING.md` are generated compatibility views. Edit the catalog, then run `sync`, rather than hand-editing multiple listings.

Python 3.10+ standard library and Godot 4.7.2 are required. Commands below run from the game repository root. Replace `python`/`godot` with installed executable paths or set `GODOT`. No runtime or pipeline dependencies need downloading. Optional Web smoke testing uses an already installed Node, Playwright and Chromium-based browser (`NODE_PATH` or `PLAYWRIGHT_MODULE_PATH` can identify the installed module; `BROWSER_EXECUTABLE` can select a browser).

```powershell
python release/tools/release.py sync
python release/tools/release.py doctor --godot <godot-executable>
# After text/gameplay freeze: reuse cached phrases and capture the final artwork once.
python release/tools/release.py finalize-assets --godot <godot-executable>
python -m unittest discover -s tests -p test_distribution.py
# Review and commit source, configuration and finalized shared assets before export.
python release/tools/release.py prepare --godot <godot-executable>
python release/tools/release.py web-test --godot <godot-executable>
python release/tools/release.py report
python release/tools/release.py verify
```

`prepare` validates gameplay/layout/typography, source-to-capture fingerprints, metadata and saved assets, then attempts each available export, packages it and writes all platform checklists. `--targets windows web android-apk android-aab linux macos ios` can restrict export attempts. Individual `validate`, `export`, `package` and `report` commands support resuming a partial run. Unavailable targets are recorded; exporter failures return a nonzero exit code and retain logs. A produced file alone never establishes a successful export.

`finalize-assets` reuses the saved finalization receipt when inputs match. It does not regenerate Ink Free phrases; if wording changes, update the authoring list, explicitly run `generate_typography.gd -- --finalize-release` once, import and validate typography before the capture pass. Original inventories are archived; do not refresh hashes to conceal stale screenshots.

`export` requires a clean source tree and current validation. Cache receipts combine runtime/config, engine executable and export-template fingerprints and verify output bytes before reuse. Shared metadata changes can require new validation/packaging without another engine export. Package checksums are verified before reusing ZIPs. Changed/corrupt artifacts are never treated as reusable successes. No platform-specific duplicate engine exports are performed.

## Output structure

Everything large/generated stays ignored under `builds/v<version>/`:

```text
windows/   web/   android/   linux/   macos/   ios/
shared/                 one curated metadata/art/notice handoff
checklists/<platform>.md
logs/                   per-stage logs and optional browser evidence
manifest.json           build source commits, checks, signing, raw/package hashes
prerequisites.json      available targets and missing tools/credentials
validation.json         validated source/shared-material fingerprints
REPORT.md               human-readable local readiness
SHA256SUMS              checksums for the complete local handoff
```

Each format directory has `raw-<target>/` and, where needed, one portable ZIP. The Web ZIP contains `index.html` at its root. Linux ZIP preserves executable bits; macOS ZIP preserves the `.app` structure/modes and adds license notices. Android APK/AAB are already upload-container formats and are not wrapped again. Every destination references the same compatible artifact; a Steam depot or Microsoft Store adapter is not a reason to export the game again.

## Honest target boundaries

- Windows: unsigned x86_64 release, automated exported-executable smoke test.
- Web: single-thread Compatibility export; requires HTTP(S), WebAssembly and WebGL2. Local automated browser smoke is separate from structural export validation. No hosting or DNS is configured.
- Android APK: debug-signed testing build only. The default/debug key is not a production identity.
- Android AAB: release-mode **unsigned** preparation bundle; not Play-upload ready. Requires owner-controlled upload signing and platform verification. No production key is generated or read.
- Linux: cross-exported x86_64 ELF; native execution remains unverified on this Windows host.
- macOS: cross-exported universal ZIP, unsigned/not notarized; needs Mac execution/signing/notarization before normal trusted distribution. No DMG fabrication.
- iOS: unavailable here. Requires macOS/Xcode, Team ID, provisioning, signing and native validation; follow `IOS_EXPORT.md`. A template ZIP alone is not a working iOS build.
- Store SDKs, GDK/MSIXVC, SteamPipe, portal integrations, native Apple screenshots, ratings/account checks and store approvals remain platform prerequisites, not invented completed work. F-Droid is blocked by the current absence of an original-code/art FOSS license. Amazon's generic Android-phone store closed; its record covers Fire devices.

Destinations stay `not_published` until separately authorized actual publication is verified with live URL/version/date. itch.io Public Alpha is now published; see [the publication report](PUBLICATION_v0.1.0-alpha.md) and its registry entry. Other destinations remain unpublished. A source push or local package never changes publication state automatically. Keep this release free: no payments, donations, purchases, advertising SDKs or currency integration.

Tag only the finished, verified release commit. Do not move an existing tag or force-push. Committing/pushing this branch or an annotated source tag does not authorize a GitHub Release, binary upload, website deployment or store submission.
