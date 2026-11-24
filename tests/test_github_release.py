"""Offline publishing tests; never contact GitHub or rebuild assets."""
import copy, importlib.util, pathlib, tempfile, unittest

spec=importlib.util.spec_from_file_location('github_release',pathlib.Path(__file__).resolve().parents[1]/'release/tools/github_release.py')
module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)

class FakeApi:
    def __init__(self, prepared, existing=True, corrupt=False):
        self.prepared=prepared; self.calls=[]
        self.release={'id':1,'tag_name':prepared['tag'],'draft':True,'prerelease':True,'upload_url':'https://uploads.github.com/repos/test/releases/1/assets{?name,label}','html_url':'https://github.com/test/release','published_at':'2026-10-31T00:00:00Z'}
        self.assets=[{'name':a['name'],'size':a['size'],'digest':'sha256:'+('bad' if corrupt else a['sha256'])} for a in prepared['assets']] if existing else []
    def call(self, method, route, data=None, binary=False):
        self.calls.append((method,route))
        if route=='': return {'private':False}
        if route.startswith('/git/ref/'): return {'object':{'type':'commit','sha':self.prepared['source_commit']}}
        if route.startswith('/releases/tags/'): return self.release
        if '/assets?' in route: return self.assets
        if method=='PATCH': self.release.update(data); return self.release
        raise AssertionError('Unexpected API write: '+route)

class Publishing(unittest.TestCase):
    def setUp(self):
        self.prepared={'tag':'v0.1.0-alpha','source_commit':'a'*40,'assets':[{'name':str(i)+'.zip','size':1,'sha256':str(i)*64} for i in range(6)]}
        self.out=module.ROOT/'builds/v0.1.0-alpha'
    def test_existing_packages_and_no_aab(self):
        if not (self.out/'manifest.json').exists(): self.skipTest('Existing local Alpha packages unavailable; no builds generated')
        prepared,_=module.plan()
        self.assertEqual({a['target'] for a in prepared['assets']},{'windows','linux','macos','web','android-apk','checksums'})
        self.assertFalse(any(a['name'].endswith('.aab') for a in prepared['assets']))
    def test_approval_and_tag_guards_before_writes(self):
        api=FakeApi(self.prepared)
        with self.assertRaises(ValueError): module.publish(self.prepared,self.out,api,'',self.prepared['source_commit'])
        self.assertEqual(api.calls,[])
        with self.assertRaises(ValueError): module.publish(self.prepared,self.out,api,'test approval','wrong')
        self.assertEqual(api.calls,[])
    def test_duplicate_assets_reused_and_public_downloads_verified(self):
        api=FakeApi(self.prepared)
        digests={a['name']:a['sha256'] for a in self.prepared['assets']}
        with tempfile.TemporaryDirectory() as directory:
            receipt=module.publish(self.prepared,pathlib.Path(directory),api,'fixture only',self.prepared['source_commit'],download=lambda url:digests[url.rsplit('/',1)[1]])
            self.assertEqual(len(receipt['assets']),6)
            count=len(api.calls)
            module.publish(self.prepared,pathlib.Path(directory),api,'fixture only',self.prepared['source_commit'],download=lambda url:digests[url.rsplit('/',1)[1]])
            self.assertFalse(any(m in ('POST','PATCH') for m,r in api.calls[count:]))
        self.assertFalse(any(m=='POST' for m,r in api.calls))
    def test_changed_remote_asset_never_replaced(self):
        api=FakeApi(self.prepared,corrupt=True)
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError): module.publish(self.prepared,pathlib.Path(directory),api,'fixture only',self.prepared['source_commit'])
        self.assertFalse(any(m in ('POST','PATCH','DELETE') for m,r in api.calls))

class MixedSourceCommits(unittest.TestCase):
    """Packages from an earlier commit are accepted only if nothing that ships changed."""
    def test_preset_sections_pick_one_platform(self):
        text = '[preset.0]\nname="Android"\nversion/code=4\n[preset.0.options]\na=1\n[preset.1]\nname="Windows"\n[preset.1.options]\nb=2\n'
        self.assertIn('version/code=4', module.preset_sections(text, 'Android'))
        self.assertNotIn('version/code', module.preset_sections(text, 'Windows'))
        self.assertIsNone(module.preset_sections(text, 'macOS'))
    def _require(self, *commits):
        import subprocess
        for c in commits:
            if subprocess.run(['git', 'cat-file', '-e', c + '^{commit}'], cwd=module.ROOT, capture_output=True).returncode:
                self.skipTest('history not available in this clone')
    def test_tooling_only_changes_keep_earlier_packages_valid(self):
        self._require('5660a2e', '0f639b7')
        module.check_source_commit('windows', '5660a2e', '0f639b7')
    def test_game_changes_require_a_new_export(self):
        self._require('e5d106e', '5660a2e')
        with self.assertRaisesRegex(ValueError, 'game files changed'):
            module.check_source_commit('web', 'e5d106e', '5660a2e')

class SourceCommitFixtures(unittest.TestCase):
    """Exercise provenance checks even in shallow CI checkouts."""
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = pathlib.Path(self.directory.name)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Release fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.root/'export_presets.cfg').write_text(
            '[preset.0]\nname="Windows"\n[preset.0.options]\na=1\n', encoding='utf-8')
        self.source = self.commit('initial')

    def git(self, *args):
        import subprocess
        return subprocess.run(['git', *args], cwd=self.root, check=True,
                              capture_output=True, text=True).stdout.strip()

    def commit(self, message):
        self.git('add', '-A')
        self.git('commit', '-qm', message)
        return self.git('rev-parse', 'HEAD')

    def check(self, source, target, platform='windows'):
        module.check_source_commit(platform, source, target, self.root)

    def test_missing_source_rejected(self):
        for missing in (None, '', ' '):
            with self.subTest(missing=missing), self.assertRaisesRegex(ValueError, 'missing package source'):
                self.check(missing, self.source)

    def test_invalid_equal_commits_rejected(self):
        with self.assertRaisesRegex(ValueError, 'not an ancestor'):
            self.check('0'*40, '0'*40)

    def test_tooling_only_commit_accepted(self):
        (self.root/'README.md').write_text('documentation only', encoding='utf-8')
        target = self.commit('docs')
        self.check(self.source, target)
        self.check(target, target)
        with self.assertRaisesRegex(ValueError, 'not an ancestor'):
            self.check(target, self.source)

    def test_missing_preset_in_both_commits_rejected(self):
        (self.root/'README.md').write_text('documentation only', encoding='utf-8')
        target = self.commit('docs')
        with self.assertRaisesRegex(ValueError, 'cannot verify its export preset'):
            self.check(self.source, target, 'web')

    def test_failed_preset_lookup_rejected(self):
        (self.root/'export_presets.cfg').unlink()
        target = self.commit('removed presets')
        with self.assertRaisesRegex(ValueError, 'cannot verify its export preset'):
            self.check(self.source, target)

    def test_changed_target_preset_rejected(self):
        (self.root/'export_presets.cfg').write_text(
            '[preset.0]\nname="Windows"\n[preset.0.options]\na=2\n', encoding='utf-8')
        target = self.commit('changed preset')
        with self.assertRaisesRegex(ValueError, 'its export preset changed'):
            self.check(self.source, target)

    def test_changed_runtime_rejected(self):
        (self.root/'scripts').mkdir()
        (self.root/'scripts'/'game.gd').write_text('changed', encoding='utf-8')
        target = self.commit('changed game')
        with self.assertRaisesRegex(ValueError, 'game files changed'):
            self.check(self.source, target)


if __name__=='__main__': unittest.main()
