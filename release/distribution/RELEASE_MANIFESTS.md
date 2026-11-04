# Versioned release manifests

[Public Alpha v0.1.0-alpha](manifest-v0.1.0-alpha.json) is the per-version record of release source, artifact identity and destination outcomes. The [catalog](../catalog/game.json) still owns editable product metadata and build settings. The [platform registry](platforms.json) owns destination capabilities and prerequisites. Publication receipts and generated build reports remain evidence. Where older registry snapshots differ, use the versioned manifest for the recorded outcome and follow its evidence references. A receipt records verification at the time of that work.

## Reading and maintaining the record

- The source block pins the historical export commit and existing tag independently. Git object IDs identify the runtime trees and files. Artifact SHA-256 hashes identify exact distributed bytes. The tag and export have the same pinned runtime objects. The development checkout has a different runtime.
- Artifact rows are keyed by ID. `not_started` means no build preparation is recorded, `prepared` means packaging inputs have been reviewed, `built` means an artifact exists, and `tested` means a runtime test is documented within the stated validation scope. Structural tests can be recorded on a built artifact. Store outcomes are separate: `submitted` needs a submission receipt, and `published` needs public evidence. A null means unknown or not applicable. Publication never implies native runtime validation.
- Distribution rows refer to artifact IDs and evidence. A platform can rewrap a download without changing the payload. Capture wrapper hashes in destination receipts and keep the original artifact SHA-256 here. Preserve superseded receipts and distinguish the first publication date from later channel or artifact updates.
- For every future package bearing this release version, require the same pinned runtime. Confirm the exact approved artifact SHA-256 for wrappers and compare the staged executable, game payload and notices byte-for-byte. For a new platform export, resolve the pinned source and verify its fingerprint before export. Document any separately approved delivery adapter and its evidence. A gameplay or visual runtime change belongs to a different release version.

## Alpha MSIX preflight

The input is the approved Windows ZIP, with its SHA-256 and executable digest recorded in the manifest. The extracted Alpha executable completed a 120-frame headless smoke with exit 0 on Windows. Both license files and the README were present and readable. There is no MSIX, manifest XML, package checksum or install result yet.

The draft [MSIX tooling PR #6](https://github.com/miguelxhubgitty/dont-touch-me/pull/6) passed a Git merge-tree check against current main. Its explicit ZIP mode takes a supplied checksum, but it still reads the current checkout's version, default icon and asset inventory. It does not bind these inputs to the historical release manifest. The packaging prerequisites remain the exact packaged-product Identity Name and Publisher from Partner Center, Windows SDK MakeAppx.exe, and verified Alpha-source packaging assets. Partner Center redirected to sign-in and the SDK executable was not located on PATH or in the standard Windows Kits paths. Local installation testing would additionally need an authorized signature trusted on the test PC.

## Proposed automated gate for separate approval

```text
load explicitly selected release manifest and validate source pin
reject unknown artifact, missing hash or inconsistent version
verify approved ZIP and pin packaging asset to that release inventory
require exact Partner Center identity and MakeAppx before packing
stage original payload and compare every original entry by hash
pack with semantic validation, then unpack and verify identity and payload
record validation evidence without promoting submission or publication
```

For an existing release, the version and build metadata must come from that release's manifest or pinned catalog. Test a changed checkout, wrong ZIP/hash, changed artwork, and missing identity as rejection cases. The static manifest establishes the release rule. The automated gate remains a proposed tooling change under AGENTS.md.
