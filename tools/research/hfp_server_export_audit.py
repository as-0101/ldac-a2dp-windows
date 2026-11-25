#!/usr/bin/env python3
"""Read-only named-import closure for Win10 HFP donor PE metadata vs Server 2022 CI exports.
Archives are metadata only. No Microsoft binaries are extracted or published.
"""
import argparse
import hashlib
import io
import json
import re
from pathlib import Path
from zipfile import ZipFile

HFP_GLOB = 'hfp-pe/'
BTA_MEMBER = 'pe-audit/win10-BtaMPM.sys-DA5CBBDCE6AC.json'
BTA_NESTED = 'CI-6-dependency-first.zip'
EXPECTED_BTA_SHA256 = 'da5cbbdce6ac511ef8400e121df6b6eaca7d05c0f40a01f7353ce9f220eb3dcd'


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def parse_dumpbin_exports(text):
    """Parse dumpbin /exports, including hexadecimal hints and forwarded HAL exports."""
    active = False
    result = {}
    expected = None
    for raw in text.splitlines():
        s = raw.strip()
        m = re.search(r'\b(\d+) number of names$', s)
        if m:
            expected = int(m.group(1))
        if s == 'ordinal hint RVA      name':
            active = True
            continue
        if not active:
            continue
        if s == 'Summary':
            break
        if '[NONAME]' in s:
            continue
        cols = s.split()
        if len(cols) < 3 or not cols[0].isdigit() or not re.fullmatch(r'[\da-fA-F]+', cols[1]):
            continue
        index = 3 if len(cols) >= 4 and re.fullmatch(r'[\da-fA-F]{8}', cols[2]) else 2
        if index >= len(cols):
            continue
        name = cols[index]
        if name in result:
            raise ValueError(f'duplicate export name {name}')
        forwarder = None
        if '(forwarded to ' in s:
            forwarder_text = s.split('(forwarded to ', 1)[1].split(')', 1)[0].strip()
            if '.' not in forwarder_text:
                raise ValueError(f'invalid forwarded export {raw!r}')
            mod, target = forwarder_text.rsplit('.', 1)
            forwarder = [mod.lower(), target]
        result[name] = {'ordinal': int(cols[0]), 'forwarder': forwarder}
    if expected is None or not active or len(result) != expected:
        raise ValueError(f'incomplete dumpbin export inventory: got {len(result)} expected {expected}')
    return result


def meta_exports(blob):
    """PE metadata exports: list of dicts, use exact names only."""
    if isinstance(blob, dict):
        blob = blob.get('symbols', blob.get('entries', blob.get('exports', [])))
    if not isinstance(blob, list):
        raise ValueError('Unexpected BtaMPM exports representation')
    result = {}
    for item in blob:
        if not isinstance(item, dict) or not item.get('name'):
            continue
        result[item['name']] = {'ordinal': item.get('ordinal'), 'forwarder': item.get('forwarder')}
    return result


def load_sources(hfp_path, server_path, a2dp_path):
    with ZipFile(server_path) as z:
        names = z.namelist()
        exports = {}
        for n in names:
            if n.lower().endswith('.exports.txt'):
                module = n.rsplit('/', 1)[-1][:-len('.exports.txt')].lower()
                exports[module] = parse_dumpbin_exports(z.read(n).decode('utf-8-sig', errors='replace'))
        os_info = z.read('os.txt').decode('utf-8-sig', errors='replace')
        module_info = z.read('module-status.txt').decode('utf-8-sig', errors='replace')
    with ZipFile(a2dp_path) as outer:
        with ZipFile(io.BytesIO(outer.read(BTA_NESTED))) as z:
            bta = json.loads(z.read(BTA_MEMBER))
    if bta['hashes']['sha256'].lower() != EXPECTED_BTA_SHA256:
        raise ValueError('BtaMPM donor binary identity differs from pinned SHA256')
    entries = meta_exports(bta['exports'])
    if len(entries) != 14:
        raise ValueError(f'Unexpected BtaMPM exports: {len(entries)} (expected 14)')
    exports['btampm.sys'] = entries
    with ZipFile(hfp_path) as z:
        hfp = {n: json.loads(z.read(n)) for n in z.namelist() if n.startswith(HFP_GLOB) and n.endswith('.json')}
    if len(hfp) != 3:
        raise ValueError(f'Expected 3 donor PE metadata files; found {len(hfp)}')
    return exports, hfp, os_info, module_info, bta


