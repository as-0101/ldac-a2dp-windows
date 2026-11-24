# Test matrix

Stages are cumulative but independently reported. Status values use CONFIRMED/SUPPORTED/HYPOTHESIS/REFUTED/UNTESTED/BLOCKED; environment tags are mandatory.

| ID | Stage | Exact build / environment | Expected | Actual | Status | Next |
|---|---|---|---|---|---|---|
| T-001 | Build | CI #133 / 45044497961, Server 2022 hosted runner, ACX 1.0 / Universal | Compile and package | All 3 jobs pass | CONFIRMED — BUILD_ONLY | No runtime inference |
| T-002 | Package integrity | CI #133 artifacts | Exact SYS/INF/CAT identity | ZIP inspected; SYS hash and INF DriverVer checked; SYS matches unsigned SYS byte-for-byte; PDB table analysis supports ACX 1.0 | CONFIRMED — STATIC_ANALYSIS | Retain hashes and PDB evidence |
| T-003 | ACX class version | Physical Server 2022 host, read-only WinDbg | Identify registered class module version | `!wdfldr Acx01000.sys` output recorded CLASS_MODULE v1.0 / WDF 1.31 | CONFIRMED — PHYSICAL_HARDWARE_TEST (diagnostic only) | Do not infer bind compatibility |
| T-004 | ACX class version | Hosted Server 2022 LiveKD run #15 / artifact 14768915976 | Independently query runtime | CLASS_MODULE v1.0 / WDF 1.31; runtime WDF 1.33 | CONFIRMED — VM_TEST | Preserve exact report |
| T-005 | ACX 1.0 bind/load | Hosted Server 2022 disposable runner, CI #248 / 45060225420, commit 3d1d5d7 | Driver reaches DriverEntry; no 0xC000000D | ACX service explicitly RUNNING; package installed to synthetic SWDDEVGEN device; PnP Code 37 / ProblemStatus 0xC000000D; Kernel-PnP Event 219; no loaded driver or DriverEntry output | REFUTED for candidate success — VM_TEST | Test official minimal AudioCodec-based ACX 1.0 client |
| T-006 | WDK stub descriptor | CI #255 / 45060819535, commit 085705a | Verify linked ACX version metadata | ACX 1.0 stub descriptor 1.0/210/62; ACX 1.1 1.1/221/62; CI #246 SYS parsed 1.0/210/62 | CONFIRMED — STATIC_ANALYSIS | Inspect runtime bind fields or isolate minimal sample |
| T-007 | PnP target match on real OPPO | Physical Server 2022 | Bind to exact OPPO A2DP node | Last snapshot one present A2DP node, oem75.inf, Code 37 | CONFIRMED — PHYSICAL_HARDWARE_TEST | Fresh read-only baseline before any test |
| T-008 | Bluetooth/L2CAP channels | Physical Server 2022 | Required AVDTP/L2CAP channels open/close | Not established by the above tests | UNTESTED | Only after driver start and endpoint |
| T-009 | ACX circuit | Physical/VM | ACX circuit created | Not reached; no DriverEntry in #248 | UNTESTED | After bind/load succeeds |
| T-010 | Audio endpoint | Physical/VM | Windows render endpoint appears | Not reached | UNTESTED | After ACX circuit |
| T-011 | Codec negotiation | Physical OPPO | SBC then LDAC negotiated | Not tested | UNTESTED | After endpoint |
| T-012 | Audio stream | Physical OPPO | Sustained real audio, codec verified | Not tested | UNTESTED | After negotiation |
| T-013 | Reconnect/reboot/stability | Physical OPPO | Reconnect and long-run stable | Not tested | UNTESTED | Final qualification |

## Test record requirements

For every new test record: unique ID, local date/time, branch + commit + run ID, exact artifact IDs/hashes, OS build/UBR and runtime versions, VM vs physical environment, preconditions, procedure, expected/actual, logs, status, and next action. Do not combine OS servicing and driver changes in one experiment.

