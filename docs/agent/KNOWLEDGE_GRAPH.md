# Knowledge graph — ACX class binding failure

This graph captures the current causal model, not a claim that the root cause has already been proven.

```mermaid
flowchart TD
  A["Physical Server 2022 / build 20348"] --> B["ACX class module reports Version 1.0"]
  C["Driver baseline CI #126"] --> D["Driver requests ACX 1.1"]
  B --> E["ACX class version mismatch"]
  D --> E
  E --> F["FxStubBindClasses / VersionBindClass"]
  F --> G["STATUS_INVALID_PARAMETER 0xC000000D"]
  G --> H["DriverEntry body not reached"]
  I["Kernel-PnP ETW Event 227"] --> G
  J["ACX 1.0 experiment commit 593e8f4"] --> K["CI #133 build success"]
  K --> L["Physical ACX class binding test pending"]
  L --> M{"Does DriverEntry start?"}
  M -->|"Yes"| N["Investigate AcxDriverInitialize / ACX device and circuit"]
  M -->|"No"| O["Capture exact bind failure; inspect class metadata, INF/service and stub"]
  P["KMDF client 1.31 / WDF runtime 1.33"] -. "not established causal" .-> F
  Q["ACX unload ETW event"] -. "correlation only" .-> F
```

## Nodes

- **FACT-001:** class binding fails before the driver's `DriverEntry` body.
- **FACT-002:** binding status is `0xC000000D / STATUS_INVALID_PARAMETER`.
- **FACT-003:** physical target's ACX `CLASS_MODULE Version` is `v1.0`.
- **FACT-004:** CI #126 driver baseline requested ACX 1.1.
- **FACT-005:** ACX 1.0 experiment compiles successfully in CI #133.
- **HYP-001:** the class-version mismatch is the cause of the binding failure.
- **EXP-001:** ACX 1.0 experiment, commit `593e8f4...`.
- **TEST-001:** controlled physical-host load test, not yet performed.

## Edges

- FACT-001 `SUPPORTED_BY` FACT-002.
- HYP-001 `DERIVED_FROM` FACT-002 + FACT-003 + FACT-004.
- EXP-001 `TESTED_BY` CI #133 (compile/package only).
- EXP-001 `AIMS_TO_TEST` HYP-001 on physical hardware.
- FACT-005 does not prove TEST-001.
- KMDF runtime difference and ACX unload ordering are deliberately non-causal side observations.


## New evidence and branch in the graph

- **FACT-006:** CI #133 package SYS is byte-identical to the unsigned driver artifact; INF version 0.2.326.1634.
- **FACT-007:** PDB comparison shows 221 ACX API table symbols in #126 and 210 in #133; the 11 Microsoft-listed ACX 1.1-only DDIs are absent from #133.
- **FACT-008:** all 36 ACX calls used by LDAC are present in the #133 PDB API table.
- **FACT-009:** Microsoft labels ACX 1.0 pre-release/not recommended for new development; ACX 1.1 is the public current recommendation.
- **FACT-010:** target's last recorded OS build is 20348.2849 (2024-11); later cumulative build 20348.5873 exists (2026-11).
- **HYP-002:** a later OS cumulative update may change the installed ACX runtime/class version. No evidence yet; do not assume it does.

Edges:
- FACT-007 + FACT-008 `CORROBORATE` that CI #133 is a genuine ACX 1.0 build.
- FACT-009 `QUALIFIES` EXP-001: compatibility experiment only, not production-support status.
- FACT-010 `MOTIVATES` HYP-002, but does not prove it.
- HYP-002 `REQUIRES_TEST` file version and `!wdfldr` comparison on an updated image/host before any driver installation test.
