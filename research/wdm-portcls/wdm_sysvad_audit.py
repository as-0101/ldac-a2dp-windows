"""Read-only source applicability gate for pinned Microsoft SysVAD. No drivers installed."""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

UPSTREAM_SHA = "d49bb7d72f3651952b2b6e4ad28d14fe2247eb69"
PATHS = {
    "inf": "audio/sysvad/TabletAudioSample/ComponentizedAudioSample.inx",
    "project": "audio/sysvad/TabletAudioSample/TabletAudioSample.vcxproj",
    "hfp": "audio/sysvad/BthhfpDevice.cpp",
    "a2dp": "audio/sysvad/A2dpHpDevice.cpp",
    "pairs": "audio/sysvad/EndpointsCommon/bthhfpminipairs.h",
}

def scan(root: Path) -> dict:
    texts = {k: (root / rel).read_text(encoding="utf-8-sig") for k, rel in PATHS.items()}
    inf = "\n".join(l.split(";", 1)[0].strip() for l in texts["inf"].splitlines())
    project = texts["project"]
    hfp = texts["hfp"]
    a2dp = texts["a2dp"]
    pairs = texts["pairs"]
    checks = {
        "inf_ks_wdmaudio": bool(re.search(r"(?mi)^Include\s*=\s*ks\.inf\s*,\s*wdmaudio\.inf\s*$", inf)),
        "inf_needs_registrations": bool(re.search(r"(?mi)^Needs\s*=\s*KS\.Registration\s*,\s*WDMAUDIO\.Registration\s*$", inf)),
        "inf_hfp_render": bool(re.search(r"(?mi)^AddInterface\s*=\s*%KSCATEGORY_RENDER%\s*,\s*%KSNAME_WaveBthHfpSpeaker%", inf)),
        "inf_hfp_capture": bool(re.search(r"(?mi)^AddInterface\s*=\s*%KSCATEGORY_CAPTURE%\s*,\s*%KSNAME_WaveBthHfpMic%", inf)),
        "project_portcls_wdm_target": "WindowsKernelModeDriver10.0" in project and "<TargetVersion>Windows10</TargetVersion>" in project,
        "project_hfp_bypass_enabled": "SYSVAD_BTH_BYPASS" in project,
        "hfp_sideband_ioctl_dependency": "#include <bthhfpddi.h>" in hfp and "IOCTL_BTHHFP_" in hfp,
        "a2dp_sideband_guard": "#ifdef SYSVAD_A2DP_SIDEBAND" in a2dp,
        "hfp_separate_minipairs": "BthHfpSpeakerMiniports" in pairs and "BthHfpMicMiniports" in pairs,
    }
    return {
        "source_repo": "microsoft/Windows-driver-samples", "source_commit": UPSTREAM_SHA,
        "license": "MS-PL (verify LICENSE before redistributing derivative source)",
        "checks": checks, "passed": all(checks.values()),
        "source_file_sha256": {k: hashlib.sha256((root / PATHS[k]).read_bytes()).hexdigest() for k in PATHS},
        "limitations": ["Not a kernel-mode build, signed install, loaded audio endpoint, Bluetooth protocol implementation or duplex call proof",
                        "SYSVAD HFP bypass relies on pre-existing BthHfp sideband provider; this code is not an HFP AG replacement",
                        "A2DP sideband guard does not by itself implement AVDTP/SBC source"],
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = scan(args.root)
    except (OSError, UnicodeError) as exc:
        result = {"passed": False, "error": str(exc)}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"passed": result["passed"], "checks": result.get("checks", {}), "error": result.get("error")}))
    raise SystemExit(0 if result["passed"] else 1)

if __name__ == "__main__":
    main()
