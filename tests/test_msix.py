"""Offline tests for the MSIX adapter. No Godot or Windows SDK required."""
import importlib.util
import json
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

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
