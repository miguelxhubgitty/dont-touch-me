"""Release audio policy regressions using source files and disposable pack fixtures."""
import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('release_workflow', ROOT / 'release/tools/release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class AudioApprovalTests(unittest.TestCase):
    def test_active_assets_match_reviewed_sources_and_notice(self):
        streams = release.approved_audio()
        self.assertEqual(len(streams), 18)
        self.assertEqual(sum(entry['license'] == 'CC0-1.0' for entry in streams.values()), 4)
        servo = streams['audio/voice/robot_servo_mit.wav']
        self.assertEqual(servo['license'], 'MIT')
        notice = (ROOT / servo['notice']).read_text(encoding='utf-8').strip()
        self.assertIn('Copyright (c) 2026 CureJe', notice)
        self.assertIn('Permission is hereby granted', notice)
        self.assertIn('THE SOFTWARE IS PROVIDED "AS IS"', notice)

    def test_source_changes_require_review(self):
        original_load = release.load
        for change, expected in [
            ({'license': 'CC-BY-NC-3.0'}, 'Unapproved audio license'),
            ({'sha256': '0' * 64}, 'Approved audio checksum mismatch'),
            ({'notice': 'THIRD_PARTY_NOTICES.txt', 'license': 'NOASSERTION'}, 'Unapproved audio license'),
        ]:
            with self.subTest(change=change):
                def altered(path):
                    content = original_load(path)
                    if path == ROOT / release.AUDIO_MANIFEST:
                        content['streams']['audio/voice/robot_servo_mit.wav'].update(change)
                    return content

                with patch.object(release, 'load', side_effect=altered), self.assertRaisesRegex(RuntimeError, expected):
                    release.approved_audio()

    def test_enabling_unreviewed_clip_is_rejected(self):
        original_load = release.load

        def altered(path):
            content = original_load(path)
            if path == ROOT / release.AUDIO_MAP:
                content['events']['unreviewed'] = {
                    'enabled': True, 'stream': 'res://audio/voice/puppy_real_3.ogg',
                }
            return content

        with patch.object(release, 'load', side_effect=altered), self.assertRaisesRegex(RuntimeError, 'Audio approval mismatch'):
            release.approved_audio()

    def test_committed_presets_match_generated_policy(self):
        presets = (ROOT / 'export_presets.cfg').read_text(encoding='utf-8')
        self.assertEqual(release.audio_export_filters(presets), presets)
        new_preset = 'include_filter="THIRD_PARTY_NOTICES.txt"\nexclude_filter="tests/*"\n'
        filters = release.audio_export_filters(new_preset)
        self.assertIn('audio/blob_events.json', filters)
        self.assertIn('audio/prototypes/*', filters)
        self.assertIn('audio/voice/puppy_real_3.ogg.import', filters)
        self.assertNotIn('audio/voice/puppy_real_1.ogg', filters)


class AudioPackTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'audio.zip'
        self.files = {name: (ROOT / name).read_bytes() for name in (release.AUDIO_MAP, release.NOTICES)}
        for stream in release.approved_audio():
            payload = f'.godot/imported/{Path(stream).name}.sample'
            self.files[stream + '.import'] = f'[remap]\npath="res://{payload}"\n'.encode('utf-8')
            self.files[payload] = b'disposable audio fixture'

    def pack(self):
        with zipfile.ZipFile(self.path, 'w') as pack:
            for name, data in self.files.items():
                pack.writestr(name, data)
        return release.inspect_audio_pack(self.path)

    def test_approved_payloads_and_notice_pass(self):
        result = self.pack()
        self.assertEqual(set(result['stream_payload_sha256']), set(release.approved_audio()))
        self.assertEqual(result['pack_sha256'], release.sha(self.path))

    def test_leaked_candidate_raw_or_compiled_media_is_rejected(self):
        for leak in ('audio/candidate_pack/event_assignments.json',
                     'audio/prototypes/noncommercial.wav.import',
                     '.godot/imported/noncommercial.wav.sample', 'outside-audio/unreviewed.mp3'):
            with self.subTest(leak=leak):
                self.files[leak] = b'unreviewed'
                with self.assertRaisesRegex(RuntimeError, 'Unexpected packaged audio'):
                    self.pack()
                del self.files[leak]

    def test_missing_active_payload_is_rejected(self):
        del self.files['.godot/imported/robot_servo_mit.wav.sample']
        with self.assertRaisesRegex(RuntimeError, 'Missing packaged audio payload'):
            self.pack()

    def test_stale_packaged_notice_is_rejected(self):
        self.files[release.NOTICES] = b'old engine-only notices'
        with self.assertRaisesRegex(RuntimeError, 'stale packaged file'):
            self.pack()

    def test_stale_packaged_event_map_is_rejected(self):
        self.files[release.AUDIO_MAP] = b'{}'
        with self.assertRaisesRegex(RuntimeError, 'stale packaged file'):
            self.pack()


class AudioReceiptTests(unittest.TestCase):
    def test_audio_and_scene_edits_invalidate_validation_receipts(self):
        for relative in ('audio/blob_events.json', 'audio/voice/sample.wav', 'scenes/blob/blob.tscn',
                         release.AUDIO_MANIFEST, 'release/licenses/cureje-mit.txt'):
            with self.subTest(path=relative), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                file = root / relative
                file.parent.mkdir(parents=True)
                file.write_bytes(b'approved content')
                runner = release.Release.__new__(release.Release)
                runner.out = root
                runner.shared_fingerprints = lambda: {}
                with patch.object(release, 'ROOT', root), patch.object(release, 'git', return_value=relative), patch.object(release, 'asset_input', return_value={}):
                    release.save(root / 'validation.json', {
                        'runtime_fingerprint': runner.runtime_hash(), 'asset_input': {}, 'shared_fingerprints': {},
                    })
                    runner.current_validation()
                    file.write_bytes(b'changed since validation')
                    with self.assertRaisesRegex(RuntimeError, 'Run validate'):
                        runner.current_validation()
