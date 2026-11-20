"""Release regression tests; no engine exports, images, network or credentials."""
import copy
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('distribution', ROOT/'release/tools/release.py')
dist = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dist)

class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.catalog = dist.load(dist.CATALOG)
        self.registry = dist.load(dist.REGISTRY)
    def test_current_catalog_and_all_platforms(self):
        dist.check_catalog(self.catalog,self.registry)
        self.assertEqual(len(self.registry['platforms']),25)
        self.assertTrue(all(p['publication']['live_url'] is None for p in self.registry['platforms'] if p['publication']['status']!='published'))

    def test_android_identity_and_version_are_independent_of_apple(self):
        self.assertEqual(self.catalog['application_id'], 'com.littlebutterflyproductions.donttouchme')
        self.assertEqual(self.catalog['macos_build_version'], 2)
        presets = (ROOT / 'export_presets.cfg').read_text()
        dist.check_android_presets(presets, self.catalog)
        for old in (presets.replace('com.wandiel.donttouchme', self.catalog['application_id'], 1),
                    presets.replace(f'version/code={self.catalog["android_version_code"]}', 'version/code=3', 1)):
            with self.assertRaisesRegex(ValueError, 'identity/version code mismatch'):
                dist.check_android_presets(old, self.catalog)

    def test_catalog_rejects_old_android_identity_and_reused_code(self):
        for field, bad, message in [
            ('android_application_id', self.catalog['application_id'], 'Android application ID'),
            ('android_version_code', 3, 'must exceed'),
        ]:
            changed = {**self.catalog, field: bad}
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, message):
                dist.check_catalog(changed, self.registry)
    def test_monetization_rejected(self):
        self.catalog['pricing']['payments']=True
        with self.assertRaises(ValueError): dist.check_catalog(self.catalog,self.registry)
    def test_false_publication_rejected(self):
        self.registry['platforms'][0]['publication']['status']='published'
        self.registry['platforms'][0]['publication']['live_url']=None
        self.registry['platforms'][0]['publication']['last_successfully_published_version']=None
        with self.assertRaises(ValueError): dist.check_catalog(self.catalog,self.registry)
    def test_duplicate_platform_rejected(self):
        self.registry['platforms'].append(self.registry['platforms'][0])
        with self.assertRaises(ValueError): dist.check_catalog(self.catalog,self.registry)
    def test_unknown_shared_reference_rejected(self):
        self.registry['platforms'][0]['shared_material'].append('missing')
        with self.assertRaises(ValueError): dist.check_catalog(self.catalog,self.registry)
    def test_debug_and_unsigned_artifacts_not_production_formats(self):
        self.assertNotIn('android-release-apk',dist.FORMATS['android-apk'])
        self.assertNotIn('android-signed-aab',dist.FORMATS['android-aab'])
    def test_invalid_version_rejected(self):
        self.catalog['version']='../../outside'
        with self.assertRaises(ValueError): dist.check_catalog(self.catalog,self.registry)

