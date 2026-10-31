"""Prepare existing validated artifacts; upload only to an operator-verified draft."""
import argparse, datetime, hashlib, json, os, pathlib, subprocess, sys, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CHANNELS = {'windows':'windows','html5':'web','linux':'linux','mac':'macos'}

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def sha(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f,'sha256').hexdigest()

def inside(root, relative):
    path=(root/relative).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('Artifact path escapes release directory')
    return path

def validate(out, catalog, channel):
    if catalog['pricing'] != {'model':'free','payments':False,'donations':False,'in_app_purchases':False,'currency_integration':False}:
        raise ValueError('Release must be completely free')
    manifest=read(out/'manifest.json')
    if manifest['version'] != catalog['version']:
        raise ValueError('Release version mismatch')
    entry=manifest['artifacts'][CHANNELS[channel]]
    if entry['status']!='built' or entry['validation']['structure']!='passed':
        raise ValueError('Build not structurally validated')
    if not entry['validation']['runtime'].startswith('passed:'):
        raise ValueError('Native/runtime validation incomplete; refusing '+channel)
    package=inside(out,entry['package'])
    if sha(package)!=entry['package_sha256']:
        raise ValueError('Package checksum mismatch')
    for relative,digest in entry['raw_files'].items():
        if sha(inside(out,relative))!=digest:
            raise ValueError('Raw artifact checksum mismatch: '+relative)
    sums=dict((line.split('  ',1)[1],line.split('  ',1)[0]) for line in (out/'SHA256SUMS').read_text().splitlines())
    if sums.get(entry['package'])!=entry['package_sha256']:
        raise ValueError('Package differs from handoff checksum ledger')
    with zipfile.ZipFile(package) as archive:
        if archive.testzip(): raise ValueError('Damaged ZIP')
        for name in archive.namelist(): inside(out,name)
        if channel=='html5' and 'index.html' not in archive.namelist():
            raise ValueError('Web ZIP needs root index.html')
    if channel=='html5' and not read(inside(out,entry['validation']['browser_evidence']))['passed']:
        raise ValueError('Browser validation failed')
    return entry,package

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=['prepare','status','push'])
    p.add_argument('--channels',nargs='+',choices=list(CHANNELS),default=['windows','html5'])
    p.add_argument('--butler',default=os.environ.get('BUTLER_EXE',r'C:\Apps\butler-windows-amd64\butler.exe'))
    p.add_argument('--confirm-draft-no-payments',action='store_true',help='Confirm a fresh owner review of the actual itch edit page before EACH push')
    args=p.parse_args()
    catalog=read(ROOT/'release/catalog/game.json')
    config=read(ROOT/'release/distribution/itch.json')
    target=config['target']
    if target!='wandiel/dont-touch-me': raise ValueError('Unexpected upload destination')
    out=ROOT/'builds'/('v'+catalog['version'])
    folder=out/'itch'; folder.mkdir(exist_ok=True)
    if args.command=='status':
        return subprocess.call([args.butler,'status',target])
    plan=[]
    for channel in args.channels:
        entry,package=validate(out,catalog,channel)
        plan.append({'channel':channel,'package':str(package.relative_to(out)),
                     'sha256':entry['package_sha256'],'source_commit':entry['source_commit'],
                     'version':'v'+catalog['version'],'target':target+':'+channel})
    (folder/'upload-plan.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
    text=catalog['store_text']
    page={'title':text['name'],'publisher':catalog['publisher']['brand'],'tagline':config['tagline'],
          'version':catalog['phase']+' v'+catalog['version'],'description':text['google_play_full'],
          'release_notes':text['release_notes'],'visibility':'draft','pricing':'No payments',
          'kind':'HTML','embed_width':432,'embed_height':768,
          'cover':'release/catalog/branding/itch-cover-630x500.png',
          'screenshots':sorted(str(p.relative_to(ROOT)).replace('\\','/') for p in (ROOT/'release/assets/screenshots/google-play').glob('*.png'))}
    (folder/'page-materials.json').write_text(json.dumps(page,indent=2),encoding='utf-8')
    if args.command=='prepare':
        print('Verified packages and prepared page materials; no network upload.'); return 0
    if not args.confirm_draft_no_payments:
        raise ValueError('Verify owner, Draft visibility and No payments in itch edit page; supply --confirm-draft-no-payments only after that review')
    identity=pathlib.Path.home()/'.config/itch/butler_creds'
    if not identity.is_file() and not os.environ.get('BUTLER_API_KEY'):
        raise ValueError('Run butler login securely first')
    for item in plan:
        command=[args.butler,'push',str(inside(out,item['package'])),item['target'],
                 '--userversion',item['version'],'--hidden','--if-changed']
        started=datetime.datetime.now(datetime.timezone.utc).isoformat()
        # Inherit output. Never capture credentials, OAuth URLs or environment variables.
        result=subprocess.run(command)
        receipt={**item,'utc':started,'butler_exit_code':result.returncode,
                 'result':'push_returned_success; remote processing verification required' if result.returncode==0 else 'failed',
                 'visibility_review':'operator confirmed draft/no-payments; hidden applies to new channels only'}
        with (folder/'upload-results.jsonl').open('a',encoding='utf-8') as f:
            f.write(json.dumps(receipt)+'\n')
        if result.returncode: return result.returncode
        code=subprocess.call([args.butler,'status',item['target']])
        with (folder/'upload-results.jsonl').open('a',encoding='utf-8') as f:
            f.write(json.dumps({'target':item['target'],'version':item['version'],'status_exit_code':code,'result':'status_query_completed; inspect displayed version/build ID, not proof of public release'})+'\n')
        if code: return code
    return 0

if __name__=='__main__':
    try: sys.exit(main())
    except (ValueError,OSError,KeyError,zipfile.BadZipFile) as e:
        print(str(e),file=sys.stderr); sys.exit(1)
