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
| T-020 | WDK ACX 1.0 stub vs Server 2022 runtime class-bind contract | CI #255 static stub parse + CI #10/#15 hosted runtime hashes + physical WinDbg trace | Compare class-bind descriptor against runtime class module | Stub: 1.0 / 210 functions / 62 structures / 0x78-byte descriptor; runtime CLASS_MODULE v1.0 is confirmed, but its function/structure counts remain unknown. Physical trace records WdfVersionBindClass returning 0xC000000D. | PARTIAL — STATIC_ANALYSIS / PHYSICAL_DIAGNOSTIC | CI #16 full-mirror WDF type queries and WDK header scan. |