class PackagingTests(unittest.TestCase):
    def setUp(self):
        (ROOT/'test-output').mkdir(exist_ok=True)
        self.temp=tempfile.TemporaryDirectory(prefix='distribution-test-', dir=ROOT/'test-output')
        self.root=Path(self.temp.name)
        self.patch=patch.object(dist,'ROOT',self.root)
        self.patch.start()
        (self.root/'NOTICE.txt').write_text('license text')
        self.release=dist.Release.__new__(dist.Release)
        self.release.out=self.root/'builds/v0.1.0-alpha'
        self.release.out.mkdir(parents=True)
        self.release.catalog={'version':'0.1.0-alpha','licenses':['NOTICE.txt'],'publisher':{'email':'contact@example.invalid'},'pricing':{'model':'free'}}
        self.release.current_validation=lambda:None
        self.release.runtime_hash=lambda:dist.sha(self.root/'NOTICE.txt')
        self.release.write_manifest=lambda:None
        self.release.receipts={'artifacts':{}}
    def tearDown(self):
        self.patch.stop()
        assert self.root.resolve().is_relative_to((ROOT/'test-output').resolve())
        self.temp.cleanup()
    def add(self,key,files):
        raw=self.release.out/key/('raw-'+key)
        raw.mkdir(parents=True)
        for name,content in files.items(): (raw/name).write_bytes(content)
        self.release.receipts['artifacts'][key]={'status':'built','runtime_fingerprint':self.release.runtime_hash(),'audio_pack':{'pack_sha256':'fixture'},'raw_files':{p.relative_to(self.release.out).as_posix():dist.sha(p) for p in raw.iterdir()}}
        return raw
    def test_web_root_and_no_duplicate_package(self):
        self.add('web',{'index.html':b'<canvas></canvas>','index.wasm':b'\0asm'})
        self.release.package()
        entry=self.release.receipts['artifacts']['web']
        package=self.release.out/entry['package']
        with zipfile.ZipFile(package) as z:
            self.assertIn('index.html',z.namelist())
            self.assertIn('LICENSES/NOTICE.txt',z.namelist())
        before=package.stat().st_mtime_ns
        self.release.package()
        self.assertEqual(before,package.stat().st_mtime_ns)
    def test_tampered_raw_export_rejected(self):
        raw=self.add('windows',{'DontTouchMe.exe':b'MZ fixture'})
        (raw/'DontTouchMe.exe').write_bytes(b'changed')
        with self.assertRaises(RuntimeError): self.release.package()
    def test_linux_zip_executable_mode(self):
        self.add('linux',{'DontTouchMe.x86_64':b'ELF fixture'})
        self.release.package()
        entry=self.release.receipts['artifacts']['linux']
        with zipfile.ZipFile(self.release.out/entry['package']) as z:
            self.assertTrue((z.getinfo('DontTouchMe.x86_64').external_attr>>16)&0o111)
    def test_macos_packaging_preserves_signed_bundle_bytes_and_modes(self):
        raw=self.add('macos',{})
        with zipfile.ZipFile(raw/'DontTouchMe.zip','w') as z:
            executable=zipfile.ZipInfo('Game.app/Contents/MacOS/Game')
            executable.create_system=3
            executable.external_attr=0o100755<<16
            z.writestr(executable,b'signed executable fixture')
            z.writestr('Game.app/Contents/_CodeSignature/CodeResources',b'resource seal fixture')
        self.release.receipts['artifacts']['macos']['raw_files']={p.relative_to(self.release.out).as_posix():dist.sha(p) for p in raw.iterdir()}
        with patch.object(dist.platform,'system',return_value='Linux'):
            self.release.package()
        entry=self.release.receipts['artifacts']['macos']
        with zipfile.ZipFile(self.release.out/entry['package']) as z:
            self.assertEqual(z.read(executable.filename),b'signed executable fixture')
            self.assertEqual(z.getinfo(executable.filename).external_attr,executable.external_attr)
            self.assertEqual(z.read('Game.app/Contents/_CodeSignature/CodeResources'),b'resource seal fixture')
            self.assertIn('LICENSES/NOTICE.txt',z.namelist())
    def test_changed_notices_require_new_export(self):
        self.add('windows',{'DontTouchMe.exe':b'MZ fixture'})
        self.release.package()
        old=self.release.receipts['artifacts']['windows']['package_sha256']
        (self.root/'NOTICE.txt').write_text('updated license')
        with self.assertRaisesRegex(RuntimeError, 'current audio pack audit'):
            self.release.package()
        self.assertEqual(old,self.release.receipts['artifacts']['windows']['package_sha256'])
    def test_failed_exports_not_packaged(self):
        self.release.receipts['artifacts']['ios']={'status':'unavailable'}
        self.release.package()
        self.assertFalse(list(self.release.out.rglob('*.zip')))
    def test_changed_shared_assets_invalidate_validation(self):
        self.release.runtime_hash=lambda:'runtime'
        self.release.shared_fingerprints=lambda:{'screenshot.png':'changed'}
        dist.save(self.release.out/'validation.json',{'runtime_fingerprint':'runtime','asset_input':{},'shared_fingerprints':{'screenshot.png':'original'}})
        with patch.object(dist,'asset_input',return_value={}):
            with self.assertRaises(RuntimeError): dist.Release.current_validation(self.release)
    def test_unchanged_validation_reusable(self):
        self.release.runtime_hash=lambda:'runtime'
        self.release.shared_fingerprints=lambda:{'screenshot.png':'original'}
        dist.save(self.release.out/'validation.json',{'runtime_fingerprint':'runtime','asset_input':{},'shared_fingerprints':{'screenshot.png':'original'}})
        with patch.object(dist,'asset_input',return_value={}):
            dist.Release.current_validation(self.release)