| T-014 | Minimal Microsoft AudioCodec-derived ACX 1.0 client build | PASS (CI #10, #11, #13) | Not yet a bind result | CI runs 45077156403, 45077797657 | Same WDK 10.0.26100.6584, SDK 10.0.26100.0, KMDF 1.31; ACX 1.0 stub hash matches CI #255. |
| T-015 | Hosted runtime preflight before root-enumerated PnP install | Harness-only failures in CI #10/#11; CI #13 pending | NO PnP attempt in #10/#11 | Runtime artifacts 14775099125 and 14776440518 | #10 stopped at SignTool /kp; #11 stopped at strict !wdfldr class-version preflight with missing dump page. Do not classify either as a driver bind failure. |
| T-016 | Probe workflow script validation | FAIL (CI #12) | Not attempted | Run 45078310971 | PowerShell parser caught a malformed generated block; no device/certificate created. Fixed in commit 35e700a. |
| T-017 | Hosted ACX 1.0 sample bind test | BUILD PASS; RUNTIME FAIL (CI #13) | PnP selected root MEDIA probe INF; Code 37 / 0xC000000D before DriverEntry | Run 45078613003; commit 35e700a3ecb74548b858f0479a1e15e31a2d110f | CONFIRMED — VM_TEST | Rules out LDAC-specific INF topology as the cause of this pre-DriverEntry failure; inspect WDF/ACX loader stage. |

| T-018 | WDF global DbgPrintOn capture | CI #14 build/runtime harness PASS; internal-stage capture INCONCLUSIVE | DbgPrintOn was written after Wdf01000.sys DriverEntry; !dbgprint empty; Code 37 unchanged | Run 45081844225; commit 04518a83900a7e7aa093fe56a7669f91349d7588 | INCONCLUSIVE — VM_TEST | Do not repeat post-boot global setting; use per-driver VerboseOn/LogPages and WDF IFR. |
| T-019 | Per-driver WDF IFR / native LiveKD capture | CI #15 / 45082965356, hosted Server 2022 build 20348 UBR 5870 | Determine whether IFR exposes the first bind failure | PnP selected root MEDIA probe; Code 37 / 0xC000000D before DriverEntry. Raw preinstall dump contains ACX01000 IFR; probe IFR unavailable because the probe never loaded. Native dump still missed a page; structured WdfIfrLines omitted preinstall output. | CONFIRMED — VM_TEST (negative bind); diagnostic substage INCONCLUSIVE | Use CI #16 full mirror and phase-separated IFR extraction. |
| T-020 | WDK ACX 1.0 stub vs Server 2022 runtime class-bind contract | CI #255 stub parse + CI #10/#16 hosted Server 2022 runtime + physical WinDbg trace | Compare the client descriptor with the actual runtime class-bind ABI and class module | Stub: ACX 1.0 / 210 functions / 62 structures / 0x78 bytes. CI #16 runtime PDB: WDF_CLASS_BIND_INFO 0x50, WDF_CLASS_BIND_INFO2 0x78; ACX CLASS_MODULE v1.0 and WDF client 1.31 / runtime 1.33 are present. Probe still Code 37 / 0xC000000D before DriverEntry. Full mirror had zero missing pages. | PARTIAL — STATIC_ANALYSIS / VM_TEST / PHYSICAL_DIAGNOSTIC | Inspect actual bind-record field values, class registration/version resolution and the internal WdfVersionBindClass path; do not change INF topology. |

| T-021 | WDK 20348.1 / VS2019 toolchain-bundle control | CI #17 / run 45158705058, branch `experiment/acx10-wdk20348-control`, commit `79460f03492a54444473589dd142da864a703a73` | Determine whether the Server 2022-era EWDK contains ACX 1.0 headers/stub and KMDF 1.31 libraries, then build the same probe | Parser/XML gates passed; EWDK download/stub inspection/build step still in progress at 12:53 Kyiv; no artifact or runtime test yet | UNTESTED — BUILD_ONLY | Verify actual EWDK entrypoint and environment, compare stub hash/descriptor, and run hosted bind test only if build succeeds. |
| T-022 | CI #16 artifact integrity | GitHub artifact downloads vs durable Library copies | Verify byte-identical preservation | Build artifact 14779061024 and runtime artifact 14779107472 match Library copies; build ZIP corrected to SHA-256 `d332fc338cbd8c4aa41f56338bb68104059b2956558067362d69b495a0ba8e72`; runtime ZIP SHA-256 `7d53835ecaababca7451c19e0ce79bab7186f9e59568fcc3a3b047efa3e95214` | CONFIRMED — STATIC_ANALYSIS | Use corrected build digest in Build Registry and Artifact Index. |

## A2DP transport-first gates — 2026-11-23

The stages below are independent. A pass at one stage never proves a later stage.

| ID | Gate | Required proof | Windows 10 reference | Server 2022 latest recorded evidence |
|---|---|---|---|---|
| T-023 | Service start | `bthserv` and A2DP profile service start without errors | Package/service registration present; live on-demand start not proven | Core Bluetooth service state is in archive; Microsoft `BthA2dp` package absent |
| T-024 | Device enumeration | BTHENUM Audio Sink UUID `0x110B` appears as expected profile devnode | Present | Present, but generic `bth.inf` / `BthGenericService` placeholder |
| T-025 | Profile driver load | `BthA2dp.sys` loads and PnP problem code is 0 | Binary/package recorded; active runtime load not proven | No Microsoft `BthA2dp.sys`; last custom node `oem75.inf` Code 37 / `0xC000000D` |
| T-026 | A2DP endpoint | AudioEndpointBuilder exposes a stereo render endpoint | Endpoint inventory exists; endpoint presence is not playback proof | No Microsoft A2DP render endpoint recorded |
| T-027 | SBC negotiation | AVDTP SetConfiguration shows SBC and negotiated parameters | Not captured | Not tested |
| T-028 | Actual SBC stream | RTP/media packets flow and audible stereo is verified | Not captured | Not tested |
| T-029 | LDAC negotiation | AVDTP vendor-specific LDAC codec selected by both sides | Not supported by Win10 inbox stack; Enco Buds2 does not advertise LDAC | Not testable with Enco Buds2 |
| T-030 | Actual LDAC audio | LDAC media frames are observed and decoded/verified | Requires a different LDAC-capable sink and non-inbox LDAC path | Blocked by sink capability and missing LDAC transport |

### Disposable-VM execution order

1. Complete package audit and signature/catalog verification.
2. Service start.
3. BTHENUM device enumeration.
4. Microsoft A2DP profile driver load and PnP problem code 0.
5. A2DP endpoint creation.
6. SBC negotiation with Enco Buds2.
7. Actual SBC media stream and audible stereo.
8. Only with a different LDAC-capable sink: LDAC negotiation, then real LDAC media/audio proof.

No stage is marked passed by this documentation update; no runtime test was executed.

| T-031 | Win10 exporter static audit | Library source `Export-Win10-A2DP-Package.ps1`, 5,108 bytes / 95 lines | Confirm exact collection scope and safety | Read-only; scans DriverStore and Windows INF; copies matching package directories and BthA2dp.sys; records direct Include/Needs, versions, hashes and signature status | CONFIRMED — STATIC_ANALYSIS | Treat as targeted package recovery only; WinSxS/DLL/COM/PE/CAT-member closure is not covered |
| T-032 | Win10 A2DP package capture | AS-KRM-WIN10, Windows 10 Enterprise x64 build 19045 | Source/common/sink INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys captured with provenance | 23:49 archive contains these files; no local .cat; system-supplied INFs have no CatalogFile; CBS/system-catalog ownership pending | PARTIAL — STATIC_CAPTURE | Do not re-export; resolve WIM package/catalog identity |
| T-033 | Codec/transport/provider DLL and COM inventory | AS-KRM-WIN10 Win10 package + PE reports | Identify codec/provider binaries, imports/exports/delay imports and COM registrations | No Microsoft inbox LDAC DLL or codec-provider interface identified; MSSysFx DLLs are audio effects; full export/COM inventory incomplete | PARTIAL — STATIC_ANALYSIS | Reconcile exact PE copies and inspect remaining package DLLs |

No service, device, profile-driver, endpoint, SBC negotiation, audio-stream, LDAC negotiation, or LDAC audio test was run in this research pass.


## 2026-11-24 01:42 — component/codec test gates

| T-034 | INF Include/Needs closure | AS-KRM-WIN10 build 19045 | Exact source/common/A2DP dependency graph | Source UUID 0x110B → common INF; Include ks.inf/wdmaudio.inf/BtaMpm.inf; Needs KS.Registration/WDMAUDIO.Registration/BtaMPM.CopyFilesOnly/mssysfx.CopyFilesAndRegister; BthA2dp demand-start service; KSCATEGORY_AUDIO interfaces | CONFIRMED — STATIC_ANALYSIS | Resolve CBS/component ownership from original WIM metadata |
| T-035 | PE imports and BthA2dp provenance | Win10 DriverStore and System32 copies | One exact file identity plus imports/exports/delay imports | DriverStore BthA2dp hash 5FBA / 282,624 bytes / version 10.0.19041.4355 imports ntoskrnl only; separate System32 hash 0442 / 279,040 bytes has 8 import descriptors / 144 functions and is likely 10.0.19041.1 by secondary size/version corroboration (hash not matched); BtaMPM imports ntoskrnl/cng/WppRecorder; exports not captured | PARTIAL — STATIC_ANALYSIS | Reconcile file paths/versions and run Dependencies/PEInspector on exact binaries |
| T-036 | Server 20348.5761 import/export compatibility | Exact Server 2022 image and Win10 package binaries | Every imported function resolves against target kernel/dependencies | Not checked; exact Server WIM/ntoskrnl export inventory is not in current Library | BLOCKED — IMAGE_METADATA | Obtain Server WIM/component store and compare exports |
| T-037 | SBC stereo on OPPO Enco Buds2 | Disposable Server 2022 VM + OPPO ETE41 | A2DP endpoint, SBC negotiation and sustained audible stereo | Not run; no runtime stage is proven | UNTESTED — VM/HARDWARE | After package compatibility, run service → enumeration → driver load → endpoint → SBC → audio |
| T-038 | LDAC negotiation with OPPO Enco Buds2 | OPPO ETE41 | LDAC negotiation and real LDAC audio | Official specification lists AAC/SBC only; this sink cannot negotiate LDAC | REFUTED — SINK_CAPABILITY | Use a different LDAC-capable sink for LDAC tests |
| T-039 | LDAC negotiation and actual audio | Separate LDAC-capable receiver + Server 2022 VM | Negotiated LDAC and sustained real audio verified | Not run; no LDAC-capable sink is identified in current project evidence | UNTESTED — DEVICE_REQUIRED | Only after SBC milestone |
| T-040 | Alternative A2DP binary transplant | Alternative A2DP 1.8.3/1.8.3.1 | Reuse vendor LDAC driver on Server 2022 | Vendor EULA restricts reverse engineering/modification/transfer; published support matrix excludes Server 2022 | REJECTED — LICENSE/OS_SUPPORT | No transplant; vendor authorization required for any Server evaluation |



## 2026-11-24 02:05 — Server PnP stage separation

| T-041 | A2DP PnP enumeration | Archived Server 2022 read-only PnP snapshot | One BTHENUM A2DP Sink node is present before driver load | ldac-precheck records one present A2DP devnode; 20-36 identifies UUID 0x110B | CONFIRMED — HISTORICAL SNAPSHOT | Keep enumeration separate from driver-start result; no fresh host query |
| T-042 | Current custom driver start | Archived 20-36 PnP properties | Bound profile driver starts successfully | oem75.inf / LdacA2dp / 0.2.325.1600 returns Code 37 / 0xC000000D | FAILED — HISTORICAL SNAPSHOT | Do not repeat ACX probe; test Microsoft inbox package only in disposable VM after WIM/PE compatibility |
| T-043 | Microsoft A2DP package presence on Server 2022 | Archived Server 20348.5761 environment snapshot | BthA2dp.sys and Microsoft A2DP source/common INF present | btha2dp.sys absent from System32\\drivers; A2DP INF section empty in INF investigation | ABSENT — ARCHIVED INVENTORY | Resolve Windows 10 component owner/applicability from WIM |
| T-044 | Realtek rtka2dp relevance to current local radio | Server DriverStore inventory + PnP ID semantics | INF targets current local radio | Folder exists but INF bytes/version absent; public package targets LOCALMFG&005D (Realtek), current radio LOCALMFG&0002 (Intel) | NOT APPLICABLE — LOCAL_RADIO_MISMATCH | Do not install/adapt; retain as residue/reference only |



| T-045 | Windows 10 inbox LDAC codec/provider presence | Microsoft Windows 10 Classic Audio documentation | LDAC codec/provider exists in the inbox A2DP path | Official table lists SBC and aptX Classic only; no LDAC or AAC for Windows 10 | ABSENT — DOCUMENTED_CODEC_SET | Do not search for a Microsoft inbox LDAC DLL; keep SBC package analysis separate |
| T-046 | A2DP codec ownership in profile driver | Public BthA2dp.sys 10.0.17763.168 PDB symbol index | Identify codec and AVDTP ownership | Internal A2dpSbcCodec and AptXCodec classes plus AVDTP symbols; no Ldac symbol in 997 named symbols | CONFIRMED — SECONDARY_SYMBOL_EVIDENCE | Reconcile with exact 10.0.19041.4355 binary before asserting exact internal layout |
| T-047 | Legacy PE import parser correctness | Library pe_imports_a2dp.py / a2dp_pe_imports_report.txt | Advance to each 20-byte IMAGE_IMPORT_DESCRIPTOR | Parser never increments descriptor offset; report repeats first descriptor | FAILED — TOOLING_DEFECT | Retire report for dependency claims; re-run exact package bytes with retained Dependencies/PEInspector/pefile workflow |
| T-048 | Existing LDAC encoder provenance and linkage | server-2022-oppo commit 95bb92866b0d77de20ee94694eb4be2979635947 | Identify whether an LDAC DLL already exists in the project | AOSP external/libldac at eeee1a3f is built as static libraries and called by service/encoder.cpp | CONFIRMED — SOURCE_AUDIT | Treat as existing encoder source, not a Windows 10 DLL or BthA2dp plug-in |
| T-049 | BlueCaster as an existing LDAC transport alternative | BlueCaster v3.0.4 README/release metadata | Check whether a ready non-kernel implementation exists | User-mode BTstack + WinUSB; LDAC 330/660/990; USB adapter takeover; Windows 10 22H2/11 only; BTstack personal/non-commercial license | CANDIDATE — SERVER_UNTESTED / LICENSE_CONSTRAINED | Consider only after SBC and only in disposable VM; no physical adapter changes |


| T-050 | Windows Server 2022 Bluetooth in-box support vs host-subsystem qualification | Microsoft Bluetooth support and component-guideline documentation | Determine whether Server 2022 includes in-box Bluetooth/A2DP | All Server SKUs lack in-box Bluetooth wireless support; third-party drivers may be available. QD ID 130847 lists Server 2022 as a Host Subsystem qualification, not as an in-box profile package. | CONFIRMED — SCOPE DISTINCTION | Separate vendor radio/host stack, Microsoft host subsystem interfaces and A2DP profile package; do not infer A2DP from QD ID or radio enumeration |


## 2026-11-24 exact-image tests

| Test | Expected evidence | Result |
|---|---|---|
| CI #463 — Win10 A2DP package discovery | INF/component versions and package ownership | Passed |
| CI #463 — PSF payload classification | Complete PE image or explicit delta classification | Delta classification confirmed; full PE not reconstructed |
| CI #463 — Server A2DP package presence | A2DP INF/SYS/BtaMPM references in KB5126655 | No matching package/manifest hits |
| CI #463 — Winbindex exact identity | SHA-256 equals captured archive | Failed 0/3; symbol-server collision |
| UUP image audit #3 | Exact image version, captured hashes, PE import/export comparison | In progress |
| Disposable Server 2022 runtime | Service → enumeration → driver → endpoint → SBC → audio | Not started; gated on static audit |


## 2026-11-24 exact-image tests

| Test | Expected evidence | Result |
|---|---|---|
| CI #463 — Win10 A2DP package discovery | INF/component versions and package ownership | Passed |
| CI #463 — PSF payload classification | Complete PE image or explicit delta classification | Delta classification confirmed; full PE not reconstructed |
| CI #463 — Server A2DP package presence | A2DP INF/SYS/BtaMPM references in KB5126655 | No matching package/manifest hits |
| CI #463 — Winbindex exact identity | SHA-256 equals captured archive | Failed 0/3; symbol-server collision |
| UUP image audit #3 | Exact image version, captured hashes, PE import/export comparison | In progress |
| Disposable Server 2022 runtime | Service → enumeration → driver → endpoint → SBC → audio | Not started; gated on static audit |

## 2026-11-24 — package compatibility gates

| ID | Test | Evidence / result | Status |
|---|---|---|---|
| T-051 | Win10 BthA2dp/BtaMPM candidate PE imports vs Server exports | Candidate BthA2dp 19041.6392: 149 imports; 129 matched against available later Server 20348.5866 exports plus companion BtaMPM. Remaining 20 imports from HAL/SleepStudyHelper/WDFLDR/ksecdd were not compared. Candidate hashes do not match captured files. | PARTIAL — NOT EXACT / NOT TARGET BUILD |
| T-052 | Companion BtaMPM import/export closure | Candidate BtaMPM 19041.7660 exports all 10 symbols imported by candidate BthA2dp; its 42 imports resolve against available Server 20348.5866 references. | STATIC PASS FOR NON-EXACT CANDIDATE ONLY |
| T-053 | INF dependency and endpoint registration | Common INF uses ks.inf, wdmaudio.inf, BtaMpm.inf; Needs KS.Registration, WDMAUDIO.Registration, BtaMPM.CopyFilesOnly, mssysfx.CopyFilesAndRegister; AddService BthA2dp demand-start; KSCATEGORY_AUDIO source/sink interfaces. | STATIC CONFIRMED |
| T-054 | UUP exact image audit | Win10 19045.5917 and Server 20348.5761 offline extraction/PE comparison. | IN PROGRESS — RUN 45317582562 |
| T-055 | Disposable Server 2022 package staging/service start | Not started; wait for exact static/CAT/registry evidence. | BLOCKED BY STATIC AUDIT |
| T-056 | Device enumeration → driver load → A2DP endpoint → SBC negotiation → actual stereo audio | Requires a real Bluetooth radio and OPPO sink in a disposable Server 2022 VM. Hosted CI has no demonstrated radio/audio path. | NOT TESTED |
| T-057 | LDAC negotiation and actual LDAC audio | OPPO Enco Buds2 ETE41 supports AAC/SBC only. | CANNOT TEST WITH OPPO; DIFFERENT LDAC SINK REQUIRED |

