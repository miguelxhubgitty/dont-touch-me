"""Regression checks for the iOS launch screen (no default Godot logo)."""

import configparser
import struct
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LAUNCH_IMAGE = "res://release/ios/launch-transparent.png"
PREVIEW_ID = "com.littlebutterflyproductions.donttouchme.orientationpreview"


def load_presets():
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    parser.read(ROOT / "export_presets.cfg", encoding="utf-8")
    return parser


def ios_presets(parser):
    found = []
    for section in parser.sections():
        if section.count(".") == 1 and parser.get(section, "platform", fallback="") == '"iOS"':
            found.append((parser.get(section, "name").strip('"'), parser[section + ".options"]))
    return found


def png_pixels(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, header, idat = 8, None, b""
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    return header, zlib.decompress(idat)


class IosLaunchScreenTests(unittest.TestCase):
    def test_every_ios_preset_replaces_storyboard_images(self):
        presets = ios_presets(load_presets())
        self.assertTrue(presets, "no iOS preset found")
        for name, options in presets:
            for key in ("storyboard/custom_image@2x", "storyboard/custom_image@3x"):
                with self.subTest(preset=name, key=key):
                    self.assertEqual(options.get(key, "").strip('"'), LAUNCH_IMAGE)

    def test_launch_image_is_fully_transparent(self):
        path = ROOT / LAUNCH_IMAGE.removeprefix("res://")
        (width, height, depth, color, _, _, interlace), raw = png_pixels(path)
        self.assertEqual((width, height, depth, color, interlace), (1, 1, 8, 6, 0))
        self.assertEqual(len(raw), 1 + width * 4)
        self.assertEqual(raw[1 + 3], 0, "launch image alpha must be zero")

    def test_launch_image_stays_out_of_the_game_package(self):
        self.assertTrue((ROOT / "release/.gdignore").is_file())
        for name, _ in ios_presets(load_presets()):
            parser = load_presets()
            section = next(s for s in parser.sections() if s.count(".") == 1 and parser.get(s, "name").strip('"') == name)
            with self.subTest(preset=name):
                self.assertIn("release/*", parser.get(section, "exclude_filter"))

    def test_engine_boot_splash_and_preview_identity_unchanged(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        self.assertIn("boot_splash/show_image=false", project)
        self.assertIn("boot_splash/bg_color=Color(0.965, 0.949, 0.914, 1)", project)
        presets = dict(ios_presets(load_presets()))
        preview = presets["iOS Orientation Preview"]
        self.assertEqual(preview["application/bundle_identifier"].strip('"'), PREVIEW_ID)
        self.assertEqual(preview["application/min_ios_version"].strip('"'), "14.0")


if __name__ == "__main__":
    unittest.main()