class AndroidBundleTests(unittest.TestCase):
    def test_android_export_cannot_rebuild_frozen_alpha(self):
        runner = dist.Release.__new__(dist.Release)
        runner.catalog = dist.load(dist.CATALOG)
        runner.catalog['version'] = dist.load(ROOT / 'release/distribution/manifest-v0.1.0-alpha.json')['release_version'].removeprefix('v')
        with patch.object(dist, 'clean_tree'), self.assertRaisesRegex(ValueError, 'Alpha is frozen'):
            runner.export(['android-aab'])

    def test_bundle_metadata(self):
        catalog = dist.load(dist.CATALOG)
        package = catalog['android_application_id']
        code = str(catalog['android_version_code'])
        manifest = f'''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
            package="{package}" android:versionName="{catalog['version']}"
            android:versionCode="{code}"><uses-sdk android:targetSdkVersion="36"/></manifest>'''
        config = '{"optimizations":{"uncompressNativeLibraries":{"enabled":true,"alignment":"PAGE_ALIGNMENT_16K"}}}'
        self.assertEqual(dist.check_bundle_metadata(manifest, config, catalog)['target_sdk'], 36)
        for rejected_manifest, rejected_config, message in [
            (manifest.replace(package, catalog['application_id']), config, 'package ID mismatch'),
            (manifest.replace(f'versionCode="{code}"', 'versionCode="3"'), config, 'version mismatch'),
            (manifest.replace('targetSdkVersion="36"', 'targetSdkVersion="35"'), config, 'target SDK'),
            (manifest, config.replace('16K', '4K'), '16 KB APK alignment'),
        ]:
            with self.subTest(message=message), self.assertRaisesRegex(RuntimeError, message):
                dist.check_bundle_metadata(rejected_manifest, rejected_config, catalog)


class MacOSSigningTests(unittest.TestCase):
    def test_sync_migrates_only_disabled_macos_signing(self):
        text='[preset.0]\nplatform="Windows Desktop"\n[preset.0.options]\ncodesign/codesign=0\n[preset.1]\nplatform="macOS"\n[preset.1.options]\ncodesign/codesign=0\nnotarization/notarization=0\n'
        result=dist.macos_signing_defaults(text)
        self.assertIn('[preset.0.options]\ncodesign/codesign=0',result)
        self.assertIn('[preset.1.options]\ncodesign/codesign=1',result)
        self.assertEqual(result,dist.macos_signing_defaults(result))
    def test_sync_preserves_configured_stronger_signer(self):
        text='[preset.0]\nplatform="macOS"\n[preset.0.options]\ncodesign/codesign=3\ncodesign/identity="Developer ID configured locally"\nnotarization/notarization=2\n'
        self.assertEqual(text,dist.macos_signing_defaults(text))
    def test_unsealed_and_unsafe_archives_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'game.zip'
            with zipfile.ZipFile(path,'w') as z:
                executable=zipfile.ZipInfo('Game.app/Contents/MacOS/Game')
                executable.external_attr=0o100755<<16
                z.writestr(executable,b'template signature is insufficient')
            with self.assertRaisesRegex(RuntimeError,'resource seal missing'):
                dist.inspect_macos_zip(path)
            with zipfile.ZipFile(path,'a') as z: z.writestr('../escape',b'outside')
            with self.assertRaisesRegex(RuntimeError,'Unsafe'):
                dist.inspect_macos_zip(path)
    def test_native_invalid_signature_blocks_package(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'game.zip'
            with zipfile.ZipFile(path,'w') as z:
                executable=zipfile.ZipInfo('Game.app/Contents/MacOS/Game')
                executable.external_attr=0o100755<<16
                z.writestr(executable,b'tampered')
                z.writestr('Game.app/Contents/_CodeSignature/CodeResources',b'outdated seal')
            with patch.object(dist.platform,'system',return_value='Darwin'), patch.object(dist.subprocess,'run',side_effect=[dist.subprocess.CompletedProcess([],0),dist.subprocess.CompletedProcess([],1,'','resource mismatch')]):
                with self.assertRaisesRegex(RuntimeError,'signature verification failed'):
                    dist.inspect_macos_zip(path)

if __name__=='__main__': unittest.main()
