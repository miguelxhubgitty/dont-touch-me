"""Permit the fixed landscape selection in the generated iPhone preview plist."""

import plistlib
import re
import sys
from pathlib import Path


path = Path(sys.argv[1])
with path.open("rb") as stream:
    settings = plistlib.load(stream)

preview_id = "com.littlebutterflyproductions.donttouchme.orientationpreview"
bundle_id = settings.get("CFBundleIdentifier")
if bundle_id == "$(PRODUCT_BUNDLE_IDENTIFIER)":
    project = path.parent.with_suffix(".xcodeproj") / "project.pbxproj"
    if project.is_file():
        identifiers = set(re.findall(r"\bPRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);", project.read_text(encoding="utf-8")))
        if identifiers == {preview_id}:
            bundle_id = preview_id
if bundle_id != preview_id:
    raise SystemExit("Select the generated iOS Orientation Preview Info.plist.")

settings["UISupportedInterfaceOrientations"] = [
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
]
with path.open("wb") as stream:
    plistlib.dump(settings, stream, sort_keys=False)
