"""Static direct import resolution with explicit forwarder handling, no module load."""
import hashlib, json, os, platform, sys
from pathlib import Path
import pefile
spec=json.loads(Path(__file__).with_name("donor-symbols.json").read_text())
system=Path(os.environ["SystemRoot"])/"System32"
cache={}
donor=next(v for k,v in spec.items() if "BtaMPM.sys-" in k)
def index(items):
    table={}
    for name,ordinal,target in items:
        table["#"+str(ordinal)]=target
        if name: table[name]=target
    return table
cache["btampm.sys"]=index((s["name"],s["ordinal"],s["forwarder"]) for s in donor["exports"])
def table(module):
    if module in cache:return cache[module]
    candidates=[system/module,system/"drivers"/module]
    p=next((p for p in candidates if p.is_file()),None)
    if not p: return {}
    with pefile.PE(str(p),fast_load=True) as pe:
        pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXPORT"]])
        syms=getattr(getattr(pe,"DIRECTORY_ENTRY_EXPORT",None),"symbols",[])
        exports=index((s.name.decode() if s.name else None,s.ordinal,s.forwarder.decode() if s.forwarder else None) for s in syms if s.address)
    cache[module]=exports
    print("PROVIDER",module,"exports",len(exports),"sha256",hashlib.sha256(p.read_bytes()).hexdigest())
    return exports
def resolve(module,name,seen):
    if (module,name) in seen:return "cycle"
    exports=table(module)
    if name not in exports:return "missing "+module+"!"+name
    target=exports[name]
    if not target:return "resolved"
    dest,sym=target.rsplit(".",1)
    aliases={"ntoskrnl":"ntoskrnl.exe","hal":"hal.dll"}
    dest=aliases.get(dest.lower(),dest.lower())
    if "." not in dest:dest+=".sys"
    return resolve(dest,sym,seen|{(module,name)})
print("TARGET",platform.version())
for filename,data in spec.items():
    if data["delay"]:raise ValueError("Unexpected delay imports")
    misses=[]
    for module,names in data["imports"].items():
        for name in names:
            result=resolve(module,name,set())
            if result!="resolved": misses.append([module,name,result])
    print("AUDIT",filename,"direct",sum(map(len,data["imports"].values())),"missing",json.dumps(misses))
if resolve("ntoskrnl.exe","A2dpAbsentControl_1319",set())=="resolved": raise ValueError("Negative control failed")
if resolve("ntoskrnl.exe","IoGetDeviceObjectPointer",set())!="resolved":raise ValueError("Positive control failed")
print("CONTROLS positive=pass negative=pass")
