# Microsoft artwork — OWNER APPROVED, 2026-11-02

All nine Microsoft entries below are approved for their exact existing SHA-256 values and Alpha source `d61c865`. See [approval record](APPROVAL.md). Technical and human visual gates now pass. This does not imply a Microsoft upload or certification. The following text retains the initial audit and its then-pending status as historical evidence.

# Public Alpha Microsoft artwork review â€” PENDING

Source of truth: Alpha tag `v0.1.0-alpha`, commit `d61c86568b40c23a291db7aa2757ffe82e1896e8`. Primary Space Grotesk, handwritten Alpha Ink Free whole-phrase images. No fallback-main artwork. [Full policy/audit](../../VISUAL_UPLOAD_POLICY.md); [manifest](manifest.json).

These are the **specific candidates that would be used after approval**, not upload-approved images. Technical validation passed. Owner visual review is pending for every entry. No upload/submission has occurred.

## Proposed Microsoft PC set

| Exact file | Target | Pixels |
| --- | --- | --- |
| [01-calm-2160x3840.png](assets/microsoft/01-calm-2160x3840.png) | Gameplay screenshot: calm/intro |2160Ã—3840 |
| [02-annoyed-2160x3840.png](assets/microsoft/02-annoyed-2160x3840.png) | Gameplay screenshot: Seriously? |2160Ã—3840 |
| [03-angry-2160x3840.png](assets/microsoft/03-angry-2160x3840.png) | Gameplay screenshot: STOP. |2160Ã—3840 |
| [04-hiding-2160x3840.png](assets/microsoft/04-hiding-2160x3840.png) | Gameplay screenshot: box/peek eyes |2160Ã—3840 |
| [05-sleeping-2160x3840.png](assets/microsoft/05-sleeping-2160x3840.png) | Gameplay screenshot: sleep |2160Ã—3840 |
| [poster-1440x2160.png](assets/microsoft/poster-1440x2160.png) |2:3 poster, Space Grotesk title |1440Ã—2160 |
| [box-2160x2160.png](assets/microsoft/box-2160x2160.png) |1:1 box art, Space Grotesk title |2160Ã—2160 |
| [hero-3840x2160.png](assets/microsoft/hero-3840x2160.png) |16:9 hero, deliberately text-free |3840Ã—2160 |
| [tile-300x300.png](assets/microsoft/tile-300x300.png) |1:1 Store tile, direct vector source |300Ã—300 |

No existing1024Ã—500 feature or630Ã—500 itch cover is stretched/cropped into a Microsoft slot. The seven originals under `assets/alpha/` are exact-tag reference graphics for their separate destinations; they do not substitute for these Microsoft images. All SHA-256 values and source links are in the manifest and the ledger below.

## Quality inspection and evidence

Godot4.7.2 official rendered all nine candidates with the actual NVIDIA/OpenGL Compatibility renderer on this Windows machine. They are opaque RGB PNGs; gameplay was drawn directly to target-sized SubViewports. Existing Alpha fonts/phrase sources were reused unchanged. No new game export, gameplay edit, font replacement, post-capture resize, fake OS frame or AI-generated art was used.

Agent inspection covered the complete nine-image contact sheet, native-pixel title/dialogue/tile samples, full key-art composition and all seven exact-tag Alpha reference images in a separate sheet. Space Grotesk titles and Ink Free dialogue are consistent with the pinned implementation; no final clipping or black transparent-corner artifacts were observed. The initial tile conversion exposed black transparent corners; the authoring pipeline was corrected to composite vector output onto the warm background before RGB export. This was an authoring correction, not a game/icon change. Contact-sheet/native-detail crops are QA-only, not upload assets. Normalized text source comparison corrected a Windows CRLF false mismatch without weakening binary checks.

Technical checks cover full PNG structure/CRC/decompression, declared/required dimensions, output hashes, tag identity,18 source fingerprints, renderer/receipt/recipe and human-review fields. They cannot prove visual quality by themselves. No fresh physical-device or packaged Microsoft-app test is claimed. Store acceptance and the exact product submission route remain unverified.

## Owner must decide

- Approve or request revisions to these exact nine compositions at native size, including readable dialogue and poster/box title treatment. Keep the hero text-free.
- Approve the matching manifest fingerprint only after reviewing the image hashes. All review fields intentionally remain pending; technical QA is not owner consent.
- Confirm the Microsoft product route/actual image slots later. Microsoft is still deferred, and a visual approval alone does not authorize upload/submission.

No production credentials, accounts, payments, package/art uploads, tag moves, commits or pushes are part of this audit. Existing local uncommitted work has been retained.

## Verification results and change scope

