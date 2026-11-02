"""Upload-blocking regressions; no credentials, network, renders or real approvals."""
import copy
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('visual_assets', ROOT/'release/tools/visual_assets.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)


class VisualGates(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inputs = v.source_inputs(ROOT)
        cls.blobs = {p: v.git_bytes(ROOT, p) for p in v.ALPHA_ART.values()}

    def setUp(self):
        scratch = ROOT/'test-output/visual-audit'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='visual-test-', dir=scratch)
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT/v.DIRECTORY, self.root/v.DIRECTORY)
        (self.root/v.RENDERER).parent.mkdir(parents=True)
        shutil.copyfile(ROOT/v.RENDERER, self.root/v.RENDERER)
        self.patches = [patch.object(v, 'source_inputs', return_value=self.inputs),
                        patch.object(v, 'git_bytes', side_effect=lambda root, p: self.blobs[p]),
                        patch.object(v.subprocess, 'check_output', return_value=v.COMMIT+'\n')]
        for p in self.patches:
            p.start()
        self.manifest = v.read(self.root/v.MANIFEST)
        # Negative fixtures never inherit real owner consent.
        for asset in self.manifest['assets']:
            if 'microsoft' in asset['human_review']:
                asset['human_review']['microsoft']['status'] = 'pending'
        self.write()

    def tearDown(self):
        for p in reversed(self.patches):
            p.stop()
        assert self.root.resolve().is_relative_to((ROOT/'test-output/visual-audit').resolve())
        self.temp.cleanup()

    def write(self):
        (self.root/v.MANIFEST).write_text(json.dumps(self.manifest), encoding='utf-8')

    def check(self, **kwargs):
        return v.validate('microsoft', root=self.root, **kwargs)

    def approve_fixture(self):
        result = self.check(require_review=False)
        for a in self.manifest['assets']:
            if 'microsoft' in a['destinations']:
                a['human_review']['microsoft'] = {
                    'status': 'approved', 'reviewer_role': 'owner', 'reviewer': 'UNIT TEST ONLY',
                    'reviewed_at': '2026-11-02', 'approval_reference': 'synthetic fixture, never real approval',
                    'approved_sha256': a['sha256'], 'manifest_fingerprint': result['manifest_fingerprint']}
        self.write()

    def test_real_package_technical_pass_never_implies_owner_approval(self):
        result = self.check(require_review=False)
        self.assertFalse(result['upload_ready'])
        self.assertEqual(len(result['assets']), 9)
        with self.assertRaisesRegex(ValueError, 'Owner visual review pending'):
            self.check()

    def test_complete_reviewed_fixture_passes_but_partial_review_fails(self):
        self.approve_fixture()
        self.assertTrue(self.check()['upload_ready'])
        asset = next(a for a in self.manifest['assets'] if 'microsoft' in a['destinations'])
        asset['human_review']['microsoft']['status'] = 'pending'
        self.write()
        with self.assertRaises(ValueError):
            self.check()

    def test_stale_or_bot_review_is_rejected(self):
        self.approve_fixture()
        for field, value in [('approved_sha256', '0'*64), ('manifest_fingerprint', '0'*64),
                             ('reviewer_role', 'automation'), ('approval_reference', None)]:
            original = copy.deepcopy(self.manifest)
            next(a for a in self.manifest['assets'] if 'microsoft' in a['destinations'])['human_review']['microsoft'][field] = value
            self.write()
            with self.assertRaises(ValueError):
                self.check()
            self.manifest = original

    def test_changed_asset_and_crc_corruption_fail(self):
        asset = self.manifest['assets'][-1]
        path = self.root/asset['filename']
        data = path.read_bytes()
        path.write_bytes(data[:-5]+b'wrong')
        with self.assertRaises(ValueError):
            self.check(require_review=False)

    def test_wrong_typography_and_forged_source_identity_fail(self):
        self.manifest['typography']['primary'] = 'fallback font'
        self.write()
        with self.assertRaisesRegex(ValueError, 'typography'):
            self.check(require_review=False)
        self.manifest['typography'] = copy.deepcopy(v.STYLE)
        self.manifest['source_inputs']['scripts/typography.gd'] = 'f'*64
        self.write()
        with self.assertRaisesRegex(ValueError, 'provenance'):
            self.check(require_review=False)

    def test_main_image_cannot_be_laundered_by_refreshing_manifest_hash(self):
        asset = self.manifest['assets'][0]
        path = self.root/asset['filename']
        data = (ROOT/'release/assets/screenshots/google-play/01-calm.png').read_bytes()
        self.assertNotEqual(v.sha(data), asset['sha256'])
        path.write_bytes(data)
        asset['sha256'] = v.sha(data)
        self.write()
        with self.assertRaisesRegex(ValueError, 'Wrong Alpha typography/source bytes'):
            self.check(require_review=False)

    def test_unlisted_path_traversal_duplicates_and_incomplete_set_fail(self):
        for paths in [['release/assets/google-play-feature-1024x500.png'], ['../../outside.png'], []]:
            with self.assertRaises(ValueError):
                self.check(paths=paths)
        paths = [a['filename'] for a in self.manifest['assets'] if 'microsoft' in a['destinations']]
        for selection in [paths[:-1], paths+[paths[0]]]:
            with self.assertRaises(ValueError):
                self.check(paths=selection)
        with self.assertRaises(ValueError):
            v.safe(self.root, '../outside.png')

    def test_missing_assets_wrong_size_and_renderer_changes_fail(self):
        original = copy.deepcopy(self.manifest)
        self.manifest['assets'].pop()
        self.write()
        with self.assertRaisesRegex(ValueError, 'Missing'):
            self.check(require_review=False)
        self.manifest = original
        self.manifest['assets'][-1]['dimensions'] = [1920, 1080]
        self.write()
        with self.assertRaises(ValueError):
            self.check(require_review=False)
        (self.root/v.RENDERER).write_text('fallback renderer')
        with self.assertRaisesRegex(ValueError, 'provenance'):
            self.check(require_review=False)

    def test_resize_claim_and_receipt_tampering_fail(self):
        receipt_path = self.root/v.DIRECTORY/'assets/microsoft/render-receipt.json'
        receipt = v.read(receipt_path)
        receipt['assets'][0]['post_capture_resize'] = True
        receipt_path.write_text(json.dumps(receipt))
        self.manifest['render_receipt_sha256'] = v.canonical(receipt)
        self.write()
        with self.assertRaisesRegex(ValueError, 'resizing'):
            self.check(require_review=False)

    def test_platform_version_and_approval_cannot_be_reused_elsewhere(self):
        self.approve_fixture()
        with self.assertRaises(ValueError):
            v.validate('gamejolt', root=self.root)
        with self.assertRaises(ValueError):
            v.validate('microsoft', version='next', root=self.root)
        with self.assertRaises(ValueError):
            v.validate('unknown-store', root=self.root)

    def test_text_receipt_line_endings_are_portable(self):
        receipt_path = self.root/v.DIRECTORY/'assets/microsoft/render-receipt.json'
        receipt_path.write_bytes(receipt_path.read_bytes().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n'))
        self.assertEqual(self.check(require_review=False)['technical_validation'], 'passed')


class PublishingIntegration(unittest.TestCase):
    def test_real_manifest_approval_state_is_enforced(self):
        manifest = v.technical(ROOT)
        microsoft = [a for a in manifest['assets'] if 'microsoft' in a['destinations']]
        approved = all(a['human_review']['microsoft']['status'] == 'approved' for a in microsoft)
        if approved:
            result = v.validate('microsoft', root=ROOT)
            self.assertTrue(result['upload_ready'])
            self.assertFalse(result['submission_authorized'])
        else:
            with self.assertRaisesRegex(ValueError, 'Owner visual review pending'):
                v.validate('microsoft', root=ROOT)
        # Approval for Microsoft must never be inherited by another destination.
        with self.assertRaisesRegex(ValueError, 'Owner visual review pending'):
            v.validate('gamejolt', root=ROOT)


if __name__ == '__main__':
    unittest.main()
