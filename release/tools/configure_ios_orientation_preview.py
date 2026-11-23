"""Permit the fixed landscape selection in a generated iPhone Info.plist.

Accepts only the iOS Orientation Preview and the production iOS bundle identifiers.
"""

import plistlib
import re
import sys
from pathlib import Path


PREVIEW_ID = "com.littlebutterflyproductions.donttouchme.orientationpreview"
PRODUCTION_ID = "com.littlebutterflyproductions.donttouchme"
ACCEPTED_IDS = (PREVIEW_ID, PRODUCTION_ID)


def resolve_bundle_id(path, settings):
    bundle_id = settings.get("CFBundleIdentifier")
    if bundle_id == "$(PRODUCT_BUNDLE_IDENTIFIER)":
        project = path.parent.with_suffix(".xcodeproj") / "project.pbxproj"
        if project.is_file():
            identifiers = set(re.findall(r"\bPRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);", project.read_text(encoding="utf-8")))
            if len(identifiers) == 1:
                bundle_id = identifiers.pop()
    return bundle_id


def configure(path):
    path = Path(path)
    with path.open("rb") as stream:
        settings = plistlib.load(stream)
    bundle_id = resolve_bundle_id(path, settings)
    if bundle_id not in ACCEPTED_IDS:
        raise SystemExit("Select the generated iOS or iOS Orientation Preview Info.plist.")
    settings["UISupportedInterfaceOrientations"] = [
        "UIInterfaceOrientationPortrait",
        "UIInterfaceOrientationLandscapeLeft",
        "UIInterfaceOrientationLandscapeRight",
    ]
    with path.open("wb") as stream:
        plistlib.dump(settings, stream, sort_keys=False)
    return bundle_id


if __name__ == "__main__":
    configure(sys.argv[1])
