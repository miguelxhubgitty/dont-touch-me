"""Offline, version-specific Microsoft plan and verified Win32 packaging input.

No Partner Center API, browser credentials, name reservation or upload is implemented.
The explicit owner instruction authorizes this one attempt, not other platforms.
"""
import argparse
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
COMMIT = 'd61c86568b40c23a291db7aa2757ffe82e1896e8'
VERSION = '0.1.0-alpha'
WINDOWS_SHA256 = '42a43d68e9c0dd2af46da6dfa6f74d32b4e4c2242a68771dc046900134bcbdc9'
WINDOWS_SIZE = 38715912
STATUS_PATH = 'release/distribution/microsoft-v0.1.0-alpha.json'


def visuals(root=ROOT):
    spec = importlib.util.spec_from_file_location('visual_assets', Path(root)/'release/tools/visual_assets.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.validate('microsoft', VERSION, require_review=True, root=Path(root))


def plan(root=ROOT):
    root = Path(root)
    visual_plan = visuals(root)
    status = json.loads((root/STATUS_PATH).read_text(encoding='utf-8'))
    if (status.get('release_commit') != COMMIT or status.get('version') != VERSION or
            status.get('authorization', {}).get('owner_authorized') is not True):
        raise ValueError('This version has no matching owner submission authorization')
    return {'effect': 'Offline plan only; no reservation, upload, or certification',
            'version': VERSION, 'release_commit': COMMIT, 'visuals': visual_plan,
            'listing': 'release/microsoft/v0.1.0-alpha/listing-draft.json',
            'packaging_route': 'GDK PC / MSIXVC; use actual Partner Center identity',
            'source_zip_sha256': WINDOWS_SHA256, 'status': status,
            'submission_ready': False}


def require_submission_ready(root=ROOT):
    result = plan(root)
    status = result['status']
    if status.get('name_check', {}).get('available') is not True:
        raise ValueError('Microsoft product name unavailable; owner decision required')
    if not status.get('product_id') or not status.get('package_identity_verified'):
        raise ValueError('Actual Partner Center product/package identity is required')
    if not status.get('package_validation_passed'):
        raise ValueError('Verified Microsoft MSIXVC package is required')
    if not status.get('legal_and_account_decisions_approved'):
        raise ValueError('Outstanding legal/account decisions require owner approval')
    # A saved status file alone can never grant a live upload or certification action.
    raise ValueError('Live Partner Center verification/action-time approval is required; no uploader implemented')


def verify_archive(data):
    if len(data) != WINDOWS_SIZE or hashlib.sha256(data).hexdigest() != WINDOWS_SHA256:
        raise ValueError('Approved Windows archive changed; do not rebuild or substitute')
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        if archive.testzip():
            raise ValueError('Windows archive CRC failure')
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate archive entries')
        for name in names:
            if '\\' in name or Path(name).is_absolute() or '..' in Path(name).parts or ':' in name:
                raise ValueError('Unsafe archive path')
            if (archive.getinfo(name).external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError('Archive symlink is forbidden')
        exes = [n for n in names if n.lower().endswith('.exe')]
        if len(exes) != 1:
            raise ValueError('Expected one approved Windows executable')
        exe = archive.read(exes[0])
        if len(exe) < 64 or exe[:2] != b'MZ':
            raise ValueError('Not a Windows PE executable')
        offset = struct.unpack_from('<I', exe, 0x3c)[0]
        if offset+6 > len(exe) or exe[offset:offset+4] != b'PE\0\0' or struct.unpack_from('<H', exe, offset+4)[0] != 0x8664:
            raise ValueError('Expected Windows x86_64 PE')
        return {name: hashlib.sha256(archive.read(name)).hexdigest() for name in names if not name.endswith('/')}


def stage_payload(archive_path, root=ROOT):
    root = Path(root).resolve()
    plan(root)  # Owner consent, style, hashes and provenance must pass before staging.
    data = Path(archive_path).read_bytes()
    files = verify_archive(data)
    out = root/'builds/microsoft-v0.1.0-alpha/payload'
    if not out.resolve().is_relative_to(root/'builds'):
        raise ValueError('Output path escaped ignored build directory')
    for name, digest in files.items():
        dest = out/name
        if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest() != digest:
            raise ValueError('Existing payload changed; preserve it for investigation')
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for name in files:
            dest = out/name
            dest.parent.mkdir(parents=True, exist_ok=True)
            if not dest.exists():
                dest.write_bytes(archive.read(name))
    receipt = {'version': VERSION, 'release_commit': COMMIT, 'source_zip_sha256': WINDOWS_SHA256,
               'files': files, 'store_package_created': False,
               'effect': 'Original Windows bytes staged as GDK packaging input; not an MSIXVC or upload'}
    out.parent.mkdir(parents=True, exist_ok=True)
    (out.parent/'payload-receipt.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['plan', 'stage-payload', 'submission-check'])
    parser.add_argument('--archive', type=Path)
    args = parser.parse_args()
    if args.action == 'stage-payload':
        if not args.archive:
            parser.error('--archive must select the unchanged approved Windows ZIP')
        result = stage_payload(args.archive)
    elif args.action == 'submission-check':
        result = require_submission_ready()
    else:
        result = plan()
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
