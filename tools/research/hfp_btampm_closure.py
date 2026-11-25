"""Evidence-only comparison of two previously archived CI metadata ZIPs.

No Microsoft binaries are copied, downloaded, executed or published. This checks
only exported and imported PE symbol names, *not* kernel runtime compatibility.
"""
import argparse
import hashlib
import io
import json
import zipfile

HFP_RUN = 45612001590
HFP_ARTIFACT = 15023735500
A2DP_RUN = 45511693396
EXPECTED_BTA_SHA256 = "da5cbbdce6ac511ef8400e121df6b6eaca7d05c0f40a01f7353ce9f220eb3dcd"


def names_for_closure(hfp_imports, bta_exports):
    exports = {e["name"] for e in bta_exports if e.get("name") and not e.get("forwarder")}
    return sorted(set(hfp_imports) - exports)


def build_report(hfp_zip, a2dp_zip):
    hfp_sha = hashlib.sha256(hfp_zip).hexdigest()
    a2dp_sha = hashlib.sha256(a2dp_zip).hexdigest()
    with zipfile.ZipFile(io.BytesIO(hfp_zip)) as h, zipfile.ZipFile(io.BytesIO(a2dp_zip)) as a:
        nested_names = [p for p in a.namelist() if p.endswith("CI-6-dependency-first.zip")]
        if len(nested_names) != 1:
            raise ValueError("Expected exactly one nested CI6 ZIP")
        with zipfile.ZipFile(io.BytesIO(a.read(nested_names[0]))) as n:
            bta_reports = [p for p in n.namelist() if p.endswith("win10-BtaMPM.sys-DA5CBBDCE6AC.json")]
            if len(bta_reports) != 1:
                raise ValueError("Pinned BtaMPM report absent or ambiguous")
            bta = json.loads(n.read(bta_reports[0]))
        if bta.get("hashes", {}).get("sha256", "").lower() != EXPECTED_BTA_SHA256:
            raise ValueError("BtaMPM identity mismatch")
        hfp_reports = sorted(p for p in h.namelist() if p.startswith("hfp-pe/BthHfEnum.sys-") and p.endswith(".json"))
        if len(hfp_reports) != 2:
            raise ValueError("Expected two BthHfEnum versions")
        records = []
        for p in hfp_reports:
            j = json.loads(h.read(p))
            bta_imports = [i for i in j["imports"] if i["dll"].lower() == "btampm.sys"]
            if len(bta_imports) != 1:
                raise ValueError("BtaMPM import descriptor absent or ambiguous")
            if any(s.get("ordinal") is not None for s in bta_imports[0]["symbols"]):
                raise ValueError("Ordinal-based imports require additional matching")
            names = [s["name"] for s in bta_imports[0]["symbols"]]
            missing = names_for_closure(names, bta["exports"])
            records.append({"report_file": p, "driver_sha256": j["hashes"]["sha256"],
                            "size_bytes": j["size_bytes"], "btampm_imports_count": len(names),
                            "missing_export_names": missing, "imported_names": sorted(names),
                            "closure_by_name": not missing})
    return {"scope": "Static name-only PE import/export closure; no CAT/staging/binding/driver load",
            "hfp_run_id": HFP_RUN, "hfp_artifact_id": HFP_ARTIFACT,
            "hfp_artifact_zip_sha256": hfp_sha, "a2dp_archive_zip_sha256": a2dp_sha,
            "bta_driver_sha256": bta["hashes"]["sha256"], "bta_export_count": len(bta["exports"]),
            "enum_versions": records, "all_7_imports_resolve": all(x["closure_by_name"] and x["btampm_imports_count"] == 7 for x in records)}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--hfp", required=True)
    p.add_argument("--a2dp", required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()
    with open(args.hfp, "rb") as f: hf = f.read()
    with open(args.a2dp, "rb") as f: ad = f.read()
    result = build_report(hf, ad)
    with open(args.output, "w", encoding="utf8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(json.dumps({"closure":result["all_7_imports_resolve"], "exports":result["bta_export_count"], "enum_versions":len(result["enum_versions"])}))
    return 0 if result["all_7_imports_resolve"] else 1


if __name__ == "__main__":
    raise SystemExit(main())