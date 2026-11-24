#!/usr/bin/env python3
"""Fetch exact captured Win10 A2DP binaries and Server 2022 reference exports.

Downloads are read-only and originate from Winbindex metadata and Microsoft's
public symbol server. No driver is installed or loaded. A symbol-server
response is treated as the captured file only when its SHA-256 and size match
the independently recorded archive identity.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

from winbindex import WinbindexClient

WIN10_BINARIES = (
    {
        "role": "win10-driverstore-btha2dp",
        "filename": "btha2dp.sys",
        "expected_sha256": "5fba5ee606aac39d9cbda51c0a14dbabbb3a9b47bbd8ac5485ed137b4f354ec3",
        "expected_version": "10.0.19041.4355",
        "expected_size": 282624,
        "purpose": "Captured DriverStore package copy; priority compatibility target",
    },
    {
        "role": "win10-system32-btha2dp-secondary",
        "filename": "btha2dp.sys",
        "expected_sha256": "0442a18bbed4e323265c66561c8f8c171d8e934e9089c12b94d1dfdbb057b737",
        "expected_version": "10.0.19041.1",
        "expected_size": 279040,
        "purpose": "Separate older System32 copy; never merge its imports with DriverStore copy",
    },
    {
        "role": "win10-btampm",
        "filename": "btampm.sys",
        "expected_sha256": "da5cbbdce6ac511ef8400e121df6b6eaca7d05c0f40a01f7353ce9f220eb3dcd",
        "expected_version": "10.0.19041.5848",
        "expected_size": 43008,
        "purpose": "BtaMPM profile-management dependency",
    },
)

# Static imports established for the captured package: ntoskrnl.exe from
# BthA2dp.sys; ntoskrnl.exe, cng.sys and WppRecorder.sys from BtaMPM.sys.
# The additional Bluetooth/KS files are runtime/INF context, not asserted PE imports.
SERVER_REFERENCE_FILES = (
    "ntoskrnl.exe",
    "cng.sys",
    "WppRecorder.sys",
    "bthport.sys",
    "bthenum.sys",
    "bthusb.sys",
    "bthmini.sys",
    "ks.sys",
    "portcls.sys",
)

SERVER_BUILD = (10, 0, 20348)
SERVER_UBR_CEILING = 5761
SERVER_RELEASE_CUTOFF = "2026-10-13"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def release_to_dict(release: Any) -> dict[str, Any]:
    return {
        "windows_version": release.windows_version,
        "update": release.update,
        "release_date": release.release_date,
        "source_paths": list(release.source_paths),
        "assemblies": release.assemblies,
        "update_info": release.update_info,
        "windows_version_info": release.windows_version_info,
    }


def entry_to_dict(entry: Any) -> dict[str, Any]:
    info = entry.file_info
    try:
        binary_url = entry.binary_url() if entry.has_binary_download else None
    except Exception as exc:
        binary_url = None
        url_error = str(exc)
    else:
        url_error = None

    return {
        "filename": entry.filename,
        "sha256": entry.sha256,
        "version": info.version,
        "machine_type": info.machine_type,
        "machine": info.machine_name,
        "size": info.size,
        "timestamp": info.timestamp,
        "virtual_size": info.virtual_size,
        "signed": info.is_signed,
        "signing_status": info.signing_status,
        "signature_type": info.signature_type,
        "signing_date": list(info.signing_date or ()),
        "windows_versions": sorted(entry.windows_versions),
        "updates": sorted(entry.updates),
        "releases": [release_to_dict(item) for item in entry.releases],
        "binary_url": binary_url,
        "binary_url_error": url_error,
        "raw_file_info": info.raw,
    }


def download_entry(client: WinbindexClient, entry: Any, destination: Path) -> dict[str, Any]:
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        downloaded_path = client.download_binary(entry, destination, overwrite=True)
        actual_hash = sha256_file(downloaded_path)
        return {
            "status": "downloaded",
            "path": str(downloaded_path),
            "size": downloaded_path.stat().st_size,
            "downloaded_sha256": actual_hash,
            "matches_winbindex_sha256": actual_hash == entry.sha256.lower(),
            "error": None,
        }
    except Exception as exc:
        return {
            "status": "download_failed",
            "path": None,
            "size": None,
            "downloaded_sha256": None,
            "matches_winbindex_sha256": False,
            "error": f"{type(exc).__name__}: {exc}",
        }


def fetch_exact_win10(client: WinbindexClient, item: dict[str, Any], out_dir: Path) -> dict[str, Any]:
    result: dict[str, Any] = {
        **item,
        "indexed_entry": None,
        "download": None,
        "identity_verified": False,
        "audit": None,
    }
    try:
        matches = list(client.find(item["filename"], sha256=item["expected_sha256"], machine_type=0x8664))
    except Exception as exc:
        result["status"] = "index_query_failed"
        result["error"] = f"{type(exc).__name__}: {exc}"
        return result

    if len(matches) != 1:
        result["status"] = "expected_hash_match_count"
        result["match_count"] = len(matches)
        result["candidates"] = [entry_to_dict(entry) for entry in matches]
        return result

    entry = matches[0]
    result["indexed_entry"] = entry_to_dict(entry)
    safe_role = re.sub(r"[^a-z0-9-]+", "-", item["role"].lower())
    destination = out_dir / "win10" / safe_role / item["filename"]
    result["download"] = download_entry(client, entry, destination)

    download = result["download"]
    indexed_version_matches = entry.version == item["expected_version"]
    result["indexed_version_matches_expected"] = indexed_version_matches
    result["identity_verified"] = (
        download["status"] == "downloaded"
        and download["downloaded_sha256"] == item["expected_sha256"]
        and download["size"] == item["expected_size"]
    )
    if result["identity_verified"] and indexed_version_matches:
        result["status"] = "exact_hash_size_and_version_match"
    elif result["identity_verified"]:
        result["status"] = "exact_hash_and_size_match_version_label_differs"
    elif download["status"] == "downloaded":
        result["status"] = "symbol_server_bytes_do_not_match_capture"
    else:
        result["status"] = "symbol_server_download_unavailable"
    return result


def server_candidates(entries: list[Any]) -> list[Any]:
    candidates: list[tuple[tuple[int, ...], str, Any]] = []
    for entry in entries:
        if entry.file_info.machine_type != 0x8664:
            continue
        version = tuple(entry.version_tuple or ())
        if len(version) < 4 or version[:3] != SERVER_BUILD or version[3] > SERVER_UBR_CEILING:
            continue
        eligible_releases = [
            release
            for release in entry.releases
            if not release.release_date or release.release_date <= SERVER_RELEASE_CUTOFF
        ]
        if not eligible_releases:
            continue
        server_releases = [
            release
            for release in eligible_releases
            if "server" in release.windows_version.lower()
            or "2022" in release.windows_version.lower()
        ]
        if server_releases:
            eligible_releases = server_releases
        latest_date = max((release.release_date or "") for release in eligible_releases)
        candidates.append((version, latest_date, entry))

    if not candidates:
        return []

    best_version = max(item[0] for item in candidates)
    candidates = [item for item in candidates if item[0] == best_version]
    best_date = max(item[1] for item in candidates)
    candidates = [item for item in candidates if item[1] == best_date]
    return [item[2] for item in candidates]


def fetch_server_reference(client: WinbindexClient, filename: str, out_dir: Path) -> dict[str, Any]:
    result: dict[str, Any] = {
        "filename": filename,
        "target_os": "Windows Server 2022",
        "target_build": "20348.5761",
        "selected_entry": None,
        "candidates": [],
        "download": None,
        "usable_as_reference": False,
    }
    try:
        entries = client.get_file(filename)
    except Exception as exc:
        result["status"] = "index_query_failed"
        result["error"] = f"{type(exc).__name__}: {exc}"
        return result

    candidates = server_candidates(entries)
    result["candidates"] = [entry_to_dict(entry) for entry in candidates]
    if len(candidates) == 0:
        result["status"] = "no_matching_server_build_entry"
        result["note"] = (
            "No x64 10.0.20348.* entry at or below UBR 5761 was found in "
            "indexed releases dated on or before 2026-10-13."
        )
        return result

    if len(candidates) > 1:
        result["status"] = "ambiguous_server_build_entries"
        result["note"] = "Multiple equally ranked hashes remain; no reference binary was selected."
        return result

    entry = candidates[0]
    result["selected_entry"] = entry_to_dict(entry)
    safe_name = re.sub(r"[^a-z0-9.-]+", "-", filename.lower())
    destination = out_dir / "server2022" / "references" / safe_name
    result["download"] = download_entry(client, entry, destination)

    download = result["download"]
    result["usable_as_reference"] = (
        download["status"] == "downloaded"
        and download["downloaded_sha256"] == entry.sha256.lower()
    )
    if result["usable_as_reference"]:
        result["status"] = "downloaded_and_hash_verified"
    elif download["status"] == "downloaded":
        result["status"] = "symbol_server_hash_mismatch"
    else:
        result["status"] = "symbol_server_download_unavailable"
    return result


def run_pe_audit(
    script: Path,
    role: str,
    binary: Path,
    out_dir: Path,
    reference_dir: Path,
) -> dict[str, Any]:
    out_json = out_dir / "pe-audit" / f"{role}.json"
    out_summary = out_dir / "pe-audit" / f"{role}.md"
    out_json.parent.mkdir(parents=True, exist_ok=True)
    command = [
        sys.executable,
        str(script),
        "--input",
        str(binary),
        "--output",
        str(out_json),
        "--summary",
        str(out_summary),
    ]
    if reference_dir.is_dir():
        command.extend(["--reference-dir", str(reference_dir)])
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    return {
        "command": command,
        "return_code": completed.returncode,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
        "json_path": str(out_json) if out_json.exists() else None,
        "summary_path": str(out_summary) if out_summary.exists() else None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=Path("build/win10-a2dp-symbol-audit"))
    args = parser.parse_args()

    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    cache_dir = out_dir / "winbindex-cache"
    manifest: dict[str, Any] = {
        "target": {
            "win10_reference": "Windows 10 22H2 / build 19045",
            "server_reference": "Windows Server 2022 / build 20348.5761",
            "server_release_cutoff": SERVER_RELEASE_CUTOFF,
            "architecture": "x64",
        },
        "sources": {
            "metadata": "https://winbindex.m417z.com/data",
            "binary_downloads": "https://msdl.microsoft.com/download/symbols",
            "metadata_client": "winbindex Python client 3.0.0",
        },
        "win10_binaries": [],
        "server_references": [],
        "pe_audits": [],
        "limitations": [
            "Winbindex metadata is a third-party index; downloaded binary bytes come from Microsoft's public symbol server.",
            "A symbol-server response is treated as the captured file only when its computed SHA-256, size and indexed version match the archived identity.",
            "Winbindex signature metadata is not a substitute for verifying the original system catalog or catalog membership.",
            "This pass does not obtain WIM/ESD, MUM, manifest or CAT files; CBS package ownership remains a separate gate.",
            "The PE parser performs static import/export inspection; forwarded exports, API-set host resolution and dynamic LoadLibrary/GetProcAddress paths require separate validation.",
            "Server references are reconstructed from Winbindex release metadata up to the 20348.5761 cutoff; they are not a fresh read of the physical host.",
        ],
    }

    with WinbindexClient(cache_dir=cache_dir, cache_ttl=24 * 3600, timeout=45.0) as client:
        for item in WIN10_BINARIES:
            manifest["win10_binaries"].append(fetch_exact_win10(client, item, out_dir))
        for filename in SERVER_REFERENCE_FILES:
            manifest["server_references"].append(fetch_server_reference(client, filename, out_dir))

    reference_dir = out_dir / "server2022" / "references"
    reference_dir.mkdir(parents=True, exist_ok=True)
    parser_script = Path(__file__).with_name("audit_pe_binary.py")
    if not parser_script.is_file():
        raise SystemExit(f"PE audit script is missing: {parser_script}")

    for item in manifest["win10_binaries"]:
        download = item.get("download") or {}
        if download.get("status") != "downloaded" or not download.get("path"):
            continue
        binary = Path(download["path"])
        if not binary.is_file():
            continue
        audit_result = run_pe_audit(parser_script, item["role"], binary, out_dir, reference_dir)
        item["audit"] = audit_result
        manifest["pe_audits"].append(
            {
                "role": item["role"],
                "binary": str(binary),
                "identity_verified": item["identity_verified"],
                **audit_result,
            }
        )

    manifest_path = out_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines = [
        "# Windows 10 A2DP / Server 2022 static binary audit",
        "",
        f"- Target: {manifest['target']['server_reference']}",
        f"- Win10 reference: {manifest['target']['win10_reference']}",
        f"- Server release cutoff: {manifest['target']['server_release_cutoff']}",
        "- No driver was installed or loaded; no physical host was accessed.",
        "",
        "## Captured Windows 10 binaries",
        "",
        "| Role | Expected SHA-256 | Download SHA-256 | Exact identity | Status |",
        "|---|---|---|---|---|",
    ]
    for item in manifest["win10_binaries"]:
        download = item.get("download") or {}
        lines.append(
            f"| {item['role']} | {item['expected_sha256']} | "
            f"{download.get('downloaded_sha256') or '—'} | "
            f"{'yes' if item.get('identity_verified') else 'no'} | {item.get('status', 'unknown')} |"
        )

    lines.extend(
        [
            "",
            "## Server 2022 reference candidates",
            "",
            "| File | Selected version | SHA-256 verified | Status |",
            "|---|---|---|---|",
        ]
    )
    for item in manifest["server_references"]:
        selected = item.get("selected_entry") or {}
        lines.append(
            f"| {item['filename']} | {selected.get('version') or '—'} | "
            f"{'yes' if item.get('usable_as_reference') else 'no'} | {item.get('status', 'unknown')} |"
        )

    lines.extend(
        [
            "",
            "## PE audit runs",
            "",
            "| Role | Return code | Exact captured identity | JSON |",
            "|---|---:|---|---|",
        ]
    )
    for item in manifest["pe_audits"]:
        lines.append(
            f"| {item['role']} | {item['return_code']} | "
            f"{'yes' if item['identity_verified'] else 'no'} | {item.get('json_path') or '—'} |"
        )

    lines.extend(
        [
            "",
            "## Interpretation limits",
            "",
            *[f"- {item}" for item in manifest["limitations"]],
            "",
            "Full Winbindex release, update and assembly metadata is preserved in manifest.json.",
        ]
    )
    (out_dir / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Manifest: {manifest_path}")
    print(f"Summary: {out_dir / 'README.md'}")
    print(
        "Exact Win10 binary identities: "
        f"{sum(1 for item in manifest['win10_binaries'] if item.get('identity_verified'))}/"
        f"{len(manifest['win10_binaries'])}"
    )
    print(
        "Hash-verified Server references: "
        f"{sum(1 for item in manifest['server_references'] if item.get('usable_as_reference'))}/"
        f"{len(manifest['server_references'])}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
