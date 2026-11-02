"""Offline Microsoft readiness guards; never create products or upload anything."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('microsoft_store', ROOT/'release/tools/microsoft_store.py')
ms = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ms)


class MicrosoftGuards(unittest.TestCase):
    def test_actual_visual_approval_does_not_bypass_product_name_blocker(self):
        result = ms.plan()
        self.assertTrue(result['visuals']['upload_ready'])
        self.assertFalse(result['submission_ready'])
        self.assertIsNone(result['status']['product_id'])
        self.assertFalse(result['status']['name_check']['available'])
        with self.assertRaisesRegex(ValueError, 'name unavailable'):
            ms.require_submission_ready()

    def test_corrupt_or_substituted_windows_archive_rejected(self):
        with self.assertRaisesRegex(ValueError, 'archive changed'):
            ms.verify_archive(b'not the approved Alpha')

    def test_other_version_or_missing_authorization_is_not_inherited(self):
        scratch = ROOT/'test-output/microsoft-tests'
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=scratch) as folder:
            root = Path(folder)
            path = root/ms.STATUS_PATH
            path.parent.mkdir(parents=True)
            status = json.loads((ROOT/ms.STATUS_PATH).read_text(encoding='utf-8'))
            status['version'] = 'different'
            path.write_text(json.dumps(status))
            with patch.object(ms, 'visuals', return_value={'upload_ready': True}):
                with self.assertRaisesRegex(ValueError, 'authorization'):
                    ms.plan(root)
                status['version'] = ms.VERSION
                status['authorization']['owner_authorized'] = False
                path.write_text(json.dumps(status))
                with self.assertRaisesRegex(ValueError, 'authorization'):
                    ms.plan(root)

    def test_payload_input_can_be_staged_without_fake_store_identity(self):
        # Synthetic approved archive; no production game bytes or approvals edited.
        exe = bytearray(128)
        exe[:2] = b'MZ'
        struct.pack_into('<I', exe, 0x3c, 64)
        exe[64:68] = b'PE\0\0'
        struct.pack_into('<H', exe, 68, 0x8664)
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, 'w') as archive:
            archive.writestr('DontTouchMe.exe', exe)
            archive.writestr('LICENSES/OFL.txt', 'fixture notice')
        data = buffer.getvalue()
        scratch = ROOT/'test-output/microsoft-tests'
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=scratch) as folder:
            root = Path(folder)
            package = root/'approved.zip'
            package.write_bytes(data)
            with patch.object(ms, 'plan', return_value={}), patch.object(ms, 'WINDOWS_SIZE', len(data)), patch.object(ms, 'WINDOWS_SHA256', hashlib.sha256(data).hexdigest()):
                result = ms.stage_payload(package, root)
                self.assertFalse(result['store_package_created'])
                ms.stage_payload(package, root)  # identical staging reuses files
                output = root/'builds/microsoft-v0.1.0-alpha/payload/DontTouchMe.exe'
                self.assertEqual(output.read_bytes(), exe)
                output.write_bytes(b'changed')
                with self.assertRaisesRegex(ValueError, 'payload changed'):
                    ms.stage_payload(package, root)


if __name__ == '__main__':
    unittest.main()
