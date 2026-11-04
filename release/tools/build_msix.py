"""Build Microsoft Store desktop MSIX from an approved Windows release ZIP.

Reuses the release's finalized visuals and verified Windows export. Does not
export the game, regenerate game art, sign, publish, or upload anything.
Requires Windows SDK MakeAppx.exe for an actual .msix.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import stat
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path, PureWindowsPath

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "release/catalog/game.json"
ALPHA = "v0.1.0-alpha"
# PR #11 is the source of the approved bytes. A local file or caller hash
# cannot replace its record. Keep this commit reachable when merging PR #11.
ALPHA_RECORD = "3ca6e14c1a5198e3ba1831cdc6b9b51439426314"
ALPHA_MANIFEST = f"release/distribution/manifest-{ALPHA}.json"
ALPHA_ICON = "release/assets/icons/google-play-512.png"
RUNTIME_PATHS = {"assets", "scripts", "main.tscn", "project.godot", "export_presets.cfg", "icon.svg"}
PACKAGE_METADATA = {"appxmanifest.xml", "appxblockmap.xml", "[content_types].xml", "appxmetadata/codeintegrity.cat"}
NS = "http://schemas.microsoft.com/appx/manifest/foundation/windows10"
UAP = "http://schemas.microsoft.com/appx/manifest/uap/windows10"
RESCAP = "http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
ET.register_namespace("", NS)
ET.register_namespace("uap", UAP)
ET.register_namespace("rescap", RESCAP)


def stream_digest(stream) -> str:
    hasher = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        hasher.update(chunk)
    return hasher.hexdigest()


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return stream_digest(stream)


def check_version(version: str) -> None:
    values = version.split(".")
    if len(values) != 4 or any(not x.isdigit() or int(x) > 65535 for x in values):
        raise ValueError("MSIX version must have four numeric parts in 0..65535")
    if int(values[3]) != 0:
        raise ValueError("Microsoft Store MSIX requires a zero fourth version component")


def verify_release(out: Path, source: Path, version: str) -> str:
    receipt_path = out / "manifest.json"
    if not receipt_path.is_file():
        raise ValueError(f"Missing approved release receipt: {receipt_path}")
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    windows = receipt.get("artifacts", {}).get("windows", {})
    if receipt.get("version") != version or windows.get("status") != "built":
        raise ValueError("Windows artifact must be built for the current finalized version")
    expected_path = out / windows.get("package", "")
    if not windows.get("package") or source.resolve() != expected_path.resolve():
        raise ValueError("Source ZIP must match the validated release receipt path")
    expected_hash = windows.get("package_sha256")
    if not expected_hash or digest(source) != expected_hash:
        raise ValueError("Source ZIP checksum differs from the release receipt")
    return expected_hash


def git_bytes(*args: str) -> bytes:
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True)
    if result.returncode:
        raise ValueError(f"Cannot verify pinned release input: {' '.join(args)}")
    return result.stdout


def historical_inputs(source_zip: Path, supplied_hash: str | None) -> tuple[str, bytes, dict]:
    manifest = json.loads(git_bytes("show", f"{ALPHA_RECORD}:{ALPHA_MANIFEST}"))
    source = manifest["source"]
    commit, tag_commit = source["commit"], source["tag_commit"]
    if (manifest["schema_version"] != 1 or manifest["release_version"] != ALPHA
            or source["tag"] != ALPHA or source["audio_included"] is not False
            or any(not re.fullmatch(r"[0-9a-f]{40}", ref) for ref in (commit, tag_commit))):
        raise ValueError("Invalid historical Alpha source record")
    if git_bytes("rev-parse", "--verify", f"refs/tags/{ALPHA}^{{commit}}").decode().strip() != tag_commit:
        raise ValueError("Alpha tag differs from the pinned tag commit")
    fingerprint = source["runtime_fingerprint"]
    if (fingerprint["method"] != "git-ls-tree-object-ids-v1"
            or set(fingerprint["objects"]) != RUNTIME_PATHS):
        raise ValueError("Missing or unsupported Alpha runtime fingerprint")
    for path, expected in fingerprint["objects"].items():
        for ref in (commit, tag_commit):
            actual = git_bytes("rev-parse", "--verify", f"{ref}:{path}").decode().strip()
            if actual != expected:
                raise ValueError(f"Alpha runtime fingerprint mismatch for {ref}:{path}")

    catalog = json.loads(git_bytes("show", f"{tag_commit}:release/catalog/game.json"))
    matches = [item for item in manifest["artifacts"] if item["id"] == "windows"]
    if len(matches) != 1:
        raise ValueError("Expected one approved Windows artifact")
    artifact = matches[0]
    version = catalog["windows_version"]
    check_version(version)
    if (f"v{catalog['version']}" != ALPHA or artifact["build_version"] != version
            or (artifact["platform"], artifact["format"], artifact["architecture"]) != ("windows", "zip", "x64")
            or artifact["build_status"] != "tested" or artifact["filename"] != source_zip.name):
        raise ValueError("Windows ZIP does not match the selected Alpha artifact")
    expected = artifact["sha256"]
    if (not expected or not re.fullmatch(r"[0-9a-f]{64}", expected)
            or (supplied_hash is not None and supplied_hash.lower() != expected)
            or digest(source_zip) != expected):
        raise ValueError("Windows ZIP does not match the approved Alpha SHA-256")
    executable_hash = artifact["executable_sha256"]
    if not executable_hash or not re.fullmatch(r"[0-9a-f]{64}", executable_hash):
        raise ValueError("Missing approved Alpha executable SHA-256")
    icon = git_bytes("show", f"{tag_commit}:{ALPHA_ICON}")
    inventory = json.loads(git_bytes("show", f"{tag_commit}:release/assets-inventory.json"))
    if ALPHA_ICON not in catalog["assets"]["branding"]:
        raise ValueError("Alpha package icon is missing from the pinned catalog")
    verify_icon_bytes(inventory, ALPHA_ICON.removeprefix("release/"), hashlib.sha256(icon).hexdigest())
    return version, icon, {"export_commit": commit, "tag_commit": tag_commit,
                           "release_manifest_commit": ALPHA_RECORD,
                           "icon_sha256": hashlib.sha256(icon).hexdigest(),
                           "executable_sha256": executable_hash,
                           "source_sha256": expected}


def unpack_windows_zip(source: Path, stage: Path) -> dict[str, str]:
    with zipfile.ZipFile(source) as archive:
        seen = set()
        for item in archive.infolist():
            raw = item.filename.removesuffix("/")
            parts = raw.split("/")
            folded = raw.casefold()
            if (not raw or any(not part or part in {".", ".."} or part.endswith((" ", "."))
                               or re.search(r'[<>:"\\|?*\x00-\x1f]', part)
                               or PureWindowsPath(part).is_reserved() for part in parts)
                    or folded in seen or folded in PACKAGE_METADATA
                    or parts[0].casefold() in {"assets", "appxmetadata"}
                    or stat.S_ISLNK(item.external_attr >> 16)):
                raise ValueError(f"Unsafe, duplicate or reserved ZIP entry: {item.filename}")
            seen.add(folded)
        files = {}
        for item in archive.infolist():
            if item.is_dir():
                continue
            target = stage / item.filename
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(item) as src, target.open("xb") as dst:
                shutil.copyfileobj(src, dst)
            files[item.filename] = digest(target)
    if "DontTouchMe.exe" not in files:
        raise ValueError("Release ZIP must contain DontTouchMe.exe at the root")
    return files


def verify_x64(executable: Path) -> None:
    with executable.open("rb") as stream:
        header = stream.read(64)
        if len(header) == 64 and header.startswith(b"MZ"):
            stream.seek(struct.unpack_from("<I", header, 60)[0])
            if stream.read(6) == b"PE\0\0\x64\x86":
                return
    raise ValueError("Windows executable is not x64 PE")


def verify_icon_bytes(inventory: dict, relative: str, sha256: str) -> None:
    match = next((item for item in inventory["files"]
                  if item["file"] == relative and item.get("hash_mode") == "binary"), None)
    if not match or sha256 != match.get("sha256"):
        raise ValueError("MSIX icon does not match the owner-reviewed release inventory")


def verify_approved_icon(approved_icon: Path) -> None:
    """Use only a release-inventory-approved icon, not an arbitrary artwork file."""
    inventory_path = ROOT / "release/assets-inventory.json"
    if not inventory_path.is_file():
        raise FileNotFoundError("Release artwork inventory is missing")
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    try:
        relative = approved_icon.resolve().relative_to((ROOT / "release").resolve()).as_posix()
    except ValueError as exc:
        raise ValueError("MSIX icon must be in the release inventory") from exc
    verify_icon_bytes(inventory, relative, digest(approved_icon))


def create_icons(approved_icon: Path, stage: Path) -> None:
    try:
        from PIL import Image
    except ImportError as exc:
        raise RuntimeError("Install the MSIX-only dependency: python -m pip install Pillow") from exc
    if not approved_icon.is_file():
        raise FileNotFoundError(f"Approved release icon missing: {approved_icon}")
    assets = stage / "Assets"
    assets.mkdir()
    with Image.open(approved_icon) as image:
        if image.format != "PNG" or min(image.size) < 150 or image.width != image.height:
            raise ValueError("Approved icon must be a square PNG at least 150x150")
        image = image.convert("RGBA")
        for size, name in ((44, "Square44x44Logo.png"), (150, "Square150x150Logo.png"), (50, "StoreLogo.png")):
            image.resize((size, size), Image.Resampling.LANCZOS).save(assets / name)


def create_manifest(stage: Path, *, name: str, publisher: str, version: str,
                    display_name: str, publisher_display: str) -> None:
    check_version(version)
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._\-]{0,49}", name):
        raise ValueError("Use the exact, valid Package/Identity/Name from MSIX Partner Center")
    if not publisher.startswith("CN=") or not publisher[3:].strip():
        raise ValueError("Use the exact Package/Identity/Publisher (CN=...) from Partner Center")
    q = lambda local: f"{{{NS}}}{local}"
    package = ET.Element(q("Package"))
    ET.SubElement(package, q("Identity"), {
        "Name": name, "Publisher": publisher, "Version": version, "ProcessorArchitecture": "x64"
    })
    props = ET.SubElement(package, q("Properties"))
    for key, value in (("DisplayName", display_name), ("PublisherDisplayName", publisher_display),
                       ("Description", "A tiny interactive comedy"), ("Logo", r"Assets\StoreLogo.png")):
        ET.SubElement(props, q(key)).text = value
    ET.SubElement(ET.SubElement(package, q("Resources")), q("Resource"), {"Language": "en-us"})
    ET.SubElement(ET.SubElement(package, q("Dependencies")), q("TargetDeviceFamily"), {
        "Name": "Windows.Desktop", "MinVersion": "10.0.19041.0", "MaxVersionTested": "10.0.26100.0"
    })
    applications = ET.SubElement(package, q("Applications"))
    application = ET.SubElement(applications, q("Application"), {
        "Id": "DontTouchMe", "Executable": "DontTouchMe.exe", "EntryPoint": "Windows.FullTrustApplication"
    })
    ET.SubElement(application, f"{{{UAP}}}VisualElements", {
        "DisplayName": display_name, "Description": "An adorable blob wants some personal space",
        "Square150x150Logo": r"Assets\Square150x150Logo.png",
        "Square44x44Logo": r"Assets\Square44x44Logo.png", "BackgroundColor": "transparent"
    })
    ET.SubElement(ET.SubElement(package, q("Capabilities")), f"{{{RESCAP}}}Capability", {"Name": "runFullTrust"})
    ET.ElementTree(package).write(stage / "AppxManifest.xml", encoding="utf-8", xml_declaration=True)


def find_makeappx(given: str | None) -> Path:
    if given:
        tool = Path(given)
        if tool.is_file():
            return tool
        found = shutil.which(given)
        if found:
            return Path(found)
        raise FileNotFoundError(f"MakeAppx not found: {given}")
    located = shutil.which("makeappx.exe")
    if located:
        return Path(located)
    roots = [Path(r"C:\Program Files (x86)\Windows Kits\10\bin"),
             Path(r"C:\Program Files\Windows Kits\10\bin")]
    options = [p for root in roots if root.exists() for p in root.glob("*/x64/makeappx.exe")]
    if options:
        return sorted(options, reverse=True)[0]
    raise FileNotFoundError("Windows SDK MakeAppx.exe missing; install the Windows SDK")


def verify_package(package: Path, stage: Path, original: dict[str, str], identity: dict[str, str],
                   publisher_display: str) -> None:
    staged = {path.relative_to(stage).as_posix(): digest(path)
              for path in stage.rglob("*") if path.is_file()}
    if any(staged.get(name) != sha256 for name, sha256 in original.items()):
        raise ValueError("Staged payload differs from the original Windows ZIP")
    with zipfile.ZipFile(package) as archive:
        names = [item.filename for item in archive.infolist() if not item.is_dir()]
        required = set(staged) | {"AppxBlockMap.xml", "[Content_Types].xml"}
        if (len({name.casefold() for name in names}) != len(names)
                or not required.issubset(names)
                or set(names) - required - {"AppxMetadata/CodeIntegrity.cat"}):
            raise ValueError("MSIX file set differs from the verified staging directory")
        for name in staged:
            if name == "AppxManifest.xml":
                continue
            with archive.open(name) as stream:
                sha256 = stream_digest(stream)
            if sha256 != staged[name]:
                raise ValueError(f"MSIX bytes differ from staging: {name}")
        manifest = ET.fromstring(archive.read("AppxManifest.xml"))
        ns = {"app": NS}
        actual = manifest.find("app:Identity", ns)
        if (actual is None or actual.attrib != identity
                or manifest.findtext("app:Properties/app:PublisherDisplayName", namespaces=ns) != publisher_display):
            raise ValueError("MSIX identity differs from the verified packaging inputs")
        application = manifest.find("app:Applications/app:Application", ns)
        if application is None or application.get("Executable") != "DontTouchMe.exe":
            raise ValueError("MSIX launch target differs from the verified executable")
        if archive.testzip() is not None:
            raise ValueError("MSIX failed ZIP integrity verification")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--identity-name", required=True, help="Exact MSIX Name from Partner Center")
    parser.add_argument("--publisher", required=True, help="Exact MSIX Publisher CN= from Partner Center")
    parser.add_argument("--display-name", default="Don't Touch Me.")
    parser.add_argument("--publisher-display-name", required=True, help="Exact PublisherDisplayName from Partner Center")
    parser.add_argument("--makeappx", help="Path to Windows SDK makeappx.exe")
    parser.add_argument("--release", choices=[ALPHA], help="Select the pinned historical Alpha release")
    parser.add_argument("--source-zip", type=Path, help="Original approved Windows ZIP for --release")
    parser.add_argument("--source-sha256", help="Optional cross-check against the historical manifest")
    parser.add_argument("--approved-icon", type=Path, help="Inventory-approved icon for finalized-release mode only")
    parser.add_argument("--stage-only", action="store_true", help="Validate and prepare contents without creating a package")
    args = parser.parse_args(argv)
    if not args.publisher_display_name.strip():
        raise ValueError("Partner Center PublisherDisplayName is required")
    historical = args.release is not None
    if historical != (args.source_zip is not None) or (not historical and args.source_sha256):
        raise ValueError("Use --release and --source-zip together for historical packaging")
    if historical and args.approved_icon:
        raise ValueError("Historical packaging uses the pinned release icon")
    provenance = {}
    if historical:
        source = args.source_zip
        windows_version, icon_bytes, provenance = historical_inputs(source, args.source_sha256)
        source_hash = provenance["source_sha256"]
        version = ALPHA.removeprefix("v")
        out = ROOT / "builds" / ALPHA
    else:
        catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
        version = catalog["version"]
        if f"v{version}" == ALPHA:
            raise ValueError(f"Use --release {ALPHA} with the original approved Windows ZIP")
        windows_version = catalog["windows_version"]
        out = ROOT / "builds" / f"v{version}"
        source = out / "windows" / f"DontTouchMe-v{version}-windows.zip"
        source_hash = verify_release(out, source, version)
        approved_icon = args.approved_icon or ROOT / ALPHA_ICON
        verify_approved_icon(approved_icon)
        icon_bytes = approved_icon.read_bytes()
    check_version(windows_version)
    tool = None if args.stage_only else find_makeappx(args.makeappx)
    dest_dir = out / "microsoft"
    dest = dest_dir / f"DontTouchMe-v{version}-x64.msix"
    receipt = dest_dir / "msix-receipt.json"
    if dest.exists() or receipt.exists():
        raise FileExistsError("MSIX or receipt already exists; never overwrite release artifacts")
    dest_dir.mkdir(parents=True, exist_ok=True)
    identity = {"Name": args.identity_name, "Publisher": args.publisher,
                "Version": windows_version, "ProcessorArchitecture": "x64"}
    with tempfile.TemporaryDirectory(prefix="msix-", dir=dest_dir) as staging:
        scratch = Path(staging)
        stage = scratch / "payload"
        stage.mkdir()
        # Snapshot the input and recheck it before extraction.
        snapshot = scratch / "original.zip"
        shutil.copyfile(source, snapshot)
        if digest(snapshot) != source_hash:
            raise ValueError("Approved Windows ZIP changed during staging")
        original = unpack_windows_zip(snapshot, stage)
        verify_x64(stage / "DontTouchMe.exe")
        if historical and original["DontTouchMe.exe"] != provenance["executable_sha256"]:
            raise ValueError("Alpha executable SHA-256 mismatch")
        icon = scratch / "approved.png"
        icon.write_bytes(icon_bytes)
        create_icons(icon, stage)
        create_manifest(stage, name=args.identity_name, publisher=args.publisher,
                        version=windows_version, display_name=args.display_name,
                        publisher_display=args.publisher_display_name)
        if args.stage_only:
            print(f"Validated MSIX staging from {source}; no package created")
            return 0
        package = scratch / "verified.msix"
        subprocess.run([str(tool), "pack", "/d", str(stage), "/p", str(package), "/no"], check=True)
        verify_package(package, stage, original, identity, args.publisher_display_name)
        metadata = {
            "game_version": version, "msix_version": windows_version,
            "source_windows_zip": str(source.resolve()), "source_sha256": source_hash,
            "msix": str(dest.relative_to(ROOT)), "msix_sha256": digest(package),
            "identity": identity, "publisher_display_name": args.publisher_display_name,
            "signing": "unsigned", "validation": "SDK pack, package integrity, identity and payload verified",
            "published": False, **provenance
        }
        if dest.exists() or receipt.exists():
            raise FileExistsError("MSIX or receipt already exists")
        package.rename(dest)
        with receipt.open("x", encoding="utf-8") as stream:
            json.dump(metadata, stream, indent=2)
            stream.write("\n")
    print(f"Built unsigned MSIX: {dest}\nSHA256: {digest(dest)}")
    print("Windows install/launch, Microsoft Store identity and Partner Center acceptance remain unverified")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, RuntimeError, OSError, KeyError, zipfile.BadZipFile,
            ET.ParseError, subprocess.CalledProcessError) as exc:
        print(f"MSIX build failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
