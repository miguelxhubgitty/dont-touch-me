# Microsoft Alpha attempt — blocked on unavailable product name

Observed November 2, 2026. Version `0.1.0-alpha`, approved release source `d61c86568b40c23a291db7aa2757ffe82e1896e8`.

## Visual approval complete

The owner explicitly approved all nine images and existing hashes in [REVIEW.md](visuals/v0.1.0-alpha/REVIEW.md). Each Microsoft entry in the [manifest](visuals/v0.1.0-alpha/manifest.json) records reviewer role, approval date/reference, exact image SHA-256 and the complete manifest fingerprint. See [the attributable approval record](visuals/v0.1.0-alpha/APPROVAL.md).

Fingerprint remains `7335e14553bc98e39e440e430acbcb98e8a6e062a605a09ccc6a054ed6ef41f2`. All nine Microsoft image hashes and all seven original Alpha reference images remain unchanged. Space Grotesk and the Alpha Ink Free complete-phrase implementation are preserved; no image generator was run for this approval. Other-platform human-review fields remain pending. The owner also authorized this exact Microsoft packaging/listing/submission attempt, superseding the prior Microsoft deferral only for this attempt, not promoting other destinations or accepting legal/account decisions.

## Actual Partner Center result

The existing signed-in Partner Center Apps and games dashboard was accessible and displayed zero products. Its New product menu offers GDK game. Opening that route presents a name-reservation dialog, including name-rights and three-month reservation information.

The owner separately confirmed rights to **Don't Touch Me** and expressly authorized name reservation. The exact name was entered and **Check availability** was clicked. Microsoft returned:

> The name is not available.

The dialog advises contacting Microsoft if the name was reserved for another product. This observation does not prove infringement, identify another name holder, or authorize contacting support. No substitute name was chosen, no Reserve action was attempted after the rejection, and no product ID/Store URL was created. No account credentials, cookies or private APIs were accessed. The browser remains at the unavailable-name result for owner review.

Dashboard: [Partner Center Apps and games](https://partner.microsoft.com/en-US/dashboard/apps-and-games/overview).

| Item | Actual result |
| --- | --- |
| Product ID / public Microsoft product URL |None; product not created |
| Name reservation |Blocked by availability check |
| Artwork uploads |None |
| Package uploads |None |
| Certification |Not submitted; no review/approval claimed |
| Payments, agreements, enrollment/account changes |None |

Machine-readable record: [microsoft-v0.1.0-alpha.json](distribution/microsoft-v0.1.0-alpha.json). This records an authorized, blocked attempt; it does not change other platforms' existing publication history.

## Feasible local packaging/listing preparation

[listing-draft.json](microsoft/v0.1.0-alpha/listing-draft.json) reuses the immutable Alpha catalog's description, release notes, free/no-payments policy and public support/privacy links. It references only the nine reviewed Microsoft image paths/hashes. It is a **local draft**, not a remotely saved listing. Product identity, final legal/account declarations, ratings and distribution choices are explicitly unconfirmed. The older hosted-policy label remains a known pre-submission review item.

`release/tools/microsoft_store.py stage-payload` verified the unchanged original Windows ZIP:

```text
42a43d68e9c0dd2af46da6dfa6f74d32b4e4c2242a68771dc046900134bcbdc9
DontTouchMe-v0.1.0-alpha-windows.zip — 38,715,912 bytes
```

It checked ZIP integrity, safe/unique paths, PE x86_64 architecture and staged the original executable plus notices/readme under ignored `builds/microsoft-v0.1.0-alpha/payload/`. Executable SHA-256: `5fdf87a71cc5a05dbc18925948753e1927e0c09631c44e65d4edd40edb1e7d88`. Original Space Grotesk OFL and engine notices are retained. No export/rebuild, gameplay edit, image generation, identity fabrication or binary change occurred. The payload receipt explicitly says `store_package_created=false`.

Microsoft's current Win32 PC game guidance recommends the GDK/MSIXVC route. Store identity must come from the actual product, and the public GDK supplies MakePkg. MakePkg was not found on PATH or standard Microsoft GDK install directories here. No new tool license was accepted or software installed. An unsigned generic Windows ZIP isn't a completed Microsoft package. Xbox services are optional; this game must not acquire an invented sign-in/network dependency merely to package it. Sources checked: [PC game route](https://learn.microsoft.com/en-us/windows/apps/publish/whats-new-game-publishing), [package creation](https://learn.microsoft.com/en-us/gaming/game-publishing/tutorial-xbox-managed/how-to-create-a-package).

## Validation performed now

| Check | Result |
| --- | --- |
| Approved manifest technical/source/typography/image-size/hash/provenance checks |Pass; strict Microsoft visual check now succeeds |
| Focused branch Python discovery |39 tests:38 passed,1 skipped |
| Original checkout Python discovery, including preserved local work |42 tests:41 passed,1 skipped |
| Existing Alpha behavior |320,270 checks,0 failures |
| Existing Alpha input/resolution/lifecycle |237,076 checks,0 failures |
| Source fingerprints |17 checks,0 failures |
| Actual Alpha typography |127 checks,0 failures |
| Alpha visual/package metadata |205 checks,0 failures |
| Existing real-renderer visual QA |18 states and4 aspect ratios rendered successfully and inspected |
| Submission gate |Correctly refuses unavailable name/product identity; visual consent alone cannot bypass it |
| Approved PNGs and gameplay preservation |All approved bytes unchanged; gameplay/main typography/settings have no diff |

The skipped historical Alpha packaging test requires a `builds/v0.1.0-alpha/manifest.json` absent in these checkouts; it was not fabricated. Python tests use isolated synthetic approvals, never real consent. Godot tests use the existing isolated Alpha source. Render tests write only ignored QA sheets, not approved artwork. No physical-device, new native-platform or Microsoft-packaged runtime testing is claimed.

Offline commands (Python3.11+; no network/upload actions):

```text
python release/tools/visual_assets.py check --platform microsoft
python release/tools/visual_assets.py upload-plan --platform microsoft
python release/tools/microsoft_store.py plan
python release/tools/microsoft_store.py stage-payload --archive <unchanged-approved-Windows-ZIP>
python release/tools/microsoft_store.py submission-check
python -m unittest discover -s tests -p test_visual_assets.py
python -m unittest discover -s tests -p test_microsoft_store.py
```

The last submission check intentionally exits nonzero while the actual blockers remain. There is no automatic upload, approval-writing flag, contract acceptance or browser-credential extraction. Strict checks should run immediately before any later real upload.

## Owner stop point

Choose an available Microsoft Store product name and confirm name rights/authorization for that exact replacement, **or** resolve the unavailable-name issue with Microsoft. No alternative has been reserved. Do not alter approved artwork to match a new name without renewed image approval. Once product creation succeeds, use its real identity, install/authorize GDK tooling as necessary, package/validate MSIXVC, complete truthful account/legal/rating/listing decisions and obtain required action-time approval for final representational submissions. No certification result exists yet.

## Git scope

The focused `codex/microsoft-alpha-visual-approval` worktree starts from latest fetched main. It carries the visual safeguards/assets/approval plus Microsoft-only status, listing preparation and tests. Other uncommitted publication/account/automation records stay in the original checkout; no unrelated platform state is committed or overwritten. The approved Alpha tag and other public releases remain untouched. Changes require normal review; no main merge or force push is performed.
