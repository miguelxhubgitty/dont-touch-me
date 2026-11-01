"""Local release preparation; explicit owner-approved GitHub upload adapter. Standard library only."""
from __future__ import annotations
import argparse
import configparser
import hashlib
import http.server
import json
import os
import platform
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile
import threading
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / 'release/catalog/game.json'
REGISTRY = ROOT / 'release/distribution/platforms.json'
TEXT = {'.gd', '.tres', '.tscn', '.godot', '.cfg', '.json', '.md', '.txt', '.import', '.uid'}
TARGETS = {
    'windows': ('Windows', 'windows_release_x86_64.exe', 'DontTouchMe.exe', False),
    'web': ('Web', 'web_nothreads_release.zip', 'index.html', False),
    'android-apk': ('Android', 'android_debug.apk', 'dont-touch-me-debug.apk', True),
    'android-aab': ('Android AAB Unsigned', 'android_source.zip', 'dont-touch-me-unsigned.aab', False),
    'linux': ('Linux', 'linux_release.x86_64', 'DontTouchMe.x86_64', False),
    'macos': ('macOS', 'macos.zip', 'DontTouchMe.zip', False),
    'ios': (None, 'ios.zip', None, False),
}
FORMATS = {'windows': ['windows-zip','windows-directory'], 'web': ['web-zip','web-directory'],
           'android-apk': ['android-debug-apk'], 'android-aab': [], 'linux': ['linux-zip','linux-directory'], 'macos': ['macos-zip','macos-app'], 'ios': []}

