"""Publish existing packages only; explicit approval, immutable tags/assets, resumable uploads."""
import argparse, datetime, hashlib, json, os, pathlib, subprocess, sys, urllib.error, urllib.parse, urllib.request, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
REPO = 'miguelxhubgitty/dont-touch-me'
TARGETS = {
    'windows': ('Windows ZIP — unsigned', '.zip'),
    'linux': ('Linux ZIP — not native-tested', '.zip'),
    'macos': ('macOS ZIP — ad-hoc signing default; notarization/native testing not implied', '.zip'),
    'web': ('HTML5 Web ZIP — host over HTTP(S)', '.zip'),
}
# Debug-signed APKs are never published publicly; Android ships only through the stores.
NON_PUBLIC_EXTENSIONS = ('.apk', '.aab')

def sha(file):
    with file.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def read(file):
    return json.loads(file.read_text(encoding='utf-8'))

def git(*args):
    return subprocess.run(['git', *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip()

# Packages may come from an earlier commit than the tag (e.g. desktop builds kept while
# only the Android version code changed). They stay valid only if nothing that ships in
# the game changed between their source commit and the tag commit.
RUNTIME_PATHS = ['scripts', 'scenes', 'assets', 'audio', 'release/licenses', 'main.tscn', 'project.godot',
                 'icon.svg', 'THIRD_PARTY_NOTICES.txt', 'release/audio-manifest.json', 'release/tools/generate_notices.gd']
PRESET_NAMES = {'windows': 'Windows', 'linux': 'Linux', 'macos': 'macOS', 'web': 'Web'}

def preset_sections(text, name):
    """The [preset.N] and [preset.N.options] text of the export preset called `name`."""
    blocks, current = {}, None
    for line in text.splitlines():
        if line.startswith('[preset.'):
            current = line.strip()
            blocks[current] = []
        elif current:
            blocks[current].append(line)
    for header, lines in blocks.items():
        if header.count('.') == 1 and f'name="{name}"' in lines:
            return '\n'.join(blocks[header] + blocks.get(header[:-1] + '.options]', []))
    return None

def check_source_commit(target, source, tag_commit, root=ROOT):
    if not isinstance(source, str) or not source.strip():
        raise ValueError(f'{target}: missing package source commit')
    run = lambda *a: subprocess.run(['git', *a], cwd=root, capture_output=True, text=True)
    if run('merge-base', '--is-ancestor', source, tag_commit).returncode != 0:
        raise ValueError(f'{target} was built from {source[:7]}, which is not an ancestor of {tag_commit[:7]}')
    if source == tag_commit:
        return
    if run('diff', '--quiet', source, tag_commit, '--', *RUNTIME_PATHS).returncode != 0:
        raise ValueError(f'{target}: game files changed since its source commit {source[:7]}; re-export it')
    presets = []
    for commit in (source, tag_commit):
        result = run('show', f'{commit}:export_presets.cfg')
        preset = preset_sections(result.stdout, PRESET_NAMES[target]) if result.returncode == 0 else None
        if preset is None:
            raise ValueError(f'{target}: cannot verify its export preset at {commit[:7]}')
        presets.append(preset)
    if presets[0] != presets[1]:
        raise ValueError(f'{target}: its export preset changed since {source[:7]}; re-export it')

def plan(root=ROOT):
    catalog = read(root/'release/catalog/game.json')
    version = catalog['version']
    if not all(c.isalnum() or c in '.-' for c in version):
        raise ValueError('Unsafe version')
    out = root/'builds'/('v'+version)
    manifest = read(out/'manifest.json')
    if manifest['version'] != version or any(catalog['pricing'].get(k) for k in ('payments','donations','in_app_purchases','currency_integration')):
        raise ValueError('Version or free-release policy mismatch')
    sums = {}
    for line in (out/'SHA256SUMS').read_text(encoding='utf-8').splitlines():
        digest, name = line.split('  ', 1)
        if name in sums:
            raise ValueError('Duplicate checksum entry')
        sums[name] = digest
    assets = []
    for target, (label, extension) in TARGETS.items():
        entry = manifest['artifacts'].get(target, {})
        if entry.get('status') == 'unavailable' or not entry:
            continue
        if entry.get('status') != 'built' or entry.get('validation', {}).get('structure') != 'passed':
            raise ValueError('Invalid existing build: '+target)
        relative = entry['package']
        file = (out/relative).resolve()
        if file.suffix in NON_PUBLIC_EXTENSIONS:
            raise ValueError('Android packages are never published on GitHub: '+relative)
        if not file.is_relative_to(out.resolve()) or file.suffix != extension:
            raise ValueError('Unsafe/unsupported package')
        digest = sha(file)
        if digest != entry['package_sha256'] or digest != sums.get(relative):
            raise ValueError('Checksum mismatch: '+relative)
        with zipfile.ZipFile(file) as archive:
            if archive.testzip():
                raise ValueError('Damaged ZIP/APK: '+relative)
        check_source_commit(target, entry.get('source_commit'), manifest['repository_commit'], root)
        assets.append({'target':target, 'path':relative, 'name':file.name, 'label':label, 'sha256':digest, 'size':file.stat().st_size,
                       'source_commit':entry.get('source_commit')})
    if not assets:
        raise ValueError('No distributable builds')
    checksums = out/'SHA256SUMS'
    assets.append({'target':'checksums', 'path':'SHA256SUMS', 'name':'SHA256SUMS', 'label':'Original local handoff SHA-256 ledger (paths relative to the build directory)', 'sha256':sha(checksums), 'size':checksums.stat().st_size})
    if len({a['name'] for a in assets}) != len(assets):
        raise ValueError('Duplicate upload names')
    return {'repository':REPO, 'tag':'v'+version, 'source_commit':manifest['repository_commit'], 'version':version, 'assets':assets}, out

class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, *args, **kwargs):
        redirected = super().redirect_request(request, *args, **kwargs)
        if redirected:
            redirected.remove_header('Authorization')
        return redirected

class Api:
    def __init__(self):
        token = os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN')
        if not token:
            result = subprocess.run(['git','credential','fill'], input='protocol=https\nhost=github.com\n\n', cwd=ROOT, text=True, capture_output=True, check=True)
            token = dict(line.split('=',1) for line in result.stdout.splitlines() if '=' in line).get('password')
        if not token:
            raise ValueError('GitHub authentication unavailable; use local Git credential manager or GH_TOKEN, never commit credentials')
        self.token = token
        self.opener = urllib.request.build_opener(SafeRedirect())

    def call(self, method, route, data=None, binary=False):
        url = route if route.startswith('https:') else 'https://api.github.com/repos/'+REPO+route
        if urllib.parse.urlsplit(url).hostname not in ('api.github.com','uploads.github.com'):
            raise ValueError('Unexpected authenticated API destination')
        payload = data if binary else json.dumps(data).encode() if data is not None else None
        headers = {'Authorization':'Bearer '+self.token, 'Accept':'application/vnd.github+json', 'X-GitHub-Api-Version':'2022-11-28', 'User-Agent':'WANDIEL-release', 'Content-Type':'application/octet-stream' if binary else 'application/json'}
        try:
            with self.opener.open(urllib.request.Request(url, data=payload, headers=headers, method=method), timeout=240) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            raise RuntimeError(f'GitHub {method} failed: HTTP {error.code}; retry without replacing assets') from None

def public_digest(url):
    request = urllib.request.Request(url, headers={'User-Agent':'WANDIEL-release-verification'})
    with urllib.request.urlopen(request, timeout=240) as response:
        digest = hashlib.sha256()
        while chunk := response.read(1024*1024):
            digest.update(chunk)
        return digest.hexdigest()

def notes(prepared):
    text = (ROOT/'release/catalog/RELEASE_NOTES.md').read_text(encoding='utf-8').replace('This is a prepared release, not a claim of publication or store approval.', '')
    text += '\n\n## Downloads and testing boundaries\n\n'
    text += '\n'.join('- '+a['name']+': '+a['label']+'.' for a in prepared['assets'])
    text += '\n\nThese are the prepared Public Alpha packages. Linux has not been native-tested. macOS app-signature validation, Gatekeeper trust and native gameplay testing are separate gates; consult the release-specific evidence. Android is distributed through Google Play and Amazon only; no APK is published here. Windows is unsigned. No platform/store certification is claimed. The unsigned Android AAB is intentionally excluded. iOS is unavailable.\n\nFree, with no payments or donations. Browser play: https://wandiel.itch.io/dont-touch-me\n\nSHA256SUMS is the original full local handoff ledger, including files not uploaded here; its paths are relative to builds/'+prepared['tag']+'/. Match downloaded filenames to those paths. Package SHA-256 values:\n\n```text\n'
    text += '\n'.join(a['sha256']+'  '+a['name'] for a in prepared['assets'] if a['target'] != 'checksums')+'\n```\n'
    return text

def publish(prepared, out, api, approval, expected, download=public_digest):
    if not approval.strip():
        raise ValueError('One explicit owner release approval reference is required')
    if expected != prepared['source_commit']:
        raise ValueError('Expected tag commit differs from the saved release manifest')
    repo = api.call('GET','')
    if repo is None or repo['private']:
        raise ValueError('Public release requires an already-public game repository; visibility is never changed')
    ref = api.call('GET','/git/ref/tags/'+prepared['tag'])
    if not ref:
        raise ValueError('Existing remote tag required; this tool never creates or moves tags')
    obj = ref['object']
    while obj['type'] == 'tag':
        obj = api.call('GET','/git/tags/'+obj['sha'])['object']
    if obj['type'] != 'commit' or obj['sha'] != expected:
        raise ValueError('Existing tag target mismatch')
    release = api.call('GET','/releases/tags/'+prepared['tag'])
    if release and (not release['prerelease'] or release['tag_name'] != prepared['tag']):
        raise ValueError('Conflicting existing release; manual review required')
    if not release:
        release = api.call('POST','/releases', {'tag_name':prepared['tag'], 'name':"Don't Touch Me — Public Alpha "+prepared['tag'], 'body':notes(prepared), 'draft':True, 'prerelease':True, 'make_latest':'false'})
    ledger = out/'github'; ledger.mkdir(exist_ok=True)
    def record(event):
        with (ledger/'attempts.jsonl').open('a',encoding='utf-8') as stream:
            stream.write(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(), 'approval':approval, 'release_id':release['id'], **event})+'\n')
    existing = api.call('GET',f"/releases/{release['id']}/assets?per_page=100")
    expected_names = {a['name'] for a in prepared['assets']}
    if any(a['name'] not in expected_names for a in existing):
        raise ValueError('Unexpected existing release assets; review without deleting anything')
    for asset in prepared['assets']:
        found = [a for a in existing if a['name'] == asset['name']]
        if len(found) > 1:
            raise ValueError('Duplicate remote asset; review required')
        if found:
            remote = found[0]
            digest = remote.get('digest')
            if remote['size'] != asset['size'] or digest != 'sha256:'+asset['sha256']:
                raise ValueError('Existing asset does not match; never overwrite '+asset['name'])
            record({'asset':asset['name'], 'result':'reused', 'sha256':asset['sha256']})
        else:
            record({'asset':asset['name'], 'result':'upload_started', 'sha256':asset['sha256']})
            upload = release['upload_url'].split('{')[0]+'?'+urllib.parse.urlencode({'name':asset['name'], 'label':asset['label']})
            remote = api.call('POST',upload,(out/asset['path']).read_bytes(),binary=True)
            if remote.get('digest') != 'sha256:'+asset['sha256'] or remote['size'] != asset['size']:
                raise ValueError('Uploaded asset digest mismatch; stop and inspect')
            record({'asset':asset['name'], 'result':'uploaded', 'sha256':asset['sha256']})
    # Recheck the immutable tag immediately before the visibility change.
    if api.call('GET','/git/ref/tags/'+prepared['tag'])['object'] != ref['object']:
        raise ValueError('Tag changed during upload; publication stopped')
    if release['draft']:
        release = api.call('PATCH',f"/releases/{release['id']}", {'draft':False,'prerelease':True,'make_latest':'false'})
    release = api.call('GET','/releases/tags/'+prepared['tag'])
    if release['draft'] or not release['prerelease']:
        raise ValueError('Release visibility verification failed')
    verified = []
    for asset in prepared['assets']:
        url = f"https://github.com/{REPO}/releases/download/{prepared['tag']}/{asset['name']}"
        if download(url) != asset['sha256']:
            raise ValueError('Anonymous download checksum mismatch: '+asset['name'])
        verified.append({**asset,'url':url})
        record({'asset':asset['name'], 'result':'anonymous_download_verified', 'sha256':asset['sha256'], 'url':url})
    receipt = {'tag':prepared['tag'],'tag_commit':expected,'release_id':release['id'],'url':release['html_url'],'published_at':release['published_at'],'prerelease':True,'approval':approval,'verified_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'assets':verified}
    (ledger/'publication.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    return receipt

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['prepare','publish'])
    parser.add_argument('--approval',default='')
    parser.add_argument('--expected-tag-commit',default='')
    args = parser.parse_args(argv)
    prepared, out = plan()
    if args.command == 'prepare':
        print(json.dumps(prepared,indent=2)); return 0
    if not args.approval or not args.expected_tag_commit:
        raise ValueError('Explicit --approval and --expected-tag-commit required before authentication/publication')
    print(json.dumps(publish(prepared,out,Api(),args.approval,args.expected_tag_commit),indent=2))
    return 0

if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError,RuntimeError,OSError,subprocess.SubprocessError,KeyError) as error:
        print(str(error),file=sys.stderr); sys.exit(1)
