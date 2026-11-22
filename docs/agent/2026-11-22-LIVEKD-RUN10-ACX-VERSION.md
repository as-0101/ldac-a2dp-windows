# LiveKD run #10 — hosted Server 2022 ACX class version

**Date:** 2026-11-22 20:48 Kyiv  
**Workflow:** [ACX runtime LiveKD probe run #10](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45057090987)  
**Commit:** [218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383](https://github.com/as-0101/ldac-a2dp-windows/commit/218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383)  
**Job:** 137314604538 — Inspect hosted Server 2022 ACX class through LiveKD  
**Conclusion:** success

## Exact debugger output

The workflow started Acx01000 on the disposable hosted runner; SCM reported STATE 4 RUNNING and exit code 0. LiveKD captured a native dump, KD opened it, and Acx01000 symbols loaded.

The documented command !wdfldr acx01000 returned:

    WDF Driver: Acx01000

    CLIENT_MODULE
      WDF Version   v1.31
      ImageName     Acx01000.sys
      ImageAddress  0xfffff8045e000000
      ImageSize     0xa5000

      ImageName        WdfVer Ver
      Wdf01000.sys     v1.33  v1.33

    CLASS_MODULE
      WDF Version   v1.31
      Version       v1.0
      Service       \REGISTRY\MACHINE\SYSTEM\ControlSet001\Services\Acx01000
      ImageName     Acx01000.sys
      ImageAddress  0xfffff8045e000000
      ImageSize     0xa5000
      Clients list is empty

The subsequent !wdfkd.wdfldr Acx01000.sys query returned the same CLIENT_MODULE and CLASS_MODULE data. The class module has no clients on this hosted runner because no ACX client driver was loaded there.

## Comparison with physical Server 2022

The physical host's earlier WinDbg output reported:
- ACX CLASS_MODULE Version v1.0;
- WDF Version v1.31;
- Wdf01000 runtime v1.33.

Run #10 independently reports the same class/runtime combination on a separate hosted Server 2022 image. The physical host's active LDAC driver is built against ACX 1.1 and PnP reports ProblemCode 37 / ProblemStatus 0xC000000D; the failure is before DriverEntry.

This is strong direct evidence for the leading explanation: an ACX 1.1 client is attempting to bind to a Server 2022 ACX 1.0 class module. It is not yet a complete proof of all internal binding checks, and other metadata mismatch is not ruled out. The next discriminating experiment remains the CI #133 ACX 1.0 build on the physical host.

The hosted kernel build lab reported 20348.2849. This is not a controlled comparison of every Server 2022 cumulative update; do not claim that no future servicing can change ACX class version. The class version must be measured with !wdfldr acx01000, not inferred from Acx01000.sys file version.

## Artifact

- Artifact ID: 14768205866
- SHA-256: aed85ff189ca817191383edb38945f69c27e50a86832ea8819c2e3b42674ade7
- Files Library: /Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run10-report.zip
- Library ID: libfile_4ab21e3426e0819190b2fa201822980c

## Current status and next action

- CONFIRMED: hosted Server 2022 ACX CLASS_MODULE v1.0 / WDF 1.31 / WDF runtime 1.33.
- CONFIRMED from prior physical WinDbg: physical host ACX CLASS_MODULE v1.0 / WDF 1.31 / runtime 1.33.
- STRONGLY SUPPORTED: ACX 1.1 versus ACX 1.0 class mismatch is the leading cause of the pre-DriverEntry STATUS_INVALID_PARAMETER.
- UNTESTED: whether the CI #133 ACX 1.0 driver reaches DriverEntry on the physical host.
- Next action: read-only status pre-check for CI #133 / Universal / ACX 1.0, then separate explicit authorization before any install or system change. No prepare, certificate import, driver install, upgrade, device restart, rollback, BCD change or OS update has been performed.