def load(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

def save(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary=path.with_suffix(path.suffix+'.tmp')
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    os.replace(temporary,path)

def sha(path, normalized=False):
    path = Path(path)
    if normalized and path.suffix.lower() in TEXT:
        return hashlib.sha256(path.read_bytes().replace(b'\r\n', b'\n')).hexdigest()
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()

def require_release():
    branch = git('branch', '--show-current')
    if not branch.startswith('release/'):
        raise RuntimeError('Use a release/<version> branch. main remains basic-font development.')
    if not (ROOT / 'scripts/typography.gd').is_file():
        raise RuntimeError('Apply the approved aesthetic layer following BRANCH_WORKFLOW.md first.')
    if CATALOG.is_file() and branch not in ['release/' + load(CATALOG)['version'], 'release/v' + load(CATALOG)['version']]:
        raise RuntimeError('Release branch name must match the canonical catalog version.')

def clean_tree():
    if subprocess.run(['git', 'diff', '--quiet', 'HEAD'], cwd=ROOT).returncode or git('ls-files', '--others', '--exclude-standard'):
        raise RuntimeError('Commit source/config/assets first; builds need an identifiable clean source commit.')

def stamp():
    return datetime.now(timezone.utc).isoformat()

def check_catalog(catalog=None, registry=None):
    c, r = catalog or load(CATALOG), registry or load(REGISTRY)
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?', c['version']):
        raise ValueError('Invalid release version')
    if c['pricing'] != {'model':'free','payments':False,'donations':False,'in_app_purchases':False,'currency_integration':False}:
        raise ValueError('This release system currently permits free, nonmonetized builds only')
    ids = [p['id'] for p in r['platforms']]
    if len(ids) != len(set(ids)):
        raise ValueError('Duplicate platform IDs')
    for p in r['platforms']:
        for field in ['id','name','submission_url','accepted_formats','shared_material','overrides','prerequisites','publication']:
            if field not in p:
                raise ValueError(f'{p.get("id")}: missing {field}')
        if any(ref not in c for ref in p['shared_material']):
            raise ValueError('Unknown shared-material reference')
        pub = p['publication']
        if pub['status'] == 'published' and (not pub['live_url'] or not pub['last_successfully_published_version']):
            raise ValueError('Published status requires a real URL and published version')
    for path in [*c['licenses'], c['release_notes'], c['privacy']['policy'], c['assets']['manifest'], c['assets']['inventory']]:
        # Basic-font main may hold the release plan without the aesthetic files.
        # Actual CLI preparation is release-only and requires typography first.
        if path.startswith('assets/fonts/') and not (ROOT/'scripts/typography.gd').exists():
            continue
        if not (ROOT / path).is_file():
            raise ValueError(f'Missing shared material: {path}')
    return c, r

def sync():
    require_release()
    c, _ = check_catalog()
    # Compatibility files are generated views, not additional editable sources.
    save(ROOT / 'release/listing.json', c['store_text'])
    listing = '# Store listing — generated from release/catalog/game.json\n\n'
    listing += '\n\n'.join(f'## {k}\n\n{v}' for k, v in c['store_text'].items()) + '\n'
    (ROOT / 'release/STORE_LISTING.md').write_text(listing, encoding='utf-8')
    project = ROOT / 'project.godot'
    project.write_text(re.sub(r'(?m)^config/version="[^"]+"', f'config/version="{c["version"]}"', project.read_text()), encoding='utf-8')
    presets = ROOT / 'export_presets.cfg'
    text = presets.read_text()
    text = re.sub(r'(?m)^version/name="[^"]+"', f'version/name="{c["version"]}"', text)
    text = re.sub(r'(?m)^version/code=\d+', f'version/code={c["android_version_code"]}', text)
    text = re.sub(r'(?m)^application/(file_version|product_version)="[^"]+"', lambda m: f'application/{m[1]}="{c["windows_version"]}"', text)
    common = '\nrunnable=false\nadvanced_options=false\ncustom_features=""\nexport_filter="all_resources"\ninclude_filter="THIRD_PARTY_NOTICES.txt,assets/fonts/OFL-Space-Grotesk.txt"\nexclude_filter="tests/*,test-output/*,builds/*,release/*,docs/*,*.md"\nexport_path=""\nscript_export_mode=2\n'
    additions = [
        ('Web','Web','variant/extensions_support=false\nvariant/thread_support=false\nvram_texture_compression/for_desktop=true\nvram_texture_compression/for_mobile=true\nhtml/canvas_resize_policy=2\nhtml/focus_canvas_on_start=true\nprogressive_web_app/enabled=false\n'),
        ('Linux','Linux','binary_format/architecture="x86_64"\nbinary_format/embed_pck=true\ndebug/export_console_wrapper=0\n'),
        ('macOS','macOS',f'application/bundle_identifier="{c["application_id"]}"\napplication/short_version="{c["native_version"]}"\napplication/version="{c["android_version_code"]}"\napplication/icon="res://assets/icon_ios.png"\nbinary_format/architecture="universal"\ncodesign/codesign=0\nnotarization/notarization=0\n'),
    ]
    for name, target, options in additions:
        if f'name="{name}"' not in text:
            index = len(re.findall(r'(?m)^\[preset\.\d+\]$', text))
            text += f'\n[preset.{index}]\nname="{name}"\nplatform="{target}"\n' + common + f'\n[preset.{index}.options]\n' + options
    # Ensure future syncs update existing macOS numeric versions too.
    text = re.sub(r'(?m)^application/short_version="[^"]+"', f'application/short_version="{c["native_version"]}"', text)
    text = re.sub(r'(?m)^application/version="[^"]+"', f'application/version="{c["android_version_code"]}"', text)
    presets.write_text(text, encoding='utf-8')
    print('Synchronized alpha metadata and six native/Web export presets; no images generated.')

def inventory_refresh():
    path = ROOT / 'release/assets-inventory.json'
    data = load(path)
    archive = ROOT / f'release/history/assets-inventory-before-{load(CATALOG)["version"]}.json'
    if not archive.exists():
        archive.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, archive)
    cover='catalog/branding/itch-cover-630x500.png'
    if not any(e['file']==cover for e in data['files']):
        data['files'].append({'file':cover,'hash_mode':'binary','sha256':''})
    for entry in data['files']:
        entry['sha256'] = sha(ROOT / 'release' / entry['file'], entry['hash_mode'] == 'utf8-lf')
    data['audited'] = datetime.now(timezone.utc).date().isoformat()
    save(path, data)

def asset_input():
    # Source-only invalidation: a docs change must not re-render screenshots.
    paths = ['scripts/blob.gd','scripts/typography.gd','release/tools/generate_assets.gd','release/tools/generate_branding.gd','icon.svg']
    paths += [p.relative_to(ROOT).as_posix() for p in (ROOT / 'assets').rglob('*') if p.is_file() and p.suffix != '.uid']
    return {p: sha(ROOT / p, True) for p in sorted(set(paths))}

class Release:
    def __init__(self, godot):
        self.catalog, self.registry = check_catalog()
        self.out = ROOT / 'builds' / ('v' + self.catalog['version'])
        self.godot = str(Path(godot).resolve()) if godot else shutil.which('godot')
        self.receipts = load(self.out / 'manifest.json') if (self.out / 'manifest.json').exists() else {'schema_version':1,'version':self.catalog['version'],'artifacts':{}}
        self.settings = {}
        if os.name=='nt':
            settings_root=data_root=Path(os.environ['APPDATA'])/'Godot'
        elif platform.system()=='Darwin':
            settings_root=data_root=Path.home()/'Library/Application Support/Godot'
        else:
            settings_root=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'godot'
            data_root=Path(os.environ.get('XDG_DATA_HOME',str(Path.home()/'.local/share')))/'godot'
        for settings in settings_root.glob('editor_settings-*.tres'):
            for match in re.finditer(r'^export/android/(android_sdk_path|java_sdk_path|debug_keystore) = (".*")$', settings.read_text(), re.M):
                self.settings[match[1]] = json.loads(match[2])
        self.sdk = Path(os.environ.get('ANDROID_HOME', self.settings.get('android_sdk_path','__missing_sdk__')))
        self.jdk = Path(os.environ.get('JAVA_HOME', self.settings.get('java_sdk_path','__missing_jdk__')))
        self.templates = Path(os.environ.get('GODOT_TEMPLATES', str(data_root/'export_templates'/self.catalog['engine'])))
        if self.godot and Path(self.godot).is_file():
            version=subprocess.check_output([self.godot,'--version'],text=True).strip()
            if not version.startswith(self.catalog['engine']+'.'):
                raise RuntimeError('Godot version does not match the canonical release engine: '+version)
            self.receipts['engine']={'version':version,'executable_sha256':sha(self.godot)}
        for folder in ['shared','checklists','logs','windows','web','android','linux','macos','ios']:
            (self.out / folder).mkdir(parents=True, exist_ok=True)

    def run(self, command, label, timeout=600, allow_failure=False, cwd=None):
        log = self.out / 'logs' / (label + '.log')
        with log.open('w', encoding='utf-8') as stream:
            env=dict(os.environ)
            # A persistent Gradle child can keep Godot's Windows console launcher
            # alive after a completed export. Use a single-use build process.
            env['GRADLE_OPTS']=(env.get('GRADLE_OPTS','')+' -Dorg.gradle.daemon=false').strip()
            result = subprocess.run(list(map(str, command)), cwd=cwd or ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
        text = log.read_text(encoding='utf-8', errors='replace')
        if not allow_failure and (result.returncode or 'SCRIPT ERROR:' in text or re.search(r'(?m)^ERROR:', text)):
            raise RuntimeError(f'{label} failed; see {log}\n' + text[-2000:])
        return result.returncode, text

    def engine(self, *args, label='godot', timeout=600):
        if not self.godot or not Path(self.godot).is_file():
            raise RuntimeError('Supply --godot PATH or put godot on PATH.')
        return self.run([self.godot, '--headless', '--path', ROOT, *args], label, timeout)

    def doctor(self):
        result = {}
        for key, (preset, template, _, _) in TARGETS.items():
            missing = []
            if not self.godot or not Path(self.godot).is_file(): missing.append('Godot executable')
            if not (self.templates / template).is_file(): missing.append('matching export template: ' + template)
            if key.startswith('android'):
                if not (self.sdk / 'platform-tools').is_dir(): missing.append('Android SDK/platform-tools')
                if not (self.jdk / 'bin' / ('java.exe' if os.name == 'nt' else 'java')).is_file(): missing.append('JDK 17')
                if key == 'android-apk' and not Path(self.settings.get('debug_keystore','__missing__')).is_file(): missing.append('existing debug keystore')
            if key == 'ios': missing += ['macOS/Xcode export host, Apple Team ID, provisioning and authorized signing; no iOS preset fabricated']
            result[key] = {'export_possible': not missing, 'missing':missing, 'preset':preset}
        save(self.out / 'prerequisites.json', result)
        return result

    def validate(self):
        check_catalog()
        if load(ROOT / 'release/listing.json') != self.catalog['store_text']:
            raise RuntimeError('Generated listing is stale; run sync.')
        self.engine('--editor','--import','--quit', label='import')
        for suite in ['behavior','release','fingerprints','typography']:
            self.engine('--script', f'tests/{suite}.gd', label='test-' + suite)
        self.engine('--script','release/tools/validate_package.gd', label='test-package')
        inventory = load(ROOT / 'release/assets-inventory.json')
        for entry in inventory['files']:
            if sha(ROOT / 'release' / entry['file'], entry['hash_mode'] == 'utf8-lf') != entry['sha256']:
                raise RuntimeError('Release inventory mismatch: ' + entry['file'])
        save(self.out / 'validation.json', {'passed':True,'checked_at':stamp(),'source_commit':git('rev-parse','HEAD'),'runtime_fingerprint':self.runtime_hash(),'asset_input':asset_input(),'shared_fingerprints':self.shared_fingerprints()})
        print('Gameplay, typography, capture provenance, metadata and inventory validated.')

    def finalize_assets(self):
        receipt = ROOT / 'release/catalog/assets-finalized.json'
        inputs = asset_input()
        if receipt.exists() and load(receipt)['inputs'] == inputs:
            print('Reusing finalized captures and cached phrases; no regeneration.')
            return
        # Cached approved phrase images stay unchanged unless wording/fonts change.
        self.engine('--editor','--import','--quit', label='finalization-import')
        self.engine('--script','tests/typography.gd', label='pre-capture-typography')
        self.run([self.godot,'--path',ROOT,'--script','release/tools/generate_assets.gd','--','--finalize-release'], 'finalize-assets')
        self.run([self.godot,'--path',ROOT,'--script','release/tools/generate_branding.gd','--','--finalize-release'], 'finalize-branding')
        inventory_refresh()
        save(receipt, {'inputs':inputs,'generated_at':stamp(),'phrases':'Reused approved complete-phrase graphics; no phrase regeneration.'})
        print('Final store captures generated once; inventory refreshed.')

    def runtime_hash(self):
        paths = [p for p in git('ls-files').splitlines() if p in ['main.tscn','project.godot','export_presets.cfg','icon.svg','THIRD_PARTY_NOTICES.txt'] or p.startswith(('assets/','scripts/'))]
        return hashlib.sha256(json.dumps({p:sha(ROOT/p,True) for p in paths},sort_keys=True).encode()).hexdigest()

    def current_validation(self):
        path = self.out / 'validation.json'
        if not path.exists() or load(path)['runtime_fingerprint'] != self.runtime_hash() or load(path)['asset_input'] != asset_input() or load(path).get('shared_fingerprints') != self.shared_fingerprints():
            raise RuntimeError('Run validate on the finalized current source before exporting.')

    def shared_fingerprints(self):
        paths=['release/catalog/game.json','release/listing.json','release/assets-inventory.json',self.catalog['release_notes'],self.catalog['privacy']['policy'],*self.catalog['licenses']]
        paths += ['release/'+entry['file'] for entry in load(ROOT/'release/assets-inventory.json')['files']]
        return {p:sha(ROOT/p,True) for p in sorted(set(paths))}

    def export(self, keys):
        clean_tree()
        self.current_validation()
        availability = self.doctor()
        for key in keys:
            target = TARGETS[key]
            old = self.receipts['artifacts'].get(key, {})
            if not availability[key]['export_possible']:
                self.receipts['artifacts'][key] = {'status':'unavailable','missing':availability[key]['missing']}
                print(key + ': unavailable — ' + '; '.join(availability[key]['missing']))
                continue
            folder = 'android' if key.startswith('android') else key
            raw = self.out / folder / ('raw-' + key)
            raw.mkdir(parents=True, exist_ok=True)
            destination = raw / target[2]
            fingerprint = hashlib.sha256((self.runtime_hash()+key+sha(self.godot)+sha(self.templates/target[1])).encode()).hexdigest()
            if old.get('export_fingerprint') == fingerprint and old.get('raw_files') and all((self.out/p).is_file() and sha(self.out/p)==h for p,h in old['raw_files'].items()):
                print(key + ': reusing validated existing export')
                continue
            try:
                command = ['--export-debug' if target[3] else '--export-release', target[0], str(destination)]
                if key == 'android-aab' and not (ROOT / 'android/build').is_dir():
                    command.insert(0, '--install-android-build-template')
                self.engine(*command, label='export-' + key, timeout=1200)
                validation = self.inspect(key, destination)
                self.receipts['artifacts'][key] = {'status':'built','source_commit':git('rev-parse','HEAD'),'built_at':stamp(),'export_fingerprint':fingerprint,'raw_files':{p.relative_to(self.out).as_posix():sha(p) for p in raw.rglob('*') if p.is_file()},'validation':validation,'signing': 'debug key only' if key=='android-apk' else 'unsigned' if key in ['windows','macos','android-aab'] else 'not applicable','formats':FORMATS[key]}
                print(key + ': exported and inspected')
            except (RuntimeError, subprocess.TimeoutExpired, OSError, zipfile.BadZipFile) as error:
                self.receipts['artifacts'][key] = {'status':'failed','error':str(error),'formats':[]}
                print(key + ': FAILED — see logs')
            self.write_manifest()
        self.write_manifest()

    def inspect(self, key, path):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError('Exporter produced no nonempty artifact')
        checks = {'structure':'passed','runtime':'unverified'}
        if key == 'windows':
            if path.read_bytes()[:2] != b'MZ': raise RuntimeError('Not a Windows PE executable')
            self.run([path,'--headless','--quit-after','120'], 'windows-runtime-smoke', cwd=path.parent)
            checks['runtime'] = 'passed: exported executable, 120 headless frames'
        elif key == 'linux':
            data = path.read_bytes()[:64]
            if data[:5] != b'\x7fELF\x02' or struct.unpack_from('<H',data,18)[0] != 62: raise RuntimeError('Not x86_64 ELF')
            checks['runtime'] = 'not run: Linux host unavailable in this preparation'
        elif key == 'web':
            for name in ['index.html','index.js','index.wasm','index.pck']:
                if not (path.parent/name).is_file(): raise RuntimeError('Missing Web export file: '+name)
            if (path.parent/'index.wasm').read_bytes()[:4] != b'\0asm': raise RuntimeError('Invalid Wasm header')
            checks['threading'] = 'single-thread export; no cross-origin-isolation requirement'
        elif key == 'macos':
            with zipfile.ZipFile(path) as z:
                if z.testzip(): raise RuntimeError('Corrupt macOS ZIP')
                executables = [n for n in z.namelist() if '.app/Contents/MacOS/' in n and not n.endswith('/')]
                if not executables: raise RuntimeError('No macOS app executable')
                for name in executables:
                    if not ((z.getinfo(name).external_attr>>16)&0o111): raise RuntimeError('macOS executable permission missing')
                checks['runtime'] = 'not run: macOS host unavailable; unsigned/not notarized'
        else:
            with zipfile.ZipFile(path) as z:
                if z.testzip(): raise RuntimeError('Corrupt Android archive')
                manifest = 'AndroidManifest.xml' if key=='android-apk' else 'base/manifest/AndroidManifest.xml'
                if manifest not in z.namelist(): raise RuntimeError('Android manifest missing')
                libs = [n for n in z.namelist() if n.endswith('.so')]
                if not libs or any('/arm64-v8a/' not in n for n in libs): raise RuntimeError('Unexpected Android native architectures')
                for name in libs:
                    data = z.read(name)
                    offset = struct.unpack_from('<Q',data,32)[0]
                    size,count = struct.unpack_from('<HH',data,54)
                    for i in range(count):
                        at=offset+i*size
                        if struct.unpack_from('<I',data,at)[0]==1 and struct.unpack_from('<Q',data,at+48)[0]<16384: raise RuntimeError('Native ELF LOAD alignment below 16 KB')
                if key=='android-aab' and any(re.match(r'META-INF/.*\.(RSA|DSA|EC|SF)$',n) for n in z.namelist()): raise RuntimeError('Unexpected signature in unsigned AAB')
            checks['native_alignment'] = 'ELF LOAD segments >=16 KB; not 16 KB device execution'
            if key=='android-apk':
                tools = sorted((self.sdk/'build-tools').glob('*'), key=lambda p:tuple(int(n) for n in p.name.split('.') if n.isdigit()))[-1]
                java = self.jdk/'bin'/('java.exe' if os.name=='nt' else 'java')
                self.run([java,'-jar',tools/'lib/apksigner.jar','verify',path], 'apk-signature')
                self.run([tools/('zipalign.exe' if os.name=='nt' else 'zipalign'),'-c','-P','16','4',path], 'apk-alignment')
                _,badging=self.run([tools/('aapt2.exe' if os.name=='nt' else 'aapt2'),'dump','badging',path], 'apk-metadata')
                if f"versionName='{self.catalog['version']}'" not in badging or f"versionCode='{self.catalog['android_version_code']}'" not in badging: raise RuntimeError('APK version mismatch')
                checks['signing'] = 'debug APK signature verified; not production signing'
            checks['runtime'] = 'not run on current Android device; static package checks only'
        return checks

    def package(self):
        self.current_validation()
        for key, record in self.receipts['artifacts'].items():
            if record['status'] != 'built': continue
            raw = self.out / ('android' if key.startswith('android') else key) / ('raw-' + key)
            if any(not (self.out/p).exists() or sha(self.out/p)!=h for p,h in record['raw_files'].items()):
                raise RuntimeError('Raw export changed: ' + key)
            if key.startswith('android'):
                file = next(raw.glob('*.apk' if key=='android-apk' else '*.aab'))
                record['package'] = file.relative_to(self.out).as_posix()
                record['package_sha256'] = sha(file)
                continue
            dest = self.out / key / f'DontTouchMe-v{self.catalog["version"]}-{key}.zip'
            package_input=hashlib.sha256(json.dumps({'raw':record['raw_files'],'licenses':{p:sha(ROOT/p) for p in self.catalog['licenses']},'version':self.catalog['version'],'publisher':self.catalog['publisher'],'pricing':self.catalog['pricing'],'recipe':1},sort_keys=True).encode()).hexdigest()
            if record.get('package_input')==package_input and dest.exists() and sha(dest)==record.get('package_sha256'):
                print(key+': reusing package')
                continue
            with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
                if key=='macos':
                    with zipfile.ZipFile(raw/'DontTouchMe.zip') as source:
                        for info in source.infolist(): z.writestr(info,source.read(info.filename))
                else:
                    for file in sorted(raw.rglob('*')):
                        if not file.is_file(): continue
                        info=zipfile.ZipInfo(file.relative_to(raw).as_posix(), (2026,1,1,0,0,0))
                        info.create_system=3
                        info.external_attr=(0o100755 if key=='linux' and file.name.endswith('.x86_64') else 0o100644)<<16
                        info.compress_type=zipfile.ZIP_DEFLATED
                        z.writestr(info,file.read_bytes())
                for file in self.catalog['licenses']: z.write(ROOT/file,'LICENSES/'+Path(file).name)
                z.writestr('README.txt',f"Don't Touch Me — Public Alpha v{self.catalog['version']}\nFree: no payments, ads, accounts or in-app purchases.\nTap/click the blob. Leave it alone to relax and sleep.\nContact: {self.catalog['publisher']['email']}\n" + ('Serve this directory over HTTP(S); index.html is the entry point. WebGL2/Wasm required.\n' if key=='web' else 'Linux: run ./DontTouchMe.x86_64 (chmod +x if your extractor loses permissions).\n' if key=='linux' else 'macOS: unsigned/not notarized; native execution not verified.\n' if key=='macos' else 'Windows: unsigned executable; see release report for validation.\n'))
            with zipfile.ZipFile(dest) as z:
                if z.testzip(): raise RuntimeError('Package CRC check failed')
                if key=='web' and 'index.html' not in z.namelist(): raise RuntimeError('Web ZIP entry point is not at root')
            record.update(package=dest.relative_to(self.out).as_posix(),package_sha256=sha(dest),package_input=package_input)
        self.write_manifest()

    def write_manifest(self):
        self.receipts.update(version=self.catalog['version'],phase=self.catalog['phase'],pricing=self.catalog['pricing'],updated_at=stamp(),repository_commit=git('rev-parse','HEAD'),published=False)
        save(self.out/'manifest.json',self.receipts)

    def web_test(self):
        record=self.receipts['artifacts'].get('web',{})
        if record.get('status')!='built': raise RuntimeError('Export Web first.')
        class Handler(http.server.SimpleHTTPRequestHandler):
            def __init__(handler,*args,**kwargs):
                super().__init__(*args,directory=str(self.out/'web/raw-web'),**kwargs)
            def log_message(handler,*args): pass
        server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler)
        thread=threading.Thread(target=server.serve_forever,daemon=True)
        thread.start()
        try:
            node=shutil.which('node')
            if not node: raise RuntimeError('Web runtime validation requires Node and an installed Playwright/browser; export remains structurally validated only.')
            self.run([node,ROOT/'tests/web_smoke.cjs',f'http://127.0.0.1:{server.server_port}/',self.out/'logs'], 'web-runtime-smoke', timeout=180)
            record['validation']['runtime']='passed: local HTTP, WebGL2, desktop click, mobile-sized touch and resize; automated browser smoke only'
            record['validation']['browser_evidence']='logs/web-smoke.json'
            self.write_manifest()
        except (RuntimeError,subprocess.SubprocessError) as error:
            record['validation']['runtime']='failed: '+str(error).splitlines()[0]
            self.write_manifest()
            raise
        finally:
            server.shutdown(); server.server_close(); thread.join()

    def report(self):
        self.write_manifest()
        # Copy a curated shared handoff once, not once per destination.
        files=['release/catalog/game.json','release/distribution/platforms.json',self.catalog['release_notes'],*self.catalog['licenses'],self.catalog['privacy']['policy'],'release/CONTENT_RATING.md','release/DATA_SAFETY.md','release/APP_STORE_PRIVACY.md','release/listing.json','release/STORE_LISTING.md',*self.catalog['assets']['branding']]
        for file in files:
            dest=self.out/'shared'/file
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(ROOT/file,dest)
        shutil.copytree(ROOT/'release/assets',self.out/'shared/release/assets',dirs_exist_ok=True)
        available={fmt:key for key,entry in self.receipts['artifacts'].items() if entry['status']=='built' and entry.get('package') for fmt in entry.get('formats',[])}
        for p in self.registry['platforms']:
            body=f'# {p["name"]} — v{self.catalog["version"]}\n\nSubmission: {p["submission_url"]}\n\nPublication: {p["publication"]["status"]}; live URL: {p["publication"]["live_url"]}; last published: {p["publication"]["last_successfully_published_version"]}.\n\nShared canonical material: ../shared/release/catalog/game.json (all referenced descriptions, identity, assets, ratings, notices and notes).\n\n## Reusable local artifacts\n\n'
            for fmt in p['accepted_formats']:
                if fmt in available:
                    entry=self.receipts['artifacts'][available[fmt]]
                    key=available[fmt]
                    location=f'{key}/raw-{key}/' if fmt.endswith('-directory') else entry['package']
                    if fmt=='macos-app': location+=' (ZIP input; extract .app preserving permissions, then verify on Mac)'
                    body+=f'- [ ] {fmt}: ../{location} — {entry["signing"]}; runtime: {entry["validation"]["runtime"]}\n'
                else: body+=f'- [ ] {fmt}: MISSING / requires a platform adapter or authorized release signing.\n'
            body+='\n## Before any upload\n\n- [ ] Owner explicitly authorizes this destination; this tool never uploads.\n- [ ] Confirm free/no payments/no donations/no currency integration.\n'
            body+=''.join('- [ ] '+x+'\n' for x in p['prerequisites'])
            body+='\nOverrides: '+json.dumps(p['overrides'],ensure_ascii=False)+'\n\nRequirements source: '+p['requirements_source']+'\n'
            (self.out/'checklists'/f'{p["id"]}.md').write_text(body,encoding='utf-8')
        report=f'# Public Alpha v{self.catalog["version"]} — local preparation\n\nNothing uploaded or published. Free, no payment/currency integration.\n\n| Format | Status | Signing/runtime | Package |\n|---|---|---|---|\n'
        for key,entry in self.receipts['artifacts'].items():
            report+=f'| {key} | {entry["status"]} | {entry.get("signing","")}; {entry.get("validation",{}).get("runtime", "; ".join(entry.get("missing",[])) or entry.get("error",""))} | {entry.get("package","—")} |\n'
            if entry['status']=='unavailable': save(self.out/key/'STATUS.json',entry)
        report+='\nSee manifest.json for source commits, validation and checksums; checklists/ for all planned destinations. Local artifact readiness does not certify account setup, platform compatibility or store approval.\n'
        (self.out/'REPORT.md').write_text(report,encoding='utf-8')
        checksums=[]
        for file in sorted(self.out.rglob('*')):
            if file.is_file() and file.name!='SHA256SUMS': checksums.append(f'{sha(file)}  {file.relative_to(self.out).as_posix()}')
        (self.out/'SHA256SUMS').write_text('\n'.join(checksums)+'\n',encoding='utf-8')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['sync','doctor','finalize-assets','validate','export','package','report','prepare','verify','web-test','github-release'])
    parser.add_argument('--approval',default='')
    parser.add_argument('--expected-tag-commit',default='')
    parser.add_argument('--godot',default=os.environ.get('GODOT'))
    parser.add_argument('--targets',nargs='+',choices=list(TARGETS),default=list(TARGETS))
    args=parser.parse_args()
    require_release()
    if args.command=='github-release':
        from github_release import main as publish_github
        return publish_github(['publish','--approval',args.approval,'--expected-tag-commit',args.expected_tag_commit])
    if args.command=='sync': return sync()
    release=Release(args.godot)
    if args.command=='doctor': print(json.dumps(release.doctor(),indent=2))
    elif args.command=='finalize-assets': release.finalize_assets()
    elif args.command=='validate': release.validate()
    elif args.command=='export': release.export(args.targets)
    elif args.command=='package': release.package()
    elif args.command=='web-test': release.web_test()
    elif args.command=='report': release.report()
    elif args.command=='prepare':
        release.validate(); release.export(args.targets); release.package(); release.report()
    elif args.command=='verify':
        for line in (release.out/'SHA256SUMS').read_text().splitlines():
            digest,relative=line.split('  ',1)
            if sha(release.out/relative)!=digest: raise RuntimeError('Checksum mismatch: '+relative)
        print('Release checksums verified.')
    if args.command in ['prepare','export'] and any(entry['status']=='failed' for entry in release.receipts['artifacts'].values()):
        return 1
    return 0

if __name__=='__main__':
    try: sys.exit(main())
    except (RuntimeError,ValueError,OSError,subprocess.SubprocessError,KeyError) as error:
        print(str(error),file=sys.stderr); sys.exit(1)
