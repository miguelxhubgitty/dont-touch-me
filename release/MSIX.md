# Microsoft Store desktop MSIX adapter

**Scope:** Windows PC, packaged classic/full-trust Godot app. This is ordinary **MSIX**, not Xbox/GDK **MSIXVC**. It is one **distribution wrapper around the same approved Windows export**, not a fork of the game.

## Release integration / source of truth

1. Develop and test gameplay with default/basic fonts on `main` (see [BRANCH_WORKFLOW.md](../BRANCH_WORKFLOW.md)).
2. Once owner approves shipping, create a fresh `release/<version>` from current `main`, apply the approved aesthetic snapshot, freeze gameplay/text and finalize typography/captures **once**. Do not re-export while deciding store packaging. Never merge the release branch back into `main`.
3. Run the regular `release/tools/release.py prepare` and verify the Windows ZIP and the SHA-256 in `builds/v<version>/manifest.json`. Packaging must reuse **that exact ZIP**, with all licenses/notices, without touching game scenes or approved artwork.
4. Convert the ZIP to a **separate** `builds/v<version>/microsoft/DontTouchMe-v<version>-x64.msix`. The adapter resizes an **already approved** 512x512 icon for three Windows tile slots; it does **not** author new art, rerender gameplay or regenerate typography.
5. Review the generated `msix-receipt.json`, Windows SDK MakeAppx semantic validation, app identity, license/asset inclusion, install/launch/uninstall/update behavior and certification tests on **Windows**. This repo's optional offline Python tests cannot prove Microsoft acceptance.
6. Submit only after owner approval. A local build, Github commit, PR or artifact is **not** a Store submission. Keep store status unverified until an actual Partner Center receipt and public URL exist.

## Prerequisites

- Windows, Python 3.10+, `python -m pip install Pillow` (only needed for MSIX icon sizes) and the **Windows SDK** with `makeappx.exe`. There is no extra Godot export.
- An approved `builds/v<version>/windows/DontTouchMe-v<version>-windows.zip` **plus its release receipt**, **or** the exact previously published Windows release ZIP with its independently verified official SHA-256.
- **Exact MSIX package identity** (`Identity Name` and `Publisher`, including the `CN=` portion, plus `PublisherDisplayName`) obtained from the correct **packaged MSIX** product in Microsoft Partner Center. Do not invent these, substitute a company display name, or copy fields from an unrelated EXE/MSI listing.
- The user's reserved **“Don't Touch Me.”** name currently appears to belong to an **EXE/MSI product flow**. Before submission, verify with Microsoft whether that name/product can be converted or transferred to the packaged MSIX submission flow. **Do not delete/release the reserved name or create a conflicting product without review.**

## Build from the current finalized Windows release

From the repo root, on Windows:

```powershell
python -m pip install Pillow
python -m unittest discover -s tests -p test_msix.py

# First do the standard owner-approved final release workflow:
python release/tools/release.py prepare --godot <path-to-godot>

# Then package the SAME verified Windows ZIP, with exact MSIX product identity:
python release/tools/build_msix.py --identity-name "<Partner Center Identity Name>" --publisher "CN=<exact Partner Center publisher>" --publisher-display-name "<exact Partner Center publisher display name>" --display-name "Don't Touch Me."
```

The script reads the current `release/catalog/game.json` version, checks the Windows release receipt and SHA-256, locates `makeappx.exe`, creates a full-trust desktop `AppxManifest.xml`, uses the approved icon, and produces a versioned **unsigned** MSIX plus JSON receipt in ignored `builds/`. It rejects missing identities, stale/mismatched source hashes, missing executables, unsafe ZIP paths, unsupported version patterns and overwriting a previously generated MSIX.

## Reusing an already approved published Alpha binary (no re-export)

Use historical mode for Public Alpha v0.1.0-alpha. The normal local-build receipt path rejects this version. It requires the exact versioned manifest from [PR #11](https://github.com/miguelxhubgitty/dont-touch-me/pull/11). The manifest commit is reachable from protected main. Fetch main and the existing Alpha tag before packaging.

```powershell
git fetch origin main tag v0.1.0-alpha
python release/tools/build_msix.py --release v0.1.0-alpha --source-zip "C:/path/to/DontTouchMe-v0.1.0-alpha-windows.zip" --identity-name "<MSIX Identity Name>" --publisher "CN=<exact MSIX Publisher>" --publisher-display-name "<exact Partner Center publisher display name>"
```

The tool checks the historical export and tag runtime fingerprints, verifies the original ZIP against the pinned release manifest, and reads the Windows version and inventory-verified icon from the pinned Alpha tag. A supplied checksum is an optional cross-check. A mismatched ZIP, moved tag, missing Git object or changed artwork fails preflight.

MakeAppx runs with semantic validation. The tool reads back the archive and compares the file set, payload and logo bytes, x64 manifest identity, publisher display name and executable target. It retains the result and provenance receipt after those checks. Use `--stage-only` to test inputs without the SDK. Set `DTM_ALPHA_WINDOWS_ZIP` before running the offline test suite to exercise the original ZIP.

## Signing and testing

- Microsoft **signs MSIX for Store distribution** following certification. An unsigned locally built MSIX is **not directly installable by typical users**. For local install testing, use an appropriately matching development test certificate and trusted test machine; never commit keys, PFX files or signed production artifacts.
- Check package with the Windows SDK's MakeAppx tools and Microsoft App Certification Kit, then install/launch/tap/sleep/wake, uninstall, and test upgrading over a prior Store version when one exists.
- Store versions need four numeric components (with fourth component zero); future update versions must increase monotonically for the **same package identity**.
- This adapter doesn't upload binaries, change Partner Center settings, reserve a title, alter app signing or update distribution registry publication status.
- If/when the Store accepts the app, preserve its Identity Name and Publisher across updates. Changing its display title or approved graphics can be reviewed independently; **never break package identity for a cosmetic change**.

Official references:
- https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-manual-conversion
- https://learn.microsoft.com/en-us/windows/msix/package/create-app-package-with-makeappx-tool
- https://learn.microsoft.com/en-us/windows/apps/publish/faq/get-started-with-the-microsoft-store
