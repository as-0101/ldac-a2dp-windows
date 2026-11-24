"""Run with Python 3 and OpenSSL. Argument: directory containing the four original ZIPs."""
import csv
import hashlib
import io
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path, PureWindowsPath
from zipfile import ZipFile

root = Path(sys.argv[1])
def one(pattern):
    path, = root.glob(pattern)
    return path

def decode(data):
    return data.decode('utf-16' if data.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig')

def rows(archive, name):
    return list(csv.DictReader(io.StringIO(decode(archive.read(name)))))

def sha(data):
    return hashlib.sha256(data).hexdigest()

def check(condition, description):
    if not condition:
        raise ValueError(description)

def signature(data):
    return subprocess.run(['openssl','smime','-verify','-inform','DER','-noverify'],
                          input=data, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE).returncode == 0

def member_keys(data):
    tree = subprocess.run(['openssl','asn1parse','-inform','DER'],input=data,
                          capture_output=True,check=True).stdout.decode().splitlines()
    # In this PKCS7/CTL layout, only count the FIRST field of each CTLEntry.
    ctl = False
    member_algorithm_seen = False
    table = False
    expect_key = False
    keys = set()
    for line in tree:
        depth = int(re.search(r'd=(\d+)',line)[1])
        if '1.3.6.1.4.1.311.10.1' == line.rsplit(':',1)[-1]:
            ctl = True
            continue
        if ctl and depth < 4:
            break
        if ctl and depth == 6:
            if table:
                break
            table = 'cons: SEQUENCE' in line and member_algorithm_seen
        if ctl and '1.3.6.1.4.1.311.12.1.3' == line.rsplit(':',1)[-1]:
            member_algorithm_seen = True
        if table and depth == 7:
            expect_key = True
        elif expect_key:
            match = re.search(r'OCTET STRING\s+\[HEX DUMP\]:([0-9A-F]+)$',line)
            check(depth == 8 and match,'Unexpected CTLEntry')
            keys.add(match[1].lower())
            expect_key = False
    check(keys,'CTL member table not found')
    return keys

paths = [one(p) for p in ('A2DP-Next-Win10*.zip','A2DP-Next-Server*.zip','A2DP-CBS.zip','CI-5-stage-smoke-failure.zip')]
win, server, cbs, ci = map(ZipFile,paths)
for z in (win, server, cbs, ci):
    check(z.testzip() is None,'CRC failure')
catname, = [n for n in win.namelist() if n.endswith('.cat')]
cat = win.read(catname)
keys = member_keys(cat)
lookup = rows(win,'Catalog-lookup.csv')
for row in lookup:
    check(row['CatalogSHA256'].lower()==sha(cat) and row['CatalogMemberHash'].lower() in keys,'Catalog lookup mismatch')
mumname, = [n for n in cbs.namelist() if '~~' in n and n.endswith('.mum')]
mum = cbs.read(mumname)
check(sha(mum) in keys,'Missing neutral MUM')
drivers = {d.get('inf'):d.find('{*}assemblyIdentity').get('version') for d in ET.fromstring(mum).iterfind('.//{*}driver')}
focus = {n:v for n,v in drivers.items() if 'a2dp' in n or n=='btampm.inf'}
check(len(focus)==4,'Missing driver identity')
for name in focus:
    check(sha(win.read('INF\\'+name)) in keys,name)
src = win.read('INF\\microsoft_bluetooth_a2dp_src.inf')
check(sha(src+b' ') not in keys,'Edited INF unexpectedly matched')
member = bytes.fromhex(sha(src))
at = cat.index(member)
tampered = cat[:at] + bytes([cat[at]^1]) + cat[at+1:]
check(signature(cat) and not signature(tampered),'Catalog signature integrity control')
log = decode(server.read('SetupAPI-extract.txt'))
check("Unpublished 'oem75.inf'" in log and "Deleted service 'LdacA2dp'" in log,'Missing removal evidence')
def node(z):
    r, = [r for r in rows(z,'PnP.csv') if r['InstanceId'].upper().startswith('BTHENUM\\{0000110B-') and '_LOCALMFG&0002' in r['InstanceId'].upper()]
    return r
a,b = node(win),node(server)
check(a['InstanceId'].split('&')[-1]==b['InstanceId'].split('&')[-1],'Different remote identifiers')
stage = json.loads(decode(ci.read('stage-test.json')))
attempts = []
for line in stage['setupApiLogTail']:
    if line.startswith('>>>  [Driver Install') and 'microsoft_bluetooth_a2dp_src.inf' in line:
        attempts.append([])
    elif attempts:
        attempts[-1].append(line)
def attempt(lines):
    copies = sorted({PureWindowsPath(l.split("'")[1]).name for l in lines if 'flq:' in l and "Copying '" in l})
    include = next(i for i,l in enumerate(lines) if 'Could not find include INF' in l)
    policy = next(i for i,l in enumerate(lines) if 'IMPORT VALIDATE}' in l)
    failure = next(i for i,l in enumerate(lines) if 'Error = 0xE000022F' in l)
    check(include < policy < failure,'Unexpected stage sequence')
    return copies
copy_attempts = [attempt(lines) for lines in attempts]
check(copy_attempts==[['microsoft_bluetooth_a2dp_src.inf']]*2,'Unexpected file queues')
print(json.dumps(dict(archive_sha256={p.name:sha(p.read_bytes()) for p in paths},
    cat_sha256=sha(cat),ci5_cat_sha256=stage['package']['catalogSha256'].lower(),ctl_member_keys=len(keys),
    lookup_rows=len(lookup),unique_lookup_hashes=len({r['CatalogMemberHash'] for r in lookup}),
    neutral_mum_sha256=sha(mum),total_driver_declarations=len(drivers),selected_driver_versions=focus,
    signature_integrity='original passes, one-bit CTL change fails; no chain validation',
    edited_inf='appended byte absent from member keys',pnp={k:{f:r[f] for f in ('Class','FriendlyName','Problem')} for k,r in [('win10',a),('server',b)]},
    ci5_copy_sources_by_attempt=copy_attempts),indent=2,ensure_ascii=False))
