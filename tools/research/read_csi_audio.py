"""Read installed CSI manifests and report matches and coverage on a disposable VM."""
import collections
import ctypes
import hashlib
import json
import os
from pathlib import Path
import runpy
import sys
import xml.etree.ElementTree as ET

decode = runpy.run_path("decoder/src/decode-dcm-manifest.py")["apply_delta_b"]
windows = Path(os.environ["WINDIR"])
dll = ctypes.WinDLL(str(windows / "System32/msdelta.dll"))
dictionary = Path(sys.argv[1]).read_bytes()
print("DICTIONARY", len(dictionary), hashlib.sha256(dictionary).hexdigest())
needles = ("btha2dp", "btampm", "microsoft_bluetooth_a2dp", "bluetooth-audio-a2dp")
coverage = collections.Counter()
errors = collections.Counter()
samples = []
deployment = []
hits = []
def names(root):
    return [e.get("name", "") for e in root.iter() if e.tag.rsplit("}",1)[-1] == "assemblyIdentity"]
for p in sorted((windows / "WinSxS/Manifests").glob("*.manifest")):
    coverage["total"] += 1
    try:
        raw = p.read_bytes()
        if raw[:4] == b"DCM\x01":
            ok, error, raw = decode(dll, dictionary, raw[4:])
            if not ok:
                raise ValueError("ApplyDeltaB error " + str(error))
            coverage["dcm_decoded"] += 1
        tree = ET.fromstring(raw)
        ids = names(tree)
        rootname = tree.find("{*}assemblyIdentity")
        rootname = rootname.get("name","") if rootname is not None else ""
        if rootname.casefold() == "microsoft-onecore-bluetooth-deployment":
            deployment.append({"manifest": p.name, "references":ids})
        values = (s.casefold() for e in tree.iter() for s in (*e.attrib.values(),e.text or ""))
        found = set()
        for s in values:
            found.update(t for t in needles if t in s)
        if found:
            hits.append({"manifest":p.name,"markers":sorted(found)})
        coverage["xml_parsed"] += 1
    except (OSError, ValueError, ET.ParseError) as exc:
        errors[str(exc).split(": line")[0]] += 1
        if len(samples) < 4:
            samples.append((p.name,str(exc)))
print("COVERAGE",json.dumps(coverage))
print("ERRORS",json.dumps(errors.most_common(10)),json.dumps(samples))
for d in deployment:
    print("DEPLOYMENT",json.dumps(d))
print("HITS",json.dumps(hits))
if not deployment or not coverage["dcm_decoded"]:
    raise SystemExit("Positive deployment/decoder control missing")
