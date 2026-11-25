#!/usr/bin/env python3
"""Read-only HFP INF/CAT *evidence* audit; never installs drivers or trusts names alone.

A catalog filename, an Authenticode signature and file membership are distinct tests.
Real package signing/OS eligibility must be verified with Windows tools and a genuine
unmodified, complete donor package. This module does not infer them from INF text.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

HFP_INF_PATTERN = re.compile(r'^(?:microsoft_bluetooth_hfp|bthhf|bthag)[^\\/]*\.inf$', re.I)
HFP_HW_PATTERN = re.compile(r'BTH(?:HFENUM|ENUM)\\(?:BthHFPAudio|\{0000111e-0000-1000-8000-00805f9b34fb\})', re.I)
SERVICE_PATTERN = re.compile(r'\b(?:BthHfAud|BthHfEnum|BthHFSrv|BTAGService)\b', re.I)
DRIVER_NAMES = ('BthHfAud.sys','BthHfEnum.sys')


def file_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b'\xff\xfe'):
        return raw[2:].decode('utf-16-le')
    if raw.startswith(b'\xfe\xff'):
        return raw[2:].decode('utf-16-be')
    return raw.decode('utf-8-sig')


def strip_comment(line: str) -> str:
    # INF strings may contain semicolons within quoted values.
    quoted = False
    for index, char in enumerate(line):
        if char == '"':
            quoted = not quoted
        elif char == ';' and not quoted:
            return line[:index]
    return line


def sections_of(text: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current = None
    pending = ''
    for physical in text.splitlines():
        line = strip_comment(physical).strip()
        if not line:
            continue
        if line.endswith('\\'):
            pending += line[:-1].rstrip() + ' '
            continue
        line = pending + line
        pending = ''
        if line.startswith('[') and line.endswith(']'):
            name = line[1:-1].strip().lower()
            if name in sections:
                raise ValueError('Duplicate section ' + name)
            sections[name] = []
            current = name
        elif current:
            sections[current].append(line)
    if pending:
        raise ValueError('Dangling INF line continuation')
    return sections


def entries(sections: dict[str,list[str]], key: str) -> list[tuple[str,str,str]]:
    result = []
    for section, lines in sections.items():
        for line in lines:
            if '=' not in line:
                continue
            k,v = line.split('=',1)
            if k.strip().lower() == key.lower():
                result.append((section,k.strip(),v.strip()))
    return result


def inf_summary(path: Path, package_roots: list[Path]) -> dict:
    text = read_text(path)
    blocks = sections_of(text)
    ver = blocks.get('version', [])
    catalog_names = []
    for line in ver:
        if '=' not in line:
            continue
        key,value = (x.strip() for x in line.split('=',1))
        if re.fullmatch(r'catalogfile(?:\.[\w.]+)?',key,re.I):
            catalog_names.append({'key':key,'name':value.strip('"')})
    member_files = []
    for section,k,value in entries(blocks,'ServiceBinary'):
        for part in re.split(r'[,\\/]',value):
            match = re.search(r'(?i)\b([\w.-]+\.sys)\b',part)
            if match:
                member_files.append(match.group(1))
    # Require each referenced driver within the candidate package directory.
    binary_presence = [{'name':name, 'exists':any((root/name).is_file() for root in package_roots)} for name in sorted(set(member_files), key=str.lower)]
    # Catalog filenames do not demonstrate content membership or signed status.
    catalogs=[]
    for cat in catalog_names:
        name=cat['name']
        candidates=[root/name for root in package_roots]
        matched=next((x for x in candidates if x.is_file()),None)
        catalogs.append({'directive':cat['key'],'file':name,'exists':matched is not None,
                         'sha256':file_digest(matched) if matched else None,
                         'signature_status':'UNTESTED','member_verification':'UNTESTED'})
    return {
        'inf_name':path.name,'inf_sha256':file_digest(path),'sections_count':len(blocks),
        'catalogs':catalogs,'catalog_directives':len(catalog_names),
        'includes':entries(blocks,'Include'),'needs':entries(blocks,'Needs'),
        'add_services':entries(blocks,'AddService'),
        'service_binaries':entries(blocks,'ServiceBinary'),
        'copy_files':entries(blocks,'CopyFiles'),
        'hardware_ids_found':bool(HFP_HW_PATTERN.search(text)),
        'hfp_service_mentions':sorted(set(SERVICE_PATTERN.findall(text)), key=str.lower),
        'binary_names':sorted(set(member_files),key=str.lower),
        'service_binary_presence':binary_presence,
        'candidate_complete':bool(catalogs and all(c['exists'] for c in catalogs)
                                  and HFP_HW_PATTERN.search(text)
                                  and entries(blocks,'AddService')
                                  and entries(blocks,'ServiceBinary') and binary_presence
                                  and all(x['exists'] for x in binary_presence)),
        'signature_gate':'UNTESTED',
    }


def audit(root: Path) -> dict:
    if not root.is_dir():
        return {'status':'BLOCKED','reason':'donor_root_missing','source':str(root),'packages':[]}
    candidates=[p for p in root.rglob('*.inf') if HFP_INF_PATTERN.fullmatch(p.name)]
    if not candidates:
        return {'status':'BLOCKED','reason':'original_hfp_inf_unavailable','source':str(root),'packages':[]}
    packages=[]
    for f in sorted(candidates):
        local_roots=[f.parent]
        packages.append(inf_summary(f,local_roots))
    # Even a complete INF/CAT directory is not signing verified until SignTool checks the
    # real catalog and each referenced original SYS on an isolated supported target.
    return {'status':'STATIC_INSPECTED','reason':'real_cat_membership_and_server_signing_still_untested',
            'source':str(root),'packages':packages,'runtime_gate':'UNTESTED',
            'required_native_checks':['InfVerif on original INF','Inf2Cat /nocat /os:ServerFE_X64 on a complete original package',
                                      'SignTool verify /kp /v /c actual.cat actual.sys for each member',
                                      'check full original package CAT trust on hosted Server',
                                      'PnP staging/binding/service start only with authentic trusted package and user authorization']}


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',required=True,type=Path)
    ap.add_argument('--out',required=True,type=Path)
    args=ap.parse_args()
    result=audit(args.root)
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print(json.dumps({'status':result['status'],'reason':result['reason'],
                      'packages':len(result['packages'])}))
    return 0 if result['status'] in ('BLOCKED','STATIC_INSPECTED') else 1

if __name__ == '__main__':
    raise SystemExit(main())