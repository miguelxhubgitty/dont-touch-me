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

if __name__=='__main__': unittest.main()
