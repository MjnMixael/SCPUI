"""Builds SCPUI's Nebula packages and publishes them.

Used by release.yml (public SCPUI mod) and dev-build.yml (SCPUIDEV mod).

  version  Work out the version to publish, check it, and write it to $GITHUB_OUTPUT.
  build    Pack one .7z per mod.json package and render the Nebula release metadata.
  publish  Upload the archives to Nebula and submit the release.

The Nebula API usage follows OFP's ci/post/nebula.py: log in, upload each archive through the
chunked multiupload endpoints (keyed by sha256, skipped if Nebula already has it), then post the
mod metadata to mod/release. The package layout matches what Nebula already holds for SCPUI:
one archive per package, with paths inside it relative to the package folder.
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import zipfile

CORE_FILE = 'content/data/scripts/scpui_system_core.lua'
MOD_JSON = 'mod.json'
RELEASE_TEMPLATE = '.github/nebula/scpui_release.json'

NEBULA_API = 'https://fsnebula.org/api/1/'
NEBULA_REPO = 'https://fsnebula.org/storage/repo_minimal.json'
UPLOAD_CHUNK_SIZE = 10 * 1024 * 1024
TIMEOUT = 120

VERSION_RE = re.compile(r'^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.]+))?$')
RELEASE_VERSION_RE = re.compile(r'^\d+\.\d+\.\d+(?:-RC\d+)?$')
RELEASE_TAG_RE = re.compile(r'^v\.(\d+\.\d+\.\d+(?:-RC\d+)?)-release$')


def fail(message):
    print('::error::' + message)
    sys.exit(1)


def set_output(name, value):
    print('{} = {}'.format(name, value))
    path = os.environ.get('GITHUB_OUTPUT')
    if path:
        with open(path, 'a') as f:
            f.write('{}={}\n'.format(name, value))


# ---------------------------------------------------------------------------------------------
# Versions
# ---------------------------------------------------------------------------------------------

def version_key(version):
    """Sort key following semver precedence: a pre-release sorts before its release, numeric
    identifiers compare as numbers, and RC-style identifiers compare by their number (RC2 < RC10)."""
    m = VERSION_RE.match(version)
    if not m:
        return None
    core = tuple(int(x) for x in m.group(1, 2, 3))
    pre = m.group(4)
    if pre is None:
        return core, (1,)
    idents = []
    for ident in pre.split('.'):
        if ident.isdigit():
            idents.append((0, int(ident), ''))
        else:
            parts = re.match(r'^([A-Za-z-]*)(\d*)$', ident)
            if parts:
                idents.append((1, int(parts.group(2) or 0), parts.group(1)))
            else:
                idents.append((1, 0, ident))
    return core, (0, tuple(idents))


def read_core_version():
    with open(CORE_FILE) as f:
        for line in f:
            m = re.match(r'^local version = "(.*)"', line)
            if m:
                return m.group(1)
    fail('Could not find `local version = "..."` in ' + CORE_FILE)


def http_get_json(url):
    import requests
    r = requests.get(url, timeout=TIMEOUT)
    r.raise_for_status()
    return r.json()


def nebula_versions(mod_id):
    """Every public version of a mod on Nebula."""
    data = http_get_json(NEBULA_REPO)
    return [m['version'] for m in data['mods'] if m['id'] == mod_id]


def nebula_has_version(mod_id, version):
    data = http_get_json(NEBULA_API + 'mod/json/{}/{}'.format(mod_id, version))
    return bool(data.get('result'))


def cmd_version(args):
    base = read_core_version()
    if not VERSION_RE.match(base):
        fail('Version in {} is "{}", which is not X.Y.Z or X.Y.Z-RCn'.format(CORE_FILE, base))

    if args.mode == 'release':
        if not RELEASE_VERSION_RE.match(base):
            fail('Release version must be X.Y.Z or X.Y.Z-RCn (got "{}")'.format(base))
        version = base
        tag = 'v.{}-release'.format(version)
        mod_id = load_json(RELEASE_TEMPLATE)['id']

        tags = subprocess.check_output(['git', 'tag', '--list', 'v.*-release']).decode().split()
        if args.resume:
            if tag not in tags:
                fail('Resuming, but tag {} does not exist yet; run a normal release instead'.format(tag))
        elif tag in tags:
            fail('Tag {} already exists. Bump the version in {} on master first.'.format(tag, CORE_FILE))
        released = [RELEASE_TAG_RE.match(t).group(1) for t in tags if RELEASE_TAG_RE.match(t)]
        released = [v for v in released if v != version]
        if released:
            latest = max(released, key=version_key)
            if version_key(version) <= version_key(latest):
                fail('Version {} is not newer than the latest release tag ({})'.format(version, latest))
            print('Latest existing release tag: v.{}-release'.format(latest))
        set_output('tag', tag)
        set_output('prerelease', 'true' if '-RC' in version else 'false')
    else:
        # Dev builds: the version in core stays at the last release; Nebula gets a date suffix.
        # YYYYMMDD so newer builds always sort higher.
        if '-' in base:
            fail('Dev builds need a plain X.Y.Z version in {} (got "{}")'.format(CORE_FILE, base))
        date = datetime.datetime.utcnow().strftime('%Y%m%d')
        version = '{}-{}'.format(base, date)
        mod_id = load_json(MOD_JSON)['id']

    # Nebula must not have this version yet, and it must sort above what's there, otherwise
    # Knossos never offers it as an update.
    if nebula_has_version(mod_id, version):
        fail('{} {} already exists on Nebula'.format(mod_id, version))
    existing = [v for v in nebula_versions(mod_id) if version_key(v) is not None and v != version]
    if existing:
        newest = max(existing, key=version_key)
        print('Newest public {} on Nebula: {}'.format(mod_id, newest))
        if version_key(version) <= version_key(newest):
            fail('{} {} would sort below {} {} on Nebula, so Knossos would never offer it as an update'
                 .format(mod_id, version, mod_id, newest))

    set_output('mod_id', mod_id)
    set_output('version', version)


# ---------------------------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------------------------

def load_json(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def tracked_files(folder):
    """Files git tracks under a package folder, relative to that folder, in a stable order."""
    out = subprocess.check_output(['git', 'ls-files', '-z', '--', folder]).decode('utf-8')
    prefix = folder.rstrip('/') + '/'
    return sorted(p[len(prefix):] for p in out.split('\0') if p)


def image_checksum(value):
    """mod.json stores images as kn_images\\<sha256>.png; Nebula wants the bare checksum."""
    if not value:
        return None
    name = os.path.basename(value.replace('\\', '/'))
    return os.path.splitext(name)[0]


def cmd_build(args):
    mod = load_json(MOD_JSON)
    template = load_json(RELEASE_TEMPLATE) if args.mode == 'release' else {}
    exclude = set(template.get('exclude_packages', []))
    renames = template.get('rename_packages', {})

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)

    meta = {
        'id': mod['id'],
        'title': mod['title'],
        'type': mod.get('type', 'mod'),
        'parent': mod.get('parent', 'FS2'),
        'version': args.version,
        'stability': args.stability,
        'description': mod.get('description', ''),
        'notes': '',
        'release_thread': mod.get('release_thread'),
        'first_release': mod.get('first_release'),
        'last_update': datetime.datetime.utcnow().strftime('%Y-%m-%d'),
        'cmdline': mod.get('cmdline', ''),
        'mod_flag': mod.get('mod_flag') or [mod['id']],
        'tile': image_checksum(mod.get('tile')),
        'banner': image_checksum(mod.get('banner')),
        'logo': None,
        'screenshots': [],
        'videos': [],
        'attachments': [],
        'private': args.private,
        'packages': [],
    }
    for key in ('id', 'title', 'description', 'release_thread', 'first_release', 'cmdline',
                'mod_flag', 'tile', 'banner'):
        if key in template:
            meta[key] = template[key]

    archives = []
    for pkg in mod['packages']:
        if pkg['name'] in exclude:
            print('Skipping package {}'.format(pkg['name']))
            continue
        name = renames.get(pkg['name'], pkg['name'])
        folder = pkg['folder']
        files = tracked_files(folder)
        if not files:
            fail('Package {} has no tracked files under {}/'.format(name, folder))

        archive_name = folder + '.7z'
        archive_path = os.path.join(out, archive_name)
        if os.path.exists(archive_path):
            os.remove(archive_path)
        list_path = os.path.join(out, folder + '.lst')
        with open(list_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(files) + '\n')
        subprocess.check_call([args.sevenzip, 'a', '-t7z', '-mx=9', '-bd', '-bso0', archive_path,
                               '@' + list_path], cwd=folder)
        os.remove(list_path)

        filelist = [{
            'filename': fn,
            'archive': archive_name,
            'orig_name': fn,
            'checksum': ['sha256', sha256_file(os.path.join(folder, fn))],
        } for fn in files]

        checksum = sha256_file(archive_path)
        size = os.path.getsize(archive_path)
        meta['packages'].append({
            'name': name,
            'notes': pkg.get('notes') or '',
            'status': pkg.get('status', 'optional'),
            'dependencies': pkg.get('dependencies') or [],
            'environment': pkg.get('environment'),
            'folder': folder,
            'is_vp': bool(pkg.get('is_vp')),
            'executables': [],
            'files': [{
                'filename': archive_name,
                'dest': '',
                'checksum': ['sha256', checksum],
                'filesize': size,
            }],
            'filelist': filelist,
        })
        archives.append({'path': archive_path, 'checksum': checksum, 'size': size})
        print('Packed {} ({} files, {} bytes, sha256 {})'.format(archive_name, len(files), size, checksum))

    with open(os.path.join(out, 'nebula_meta.json'), 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    with open(os.path.join(out, 'nebula_archives.json'), 'w', encoding='utf-8') as f:
        json.dump(archives, f, indent=2)

    if args.zip:
        write_download_zip(meta, mod, os.path.join(out, args.zip))


def write_download_zip(meta, mod, zip_path):
    """GitHub download: the same folder layout Knossos installs, e.g. SCPUI-1.2.0/content/data/...,
    with a local mod.json so the folder can be dropped into a Knossos library as-is."""
    root = '{}-{}'.format(meta['id'], meta['version'])
    local = {k: v for k, v in meta.items() if k not in ('packages', 'private', 'tile', 'banner')}
    local.update({'mod_source': 'nebula', 'installed': True, 'owners': mod.get('owners'),
                  'tile': None, 'banner': None, 'packages': []})
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
        for pkg in meta['packages']:
            pkg_local = {k: v for k, v in pkg.items() if k not in ('files', 'filelist')}
            pkg_local.update({'files': None, 'filelist': None, 'isEnabled': True})
            local['packages'].append(pkg_local)
            for entry in pkg['filelist']:
                src = os.path.join(pkg['folder'], entry['filename'])
                z.write(src, '{}/{}/{}'.format(root, pkg['folder'], entry['filename']))
        z.writestr(root + '/mod.json', json.dumps(local, indent=2))
    print('Wrote {}'.format(zip_path))


# ---------------------------------------------------------------------------------------------
# Publish
# ---------------------------------------------------------------------------------------------

def nebula_request(session, method, path, **kwargs):
    last_error = None
    for attempt in range(5):
        try:
            return session.request(method, NEBULA_API + path, timeout=TIMEOUT, **kwargs)
        except Exception as e:  # network hiccups; the endpoints are safe to retry
            last_error = e
            print('  {} {} failed ({}), retrying'.format(method.upper(), path, e))
            time.sleep(5 * (attempt + 1))
    raise last_error


def ok(response):
    if response.status_code != 200:
        return False
    try:
        return bool(response.json().get('result'))
    except ValueError:
        return False


def upload_chunked(session, headers, path, checksum, size):
    with open(path, 'rb') as f:
        if ok(nebula_request(session, 'post', 'upload/check', headers=headers, data={'checksum': checksum})):
            print('  already on Nebula: {}'.format(os.path.basename(path)))
            return

        parts = max(1, (size + UPLOAD_CHUNK_SIZE - 1) // UPLOAD_CHUNK_SIZE)
        start = nebula_request(session, 'post', 'multiupload/start', headers=headers,
                               data={'id': checksum, 'size': str(size), 'parts': str(parts)})
        if not ok(start):
            fail('multiupload/start failed for {}: {}'.format(path, start.text[:200]))
        finished = set(start.json().get('finished_parts', []))

        for idx in range(parts):
            chunk = f.read(UPLOAD_CHUNK_SIZE)
            if idx in finished:
                continue
            part = nebula_request(session, 'post', 'multiupload/part', headers=headers,
                                  data={'id': checksum, 'part': str(idx)}, files={'file': ('chunk', chunk)})
            if part.status_code != 200:
                fail('multiupload/part {} failed for {}'.format(idx, path))
            verify = nebula_request(session, 'post', 'multiupload/verify_part', headers=headers,
                                    data={'id': checksum, 'part': str(idx),
                                          'checksum': hashlib.sha256(chunk).hexdigest()})
            if not ok(verify):
                fail('multiupload/verify_part {} failed for {}'.format(idx, path))

        finish = nebula_request(session, 'post', 'multiupload/finish', headers=headers,
                                data={'id': checksum, 'checksum': checksum})
        if not ok(finish):
            fail('multiupload/finish failed for {}: {}'.format(path, finish.text[:200]))
        print('  uploaded {}'.format(os.path.basename(path)))


def cmd_publish(args):
    import requests

    meta = load_json(os.path.join(args.out, 'nebula_meta.json'))
    archives = load_json(os.path.join(args.out, 'nebula_archives.json'))
    user = os.environ.get('NEBULA_USER')
    password = os.environ.get('NEBULA_PASSWORD')
    if not user or not password:
        fail('NEBULA_USER and NEBULA_PASSWORD secrets must be set')

    print('Publishing {} {} to Nebula ({})'.format(meta['id'], meta['version'],
                                                 'private' if meta['private'] else 'public'))
    with requests.Session() as session:
        login = nebula_request(session, 'post', 'login', data={'user': user, 'password': password})
        if not ok(login):
            fail('Nebula login failed')
        headers = {'X-KN-TOKEN': login.json()['token']}

        for image in (meta.get('tile'), meta.get('banner')):
            if image and not ok(nebula_request(session, 'post', 'upload/check', headers=headers,
                                               data={'checksum': image})):
                fail('Image {} is not on Nebula; check tile/banner in the metadata'.format(image))

        for archive in archives:
            upload_chunked(session, headers, archive['path'], archive['checksum'], archive['size'])

        result = nebula_request(session, 'post', 'mod/release', headers=headers, json=meta)
        if not ok(result):
            fail('Nebula rejected the release: {}'.format(result.text[:500]))
    print('Published {} {}'.format(meta['id'], meta['version']))


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command')
    sub.required = True

    p = sub.add_parser('version')
    p.add_argument('--mode', choices=('release', 'dev'), required=True)
    p.add_argument('--resume', action='store_true',
                   help='Release only: the tag already exists and only the Nebula publish is being retried')

    p = sub.add_parser('build')
    p.add_argument('--mode', choices=('release', 'dev'), required=True)
    p.add_argument('--version', required=True)
    p.add_argument('--stability', required=True)
    p.add_argument('--private', type=lambda s: s.lower() != 'false', default=True,
                   help="'false' publishes publicly; anything else is private")
    p.add_argument('--out', default='dist')
    p.add_argument('--zip', help='Also write the GitHub download zip under this name')
    p.add_argument('--sevenzip', default='7z')

    p = sub.add_parser('publish')
    p.add_argument('--out', default='dist')

    args = parser.parse_args()
    {'version': cmd_version, 'build': cmd_build, 'publish': cmd_publish}[args.command](args)


if __name__ == '__main__':
    main()
