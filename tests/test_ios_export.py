"""iOS export preset and post-export orientation plist regressions."""
import importlib.util
import plistlib
import re
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('ios_orientation', ROOT / 'release/tools/configure_ios_orientation_preview.py')
ios_orientation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ios_orientation)

PREVIEW_ID = 'com.littlebutterflyproductions.donttouchme.orientationpreview'
PRODUCTION_ID = 'com.littlebutterflyproductions.donttouchme'
WIDENED = ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight']


def ios_presets():
    text = (ROOT / 'export_presets.cfg').read_text(encoding='utf-8')
    sections = {}
    for match in re.finditer(r'(?m)^\[(preset\.\d+(?:\.options)?)\]\n(.*?)(?=^\[|\Z)', text, re.S):
        sections[match[1]] = dict(re.findall(r'(?m)^([^=\n]+)=(.*)$', match[2]))
    presets = {}
    for key, values in sections.items():
        if not key.endswith('.options') and values.get('platform') == '"iOS"':
            presets[values['name'].strip('"')] = (values, sections[key + '.options'])
    return presets


class IosPresetTests(unittest.TestCase):
    def test_preview_preset_is_unchanged(self):
        preset, options = ios_presets()['iOS Orientation Preview']
        self.assertEqual(options['application/bundle_identifier'], f'"{PREVIEW_ID}"')
        self.assertEqual(options['application/min_ios_version'], '"14.0"')
        self.assertEqual(preset['custom_features'], '"manual_ios_orientation"')

    def test_production_preset_uses_production_identity_and_ios_15(self):
        preset, options = ios_presets()['iOS']
        self.assertEqual(options['application/bundle_identifier'], f'"{PRODUCTION_ID}"')
        self.assertEqual(options['application/min_ios_version'], '"15.0"')
        self.assertEqual(options['application/app_store_team_id'], '""', 'team is set at signing time, not committed')
        self.assertEqual(options['application/export_project_only'], 'true')
        self.assertEqual(options['application/targeted_device_family'], '0', 'iPhone only')
        self.assertEqual(options['architectures/arm64'], 'true')
        self.assertEqual(options['icons/app_store_1024x1024'], '"res://assets/icon_ios.png"')
        # Approved 0.1.1 iOS version and build (release/IOS_EXPORT.md); never the macOS build.
        self.assertEqual(options['application/short_version'], '"0.1.1"')
        self.assertEqual(options['application/version'], '"2"')

    def test_production_preset_keeps_preview_orientation_and_content(self):
        presets = ios_presets()
        preview, preview_options = presets['iOS Orientation Preview']
        production, production_options = presets['iOS']
        for key in ('custom_features', 'export_filter', 'include_filter', 'exclude_filter', 'script_export_mode'):
            self.assertEqual(production[key], preview[key], key)
        # Version and build are release metadata of the production preset only.
        ignored = {'application/bundle_identifier', 'application/min_ios_version',
                   'application/short_version', 'application/version'}
        self.assertEqual({k: v for k, v in production_options.items() if k not in ignored},
                         {k: v for k, v in preview_options.items() if k not in ignored})

    def test_bundle_identifiers_stay_distinct(self):
        identifiers = [options['application/bundle_identifier'] for _, options in ios_presets().values()]
        self.assertEqual(len(identifiers), len(set(identifiers)))


class OrientationPlistTests(unittest.TestCase):
    def export(self, folder, plist_id, project_ids=()):
        target = Path(folder) / 'DontTouchMe'
        target.mkdir()
        plist = target / 'DontTouchMe-Info.plist'
        with plist.open('wb') as stream:
            plistlib.dump({'CFBundleIdentifier': plist_id, 'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait'], 'UIRequiresFullScreen': True}, stream)
        if project_ids:
            project = Path(folder) / 'DontTouchMe.xcodeproj'
            project.mkdir()
            (project / 'project.pbxproj').write_text(''.join(f'PRODUCT_BUNDLE_IDENTIFIER = {i};\n' for i in project_ids), encoding='utf-8')
        return plist

    def read(self, plist):
        with plist.open('rb') as stream:
            return plistlib.load(stream)

    def test_widens_preview_and_production_only(self):
        for identifier in (PREVIEW_ID, PRODUCTION_ID):
            with tempfile.TemporaryDirectory() as folder:
                plist = self.export(folder, '$(PRODUCT_BUNDLE_IDENTIFIER)', [identifier, identifier])
                self.assertEqual(ios_orientation.configure(plist), identifier)
                settings = self.read(plist)
                self.assertEqual(settings['UISupportedInterfaceOrientations'], WIDENED)
                self.assertEqual(settings['CFBundleIdentifier'], '$(PRODUCT_BUNDLE_IDENTIFIER)')
                self.assertTrue(settings['UIRequiresFullScreen'])

    def test_rejects_unknown_or_ambiguous_identifiers(self):
        cases = (('com.example.other', ()), ('$(PRODUCT_BUNDLE_IDENTIFIER)', [PREVIEW_ID, PRODUCTION_ID]),
                 ('$(PRODUCT_BUNDLE_IDENTIFIER)', ()))
        for plist_id, project_ids in cases:
            with tempfile.TemporaryDirectory() as folder:
                plist = self.export(folder, plist_id, project_ids)
                before = plist.read_bytes()
                with self.assertRaises(SystemExit):
                    ios_orientation.configure(plist)
                self.assertEqual(plist.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