def analyze_imports(hfp_files, exports):
    report = []
    for path, pe in sorted(hfp_files.items()):
        details = []
        for d in pe['imports']:
            module = d['dll'].lower()
            symbols = d['symbols']
            if d.get('count') is not None and int(d['count']) != len(symbols):
                raise ValueError(f'Truncated PE import table: {path}/{module}: {len(symbols)} != {d["count"]}')
            actual = exports.get(module)
            missing = []
            transitive_missing = []
            ordinals = []
            forwarded = []
            for symbol in symbols:
                name = symbol.get('name')
                if not name:
                    ordinals.append(symbol.get('ordinal'))
                    continue
                if actual is None or name not in actual:
                    missing.append(name)
                    continue
                fw = actual[name].get('forwarder')
                if fw:
                    forwarded.append({'name': name, 'target': '.'.join(fw)})
                    final = next((exports[k] for k in [fw[0]+'.dll', fw[0]+'.sys', fw[0]+'.exe'] if k in exports), {})
                    if fw[1] not in final:
                        transitive_missing.append({'name': name, 'forward_to': '.'.join(fw)})
            details.append({'module': module, 'imports': len(symbols), 'provided': actual is not None,
                            'missing': sorted(missing), 'ordinal_imports': ordinals,
                            'forwarded': forwarded, 'forwarder_missing': transitive_missing})
        file_pass = all(d['provided'] and not d['missing'] and not d['ordinal_imports'] and not d['forwarder_missing'] for d in details)
        report.append({'file': path, 'sha256': pe['hashes'].get('sha256') or pe['hashes'].get('SHA256'),
                       'imports_total': sum(d['imports'] for d in details), 'modules': details, 'passed': file_pass})
    return report


def run(hfp_path, server_path, a2dp_path):
    exports, donor, os_info, module_info, bta = load_sources(hfp_path, server_path, a2dp_path)
    pe_reports = analyze_imports(donor, exports)
    return {'scope':'Static named PE import/export resolution only, no ABI/runtime/signature/binding',
            'source_archives':{'hfp_metadata': digest(hfp_path),'server_exports': digest(server_path),
                               'a2dp_donor_results':digest(a2dp_path)},
            'server_environment':os_info.strip(),
            'server_module_status_sha256':hashlib.sha256(module_info.encode()).hexdigest(),
            'server_inventory_name_counts':{k:len(v) for k,v in exports.items() if k!='btampm.sys'},
            'bta_export_count':len(exports['btampm.sys']),
            'pe_reports':pe_reports,
            'summary':{'files':len(pe_reports),'imports':sum(p['imports_total'] for p in pe_reports),
                       'unresolved':sum(len(d['missing'])+len(d['ordinal_imports'])+len(d['forwarder_missing']) for p in pe_reports for d in p['modules']),
                       'all_pass':all(p['passed'] for p in pe_reports)},
            'limitations':['Server 20348.5866 inventory differs from physical 20348.5761 and hosted 20348.5870',
                           'Export name closure does not establish call ABI, PnP binding, installability, kernel signature, or loaded audio endpoints',
                           'BtaMPM exports come from pinned Win10 donor package, not from Server inbox',
                           'No physical OPPO mic or live duplex tested']}


def main():
    p=argparse.ArgumentParser()
    for x in ['hfp','server','a2dp','out']:
        p.add_argument('--'+x,required=True,type=Path)
    a=p.parse_args()
    report=run(a.hfp,a.server,a.a2dp)
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print(json.dumps(report['summary'],ensure_ascii=False))
    raise SystemExit(0 if report['summary']['all_pass'] else 1)
if __name__=='__main__':main()