- Technical verification passed for all16 allowlisted images (seven exact-tag references plus nine Microsoft candidates).
- Twelve visual/integration regression tests passed, including strict real-preflight blocking before package/upload work. The complete Python discovery run:42 tests,41 passed,1 skipped. The skipped historical Alpha build-tree test needs a local `builds/v0.1.0-alpha/manifest.json` that is absent; it was not fabricated or rebuilt.
- Six CLI checks behaved as expected: technical previews pass; strict Microsoft check/upload-plan fail pending owner review; the general Microsoft publication plan also fails existing deferral; Game Jolt's listing preflight fails pending visual review. No remote API was called by those checks.
- Existing tests' Windows sandbox temporary-directory access issues were resolved for the run by placing test scratch files under ignored workspace output. A stale blanket null-URL assertion was corrected to preserve the already-recorded Game Jolt partial-verification state, without changing the publication registry.
- The32 pre-existing local files remain:26 are byte-identical; six received the scoped integrations/documentation below. The prior local journal bytes are retained as a prefix. Main gameplay, settings, font resources and original store-image files have no diff from the starting commit. No branch/commit/tag was created or moved.

New files/logic:

| File | Purpose |
| --- | --- |
| `release/tools/visual_assets.py` | Version/source/typography allowlist, PNG integrity, hash/role/dimension validation, exact-byte owner-review gate, offline authoring orchestration; no uploader/auto-approve action |
| `release/tools/generate_microsoft_assets.gd` | Direct final-resolution Alpha rendering, text-free hero and vector tile; no main gameplay edits |
| `release/visuals/v0.1.0-alpha/manifest.json` |16 candidates, destination-specific metadata/provenance/hashes, all human reviews pending |
| `release/visuals/v0.1.0-alpha/assets/` | Seven unchanged tag references, nine new Microsoft candidates, render receipt |
| `release/VISUAL_UPLOAD_POLICY.md`, this review file | Audit, quality/approval rules, exact candidate list, limitations and stop point |
| `tests/test_visual_assets.py` | Fail-closed corruption/substitution/approval and integration regression coverage |

Modified files/logic (existing local work preserved):

| File | Scoped change |
| --- | --- |
| `release/tools/publishing_audit.py` | Strict versioned visuals in listing plans; preview-only visuals action replaces generic main-manifest authority |
| `release/tools/gamejolt_release.py` | Requires strict visual preflight before preparing a listing |
| `release/tools/release.py` | Marks generic shared artwork not upload-approved; adds explicit gate to generated checklists |
| `AGENTS.md` | Requires visual gate immediately before any browser/API artwork upload; preserves normal main typography |
| `release/PUBLISHING_WORKFLOWS.md`, `release/RELEASE_SYSTEM.md` | Point workflows to versioned review authority and distinguish technical preview from upload permission |
| `docs/INTERNAL_DEVELOPER_JOURNAL.md` | Appended dated source-grounded audit/decision/test entry |
| `tests/test_distribution.py` | Recognizes pre-existing `published_verification_partial` public URLs without promoting them |

Existing dirty `release/tools/github_release.py`, `release/distribution/platforms.json`, prior account/automation/other publication records and unrelated plans were not changed by this audit. The GitHub adapter uploads packages, not listing artwork; its existing guards remain intact.

## SHA-256 ledger

Generated from final candidate bytes; no reviewer approval is implied.

Review fingerprint: `7335e14553bc98e39e440e430acbcb98e8a6e062a605a09ccc6a054ed6ef41f2`

```text
5baaffae4d7455e7e55aa23a2aa1444ee2c9f15b70340926f97efb220def3568  01-calm-2160x3840.png
affc647bf272dc1268631c9c515e5dae3ba5e4da50cd3a8d0461fec8d28b9d2f  02-annoyed-2160x3840.png
2f18d6e09fb83ed8d99457210b97ad6ec90681ced80e3c48ab9514492d657bc3  03-angry-2160x3840.png
589fe64bbc9dd4f488552c7856bc7864d6164925016943f57eb88dee1021ff0f  04-hiding-2160x3840.png
3e2b1894364b44b0c0584c7c8b9fed0c586f17c58289bb8e0823fed371504cfa  05-sleeping-2160x3840.png
4f5f4417e972c7f62796c626eb438a8d8c884e1c638c7a27b7fbfb4d08592eb3  poster-1440x2160.png
6afad2017e3fcd8370d1d54667eaebde8c555b3ba842a75a16c4d1748b7b354a  box-2160x2160.png
158977ba927c881c246982ec9ee5ae5906e432f4a9cc21e26a22c03e0ca55b10  hero-3840x2160.png
929551a98f1c138b2de2ffdbc10a6066dd369ef972b76a8161aec075bfb75223  tile-300x300.png
```
