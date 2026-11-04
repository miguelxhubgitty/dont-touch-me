# Historical Windows ZIP to MSIX correction

Status: owner approved and implemented on the PR #6 tooling branch. Separate merge approval is pending. Draft PR #6 is the packaging adapter. Draft PR #11 supplies the versioned release record. Test their combination in an isolated topic checkout once the design is approved.

## Current gap

Historical mode in build_msix.py accepts a ZIP and a caller-provided hash, then reads the current checkout's catalog, icon and inventory. A caller can hash a development export and pass the resulting digest. The current draft also defaults PublisherDisplayName rather than requiring the Partner Center value. The regular finalized-release path already checks a local release receipt and should retain that workflow.

## Proposed flow

```text
select an explicit release and load its approved versioned manifest
resolve the named Git tag and compare its peeled commit with the record
verify every runtime object at both the export commit and tag commit
read the release catalog and artwork inventory directly from pinned Git objects
cross-check manifest version, Windows build version, architecture and artifact ID
require the original Windows ZIP and compare its SHA-256 to the manifest
if a caller supplies a checksum, require equality with the manifest as well
load the designated Alpha icon and verify its exact bytes against the pinned inventory
require exact packaged-product identity fields and MakeAppx for package creation
validate safe ZIP paths, unique Windows paths, expected payload and x64 executable
stage original files unchanged and generate only packaging logos and metadata
pack with SDK semantic validation, unpack and compare identity and payload digests
record provenance and results in the local receipt for review and manifest update
```

The approved Alpha ZIP digest binds the wrapper to the known audio-free payload. A renamed or repacked archive, a different executable, or a newly computed development ZIP digest cannot establish release provenance. Reject missing or mismatched refs, hashes, files, artwork, identity and incompatible versions. Reject case-insensitive duplicates, traversal and reserved package paths before extraction. Compare the original staged and unpacked file set and bytes, including notices. Build to a temporary path and retain the final artifact only after validation. Keep installation, submission and publication outcomes separate.

The manifest owns per-release artifact provenance and outcomes. The pinned catalog owns version settings and existing artwork references. The platform registry owns destination requirements. Historical packaging uses one manifest gate and reads the pinned inputs through it. It does not copy store metadata into another registry or silently fall back to the worktree.

## Review tests

- Correct Alpha ZIP with an audio-enabled checkout stages the original payload and pinned visuals.
- A rehashed development ZIP, a modified original ZIP, or a moved tag fails before staging.
- Missing records, wrong version or architecture, mutated icon, missing identity, unsafe ZIP paths and existing output fail with specific errors.
- Offline fixtures exercise gate and staging. A Windows run with authorized SDK tools verifies packaging and unpacking, exact identity and payload hashes. Installation and launch are separate checks with authorized signing or a supported test configuration.

## Remaining inputs

- x64 MakeAppx from Microsoft.Windows.SDK.BuildTools. A project-local, version-pinned NuGet restore can provide it without a machine-wide SDK install. SignTool is needed only if the chosen local validation flow calls for signing.
- Exact Package/Identity/Name, Package/Identity/Publisher and Package/Properties/PublisherDisplayName from the correct packaged product's Partner Center Product identity page. Capture Store ID or dashboard URL to cross-check the product. Confirm the product route if only EXE/MSI or GDK details are available.
- Separate merge approval for PR #11 and PR #6.

## Implementation and verification

Historical mode pins the manifest bytes to the exact PR #11 commit. Alpha is rejected by the ordinary build-receipt path. Staging verifies the ZIP snapshot, x64 PE and executable digest. Output validation reads the MSIX archive directly, checks package identity and verifies every original payload file and generated logo against staging before retaining the package.

Windows offline tests passed: 10 MSIX tests, including staging with the original ZIP and a different development catalog, and 19 distribution tests. The original ZIP hash was unchanged. Output checks were exercised on archive fixtures. Real MakeAppx packaging and installation remain pending SDK and verified Partner Center identity.
