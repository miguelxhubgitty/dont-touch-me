"""Offline tests for the MSIX adapter. No Godot or Windows SDK required."""
import importlib.util
import hashlib
import json
import os
import shutil
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "release/tools/build_msix.py"
spec = importlib.util.spec_from_file_location("build_msix", SCRIPT)
msix = importlib.util.module_from_spec(spec)
spec.loader.exec_module(msix)


class MsixPackagingTests(unittest.TestCase):
    def test_store_version_format(self):
        msix.check_version("0.1.0.0")
        for value in ("0.1.0", "1.2.3.4.5", "1.2.3.1", "65536.0.0.0"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                msix.check_version(value)

    def test_manifest_uses_desktop_full_trust_and_real_identity(self):
        with tempfile.TemporaryDirectory() as work:
            stage = Path(work)
            msix.create_manifest(stage, name="Publisher.DontTouchMe",
                publisher="CN=00000000-0000-0000-0000-000000000000", version="0.1.0.0",
                display_name="Don't Touch Me.", publisher_display="WANDIEL")
            root = ET.parse(stage / "AppxManifest.xml").getroot()
            ns = "{" + msix.NS + "}"
            identity = root.find(ns + "Identity")
            self.assertEqual(identity.attrib["Name"], "Publisher.DontTouchMe")
            self.assertEqual(identity.attrib["ProcessorArchitecture"], "x64")
            self.assertEqual(root.find(".//{" + msix.RESCAP + "}Capability").attrib["Name"], "runFullTrust")
            self.assertEqual(root.find(".//" + ns + "Application").attrib["Executable"], "DontTouchMe.exe")
            self.assertEqual(root.find(".//" + ns + "Properties/" + ns + "DisplayName").text, "Don't Touch Me.")

    def test_unsafe_zip_and_missing_exe_rejected(self):
        for member in ("../escape.txt", r"Assets\StoreLogo.png", "AppxManifest.xml", "README.txt"):
            with self.subTest(member=member), tempfile.TemporaryDirectory() as work:
                stage = Path(work) / "stage"
                stage.mkdir()
                zipped = Path(work) / "in.zip"
                with zipfile.ZipFile(zipped, "w") as archive:
                    archive.writestr(member, b"content")
                with self.assertRaises(ValueError if member != "README.txt" else ValueError):
                    msix.unpack_windows_zip(zipped, stage)

    def test_verified_release_zip_hash(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            zipped = root / "windows" / "release.zip"
            zipped.parent.mkdir()
            with zipfile.ZipFile(zipped, "w") as archive:
                archive.writestr("DontTouchMe.exe", b"dummy test fixture")
            (root / "manifest.json").write_text(json.dumps({
                "version": "0.1.0-alpha",
                "artifacts": {"windows": {"status": "built",
                    "package": "windows/release.zip", "package_sha256": msix.digest(zipped)}}
            }), encoding="utf-8")
            msix.verify_release(root, zipped, "0.1.0-alpha")
            zipped.write_bytes(b"tampered")
            with self.assertRaises(ValueError):
                msix.verify_release(root, zipped, "0.1.0-alpha")

    def test_archive_rejects_case_collisions_and_windows_paths(self):
        for entries in (("Readme.txt", "README.TXT"), ("C:/escape",),
                        ("assets/other.png",), ("NUL.txt",), ("nested/../escape",)):
            with self.subTest(entries=entries), tempfile.TemporaryDirectory() as work:
                root = Path(work)
                zipped = root / "release.zip"
                stage = root / "stage"
                stage.mkdir()
                with zipfile.ZipFile(zipped, "w") as archive:
                    for entry in entries:
                        archive.writestr(entry, b"invalid")
                with self.assertRaises(ValueError):
                    msix.unpack_windows_zip(zipped, stage)
                self.assertEqual(list(stage.iterdir()), [])

    def test_package_verification(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            stage = root / "stage"
            stage.mkdir()
            executable = stage / "DontTouchMe.exe"
            executable.write_bytes(b"approved payload")
            identity = {"Name": "Publisher.DontTouchMe", "Publisher": "CN=example",
                        "Version": "0.1.0.0", "ProcessorArchitecture": "x64"}
            msix.create_manifest(stage, name=identity["Name"], publisher=identity["Publisher"],
                                 version=identity["Version"], display_name="Don't Touch Me.",
                                 publisher_display="WANDIEL")
            original = {executable.name: msix.digest(executable)}
            manifest = (stage / "AppxManifest.xml").read_bytes()
            package = root / "test.msix"

            def write_package(payload, xml, extra=None):
                with zipfile.ZipFile(package, "w") as archive:
                    archive.writestr(executable.name, payload)
                    archive.writestr("AppxManifest.xml", xml)
                    archive.writestr("AppxBlockMap.xml", b"fixture")
                    archive.writestr("[Content_Types].xml", b"fixture")
                    if extra:
                        archive.writestr(extra, b"unexpected")

            write_package(executable.read_bytes(), manifest)
            msix.verify_package(package, stage, original, identity, "WANDIEL")
            for payload, xml, extra, error in (
                (b"altered", manifest, None, "bytes differ"),
                (executable.read_bytes(), manifest.replace(b"CN=example", b"CN=wrong"), None, "identity differs"),
                (executable.read_bytes(), manifest.replace(b"WANDIEL", b"Other"), None, "identity differs"),
                (executable.read_bytes(), manifest, "audio.wav", "file set differs"),
            ):
                with self.subTest(error=error):
                    write_package(payload, xml, extra)
                    with self.assertRaisesRegex(ValueError, error):
                        msix.verify_package(package, stage, original, identity, "WANDIEL")

    def test_alpha_cannot_use_current_checkout_receipt(self):
        with tempfile.TemporaryDirectory() as work:
            catalog = Path(work) / "catalog.json"
            catalog.write_text(json.dumps({"version": "0.1.0-alpha"}), encoding="utf-8")
            args = ["--identity-name", "Test.DontTouchMe", "--publisher", "CN=Test",
                    "--publisher-display-name", "Test fixture", "--stage-only"]
            with patch.object(msix, "CATALOG", catalog):
                with self.assertRaisesRegex(ValueError, "original approved Windows ZIP"):
                    msix.main(args)

    def test_historical_gate_uses_only_pinned_inputs(self):
        with tempfile.TemporaryDirectory() as work:
            zipped = Path(work) / "original.zip"
            zipped.write_bytes(b"approved ZIP fixture")
            expected = msix.digest(zipped)
            commit, tag = "1" * 40, "2" * 40
            artifact = {"id": "windows", "platform": "windows", "format": "zip",
                        "architecture": "x64", "build_status": "tested", "build_version": "0.1.0.0",
                        "filename": zipped.name, "sha256": expected, "executable_sha256": "a" * 64}
            objects = dict.fromkeys(msix.RUNTIME_PATHS, "3" * 40)
            source = {"commit": commit, "tag_commit": tag, "tag": msix.ALPHA, "audio_included": False,
                      "runtime_fingerprint": {"method": "git-ls-tree-object-ids-v1", "objects": objects}}
            manifest = {"schema_version": 1, "release_version": msix.ALPHA,
                        "source": source, "artifacts": [artifact]}
            catalog = {"version": "0.1.0-alpha", "windows_version": "0.1.0.0",
                       "assets": {"branding": [msix.ALPHA_ICON]}}
            icon = b"pinned icon fixture"
            inventory = {"files": [{"file": msix.ALPHA_ICON.removeprefix("release/"),
                                    "hash_mode": "binary", "sha256": hashlib.sha256(icon).hexdigest()}]}

            local_tag = tag
            def git_fixture(command, *args):
                ref = args[-1]
                if command == "rev-parse":
                    if ref.startswith("refs/tags/"):
                        return local_tag.encode()
                    self.assertIn(ref.split(":")[0], (commit, tag))
                    return objects[ref.split(":")[1]].encode()
                if ref == f"{msix.ALPHA_RECORD}:{msix.ALPHA_MANIFEST}":
                    return json.dumps(manifest).encode()
                entries = {"release/catalog/game.json": json.dumps(catalog).encode(),
                           msix.ALPHA_ICON: icon,
                           "release/assets-inventory.json": json.dumps(inventory).encode()}
                self.assertTrue(ref.startswith(tag + ":"))
                return entries[ref.split(":")[1]]

            with patch.object(msix, "git_bytes", side_effect=git_fixture):
                version, approved_icon, record = msix.historical_inputs(zipped, expected)
                self.assertEqual((version, approved_icon, record["source_sha256"]),
                                 ("0.1.0.0", icon, expected))
                local_tag = "4" * 40
                with self.assertRaisesRegex(ValueError, "tag differs"):
                    msix.historical_inputs(zipped, None)
                local_tag = tag
                source["audio_included"] = True
                with self.assertRaisesRegex(ValueError, "source record"):
                    msix.historical_inputs(zipped, None)
                source["audio_included"] = False
                artifact["build_version"] = "9.9.9.0"
                with self.assertRaisesRegex(ValueError, "selected Alpha artifact"):
                    msix.historical_inputs(zipped, None)
                artifact["build_version"] = "0.1.0.0"
                inventory["files"][0]["sha256"] = "0" * 64
                with self.assertRaisesRegex(ValueError, "artwork|inventory"):
                    msix.historical_inputs(zipped, None)
                inventory["files"][0]["sha256"] = hashlib.sha256(icon).hexdigest()
                zipped.write_bytes(b"audio-enabled development ZIP fixture")
                with self.assertRaisesRegex(ValueError, "approved Alpha SHA-256"):
                    msix.historical_inputs(zipped, msix.digest(zipped))
            with patch.object(msix, "git_bytes", side_effect=ValueError("missing manifest")):
                with self.assertRaisesRegex(ValueError, "missing manifest"):
                    msix.historical_inputs(zipped, None)

    @unittest.skipUnless(os.environ.get("DTM_ALPHA_WINDOWS_ZIP"), "Set DTM_ALPHA_WINDOWS_ZIP for real Alpha input")
    def test_original_alpha_staging_ignores_development_checkout(self):
        source = Path(os.environ["DTM_ALPHA_WINDOWS_ZIP"])
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            development = root / "game.json"
            development.write_text('{"version":"99.0","windows_version":"99.0.0.0"}', encoding="utf-8")
            git_root = msix.ROOT
            git_read = msix.git_bytes

            def pinned_git(*args):
                with patch.object(msix, "ROOT", git_root):
                    return git_read(*args)

            with patch.object(msix, "ROOT", root), patch.object(msix, "CATALOG", development), \
                    patch.object(msix, "git_bytes", side_effect=pinned_git):
                args = ["--release", msix.ALPHA, "--source-zip", str(source),
                        "--identity-name", "Test.DontTouchMe", "--publisher", "CN=Test",
                        "--publisher-display-name", "Test fixture", "--stage-only"]
                self.assertEqual(msix.main(args), 0)
                self.assertFalse(list(root.rglob("*.msix")))
                altered = root / source.name
                shutil.copyfile(source, altered)
                with altered.open("ab") as stream:
                    stream.write(b"tampered")
                args[3] = str(altered)
                with self.assertRaisesRegex(ValueError, "approved Alpha SHA-256"):
                    msix.main(args + ["--source-sha256", msix.digest(altered)])

    def test_approved_icon_resized_only_at_package_time(self):
        try:
            from PIL import Image
        except ImportError:
            self.skipTest("Pillow is optional until Windows MSIX packaging")
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            source = root / "approved.png"
            Image.new("RGBA", (512, 512), (10, 20, 30, 255)).save(source)
            msix.create_icons(source, root)
            for size, name in ((44, "Square44x44Logo.png"), (150, "Square150x150Logo.png"), (50, "StoreLogo.png")):
                with Image.open(root / "Assets" / name) as image:
                    self.assertEqual(image.size, (size, size))


if __name__ == "__main__":
    unittest.main()
