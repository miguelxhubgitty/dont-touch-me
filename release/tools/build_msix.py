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
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "release/catalog/game.json"
NS = "http://schemas.microsoft.com/appx/manifest/foundation/windows10"
UAP = "http://schemas.microsoft.com/appx/manifest/uap/windows10"
RESCAP = "http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
ET.register_namespace("", NS)
ET.register_namespace("uap", UAP)
ET.register_namespace("rescap", RESCAP)


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def check_version(version: str) -> None:
    values = version.split(".")
    if len(values) != 4 or any(not x.isdigit() or int(x) > 65535 for x in values):
        raise ValueError("MSIX version must have four numeric parts in 0..65535")
    if int(values[3]) != 0:
        raise ValueError("Microsoft Store MSIX requires a zero fourth version component")


def verify_release(out: Path, source: Path, version: str) -> None:
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


def unpack_windows_zip(source: Path, stage: Path) -> None:
    with zipfile.ZipFile(source) as archive:
        for item in archive.infolist():
            name = PurePosixPath(item.filename)
            if (name.is_absolute() or ".." in name.parts or "\\" in item.filename
                    or name.name == "AppxManifest.xml" or name.parts[:1] == ("Assets",)):
                raise ValueError(f"Unsafe or reserved ZIP entry: {item.filename}")
            if item.is_dir():
                continue
            target = stage.joinpath(*name.parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(item) as src, target.open("wb") as dst:
                shutil.copyfileobj(src, dst)
    if not (stage / "DontTouchMe.exe").is_file():
        raise ValueError("Release ZIP must contain DontTouchMe.exe at the root")


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
    match = next((item for item in inventory.get("files", [])
                  if item.get("file") == relative and item.get("hash_mode") == "binary"), None)
    if not match or digest(approved_icon) != match.get("sha256"):
        raise ValueError("MSIX icon does not match the owner-reviewed release inventory")


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
    if not publisher.startswith("CN=") or not publisher.strip():
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


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--identity-name", required=True, help="Exact MSIX Name from Partner Center")
    parser.add_argument("--publisher", required=True, help="Exact MSIX Publisher CN= from Partner Center")
    parser.add_argument("--display-name", default="Don't Touch Me.")
    parser.add_argument("--publisher-display-name", default="WANDIEL")
    parser.add_argument("--makeappx", help="Path to Windows SDK makeappx.exe")
    parser.add_argument("--source-zip", type=Path, help="Existing approved release ZIP, rather than local builds output")
    parser.add_argument("--source-sha256", help="Required SHA-256 when using --source-zip")
    parser.add_argument("--approved-icon", type=Path, default=ROOT / "release/assets/icons/google-play-512.png")
    parser.add_argument("--stage-only", action="store_true", help="Validate and prepare contents without creating a package")
    args = parser.parse_args(argv)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    version = catalog["version"]
    out = ROOT / "builds" / f"v{version}"
    source = args.source_zip or out / "windows" / f"DontTouchMe-v{version}-windows.zip"
    check_version(catalog["windows_version"])
    if not source.is_file():
        raise FileNotFoundError(f"Produce or obtain the approved Windows ZIP first: {source}")
    if args.source_zip:
        if not args.source_sha256 or not re.fullmatch(r"[a-fA-F0-9]{64}", args.source_sha256):
            raise ValueError("--source-zip requires the official 64-character --source-sha256")
        if digest(source).lower() != args.source_sha256.lower():
            raise ValueError("Existing release ZIP failed supplied official SHA-256 check")
    else:
        verify_release(out, source, version)
    dest_dir = out / "microsoft"
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"DontTouchMe-v{version}-x64.msix"
    if dest.exists():
        raise FileExistsError(f"MSIX already exists; never overwrite release artifacts: {dest}")
    with tempfile.TemporaryDirectory(prefix="msix-", dir=dest_dir) as staging:
        stage = Path(staging)
        unpack_windows_zip(source, stage)
        verify_approved_icon(args.approved_icon)
        create_icons(args.approved_icon, stage)
        create_manifest(stage, name=args.identity_name, publisher=args.publisher,
                        version=catalog["windows_version"], display_name=args.display_name,
                        publisher_display=args.publisher_display_name)
        if args.stage_only:
            print(f"Valid MSIX staging inputs prepared from verified Windows ZIP: {source}")
            print("No .msix created (--stage-only); no Store installation or certification tested")
            return 0
        tool = find_makeappx(args.makeappx)
        subprocess.run([str(tool), "pack", "/d", str(stage), "/p", str(dest), "/no"], check=True)
    with zipfile.ZipFile(dest) as archive:
        required = {"AppxManifest.xml", "AppxBlockMap.xml", "[Content_Types].xml", "DontTouchMe.exe"}
        if not required.issubset(archive.namelist()) or archive.testzip() is not None:
            raise RuntimeError("Incomplete or corrupt MSIX; do not upload")
    metadata = {
        "game_version": version, "msix_version": catalog["windows_version"],
        "source_windows_zip": str(source.resolve()), "source_sha256": digest(source),
        "msix": str(dest.relative_to(ROOT)), "msix_sha256": digest(dest),
        "identity_name": args.identity_name, "publisher": args.publisher,
        "display_name": args.display_name, "signing": "unsigned; Microsoft Store signs upon approval",
        "validation": "MakeAppx pack and archive integrity only; no Windows install, launch, or Store approval verified",
        "published": False
    }
    (dest_dir / "msix-receipt.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(f"Built unsigned MSIX: {dest}\nSHA256: {digest(dest)}")
    print("Windows install/launch, Microsoft Store identity and Partner Center acceptance remain unverified")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, RuntimeError, FileNotFoundError, subprocess.CalledProcessError) as exc:
        print(f"MSIX build failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
