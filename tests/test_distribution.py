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
        self.release.receipts['artifacts'][key]={'status':'built','raw_files':{p.relative_to(self.release.out).as_posix():dist.sha(p) for p in raw.iterdir()}}
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
    def test_changed_notices_repackage_without_export(self):
        self.add('windows',{'DontTouchMe.exe':b'MZ fixture'})
        self.release.package()
        old=self.release.receipts['artifacts']['windows']['package_sha256']
        (self.root/'NOTICE.txt').write_text('updated license')
        self.release.package()
        self.assertNotEqual(old,self.release.receipts['artifacts']['windows']['package_sha256'])
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
