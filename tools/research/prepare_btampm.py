"""Prepare an unsigned BtaMPM catalog experiment; never installs anything."""
import argparse
import hashlib
import re
from pathlib import Path

INF_SHA = 'c657a6b32ac8ccfdeef3c12630686b87c973dd114bee73aec288d86b989961ef'
SYS_SHA = 'da5cbbdce6ac511ef8400e121df6b6eaca7d05c0f40a01f7353ce9f220eb3dcd'
CAT_LINE = 'CatalogFile.NTamd64 = BtaMPM-Server2022.cat'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def patch(data):
    if data.startswith(b'\xff\xfe'):
        bom, enc = b'\xff\xfe', 'utf-16-le'
    elif data.startswith(b'\xef\xbb\xbf'):
        bom, enc = b'\xef\xbb\xbf', 'utf-8'
    else:
        bom, enc = b'', 'ascii'
    body = data[len(bom):].decode(enc)
    if re.search(r'(?im)^\s*CatalogFile(?:\.[^=\r\n]+)?\s*=', body):
        raise ValueError('Existing catalog directive; inspect manually')
    matches = list(re.finditer(r'(?im)^[ \t]*\[Version\][ \t]*(\r?\n)', body))
    if len(matches) != 1:
        raise ValueError('Expected exactly one [Version] section')
    for token in ('[BtaMPM.CopyFilesOnly]', 'CopyFiles=BtaMPM.CopyFiles', '[BtaMPM.CopyFiles]', 'BtaMPM.sys'):
        if token.lower() not in body.lower():
            raise ValueError('Missing donor evidence: ' + token)
    m = matches[0]
    inserted = CAT_LINE + m.group(1)
    result = body[:m.end()] + inserted + body[m.end():]
    return bom + result.encode(enc)


def prepare(inf, sys, out):
    original, binary = inf.read_bytes(), sys.read_bytes()
    if sha(original) != INF_SHA or sha(binary) != SYS_SHA:
        raise ValueError(f'Donor SHA mismatch: INF={sha(original)} SYS={sha(binary)}; no output created')
    modified = patch(original)
    out.mkdir(parents=True, exist_ok=False)
    (out / 'btampm.inf').write_bytes(modified)
    (out / 'BtaMPM.sys').write_bytes(binary)
    print('UNSIGNED_CANDIDATE', out, 'INF_SHA256=' + sha(modified), 'SYS_SHA256=' + sha(binary))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('inf', type=Path)
    p.add_argument('sys', type=Path)
    p.add_argument('out', type=Path)
    a = p.parse_args()
    prepare(a.inf, a.sys, a.out)
