"""Offline visual allowlist, render provenance and byte-specific owner-review gate.

No upload or approval-writing command exists. Runtime dependencies: standard library.
Manual/browser upload workflows must use the same preflight; this is not an OS file lock.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
from pathlib import Path
import struct
import subprocess
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[2]
VERSION = '0.1.0-alpha'
COMMIT = 'd61c86568b40c23a291db7aa2757ffe82e1896e8'
TAG = 'v0.1.0-alpha'
DIRECTORY = f'release/visuals/v{VERSION}'
MANIFEST = f'{DIRECTORY}/manifest.json'
RENDERER = 'release/tools/generate_microsoft_assets.gd'
STYLE = {'primary': 'Space Grotesk', 'handwritten': 'Ink Free',
         'implementation': 'Alpha whole-phrase PNGs; Space Grotesk title weight 600',
         'fallback_fonts_permitted': False}
MICROSOFT = {
    **{f'{i:02}-{name}-2160x3840.png': (2160, 3840, 'desktop_screenshot')
       for i, name in enumerate(('calm', 'annoyed', 'angry', 'hiding', 'sleeping'), 1)},
    'poster-1440x2160.png': (1440, 2160, 'poster'),
    'box-2160x2160.png': (2160, 2160, 'box_art'),
    'hero-3840x2160.png': (3840, 2160, 'text_free_hero'),
    'tile-300x300.png': (300, 300, 'tile'),
}
ALPHA_ART = {
    **{f'{i:02}-{name}.png': f'release/assets/screenshots/google-play/{i:02}-{name}.png'
       for i, name in enumerate(('calm', 'annoyed', 'angry', 'hiding', 'sleeping'), 1)},
    'google-play-feature-1024x500.png': 'release/assets/google-play-feature-1024x500.png',
    'itch-cover-630x500.png': 'release/catalog/branding/itch-cover-630x500.png',
}


def alpha_destinations(name):
    if name == 'itch-cover-630x500.png':
        return ['itch']
    if name == 'google-play-feature-1024x500.png':
        return ['google-play', 'gamejolt']
    return ['itch', 'gamejolt', 'google-play']


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':')).encode())


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def safe(root, relative):
    if not isinstance(relative, str) or Path(relative).is_absolute() or '\\' in relative:
        raise ValueError('Invalid asset path')
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('Asset path escapes repository')
    return path


def git_bytes(root, path):
    return subprocess.check_output(['git', 'show', f'{COMMIT}:{path}'], cwd=root)


def source_inputs(root):
    paths = ['scripts/blob.gd', 'scripts/typography.gd', 'assets/typography/phrases.gd',
             'assets/fonts/title.tres', 'assets/fonts/SpaceGrotesk.ttf',
             'project.godot', 'main.tscn', 'icon.svg']
    paths += [f'assets/typography/phrase-{i:02}.png' for i in range(10)]
    return {path: source_sha(path, git_bytes(root, path)) for path in paths}


def source_sha(path, data):
    return sha(data.replace(b'\r\n', b'\n') if Path(path).suffix in ('.gd', '.tres', '.tscn', '.godot', '.svg') else data)


def png_info(data):
    """Validate PNG CRCs, complete decompression and scanline structure, not extension alone."""
    if len(data) > 50 * 1024 * 1024 or data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('Invalid or oversized PNG')
    offset, compressed, header, ended = 8, bytearray(), None, False
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError('Truncated PNG')
        length = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        payload = data[offset+8:offset+8+length]
        end = offset + 12 + length
        if end > len(data) or zlib.crc32(kind + payload) != struct.unpack('>I', data[end-4:end])[0]:
            raise ValueError('PNG CRC/truncation failure')
        if header is None and kind != b'IHDR':
            raise ValueError('PNG header must be first')
        if kind == b'IHDR':
            if header is not None or length != 13:
                raise ValueError('Invalid PNG header')
            header = struct.unpack('>IIBBBBB', payload)
        elif kind == b'IDAT':
            compressed.extend(payload)
        elif kind == b'IEND':
            if length or end != len(data):
                raise ValueError('Invalid PNG terminator/trailing data')
            ended = True
            break
        offset = end
    if not ended or not header:
        raise ValueError('Incomplete PNG')
    w, h, depth, color, compression, filtering, interlace = header
    if not (1 <= w <= 4096 and 1 <= h <= 4096) or depth != 8 or color not in (2, 6) or any((compression, filtering, interlace)):
        raise ValueError('Require noninterlaced 8-bit RGB/RGBA PNG at supported dimensions')
    stride = w * (3 if color == 2 else 4) + 1
    limit = stride * h
    decoder = zlib.decompressobj()
    raw = decoder.decompress(compressed, limit + 1)
    if len(raw) != limit or not decoder.eof or decoder.unused_data or any(raw[i] > 4 for i in range(0, limit, stride)):
        raise ValueError('Invalid PNG image data')
    return w, h, color


def recipe(root, inputs):
    return {'source_commit': COMMIT, 'source_inputs': inputs,
            'renderer': RENDERER, 'renderer_sha256': sha(safe(root, RENDERER).read_bytes().replace(b'\r\n', b'\n')),
            'target_pixels': {k: list(v[:2]) for k, v in MICROSOFT.items()},
            'post_capture_resize': False, 'maximum_handwriting_scale': 129 / 160,
            'engine_required': '4.7.2.stable'}


def technical(root=ROOT, manifest=None):
    root = Path(root)
    m = manifest if manifest is not None else read(root / MANIFEST)
    if (m.get('schema_version') != 1 or m.get('version') != VERSION or
            m.get('release_commit') != COMMIT or m.get('release_tag') != TAG or m.get('typography') != STYLE):
        raise ValueError('Unapproved release or typography; Alpha Space Grotesk / Ink Free required')
    tag = subprocess.check_output(['git', 'rev-parse', f'{TAG}^{{}}'], cwd=root, text=True).strip()
    if tag != COMMIT:
        raise ValueError('Approved release tag has moved')
    inputs = source_inputs(root)
    if m.get('source_inputs') != inputs or m.get('render_recipe') != recipe(root, inputs):
        raise ValueError('Source or renderer provenance changed; new render and owner review required')
    receipt_path = safe(root, f'{DIRECTORY}/assets/microsoft/render-receipt.json')
    receipt = read(receipt_path)
    if canonical(receipt) != m.get('render_receipt_sha256') or receipt.get('recipe_sha256') != canonical(m['render_recipe']):
        raise ValueError('Render receipt/provenance changed')
    if receipt.get('engine') != '4.7.2-stable (official)':
        raise ValueError('Incorrect render engine')
    expected_paths = {f'{DIRECTORY}/assets/alpha/{name}' for name in ALPHA_ART}
    expected_paths |= {f'{DIRECTORY}/assets/microsoft/{name}' for name in MICROSOFT}
    entries = m.get('assets', [])
    actual_paths = [a.get('filename') for a in entries]
    if len(actual_paths) != len(set(actual_paths)) or set(actual_paths) != expected_paths:
        raise ValueError('Missing, duplicate or unapproved asset in manifest')
    rendered = {a['filename']: a for a in receipt['assets']}
    if set(rendered) != set(MICROSOFT) or len(receipt['assets']) != len(MICROSOFT):
        raise ValueError('Render receipt asset set mismatch')
    for asset in entries:
        filename = asset['filename']
        data = safe(root, filename).read_bytes()
        w, h, color = png_info(data)
        if sha(data) != asset.get('sha256') or [w, h] != asset.get('dimensions') or asset.get('approved_release') != VERSION:
            raise ValueError('Changed asset/dimensions/version: ' + filename)
        name = Path(filename).name
        if '/microsoft/' in filename:
            required_w, required_h, role = MICROSOFT[name]
            record = rendered[name]
            if (w, h) != (required_w, required_h) or color != 2:
                raise ValueError('Wrong Microsoft target size/format: '+name)
            if asset.get('destinations') != ['microsoft'] or asset.get('role') != role:
                raise ValueError('Wrong destination/role: '+name)
            if (asset.get('provenance') != {'kind': 'direct_alpha_render', 'source_path': 'icon.svg' if role == 'tile' else 'scripts/blob.gd', 'source_commit': COMMIT, 'recipe_sha256': canonical(m['render_recipe'])} or
                    record.get('sha256') != asset['sha256'] or record.get('dimensions') != [w, h] or record.get('post_capture_resize') is not False):
                raise ValueError('Unverified render or resizing: '+name)
        else:
            original = ALPHA_ART[name]
            if data != git_bytes(root, original) or asset.get('provenance') != {'kind': 'exact_git_blob', 'source_path': original, 'source_commit': COMMIT}:
                raise ValueError('Wrong Alpha typography/source bytes: '+name)
            if asset.get('destinations') != alpha_destinations(name) or asset.get('role') != 'alpha_reference':
                raise ValueError('Unapproved Alpha destination/role')
    return m


def validate(platform, version=VERSION, paths=None, *, require_review=True, root=ROOT):
    if version != VERSION:
        raise ValueError('No approved visual manifest for this version')
    m = technical(root)
    assets = [a for a in m['assets'] if platform in a['destinations']]
    if not assets:
        raise ValueError('No allowlisted artwork for destination: '+platform)
    if paths is not None:
        if not paths or len(paths) != len(set(paths)):
            raise ValueError('Empty or duplicate upload selection')
        by_path = {a['filename']: a for a in assets}
        if any(p not in by_path for p in paths):
            raise ValueError('Unapproved asset path; main fallback artwork is forbidden')
        # Microsoft review covers the complete final listing set, not just a single passing image.
        if platform == 'microsoft' and set(paths) != set(by_path):
            raise ValueError('Microsoft requires the complete reviewed nine-image set')
        assets = [by_path[p] for p in paths]
    manifest_hash = canonical({k: v for k, v in m.items() if k != 'assets'} | {
        'assets': [{k: v for k, v in a.items() if k != 'human_review'} for a in m['assets']]})
    for asset in assets:
        review = asset.get('human_review', {}).get(platform, {})
        if require_review and (review.get('status') != 'approved' or review.get('reviewer_role') != 'owner' or
                review.get('approved_sha256') != asset['sha256'] or review.get('manifest_fingerprint') != manifest_hash or
                not all(review.get(k) for k in ('reviewer', 'reviewed_at', 'approval_reference'))):
            raise ValueError('Owner visual review pending or stale: '+asset['filename'])
    return {'version': VERSION, 'platform': platform, 'manifest': MANIFEST,
            'manifest_fingerprint': manifest_hash, 'technical_validation': 'passed',
            'scope': 'visual allowlist only; separate destination and publication authorization required',
            'submission_authorized': False,
            'human_visual_review_required': True, 'upload_ready': bool(require_review),
            'assets': assets}


def prepare(godot, root=ROOT):
    """Explicit offline authoring. No automatic owner approval; existing approvals never overwritten."""
    root = Path(root)
    if (root / MANIFEST).exists():
        technical(root)
        return {'effect': 'Reused existing review package; no regeneration or approval', 'manifest': MANIFEST}
    source = root / 'builds/visual-review/source'
    if source.exists():
        for path, digest in source_inputs(root).items():
            if source_sha(path, safe(source, path).read_bytes()) != digest:
                raise ValueError('Existing isolated Alpha source changed: '+path)
    else:
        source.mkdir(parents=True)
        data = subprocess.check_output(['git', 'archive', '--format=zip', COMMIT], cwd=root)
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            archive.extractall(source)
    inputs = source_inputs(root)
    output = root / DIRECTORY / 'assets/microsoft'
    output.mkdir(parents=True, exist_ok=True)
    subprocess.run([str(godot), '--headless', '--path', str(source), '--editor', '--import', '--quit'], check=True)
    for path, digest in inputs.items():
        if source_sha(path, safe(source, path).read_bytes()) != digest:
            raise ValueError('Import changed approved render source: '+path)
    subprocess.run([str(godot), '--path', str(source), '--script', str(root/RENDERER), '--', '--visual-review-only', '--output', str(output)], check=True)
    receipt_path = output/'render-receipt.json'
    receipt = read(receipt_path)
    render_recipe = recipe(root, inputs)
    receipt['recipe_sha256'] = canonical(render_recipe)
    assets = []
    for name, source_path in ALPHA_ART.items():
        data = git_bytes(root, source_path)
        dest = root / DIRECTORY / 'assets/alpha' / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        w, h, _ = png_info(data)
        assets.append({'filename': dest.relative_to(root).as_posix(), 'destinations': alpha_destinations(name),
                       'role': 'alpha_reference', 'dimensions': [w, h], 'sha256': sha(data), 'approved_release': VERSION,
                       'provenance': {'kind': 'exact_git_blob', 'source_path': source_path, 'source_commit': COMMIT}})
    for name, (w, h, role) in MICROSOFT.items():
        dest = output / name
        digest = sha(dest.read_bytes())
        next(a for a in receipt['assets'] if a['filename'] == name)['sha256'] = digest
        assets.append({'filename': dest.relative_to(root).as_posix(), 'destinations': ['microsoft'], 'role': role,
                       'dimensions': [w, h], 'sha256': digest, 'approved_release': VERSION,
                       'provenance': {'kind': 'direct_alpha_render', 'source_path': 'icon.svg' if role == 'tile' else 'scripts/blob.gd',
                                      'source_commit': COMMIT, 'recipe_sha256': canonical(render_recipe)}})
    receipt_path.write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    for asset in assets:
        asset['human_review'] = {p: {'status': 'pending', 'reviewer_role': None, 'reviewer': None, 'reviewed_at': None,
                                    'approved_sha256': None, 'manifest_fingerprint': None, 'approval_reference': None}
                                 for p in asset['destinations']}
    m = {'schema_version': 1, 'version': VERSION, 'release_tag': TAG, 'release_commit': COMMIT,
         'typography': STYLE, 'source_inputs': inputs, 'render_recipe': render_recipe,
         'render_receipt_sha256': canonical(receipt), 'assets': assets}
    (root / MANIFEST).write_text(json.dumps(m, indent=2)+'\n', encoding='utf-8')
    technical(root)
    return {'effect': 'Offline review package created; NO human approval or upload', 'manifest': MANIFEST}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'inspect', 'check', 'upload-plan'])
    parser.add_argument('--platform', default='microsoft')
    parser.add_argument('--version', default=VERSION)
    parser.add_argument('--asset', action='append')
    parser.add_argument('--godot', type=Path)
    args = parser.parse_args()
    if args.action == 'prepare':
        if not args.godot:
            parser.error('prepare requires --godot; real renderer only')
        result = prepare(args.godot.resolve())
    else:
        result = validate(args.platform, args.version, args.asset, require_review=args.action != 'inspect')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
