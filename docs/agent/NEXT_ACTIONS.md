# NEXT_ACTIONS — live executable queue (2026-11-25 17:26 UTC)

## Mission / invariant
WinServer 2022 20348: OPPO Enco Buds2 + Intel, A2DP Source/SBC 0x110B **and** HFP AG 0x111E render+capture from the **same headset**, confirmed two-way real messenger call, reconnect and stereo recovery, Win10 control, second headset/controller. Hardware acceptance **UNTESTED**. Chat only; no Codex/Work, paid runner, physical Server change, test-signing, Secure Boot/integrity weakening or publication of Microsoft binaries.

## VERIFIED — do not repeat
- Exact HFP 3 Win10 donor PE variants vs hosted Server 20348.5866 + companion BtaMPM: **229/229** imports resolve by name, 11/11 tests. [Report](../../research/native-inf-preflight-20261124/HFP-SERVER20348-EXPORT-CLOSURE-20261125.md), commit `892c877`. Static name closure only, not ABI/load.
- SysVAD unmodified code base plus isolated checkout INF fix: compile, link and 3/3 x64 InfVerif **SUCCESS** [CI 45659496556](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45659496556); x86 ApiValidator build task bypassed on runner, no signed/loaded endpoint. SysVAD HFP sideband assumes missing provider.
- [Read-only HFP signature CI 45663727116](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45663727116), branch `research/hfp-inf-cat-gate-20261125`, commit `d736e25`: hosted Server **20348.5870** has **NO** original `microsoft_bluetooth_hfp.inf` in INF or DriverStore, NO HFP services / HFP SYS / BTHHFENUM child. 13/13 INF parser controls passed. Positive-control `BthPort.sys` Microsoft signature Valid and `SignTool /kp /a` exit 0; this does NOT validate Win10 donor CAT. Artifact `15046132226` ZIP SHA256 `3982d95b576707b9b8a8e5dbb0956d14ebb344acc89c28b9b0c0857bcb0c2ec7`.
- [Follow-up CI 45664199748](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45664199748) **SUCCESS** (commit `e68ae127`), validates donor collector PowerShell syntax and **rejection on Server 2022**; ZIP SHA256 `3f4f98b1f043d1199b775ba761419d22769f9c82a34406d436e8321e591ca074`. Script is **NOT YET RUN on Win10**.
- Microsoft [Driver Signing Options](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/driver-signing-offerings): Server 2016+ requires HLK-passed dashboard signing for new server device/filter drivers; desktop attestation cannot be assumed to work. Original Win10 HFP CAT trust/INF applicability to Server unknown. [Inf2Cat Server2022 target](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/inf2cat) = `ServerFE_X64`.
- Full [HFP signing gate report](https://github.com/as-0101/ldac-a2dp-windows/blob/research/hfp-inf-cat-gate-20261125/research/native-inf-preflight-20261124/HFP-INF-CAT-SIGNING-GATE-20261125.md); metadata archive retained in `/LDAC Project/Artifacts/HFP-INF-CAT-20261125`.

## P0 — PRIMARY: restore native Windows 10 Bluetooth Audio on Server 2022 (user decision 2026-11-26)
Goal: deliver a real local installable `Bluetooth-Server2022-x64` package, not another inventory or a fictional device-clearing INF. Preserve original Microsoft SYS bytes unless a specific incompatibility is proved. Reuse the existing Server Bluetooth/audio infrastructure; independent WDM/SysVAD/OpenA2DP is fallback, not the main track.
 
Target layout (logical groups; actual INF package boundaries follow verified dependencies):
```
Bluetooth-Server2022-x64/
  01-BtaMPM/
  02-A2DP/
  03-HFP/
  04-AVRCP/
  05-AudioServices/
  Install.ps1
  Uninstall.ps1
```
Each driver package contains authorized original SYS, adapted INF, and corresponding CAT; user-mode services have their actual DLL/service registration requirements, not artificial SYS/CAT. Do not redistribute Microsoft binaries publicly: assemble locally from authorized donor media. Provide source/templates, manifest, exact donor hashes, dependency order, validation and rollback scripts.
 
Execution order:
1. BtaMPM first: recover original INF and exact SYS from existing donor evidence; inspect complete Version/Manufacturer/model decorations, Include/Needs/AddService/CopyFiles and catalog requirements. Produce smallest justified Server-applicable INF candidate; keep real device matching and service configuration. No unchanged retries of 0xE000022F.
2. A2DP: adapt common/source INF and preserve dependencies; match real headset 0x110B hardware/compatible IDs. Do not bind a fake INF to suppress warnings. Obtain read-only hardware IDs for unresolved nodes if required.
3. Validate INF with InfVerif; generate matching catalog using WDK Inf2Cat /driver:<package-folder> /os:ServerFE_X64 /verbose; distinguish generation from signing. User is installing WDK 10.0.28000.3231; tool presence and supported target still unverified. Existing 26100 tooling is an alternative. No Visual Studio required solely for INF/CAT tools.
4. Signing is an engineering gate, not grounds to abandon the native approach. Separately verify original SYS signatures/catalog membership, new package catalog validity and Server kernel policy with SignTool; use authorized trusted signing, no disabling integrity or reusing third-party private keys. User supplied MultiKey files and reported existing signed third-party driver running without TESTSIGNING: anecdotal control only; static certificate metadata may be examined for legitimate compatibility, not licensing emulation or security bypass. Do not infer new driver trust from old driver's acceptance.
5. On authorized disposable Server 2022 only, test PnPUtil staging, actual binding and service start, inspect SetupAPI.dev.log and CodeIntegrity logs, WinDbg if necessary. Record exact exit codes, package hashes, endpoint evidence; rollback. No physical-server changes by agent. Gate CI on previously established free storage/budget restrictions; local user may run explicitly authorized read-only validation.
6. Obtain full original HFP INF/CAT/SYS and user-mode dependencies, then repeat for HFP, AVRCP and AudioServices. Existing HFP collector remains useful; no unchanged UUP acquisition retries. Unknown vendor-specific oppointeraction requires identification, not blind binding.
7. Deliver validated local package and one-line install/rollback instructions; label unverified gates. Final hardware acceptance remains as above.
 
Next concrete deliverable: BtaMPM INF candidate and minimal reproducible InfVerif/Inf2Cat local test, derived from actual original INF evidence (not guessed directives). If donor bytes/INF inaccessible, obtain exact missing input via read-only donor collection and advance any available independent native-package validation. Do not spend cycles repeating known static import results.
 
## P1 — HFP donor evidence / independent fallback
1. Obtain ORIGINAL, complete authorized Win10 HFP package `microsoft_bluetooth_hfp.inf`, its matching CAT and referenced `BthHfEnum.sys`/`BthHfAud.sys` (two BthHfEnum SHA variants exist). Archive from HFP donor CI 45612001590 contains **only three PE JSONs + manifest**, NOT INF/CAT; newer donor UUP repeatedly HTTP 504. Do **not** rerun identical UUP acquisition.
2. Ready read-only collector: [collect_win10_hfp_inf_cat_evidence.ps1](https://github.com/as-0101/ldac-a2dp-windows/blob/research/hfp-inf-cat-gate-20261125/tools/stand/collect_win10_hfp_inf_cat_evidence.ps1). It emits metadata only; requires a **Win10 1904x client** or complete offline source for other audit tools. Do not run on physical Server.
3. When real full package arrives: verify exact INF Sections/Include/Needs/AddService/CopyFiles and CATALOG membership **per file**, on disposable Server: `InfVerif`, `SignTool verify /kp /v /c <actual-cat> <actual-sys>`, `Inf2Cat /nocat /os:ServerFE_X64` (signability, **not** signature), registry/service provider inventory. Only a trusted *authentic* complete package can advance to safe isolated staging/loading. No stage test with missing CAT.
4. If original HFP INF/CAT remains inaccessible, advance **independent RFCOMM HFP AG and SCO/eSCO capture design/test** using official documented Bluetooth interfaces and license-compatible code; keep signing/HLK as separate runtime gate. OpenA2DP existing render-only preflight lives [here](https://github.com/as-0101/ldac-a2dp-windows/blob/research/wdm-profile-reengineering/research/wdm-portcls/OPEN_A2DP_COMPARISON.md).

## Execution discipline
Every cycle: GitHub fetch START_HERE and this file; prioritize the native package P0 above; inspect relevant existing evidence; perform a concrete independent safe test/commit and record exact blocker if no viable next action. Never claim a loaded audio driver from static imports, INF parsing, a valid signature on a different file, or successful CI build. The hourly timer being enabled is not proof of execution. PowerShell user commands **one line**.

Historical queue for provenance: [archive snapshot](../../docs/agent/history/2026-11-25-pre-hfp-signing-queue.md).


## Read-only cycle — 2026-11-25, storage conservation
- Re-read primary job logs: SysVAD job 139365168776 (run 45659496556) built EndpointsCommon before sample; standalone x64 InfVerif succeeded. Build used SignMode=Off, SkipPackageVerification=true, ApiValidator_Enable=false, RunApiValidator=false; no signed install or runtime proof. Metadata ZIP digest in log: 2dc0a0aa8f16fcb5773e46dcea55374ebb14c55babe9d221c77f22fc3aed203f.
- HFP job 139381783586 (run 45664199748): parse and Server guard passed; Server 20348.5870 HFP INF absent, packages=0, catalog_membership=UNTESTED, load=NOT_ATTEMPTED; artifact 15045324530 (2912 bytes). This does not validate actual Win10 donor.
- Independent documented transport boundary: Winsock AF_BTH/SOCK_STREAM/BTHPROTO_RFCOMM provides control channel, not SCO audio (https://learn.microsoft.com/en-us/windows/win32/bluetooth/bluetooth-and-socket). bind does not advertise SDP; WSASetService needed if local server role is used (https://learn.microsoft.com/en-us/windows/win32/bluetooth/bluetooth-and-bind). Kernel profile driver can query SCO capability with BRB_SCO_GET_SYSTEM_INFO before opening channels; transfer requires BthPort BRBs (https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/creating-a-sco-client-connection-to-a-remote-device). Availability on Server hardware remains UNTESTED.
- Missing referenced tools/stand/headset-endpoints.ps1: fetch_file returned HTTP 404 on main, docs/project-source-reorg and research/wdm-profile-reengineering. Locate replacement or implement read-only identity probe before hardware acceptance; do not claim prior tool verified.
- Next: offline verify collector source and endpoint identity metadata, obtain authentic Win10 INF/CAT evidence, then separately validate RFCOMM and SCO capability when quota and authorized test hardware permit. No new CI, no deletion, no production changes. Strict storage conservation: one-day retention for future temporary artifacts; budget $0.
