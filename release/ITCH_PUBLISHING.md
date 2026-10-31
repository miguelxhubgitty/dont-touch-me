# itch.io draft distribution with official Butler

Follow BRANCH_WORKFLOW.md, WORKFLOW_VALIDATION.md and release/RELEASE_SYSTEM.md. Tooling changes may use a feature branch based on the current release. Merge reviewed tooling into that release normally; do not merge aesthetics into main or move existing tags. No runtime/assets changes or exports are necessary for this setup.

## Authentication and initial draft

Run `C:\Apps\butler-windows-amd64\butler.exe login`. Complete official browser authorization as **wandiel** yourself. Never paste callback URLs, tokens or passwords into chat or Git. Credentials remain in `%USERPROFILE%\.config\itch\butler_creds`. If the browser does not open, open the official URL printed by Butler on this computer. Keep the login process running. Do not commit credentials or enable automatic CI uploads.

Open https://itch.io/dashboard and look for Don't Touch Me; a public 404 does not prove a draft is absent. If absent, choose Create new project (https://itch.io/game/new), title Don't Touch Me and slug `dont-touch-me`. Owner must complete any terms/account verification. Keep **Draft** visibility. Select **No payments**, not "$0 or Donate". Publisher/account is WANDIEL (`wandiel`). Never choose Public during setup.

## Existing artifacts and shared page material

From the repository root, use Python 3.11+ (standard library):

```powershell
python release/tools/itch.py prepare
python release/tools/itch.py status
# Only after freshly verifying the actual edit page is Draft and No payments:
python release/tools/itch.py push --confirm-draft-no-payments
```

`prepare` is offline and default. It validates package/raw hashes, handoff ledger, ZIP integrity, structural/runtime evidence, and browser evidence; it writes `builds/v0.1.0-alpha/itch/upload-plan.json` and `page-materials.json`. Shared description, identity, release notes and existing cover/screenshots come from the canonical catalog; no image generation or copy edits. The version supplied to Butler is `v0.1.0-alpha`. Select HTML as project kind, 432×768 portrait embed, and mark **html5** as playable in-browser. Keep Windows as downloadable with only Windows selected. Upload the existing cover and screenshots listed in page-materials.json. Verify the Alpha label, existing privacy/support links, rights and audience before public approval.

Channels: windows → Windows ZIP; html5 → Web ZIP; linux → Linux ZIP; mac → macOS ZIP. Linux/macOS uploads are refused until recorded native runtime validation passes. Do not relabel static cross-export checks as runtime testing. Existing Windows/Web packages are reused unchanged. Unsigned Windows remains unsigned.

`push` requires fresh operator confirmation of actual draft/no-payment settings. Butler cannot establish visibility from a status query: **do not use the confirmation flag without reviewing the page**. `--hidden` protects newly created channels but does not hide existing channels or turn a public project into a draft. The script never changes page visibility/pricing. Butler pushes ZIP contents, not an opaque ZIP; do not compare the remote reconstructed archive's ZIP-byte hash with the original ZIP hash.

Each attempt appends source/package hash, target/channel, version, time and exit status to ignored `itch/upload-results.jsonl`. Partial failures stop further uploads. Success is not processing completion: inspect `butler status wandiel/dont-touch-me`, verify exact versions/build IDs and matching channel names, then check editor files/OS tags and private browser play. Record that result separately. No published version/live URL is set by an upload. Public release requires separate explicit approval and a verified public URL/date/version in the central platform registry.

Official references: https://itch.io/docs/butler/login.html, https://itch.io/docs/butler/pushing.html, https://itch.io/docs/creators/html5, https://itch.io/docs/creators/pricing, https://itch.io/docs/creators/access-control.

## Setup verification — October 31, 2026

Butler v15.32.0 ran successfully and completed official local authentication. The authenticated wandiel dashboard contained no project; Don't Touch Me was created as draft ID 5273390. Saved settings were reread: Draft, No payments, HTML, In development, 432×768; original cover and five screenshots attached. Existing canonical description, WANDIEL identity and Alpha version were entered. AI code/text assistance was disclosed. Editor: https://itch.io/game/edit/5273390 (owner access required; never record secret preview URLs).

Offline preparation verified the existing Windows and Web package/raw hashes and ZIPs. Five adapter guard tests and all 14 existing distribution tests passed. The first actual push was rejected by itch.io with “Please verify your account's email address before uploading a build.” It stopped before html5. No accepted remote build is claimed. Owner must verify itch.io account email, retry the explicit command, inspect exact channel versions/processing and configure browser play. Retain Draft and No payments throughout; public release still needs separate approval. See ignored upload receipts for individual attempts.

Subsequent verification supersedes that initial blocked attempt: the owner verified account email, and both pushes succeeded. `butler status --show-all-files wandiel/dont-touch-me` reported completed Windows upload 20184231 / build 2263119 and html5 upload 20184236 / build 2263122, both exactly `v0.1.0-alpha`. The saved private page exposes the Windows download and uses html5 for browser play. Draft and No payments were retained; this is not public publication. The owner-requested itch-specific tagline is “A tiny blob. A big need for personal space.” It is stored in the adapter config without changing other platforms' copy. No Linux/mac upload was attempted.

The privately hosted Run game action launched the uploaded Godot game and visibly rendered the animated blob in its canvas. This is a hosted-browser startup observation, not physical-device or full compatibility certification. A local screenshot is retained in the ignored `builds/v0.1.0-alpha/itch/draft-preview.png`.

For later gameplay releases, carry the focused adapter tooling changes into the new release (or backport only these tooling/config/docs/tests to basic-font main after review). Never copy a previous release's gameplay/assets as part of installing the adapter. `prepare` derives the version and package names from that new release's own catalog and manifest; old draft-upload IDs remain historical evidence for their recorded version.

## Same-listing Windows verification — October 31, 2026

Rechecked Butler authentication and both completed channels on existing project 5273390 (`wandiel/dont-touch-me`). Windows upload 20184231 / build 2263119 already existed, so **no duplicate push** was performed. HTML5 upload 20184236 / build 2263122 was preserved. Both remain v0.1.0-alpha.

Windows ZIP SHA-256 matched the saved manifest and handoff ledger: `42a43d68e9c0dd2af46da6dfa6f74d32b4e4c2242a68771dc046900134bcbdc9`. Offline preparation also rechecked ZIP integrity and original raw-file hashes without exporting or generating assets.

The Windows ZIP was already downloadable but its Windows platform checkbox was unset. Enabled only **Download for Windows** and saved; rereading the editor confirmed it persisted. Windows stays Executable, not browser-played, and not hidden. HTML5 stays browser-played. The same private game page showed Run game and the Windows ZIP download with version v0.1.0-alpha. Draft and No payments were retained. Channel names alone are not proof that platform checkboxes are set: verify these in the editor for every new upload.

Remaining before public release: owner reviews the private page, existing unsigned-Windows compatibility/signing limitations and current support/privacy information, then explicitly approves publication. Do not set a published version/live URL until actual public release is authorized and verified.
