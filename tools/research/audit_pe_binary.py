#!/usr/bin/env python3
"""Static PE audit for Windows Bluetooth/A2DP binaries.

This tool never loads or executes the input binary. It reports PE headers,
imports, delay imports, exports, version resources, CodeView/PDB metadata,
API-set imports, and (optionally) compares imports with exports from a supplied
reference directory. A successful symbol comparison is not a runtime
compatibility result. Catalog membership must be verified separately with the
matching CAT file and SignTool.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any

import pefile


MACHINES = {0x014C: "I386", 0x8664: "AMD64", 0xAA64: "ARM64"}
SUBSYSTEMS = {1: "NATIVE", 2: "WINDOWS_GUI", 3: "WINDOWS_CUI", 9: "WINDOWS_CE_GUI", 10: "EFI_APPLICATION", 11: "EFI_BOOT_SERVICE_DRIVER", 12: "EFI_RUNTIME_DRIVER", 13: "EFI_ROM", 14: "XBOX", 16: "WINDOWS_BOOT_APPLICATION"}
DLL_CHARACTERISTICS = {
    0x0020: "HIGH_ENTROPY_VA", 0x0040: "DYNAMIC_BASE",
    0x0080: "FORCE_INTEGRITY", 0x0100: "NX_COMPAT",
    0x0200: "NO_ISOLATION", 0x0400: "NO_SEH",
    0x0800: "NO_BIND", 0x1000: "APPCONTAINER",
    0x2000: "WDM_DRIVER", 0x4000: "GUARD_CF",
    0x8000: "TERMINAL_SERVER_AWARE",
}


def decode(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace").rstrip("\x00")
    return str(value)


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_version_info(pe: pefile.PE) -> dict[str, str]:
    values: dict[str, str] = {}
    for file_info in getattr(pe, "FileInfo", []) or []:
        entries = file_info if isinstance(file_info, list) else [file_info]
        for entry in entries:
            if decode(getattr(entry, "Key", None)) != "StringFileInfo":
                continue
            for table in getattr(entry, "StringTable", []) or []:
                for key, value in getattr(table, "entries", {}).items():
                    k, v = decode(key), decode(value)
                    if k and v is not None:
                        values[k] = v
    return values


def collect_import_table(pe: pefile.PE, directory_name: str) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for descriptor in getattr(pe, directory_name, []) or []:
        dll = decode(getattr(descriptor, "dll", None)) or "<unknown>"
        symbols: list[dict[str, Any]] = []
        for item in getattr(descriptor, "imports", []) or []:
            name = decode(getattr(item, "name", None))
            ordinal = getattr(item, "ordinal", None)
            symbols.append({
                "name": name,
                "ordinal": int(ordinal) if ordinal is not None else None,
                "hint": int(getattr(item, "hint", 0)) if name else None,
            })
        result.append({"dll": dll, "symbols": symbols, "count": len(symbols)})
    return result


def collect_exports(pe: pefile.PE) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    directory = getattr(pe, "DIRECTORY_ENTRY_EXPORT", None)
    if not directory:
        return result
    for item in directory.symbols:
        result.append({
            "name": decode(getattr(item, "name", None)),
            "ordinal": int(getattr(item, "ordinal", 0)),
            "address_rva": int(getattr(item, "address", 0)),
            "forwarder": decode(getattr(item, "forwarder", None)),
        })
    return result


def collect_debug(pe: pefile.PE) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for item in getattr(pe, "DIRECTORY_ENTRY_DEBUG", []) or []:
        record: dict[str, Any] = {
            "type": int(getattr(item.struct, "Type", 0)),
            "size": int(getattr(item.struct, "SizeOfData", 0)),
        }
        cv = getattr(item, "entry", None)
        pdb_name = decode(getattr(cv, "PdbFileName", None)) if cv else None
        if pdb_name:
            record["pdb_file"] = pdb_name
            record["pdb_age"] = int(getattr(cv, "Age", 0))
            signature = getattr(cv, "Signature", None)
            if signature is not None:
                record["pdb_signature"] = str(signature)
        result.append(record)
    return result


def compare_with_reference(imports: list[dict[str, Any]], reference_dir: pathlib.Path) -> list[dict[str, Any]]:
    files = {
        path.name.casefold(): path
        for path in reference_dir.rglob("*")
        if path.is_file() and path.suffix.casefold() in {".dll", ".sys", ".exe"}
    }
    checks: list[dict[str, Any]] = []
    export_cache: dict[pathlib.Path, tuple[set[str], set[int]]] = {}

    for descriptor in imports:
        dll = descriptor["dll"]
        ref_path = files.get(pathlib.Path(dll).name.casefold())
        if not ref_path:
            checks.append({"dll": dll, "status": "reference-file-not-found"})
            continue
        if ref_path not in export_cache:
            try:
                ref_pe = pefile.PE(str(ref_path), fast_load=False)
                ref_pe.parse_data_directories()
                names: set[str] = set()
                ordinals: set[int] = set()
                export_dir = getattr(ref_pe, "DIRECTORY_ENTRY_EXPORT", None)
                if export_dir:
                    for symbol in export_dir.symbols:
                        if symbol.name:
                            names.add(decode(symbol.name) or "")
                        ordinals.add(int(symbol.ordinal))
                export_cache[ref_path] = (names, ordinals)
                ref_pe.close()
            except Exception as exc:
                checks.append({
                    "dll": dll,
                    "reference_file": str(ref_path),
                    "status": "reference-parse-failed",
                    "error": str(exc),
                })
                continue

        names, ordinals = export_cache[ref_path]
        missing: list[dict[str, Any]] = []
        for symbol in descriptor["symbols"]:
            if symbol["name"]:
                if symbol["name"] not in names:
                    missing.append(symbol)
            elif symbol["ordinal"] is not None and symbol["ordinal"] not in ordinals:
                missing.append(symbol)
        checks.append({
            "dll": dll,
            "reference_file": str(ref_path),
            "reference_sha256": sha256_file(ref_path),
            "import_count": descriptor["count"],
            "missing_imports": missing,
            "status": "all-static-imports-found" if not missing else "missing-static-imports",
        })
    return checks


def audit(path: pathlib.Path, reference_dir: pathlib.Path | None) -> dict[str, Any]:
    pe = pefile.PE(str(path), fast_load=False)
    pe.parse_data_directories()
    imports = collect_import_table(pe, "DIRECTORY_ENTRY_IMPORT")
    delay_imports = collect_import_table(pe, "DIRECTORY_ENTRY_DELAY_IMPORT")
    exports = collect_exports(pe)

    security_index = pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_SECURITY"]
    security = pe.OPTIONAL_HEADER.DATA_DIRECTORY[security_index]
    dll_flags = int(pe.OPTIONAL_HEADER.DllCharacteristics)
    flags = [name for bit, name in DLL_CHARACTERISTICS.items() if dll_flags & bit]
    sections = [{
        "name": decode(section.Name),
        "virtual_address": int(section.VirtualAddress),
        "virtual_size": int(section.Misc_VirtualSize),
        "raw_size": int(section.SizeOfRawData),
        "characteristics": int(section.Characteristics),
    } for section in pe.sections]

    imported_dlls = sorted({item["dll"] for item in imports + delay_imports})
    api_set_imports = [
        name for name in imported_dlls
        if name.casefold().startswith(("api-ms-win-", "ext-ms-win-"))
    ]

    result: dict[str, Any] = {
        "analysis_scope": (
            "Static PE parsing only. No binary execution, driver load, device "
            "enumeration, signature catalog verification, or runtime compatibility claim."
        ),
        "file": str(path),
        "size_bytes": path.stat().st_size,
        "hashes": {
            "sha256": sha256_file(path),
            "sha1": hashlib.sha1(path.read_bytes()).hexdigest(),
        },
        "pe": {
            "machine": int(pe.FILE_HEADER.Machine),
            "machine_name": MACHINES.get(int(pe.FILE_HEADER.Machine), "UNKNOWN"),
            "timestamp": int(pe.FILE_HEADER.TimeDateStamp),
            "timestamp_hex": f"0x{int(pe.FILE_HEADER.TimeDateStamp):08X}",
            "number_of_sections": int(pe.FILE_HEADER.NumberOfSections),
            "optional_header_magic": f"0x{int(pe.OPTIONAL_HEADER.Magic):04X}",
            "size_of_image": int(pe.OPTIONAL_HEADER.SizeOfImage),
            "size_of_headers": int(pe.OPTIONAL_HEADER.SizeOfHeaders),
            "entry_point_rva": int(pe.OPTIONAL_HEADER.AddressOfEntryPoint),
            "image_base": int(pe.OPTIONAL_HEADER.ImageBase),
            "os_version_fields": {
                "major": int(pe.OPTIONAL_HEADER.MajorOperatingSystemVersion),
                "minor": int(pe.OPTIONAL_HEADER.MinorOperatingSystemVersion),
            },
            "image_version_fields": {
                "major": int(pe.OPTIONAL_HEADER.MajorImageVersion),
                "minor": int(pe.OPTIONAL_HEADER.MinorImageVersion),
            },
            "subsystem_version_fields": {
                "major": int(pe.OPTIONAL_HEADER.MajorSubsystemVersion),
                "minor": int(pe.OPTIONAL_HEADER.MinorSubsystemVersion),
            },
            "subsystem": int(pe.OPTIONAL_HEADER.Subsystem),
            "subsystem_name": SUBSYSTEMS.get(int(pe.OPTIONAL_HEADER.Subsystem), "UNKNOWN"),
            "dll_characteristics": dll_flags,
            "dll_characteristic_flags": flags,
            "checksum": int(pe.OPTIONAL_HEADER.CheckSum),
        },
        "version_resource": collect_version_info(pe),
        "imports": imports,
        "delay_imports": delay_imports,
        "exports": exports,
        "imported_dlls": imported_dlls,
        "api_set_imports": api_set_imports,
        "debug_records": collect_debug(pe),
        "signature": {
            "security_directory_offset": int(security.VirtualAddress),
            "security_directory_size": int(security.Size),
            "embedded_authenticode_present": bool(security.Size),
            "catalog_membership": "not-verified",
        },
        "sections": sections,
        "reference_comparison": compare_with_reference(imports + delay_imports, reference_dir) if reference_dir else None,
    }
    pe.close()
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--summary", type=pathlib.Path)
    parser.add_argument("--reference-dir", type=pathlib.Path)
    parser.add_argument("--expected-sha256")
    args = parser.parse_args()

    if not args.input.is_file():
        parser.error(f"Input file does not exist: {args.input}")
    if args.reference_dir and not args.reference_dir.is_dir():
        parser.error(f"Reference directory does not exist: {args.reference_dir}")

    actual_hash = sha256_file(args.input)
    if args.expected_sha256 and actual_hash.casefold() != args.expected_sha256.casefold():
        raise SystemExit(
            f"SHA-256 mismatch for {args.input}: expected "
            f"{args.expected_sha256.lower()}, got {actual_hash}"
        )

    result = audit(args.input, args.reference_dir)
    encoded = json.dumps(result, indent=2, sort_keys=True)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n", encoding="utf-8")
    else:
        print(encoded)

    if args.summary:
        imports = result["imports"]
        delay = result["delay_imports"]
        lines = [
            f"# Static PE audit: {args.input.name}",
            "",
            f"- SHA-256: {result['hashes']['sha256']}",
            f"- Machine: {result['pe']['machine_name']}",
            f"- PE timestamp: {result['pe']['timestamp_hex']}",
            f"- SizeOfImage: {result['pe']['size_of_image']}",
            f"- Version resource: {json.dumps(result['version_resource'], sort_keys=True)}",
            f"- Import descriptors: {len(imports)}",
            f"- Imported symbols: {sum(x['count'] for x in imports)}",
            f"- Delay-import descriptors: {len(delay)}",
            f"- Delay-imported symbols: {sum(x['count'] for x in delay)}",
            f"- Exported symbols: {len(result['exports'])}",
            f"- API-set imports: {len(result['api_set_imports'])}",
            f"- Embedded Authenticode directory: {result['signature']['embedded_authenticode_present']}",
            "- Catalog membership: not verified",
            "",
            "## Imported DLLs",
        ]
        lines.extend(f"- {name}" for name in result["imported_dlls"])
        lines.extend(["", "## Scope", result["analysis_scope"]])
        args.summary.parent.mkdir(parents=True, exist_ok=True)
        args.summary.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        f"PE audit complete: {args.input.name}; "
        f"SHA-256={result['hashes']['sha256']}; "
        f"imports={sum(x['count'] for x in result['imports'])}; "
        f"delay={sum(x['count'] for x in result['delay_imports'])}; "
        f"exports={len(result['exports'])}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
