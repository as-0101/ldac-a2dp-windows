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
