# Current Microsoft status — 2026-11-02

The owner has approved the nine exact Microsoft image hashes and authorized this version-specific submission attempt, superseding the earlier Microsoft deferral only for this attempt. See [approval](visuals/v0.1.0-alpha/APPROVAL.md) and [Microsoft status](MICROSOFT_ALPHA_STATUS.md). No artwork regeneration occurred. Other-platform review fields remain pending. The following initial audit retains its then-pending/deferred statements as historical context.

# Version-specific publishing visuals — approval required

Audited November 2, 2026. **No Microsoft submission, artwork/package upload, account action or publication is authorized by this preparation.** Microsoft remains deferred in the existing automation policy. This visual gate is an additional requirement, never an override of that policy.

## Authority and existing safeguards

The owner corrected the requested font names to **Space Grotesk + Ink Free**. The authoritative implementation is Public Alpha `v0.1.0-alpha`, commit `d61c86568b40c23a291db7aa2757ffe82e1896e8`, whose runtime matches the recorded export source `9788e0343cb888a31ea9092f7409e2455a961261`.

- Space Grotesk supplies primary/title/standard text. Alpha `assets/fonts/title.tres` selects weight600. Font files and metrics come from that release, not installed system substitutions.
- Ink Free handwriting is supplied by the Alpha's ten cached **complete-phrase** PNGs and metrics; no proprietary font file is added. Dialogue and reaction lettering keep that implementation.
- The blob and props are drawn by the actual Alpha controller. Promotional layout is separate authoring code, never a replacement for gameplay.
- Main intentionally uses the Godot fallback font for development. Its images are not approved store material, even when their dimensions and local inventory hashes pass.

Before this audit, local safeguards already included `AGENTS.md`, `BRANCH_WORKFLOW.md`, guarded aesthetic integration, release-only authoring flags, `tests/typography.gd` on the Alpha branch, source-to-capture fingerprints, a39-PNG metadata manifest, asset SHA-256 inventory, clean-tree/source/template/export checks, artifact approval/tag guards, and upload deferral policy. These are useful but do not establish owner approval of each promotional image.

There was substantial **uncommitted local work**, not merely unpushed commits:32 dirty/untracked files were recorded at start. This includes `publishing_audit.py`, `gamejolt_release.py`, automation/access/publication receipts and modified release/GitHub tooling. Existing GitHub package guards are unrelated to uploading listing images; they remain intact. No local Microsoft artwork uploader or per-image human approval gate was found. The existing ignored `builds/publishing-audit/approved-alpha-art/provenance.json` pins five captures but lacks dimensions/platform-specific review state.

The local Game Jolt report records an actual near miss: a basic-main thumbnail was staged, owner caught it, and it was replaced before publication with the unchanged Alpha feature. This audit preserves that report. Critically, the existing publishing plan still labeled `release/assets/manifest.json` as approved art; that main manifest fingerprints the basic-font controller (`1092a56e…`), while the normalized Alpha controller is `1d6abd34…`. A passing local hash inventory could therefore bless the wrong visual source. A version-specific independent upload allowlist was missing.

## What is now enforced

`release/visuals/v0.1.0-alpha/manifest.json` records16 candidates: seven byte-exact Alpha reference graphics plus nine newly rendered Microsoft images. Every entry includes path, platforms, dimensions, SHA-256, provenance, version and separate per-destination human review fields. **All new review fields are pending.** Historical Alpha approval does not imply review of a new Microsoft composition.

`release/tools/visual_assets.py` is offline and has no upload or approval-writing command. It:

1. Pins the exact tag/commit and18 runtime/font/phrase/vector source fingerprints. Equivalent LF/CRLF source text is normalized; PNG/font binaries remain byte-exact.
2. Requires the Alpha Space Grotesk/Ink Free style declaration and actual pinned source identities, not just a font label in JSON.
3. Pins the authoring recipe/renderer SHA, target sizes, render receipt and output hashes. Original Alpha reference images must also equal their immutable Git blobs; refreshing a hash cannot launder a main-font image.
4. Checks PNG signature, CRCs, decompression, scanline structure, RGB/RGBA depth, dimensions and size limit. Microsoft candidates are opaque RGB PNGs at the exact selected slot sizes.
5. Rejects unknown versions/destinations/paths, directory traversal, missing/duplicate images, altered source/recipe/image bytes, wrong dimensions/roles, and post-capture-resize claims. Microsoft uses the complete nine-image set, not a partial subset to bypass a pending image.
6. Requires **owner** review for the exact image SHA and complete manifest fingerprint, with reviewer/date/reference. Missing, stale, machine-only or other-platform approvals fail. Changing a source, recipe, image, slot or destination invalidates existing approval.

`publishing_audit.py plan` now obtains the reviewed versioned visual allowlist rather than the generic main manifest. New `visuals --platform …` is preview-only and cannot report upload readiness. `gamejolt_release.py prepare` also requires the gate. The generic release handoff gets a **VISUALS_NOT_UPLOAD_APPROVED.md** warning and every generated destination checklist requires the strict visual check. Historical capture exports stay intact for provenance; that directory is not a file-picker source. The binary-only GitHub adapter has no artwork-upload feature and is left unchanged by this audit.

**Boundary:** these are supported-tool/agent workflow guards, not an OS file lock or a cryptographic signature from the owner. They cannot intercept someone manually bypassing tools in a browser, prove font identity using OCR, or judge sharpness/composition automatically. Pinned sources, hashes and the verified rendering route prevent accidental substitution; owner review provides the remaining visual judgment. Never upload from a remembered path, a cached plan or a generic folder. Run the gate immediately before selecting/sending the exact files, recheck their hashes, and preserve the approval reference. Future artwork upload adapters must call this gate before their first remote write. No Microsoft upload adapter exists yet; adding one must preserve these gates and separate destination/publication authorization.

## Rendering quality and target choices

Microsoft PC review candidates use the higher documented poster/box/hero resolution options. Five gameplay captures are direct2160×3840 renders of the same720×1280 Alpha canvas, with no stretching/compositing after capture. Font outlines and the procedural character render directly at target pixels; no small store screenshot/feature image is enlarged. The maximum used handwritten size is129 physical pixels (STOP43×3), below the cached160-pixel authoring size. Key-art titles use Space Grotesk font rendering rather than scaling a title PNG. The300px tile is rasterized directly from the original SVG and composited on warm paper; it is not resized from a launcher PNG.

The authoring command verifies the isolated Alpha source before rendering and after import. It uses the real Compatibility renderer; no headless screenshot output is accepted as graphical evidence. Rendering is explicit, release-only, and separate from routine main development. Existing manifests are validated/reused rather than regenerated or overwritten; approved manifests are never silently re-approved. A future changed recipe/output requires a new reviewed revision/version and explicit owner approval.

The Microsoft hero intentionally has **no text**, matching that slot's rule; it is not missing approved typography. The five screenshots are truthful gameplay renders without marketing overlays. Review them at native size as well as thumbnails. The supplied portrait layout remains unchanged; no desktop gameplay redesign was made for store images.

Current reference: [Microsoft MSIX screenshot/image specifications](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/screenshots-and-images), checked2026-11-02. It permits portrait/landscape PNG screenshots (≤50MB), desktop minimum1366×768; poster1440×2160, box2160×2160, hero3840×2160, tile300×300. Hero excludes text. These are PC listing preparation choices; actual product route/Partner Center slots still need confirmation before submission. No Xbox/Holographic support or certification is implied.

## Review and stop point

Read-only technical preview:

```text
python release/tools/visual_assets.py inspect --platform microsoft
python release/tools/publishing_audit.py visuals --platform microsoft
```

Strict prerequisite for any artwork upload (currently exits nonzero on pending owner review):

```text
python release/tools/visual_assets.py check --platform microsoft
python release/tools/visual_assets.py upload-plan --platform microsoft
```

For a specific selection, pass each repo-relative manifest filename with `--asset`. Microsoft requires all nine filenames. Unlisted main artwork fails even if the file exists and looks plausible. `inspect` is never a substitute for `check`.

Owner review must identify the nine exact images and manifest fingerprint from `inspect`, explicitly approve their typography/sharpness/composition, and provide an attributable approval reference. Only after that actual approval may an authorized maintainer populate each image's Microsoft review with `status=approved`, `reviewer_role=owner`, reviewer, reviewed_at, the exact approved_sha256, manifest_fingerprint and approval_reference. There is deliberately no auto-approve flag. A prior test fixture's approval is not real approval. Then rerun strict checks. This still does not authorize uploads, change deferred policy, accept contracts or submit the app.

For a fresh unprepared review version, the authoring recipe is:

```text
python release/tools/visual_assets.py prepare --godot <Godot-4.7.2-console-executable>
```

It writes an isolated ignored source checkout under `builds/visual-review/source`, versioned candidate artwork and a receipt/manifest with **pending** reviews. It never overwrites gameplay, regenerates Alpha phrases, changes a tag or sends network requests. Changing the approved source/version requires an explicitly reviewed new trust anchor and policy revision; unsupported versions fail closed.

Tests: `python -m unittest discover -s tests -p test_visual_assets.py -v`. See [the review package](visuals/v0.1.0-alpha/REVIEW.md) for filenames, hashes, inspection results and remaining blockers. Stop for owner visual approval before any upload.
