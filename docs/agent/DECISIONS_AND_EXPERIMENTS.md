## 2026-11-24 — Native preflight decision

Retire the unchanged client INF/CAT staging recipe. Full-path append is a parser control, not DriverStore publication. Preserve the client package as evidence. [Native INF preflight and signed-catalog evidence](/research/native-inf-preflight-20261124/README.md).

## Decisions added — 2026-11-24

| ID | Decision | Rationale | State |
|---|---|---|---|
| D-057 | Do not add a `CatalogFile` directive to the system-supplied Win10 A2DP INFs and do not label them unsigned because the directive is absent. | Microsoft documents that system-supplied INFs omit CatalogFile and are validated against all system-supplied catalogs. Verify exact INF/SYS membership against the offline OS catalog set; never modify the signed INF. | ACTIVE |

## EXP-008 — UUP offline catalog membership and service registry audit

- Question: do the exact Win10 A2DP source/common INF, BthA2dp.sys and BtaMPM.sys belong to a valid system-supplied catalog, and what service registrations exist in Win10 19045.5917 versus Server 20348.5761?
- Scope: offline UUP images only; no driver staging, service start, PnP binding, physical-host access or audio test.
- UUP #7 [45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564) failed because StrictMode accessed an optional `ServiceDll` property absent from a registry object. This was a tooling failure, not a driver compatibility result.
- Recovery commits: [f451e4ce](https://github.com/as-0101/ldac-a2dp-windows/commit/f451e4cee683a1922aacdfb0505d3f8a97ece8a8), [fd9fd19c](https://github.com/as-0101/ldac-a2dp-windows/commit/fd9fd19cf261b97c0c509127035639c2a69e8386), [f0605f14](https://github.com/as-0101/ldac-a2dp-windows/commit/f0605f14aff2f8ff937c169c3796216b26058aac), [ff8c4a3b](https://github.com/as-0101/ldac-a2dp-windows/commit/ff8c4a3b6a8467d940b239571670ae29da5ca1a3).
- CI #11 [45347639357](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45347639357): PowerShell parser and x64 SignTool preflight passed; offline image audit is still running.
- Results: PENDING. Do not claim catalog membership or service-registration success until JSON reports are inspected.
- Decision: retain the exact Win10 system INF and SYS bytes; do not edit INF, add a CatalogFile line, or copy Win10 KS/WDMAUDIO core.
- Physical Server 2022 remains untouched; ACX bind-probe remains parked.

# Decisions and experiment ledger

## Decisions

| ID | Decision | Rationale | State |
|---|---|---|---|
| D-001 | Keep the physical user's Server 2022 unchanged during investigation. | Avoid risking production Bluetooth/audio and system stability. | ACTIVE |
| D-002 | Keep ACX version as the isolated experimental variable. | Historical experiment control; no longer the current project path. | PARKED — HISTORICAL |
| D-003 | Keep `DriverTargetPlatform=Universal` for the ACX 1.0 experiment. | Historical experiment control; no longer the current project path. | PARKED — HISTORICAL |
| D-004 | Do not merge draft PR #2. | It is a diagnostic branch until physical binding behavior is known. | ACTIVE |
| D-005 | Preserve Notion journal append-only. | Retain all historical reasoning and failed experiments. | ACTIVE |

## Experiments

### EXP-001 — ACX 1.0 class binding compatibility

- Question: does targeting the ACX class version actually registered on the Server 2022 host remove the pre-DriverEntry binding failure?
- Target observation: host reports `CLASS_MODULE Version v1.0`; CI #126 driver targeted ACX 1.1.
- Single intended variable: ACX version from 1.1 to 1.0 (project macro/include/link selection and matching runtime version gate).
- Commit: `593e8f407ec18e72a332edbec323a4ddbbd27774`.
- Branch: `experiment/acx10-server2022-bind`.
- CI result: run #133 PASS; all 3 jobs completed successfully; test and unsigned driver artifacts created.
- Build caveat: the captured job log confirms successful compile/package on Windows Server 2022 runner, but does not print the fully expanded ACX include/link path. The project computes both from `ACX_VERSION_MINOR=0`; do not overstate the log.
- Physical-host result: NOT RUN.
- Success criterion: first `LdacA2dp: DriverEntry started` appears; no `FxStubBindClasses class Acx 0xC000000D`.
- If success: next isolate `WdfDriverCreate`, `AcxDriverInitialize`, ACX device/circuit creation, then A2DP/SBC.
- If failure: preserve the full kernel debug log and exact NTSTATUS; inspect ACX stub/class binding metadata and compare against official Microsoft AudioCodec sample.
- Safety: no install or system changes by the agent; require explicit user-side test authorization and rollback plan.

## Previously investigated / do not repeat without new evidence

| Direction | Existing finding | Reopen only if |
|---|---|---|
| INF does not match / device not discovered | Device was configured and bound to `oem75.inf`; failure occurs during start. | Hardware ID or selected INF changes. |
| ACX runtime cannot load at all | ACX runtime successfully initialized/registered as a WDF client. | New runtime load failure appears. |
| KMDF 1.31 vs runtime 1.33 | No direct evidence that this is causal. | New WDF diagnostics isolate a framework-version failure. |
| PeerInitialize() causes DriverEntry failure | Incompatible with observed failure before DriverEntry; reviewed function has no NTSTATUS-returning operation. | Evidence relocates failure into DriverEntry. |
| Secure Boot / test certificate | Not the current 0xC000000D class-bind failure. | New signature/code-integrity error appears. |
| ACX unload caused bind failure | Event ordering is correlation only. | Causal evidence (not just timing) appears. |

## Update protocol

Append a dated record after each meaningful experiment. Record question, exact changed variable, commit, CI run, artifact IDs/digests, observations, interpretation, status and next step. Do not erase previous records; update the current snapshot separately.

## EXP-002 — DriverTargetPlatform A/B against official AudioCodec sample

- Question: does using the official AudioCodec sample's DriverTargetPlatform=Windows Driver instead of Universal change the ACX 1.0 build/package behavior?
- Base: experiment/acx10-server2022-bind at commit 593e8f407ec18e72a332edbec323a4ddbbd27774.
- Single changed variable: DriverTargetPlatform Universal -> Windows Driver.
- Branch: experiment/acx10-windowsdriver-platform.
- Commit: 6656e2d1fcda8d731f6795bd2e7a2950d5ba8309.
- Draft PR: https://github.com/as-0101/ldac-a2dp-windows/pull/3; do not merge.
- CI run #143: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45050062916; all 3 jobs passed, including KMDF driver; INF DriverVer 0.2.326.1734; 0 warnings/errors; test and unsigned driver artifacts persisted in Files Library.
- This experiment is build/package-only. It cannot prove physical ACX class binding.
- Microsoft Target Platforms documentation explicitly lists Server 2022 for Universal drivers, so Universal is valid; the sample difference remains a low-priority A/B check.
- Result: PASS for compile/package only. Physical class binding remains UNTESTED.

## D-006 — First physical test candidate

Choose CI #133 / Universal / ACX 1.0 for the first runtime test because it isolates ACX version only and preserves the original Universal target. Do not use CI #143 as the first runtime candidate because it also changes DriverTargetPlatform. No server-side preparation or installation is authorized by this documentation decision.

## Decision D-007 — avoid `-kl` until local debugging is already configured

- **Decision:** Do not use the earlier `Launch-WinDbg-Kernel.bat` on the physical host as-is. It launches `-kl` only; Microsoft requires BCD `debug on`, local `dbgsettings`, and a reboot. Do not change BCD or suspend security controls without explicit authorization.
- **Preferred alternative:** validate Sysinternals LiveKD `-ml` native live-dump capture on a disposable runner, then use it for a read-only host snapshot if needed. CI #5 confirmed capture and KD processing; WDF loader symbols remain a limitation.
- **Status:** ACTIVE; LiveKD capture validated, `!wdfldr` symbol resolution still under investigation.

## Experiment EXP-003 — hosted Server 2022 ACX runtime inspection

- **Purpose:** determine whether a more-serviced Server 2022 runner has a different ACX class version, without touching the physical server.
- **Branch:** `research/acx-runtime-livekd`; latest workflow commit `d30bc2cdccc5bcea16059505ef444393701dac0a`.
- **Baseline:** hosted runner build 20348; `Acx01000.sys` file version 10.0.20348.5866; `Wdf01000.sys` 1.33.20348.1. ACX service is stopped by default; starting it succeeded on the disposable runner.
- **CI #5:** run `45054287408`, commit `40d40d4b0300b708388c25f83e3fb2bc00c7b19e`, successful LiveKD dump capture and KD processing. `!wdfkd.wdfldr` could not resolve `wdfldr!WdfLdrGlobals` from public symbols; no class version was returned. Report artifact 14766509597 is preserved in Files Library.
- **CI #6:** run `45054673989`, commit `e13cd43d66d13e7c341f7c81a64f1677a3aabfe4`, direct LiveKD `-k` path; in progress at snapshot.
- **CI #7:** run `45054866734`, commit `d30bc2cdccc5bcea16059505ef444393701dac0a`, preconfigured `_NT_SYMBOL_PATH`; in progress at snapshot.
- **Interpretation:** file-version difference is confirmed; ACX class-module version on the hosted runner remains UNKNOWN. Do not use file version as a proxy.
- **Physical-server impact:** none. No driver installation, certificate import, BCD change, device restart, or OS update.

## EXP-002 — ACX 1.0 hosted driver load (negative)

- Date: 2026-11-22.
- Question: does matching the hosted Server 2022 ACX CLASS_MODULE v1.0 by building against ACX 1.0 allow the LDAC driver to bind?
- Environment: disposable hosted Windows Server 2022 runner only; synthetic SWD device with BTHENUM A2DP compatible IDs.
- Build: CI run #248 / 45060225420; branch `experiment/acx10-hosted-load`; commit `3d1d5d7e179da3379013b10f9863066200c459b6`; DriverVer 0.2.326.1922; ACX 1.0 / Universal.
- Preconditions: `Acx01000` was explicitly started and confirmed RUNNING before PnP installation; testsigning was already Yes on disposable runner; temporary certificate/device removed after test (DevGen removal failed, pnputil fallback succeeded).
- Result: package imported and selected as oem13.inf; SetupAPI attempted device start; Code 37 / CM_PROB_FAILED_DRIVER_ENTRY; ProblemStatus 0xC000000D; Kernel-PnP Event 219. No DriverEntry log; post-failure mirror did not contain Acx01000/LdacA2dp modules and debugger found no WDF clients.
- Status: CONFIRMED negative runtime result (VM_TEST). It disproves the claim that ACX 1.0 version selection alone is sufficient. It does not identify the internal validation returning STATUS_INVALID_PARAMETER.
- Related static check: CI #255 parsed the actual ACX 1.0 stub descriptor and CI #246 SYS descriptor (1.0 / 210 functions / 62 structures); accidental 1.1 descriptor selection is ruled out for that candidate.
- Decision: do not attempt physical CI #133 installation as the next experiment. First test a minimal official AudioCodec-derived ACX 1.0 client on the same hosted Server 2022 runtime.
- Report: artifact 14769048266, SHA-256 e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb. Stub report: artifact 14769755224, SHA-256 8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce.


## D-009 — Use SignTool /pa for the self-signed test package preflight (2026-11-22)
CI #10 proved that verify /kp rejects the probe's self-signed test certificate because it does not chain to a Microsoft root. Microsoft driver-installation documentation explicitly prescribes SignTool verify /v /pa Catalog.cat and SignTool verify /v /pa /c Catalog.cat DriverFile for PnP package verification. The probe now verifies CAT, SYS and INF with /pa; this is a harness correction, not a change to driver signing or the physical host.

## D-010 — Use SCM query output for Acx01000 service state (2026-11-23)
CI #11 showed sc.exe query Acx01000 = RUNNING while WMI Win32_SystemDriver.Started reported false. The probe now uses sc.exe query for before/start/cleanup decisions. It does not stop Acx01000 if it was already running before the probe.

## D-011 — LiveKD class-module visibility is evidence, not a hard gate when the bitmap dump is incomplete (2026-11-23)
CI #11's LiveKD mirror reported a missing page; !wdfldr still showed WDF runtime 1.33 and a WDF 1.31 client row associated with Acx01000, but could not display the class-module record. The same runtime file hashes match CI #10, which directly showed ACX class module 1.0. The probe now records missing-page limitations and proceeds when the pinned runtime files are present, instead of treating an incomplete debugger view as a driver failure.

## E-009 — Microsoft AudioCodec-derived ACX 1.0 minimal client (2026-11-23)
- Official source pinned at Microsoft Windows-driver-samples commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69; shared Public.h blob f1e9da3bd6101a503f620a31fa3d2ec471009161.
- The official project defaults to ACX 1.1; the probe deliberately targets ACX 1.0, keeps KMDF 1.31 and reduces INF topology to MEDIA / root-enumerated ROOT\AudioCodec. DriverEntry mirrors WdfDriverCreate then AcxDriverInitialize; EvtDeviceAdd logs and returns STATUS_NOT_SUPPORTED to isolate bind/entry from full codec topology.
- CI #11 build manifest proves the exact ACX 1.0 stub hash equals CI #255: 9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74. It also pins acx.h SHA-256 91877A614618A3A726E376A6014B99431C9E4EF54A804E9B48F1F7F8680F19FA, WdfDriverEntry.lib SHA-256 101BF4D30BBF773AC46FF96352EBFDE88A88C834C29F67C10065488CFE2F475C, and WdfLdr.lib SHA-256 AF708DE43A0975239F976BDF5F2596CC6FD7219A076643B2C6C98BDD6C4FF530.


## EXP-004 — Official AudioCodec-derived ACX 1.0 minimal bind test (CI #13, 2026-11-23)

- **Question:** does a minimal client based on Microsoft's AudioCodec sample bind on the same hosted Server 2022 runtime?
- **Source:** Windows-driver-samples commit `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`; project defaults ACX 1.1 / KMDF 1.31. Probe deliberately used ACX 1.0 / KMDF 1.31 / WDK 10.0.26100.6584 and a root-enumerated MEDIA INF.
- **Run:** CI #13 / 45078613003; commit `35e700a3ecb74548b858f0479a1e15e31a2d110f`.
- **Result:** BUILD PASS; PnP selected the probe INF, then Code 37 / `0xC000000D` before DriverEntry. Same failure class as LDAC candidate.
- **Interpretation:** CONFIRMED negative runtime test. LDAC's original topology and DriverEntry-specific code are not required to reproduce the failure. Internal WDF/ACX stage remains unknown.

## D-012 — Treat the pre-DriverEntry failure as a shared WDF/ACX bind problem, not an LDAC-only problem

CI #13 reproduces Code 37 / 0xC000000D with a minimal root-enumerated MEDIA client derived from Microsoft's sample. Do not spend another cycle simplifying LDAC topology or changing LDAC DriverEntry order until the shared loader failure is understood.

## EXP-005 — Global DbgPrintOn post-boot attempt (CI #14, 2026-11-23)

- **Run:** CI #14 / 45081844225; commit `04518a83900a7e7aa093fe56a7669f91349d7588`.
- **Result:** build and runtime harness pass; sample still fails Code 37 / 0xC000000D before DriverEntry; `!dbgprint` is empty.
- **Important correction:** the script wrote `HKLM\SYSTEM\CurrentControlSet\Control\Wdf\Kmdf\Diagnostics\DbgPrintOn=1` after the OS had booted. Microsoft WDF source initializes `WdfLdrDbgPrintOn` in `Wdf01000.sys` DriverEntry and reads the registry there (pinned source commit `b6191d9543441329154da32f7ab9bdd97228dd3c`, lines 111–115 and 358). The write was too late; empty `!dbgprint` is not evidence of an absent loader trace.
- **Decision:** do not repeat post-boot global DbgPrintOn writes. Use per-driver WDF `VerboseOn` / `LogPages` and `!wdfkd.wdflogdump`, or attach a live kernel debugger before PnP.

## D-013 — Use per-driver WDF IFR logging for the next hosted bind attempt

CI #15 sets WDF `VerboseOn=1` and `LogPages=16` for the probe through its INF and for Acx01000 before service start, with snapshot/restore. It uses LiveKD native `-ml` dumps and WDF IFR log dumps. The experiment remains on a disposable hosted runner; physical Server 2022 remains untouched.

## Compatibility note — ACX 1.0 support matrix

Microsoft ACX version information lists ACX 1.0 as pre-release for Windows 10 1903 / KMDF 1.29; Server 2022 is not listed. The official AudioCodec sample defaults to ACX 1.1 / KMDF 1.31. The tested ACX 1.0 + WDK 26100 + KMDF 1.31 + Server 2022 tuple is not documented as supported. This is a caveat, not a proven explanation for Code 37.

## EXP-006 — CI #15 minimal AudioCodec-derived ACX 1.0 bind test (2026-11-23)

- **Question:** does a minimal ACX 1.0 client derived from Microsoft's AudioCodec sample bind on the same hosted Server 2022 runtime as the LDAC candidate?
- **Source:** Microsoft Windows-driver-samples commit `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`. The full sample defaults to ACX 1.1 / KMDF 1.31; the probe is deliberately reduced to ACX 1.0 / KMDF 1.31, root-enumerated `ROOT\AudioCodec`, `Class=MEDIA`, and minimal WdfDriverCreate/AcxDriverInitialize code. It is not a full build of the complete sample.
- **Run:** CI #15 / 45082965356; branch `experiment/acx10-sample-bind-probe-v2`; commit `488ae8104eec960370c0887e07136a3e9e3846b5`.
- **Build:** WDK NuGet 10.0.26100.6584, SDK 10.0.26100.0, VS2022 MSBuild 17.14.60.43110, KMDF 1.31, ACX 1.0, Windows Driver target. DriverVer `11/22/2026,23.24.24.909`. SYS SHA-256 `BAB3C54C0EAB186CC8C9D89B07BCA871112454175C0C45F8D199DA57927114B6`.
- **Runtime:** hosted Server 2022 build 20348 / UBR 5870; PnP selected `oem13.inf` for the synthetic root device and returned Code 37 / `0xC000000D`; no DriverEntry marker. This is a confirmed negative bind result, not a successful load.
- **Diagnostics:** per-driver WDF `VerboseOn=1` / `LogPages=16` were set for Acx01000 before service start and restored afterward. The raw preinstall LiveKD log contains ACX01000 IFR entries; the probe's own IFR is unavailable because it never loaded. The native dump still lacked a page required to display the class-module record. The script's structured IFR field missed preinstall output; CI #16 fixes this.
- **Cleanup:** device, probe service and temporary certificate removed; Acx01000 restored to its original STOPPED state; WDF diagnostic values restored; no private-key files/markers; private temporary directory removed.
- **Artifacts:** build artifact 14778450384 / ZIP SHA-256 `8e701ee7f69f1d9c855f5b2c3d4c06de39628dfb7e955ecb12877fc9f811e449`; runtime artifact 14778137925 / ZIP SHA-256 `aa63c8dfbce7b9b319d9117e1be7b8db1565ff85a0d56c08e57c9de98710e59b`. Both durable Library copies are indexed in `research/ARTIFACT_INDEX.md`.
- **Interpretation:** the shared pre-DriverEntry failure is not specific to LDAC's INF topology or DriverEntry body. The exact runtime validation that returns `STATUS_INVALID_PARAMETER` remains unknown.

## D-014 — Inspect the runtime class-bind contract before another driver-code change
CI #15 reproduces the pre-DriverEntry failure with the minimal sample-derived client. Existing physical debug evidence identifies `WdfVersionBindClass` returning `0xC000000D`; WDF source describes this call as loading/referencing the class extension and linking the client. The next step is to compare runtime class-bind information with the exact WDK ACX 1.0 descriptor, not to simplify LDAC topology or change DriverEntry code. CI #16 uses a full LiveKD mirror and WDF type/header inspection. Physical Server 2022 remains unchanged.

## D-015 — Do not expect probe-driver IFR when class binding fails before DriverEntry
CI #15's `!wdfkd.wdflogdump AcxAudioCodecProbe` output says to confirm that the driver was successfully loaded. That is expected: the probe never becomes a loaded WDF client, so its per-driver IFR is not available. Preserve ACX01000 preinstall IFR separately; do not classify the missing probe IFR as evidence that the class-bind failure did not occur.


## EXP-007 — WDK 20348.1 / VS2019 toolchain-bundle control (CI #17, 2026-11-23)

- **Question:** does the Server 2022-era EWDK 20348.1 contain a usable ACX 1.0 stub/header plus KMDF 1.31 libraries, and does a probe built with that toolchain bind on hosted Server 2022?
- **Source sample:** Microsoft Windows-driver-samples commit `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`. The official solution uses VS2019 `16.0.31409.214`; the project defaults ACX 1.1 / KMDF 1.31, WPP/WPP Recorder, SamplesCommon and the Windows Driver target. The minimal probe is deliberately ACX 1.0 / KMDF 1.31 and root-enumerated MEDIA, preserving the sample's WdfDriverCreate → AcxDriverInitialize order.
- **Run:** CI #17 / 45158705058; branch `experiment/acx10-wdk20348-control`; commit `79460f03492a54444473589dd142da864a703a73`; build job `137638217372`.
- **Status at 2026-11-23 12:53 Kyiv:** PowerShell parser and project XML gates passed. EWDK ISO acquisition, ACX 1.0 stub inspection and build step still in progress. No artifact, stub-discovery result, build result or runtime result is claimed.
- **Method:** official Microsoft EWDK 20348.1 ISO, hosted Windows Server 2022 runner only. This changes both WDK and compiler generation (26100/VS2022 → 20348/VS2019), so it is a toolchain-bundle comparison, not a pure WDK-only A/B test.
- **Important audit point:** Microsoft documents mounting the EWDK ISO, running `LaunchBuildEnv.cmd`, then `SetupVSEnv`. The current script chooses `SetupBuildEnv.cmd` when found, otherwise `LaunchBuildEnv.cmd`, then calls `SetupVSEnv.cmd` if present. Verify the actual selected script and environment from the artifact before accepting any build failure/success as a toolchain result.
- **Next:** if ACX 1.0 stub/header and KMDF 1.31 libraries are present, compare hashes/descriptor fields/relocations with WDK 26100 and run the same probe on a fresh hosted Server 2022 runner. If the probe reaches DriverEntry, compare the WDF/ACX bind sequence with LDAC. If it fails similarly, inspect the old stub against the actual Server 2022 runtime bind contract. If no ACX 1.0 stub exists, record a blocked toolchain discovery; do not silently substitute ACX 1.1.

## D-016 — Reject simple WDF class-bind descriptor-size mismatch as the primary explanation

CI #16's actual Server 2022 Wdf01000 PDB reports `WDF_CLASS_BIND_INFO` base size 0x50 and `WDF_CLASS_BIND_INFO2` size 0x78. The WDK 26100 ACX 1.0 stub descriptor is 0x78 bytes. The ACX 1.0 CLASS_MODULE v1.0 is already present before the probe. Therefore neither a simple 0x78-vs-runtime-size mismatch nor absence of the ACX 1.0 class module explains the current Code 37. The exact invalid parameter inside `WdfVersionBindClass` remains unknown; inspect actual pointer/value semantics, class-version resolution and ACX class callback behavior. Do not repeat a size-only investigation.

## D-017 — Keep WDK 20348.1 strictly research-only

Microsoft lists WDK 20348.1 as unsupported and pairs it with VS2019. The legacy SDK/WDK installers are marked affected by CVE-2024-29187, while the EWDK distribution is marked not affected. Use only the official EWDK ISO for this isolated diagnostic experiment; never ship this kit or treat it as the production build toolchain. The supported current path when remaining on VS2022 is WDK 26100.6584.


## Decisions — 2026-11-23 strategy reset

### D-018 — Microsoft Windows 10 A2DP package is the primary first-milestone path
Reuse the complete signed Win10 A2DP source package to establish SBC stereo in a disposable Server 2022 VM. Do not develop a replacement Bluetooth/ACX driver while this package path is incomplete.

### D-019 — No Microsoft inbox LDAC DLL exists to transplant
Windows 10's documented built-in A2DP codec set is SBC and classic aptX; LDAC is not present. The project's AOSP `libldac` is source/static code, not a Win10 DLL and not a documented plug-in for `BthA2dp.sys`.

### D-020 — OPPO Enco Buds2 is an SBC milestone receiver, not an LDAC test sink
ETE41 supports AAC/SBC only. Windows 10's built-in stack and this headset share SBC. LDAC negotiation/audio requires a different LDAC-capable receiver.

### D-021 — ACX bind-probe is paused
CI #248 and #255 remain closed evidence. No new ACX AudioCodec bind-probe unless package and component analysis proves ACX bind is the necessary blocker.

### D-022 — No physical Server 2022 changes
Only read-only evidence may be collected from the physical host. All staging/install tests belong in a disposable Server 2022 VM. No BCD, test-signing, security, certificate, device restart, or OS changes.

### D-023 — BlueCaster is a fallback, not the primary path
BlueCaster offers a ready user-mode LDAC/SBC stack over WinUSB, but its published platform support is Windows 10 22H2 / Windows 11, not Server 2022, and it takes ownership of the selected adapter. Evaluate only in a disposable VM with a suitable adapter if the Microsoft package path fails.

### Experiment — WIN10-A2DP-PACKAGE-AUDIT
**Status:** PARTIAL — source/common/sink INFs and BthA2dp/BtaMPM binaries are captured; exact source system catalog and CBS/component ownership remain pending.  
**Entry criteria:** static INF/PE analysis can proceed from the existing 23:49 archive; WIM metadata and system-catalog identity are required before cross-SKU staging.  
**Required outputs:** SHA-256; PE machine/version/imports/delay-imports/exports; API-set and OS assumptions; INF Include/Needs graph; catalog signature and member verification; Server 2022 counterpart comparison.  
**No code or driver build is required for this audit.**

## Decisions — component-path audit, 2026-11-23 23:40

### D-024 — Do not treat an LDAC DLL as a Microsoft A2DP plug-in without a proven interface
Microsoft documents a PnP-selected WDM A2DP profile driver communicating with BthPort through IRPs/BRBs, and Windows 10's inbox codecs as SBC/aptX Classic. No user-mode codec-provider DLL hook is documented. A standalone LDAC encoder is not sufficient to extend `BthA2dp.sys`.

### D-025 — Keep Alternative A2DP and BlueCaster as fallback architectures only
Alternative A2DP is a third-party kernel driver with official support for Windows 10 22H2 / Windows 11, not Server 2022. BlueCaster is a user-mode BTstack/WinUSB stack for Windows 10 22H2 / Windows 11 that takes over a USB adapter. Neither is a Microsoft inbox DLL.

### D-026 — No ACX/WDK bind-probe until the component/package path proves ACX is the blocker
The next evidence gate is the complete Windows 10 A2DP package and its dependency closure. CI #248 and #255 remain closed historical evidence; no repeat bind-probe.


## Decisions — 2026-11-24 01:42 (component audit)

### D-027 — Do not treat the missing package-local .cat as an unsigned inbox package
The captured system-supplied A2DP INFs have no CatalogFile directive. Microsoft documents that system-supplied INFs are validated through system catalogs. Keep the source catalog identity/member proof as an open cross-SKU staging requirement, but do not repeat collection merely to find a package-local .cat.

### D-028 — Do not transplant or reverse-engineer Alternative A2DP Driver
The vendor advertises LDAC, but the EULA restricts reverse engineering/decompilation/disassembly/modification/transfer and the license is hardware-bound. Its OSS addendum lists AOSP components but does not identify the bundled files or grant rights to the proprietary driver; the project already has its own AOSP libldac source. Published OS support is Windows 10 22H2 / Windows 11 21H2–25H2, not Server 2022. No binary transplant or reverse engineering. Any Server evaluation requires vendor authorization and a suitable license.

### D-029 — Keep the two BthA2dp.sys copies separate
The DriverStore package copy (282,624 bytes, SHA-256 5FBA...) and the separate System32 copy (279,040 bytes, SHA-256 0442...) have different import reports. Do not use the System32 import table as the dependency list for the DriverStore package binary. Reconcile exact paths, versions and catalog membership first.

### D-030 — OPPO Enco Buds2 is not an LDAC-capable sink
The official ETE41 specification lists AAC/SBC only. Keep it for the SBC milestone; use a different LDAC-capable receiver for any LDAC negotiation/audio test.

### D-031 — WIM component ownership is the next evidence gate
The Win10 package capture is already present. Do not rerun the exporter or repeat Server file searches. Obtain Windows 10 22H2 and Server 2022 WIM/component metadata, resolve CBS package identities/MUMs/manifests/system catalogs and compare applicability before staging anything.

### D-032 — Keep APO/COM registrations separate from A2DP codec providers
The mssysfx path registers Windows audio-effect APOs (user-mode COM DSP objects). WMALFXGFXDSP.dll and SysFxUI.dll are not LDAC encoder/decoder DLLs. No Microsoft LDAC codec-provider CLSID or user-mode codec DLL has been identified.



### D-033 — Prioritize the updated DriverStore BthA2dp package copy
The 282,624-byte DriverStore copy (version 10.0.19041.4355, SHA 5FBA...) has a direct import report from ntoskrnl.exe only. The separate 279,040-byte System32 copy (likely 10.0.19041.1 by secondary size/version corroboration; SHA 0442...) has 8 import descriptors / 144 functions. Treat them as different servicing generations and use the DriverStore package copy as the primary Server compatibility candidate. Do not infer that its smaller import table eliminates dynamic or INF-level dependencies.


### D-034 — Interpret LOCALMFG as the local radio, not the remote OPPO device
Microsoft's Bluetooth PnP documentation defines LOCALMFG as the manufacturer of the local Bluetooth radio. Bluetooth SIG company ID 0x0002 is Intel and 0x005D is Realtek. Therefore the recorded BTHENUM 0x110B node's LOCALMFG&0002 identifies the host Intel radio; it does not identify OPPO. Do not infer remote-device vendor from this suffix.

### D-035 — Do not use the residual Realtek rtka2dp package for the current host
A rtka2dp.inf DriverStore folder exists, but its INF bytes/version were not captured and it is not the current oem75 binding. Public Realtek IDs use LOCALMFG&005D, while this host's local radio is LOCALMFG&0002 (Intel). Keep it as an unverified residue/reference only; do not install or adapt it for the OPPO path.


## Decisions added — 2026-11-24 02:19

### D-036 — Stop searching for a Microsoft Windows 10 inbox LDAC DLL
Microsoft's Windows 10 Classic Audio codec table lists SBC and aptX Classic, not LDAC. The captured A2DP path is a kernel profile-driver package. No Microsoft inbox LDAC codec DLL/provider exists in the documented path. Continue with that package for SBC; do not spend cycles looking for a nonexistent inbox LDAC DLL.

### D-037 — Treat BthA2dp as the profile/codec implementation, not a DLL host
The documented profile-driver model loads a PnP profile driver through INF and sends WDM IRPs/BRBs to BthPort. Older public BthA2dp symbols show internal SBC/aptX codec classes and AVDTP. No documented user-mode LDAC provider interface was found in the reviewed Windows 10 docs/INFs. Do not assume a standalone codec DLL can be registered into this stack.

### D-038 — Retire the legacy PE import report for dependency conclusions
The Library `pe_imports_a2dp.py` does not advance the IMAGE_IMPORT_DESCRIPTOR pointer by 20 bytes; its 1.3 MB output repeats the first descriptor. Preserve the file/report as historical evidence, but do not use them for imports, exports or dependency closure. Re-run with a retained corrected toolchain.

### D-039 — Keep AOSP libldac as encoder source, not as a Win10 binary
The existing project vendors AOSP `external/libldac` at `eeee1a3f` and statically links it into the custom service. It is not a Windows 10 DLL and does not by itself integrate with Microsoft's A2DP profile driver. Sony certification/licensing must be clarified before product distribution.

### D-040 — Evaluate BlueCaster only as a later, separate transport option
BlueCaster v3.0.4 already implements user-mode A2DP with LDAC through BTstack+WinUSB. It bypasses the Windows Bluetooth stack, takes over a USB adapter, does not list Server 2022 support, and includes BTstack with a personal/non-commercial license. It may be assessed in a disposable VM after SBC, but is not a drop-in DLL and must not be installed on the physical host.


## D-2026-11-24-01 — Prefer full UUP images over ad-hoc PSF reconstruction

The Catalog audit found that A2DP SYS entries in KB5036979/KB5126657 are PSF forward deltas. PSFExtractor v3.07 is MIT-licensed but its inspected PA30 path does not supply the RTM base file required for forward-delta reconstruction. 0xZ0F/Windows-Patch-Diff-Helpers handles forward deltas via msdelta.dll, but has no declared license; do not vendor it. Use exact full UUP images first, then revisit PSF reconstruction only if the full image route fails.

## D-2026-11-24-02 — Reject Winbindex symbol-server output as exact identity when SHA differs

The three downloaded files retained timestamp/size but returned different file versions and hashes. Treat Winbindex index metadata as a lookup lead only; a binary is accepted only when its SHA-256 matches the captured archive or a trusted full-image/package extraction.

## D-2026-11-24-03 — Keep ACX bind-probe paused

No evidence yet demonstrates that ACX binding is the blocker. The immediate task is exact Win10 component extraction, INF/CBS/registry mapping, and static Server export compatibility. CI #248 and #255 remain closed.


## D-2026-11-24-01 — Prefer full UUP images over ad-hoc PSF reconstruction

The Catalog audit found that A2DP SYS entries in KB5036979/KB5126657 are PSF forward deltas. PSFExtractor v3.07 is MIT-licensed but its inspected PA30 path does not supply the RTM base file required for forward-delta reconstruction. 0xZ0F/Windows-Patch-Diff-Helpers handles forward deltas via msdelta.dll, but has no declared license; do not vendor it. Use exact full UUP images first, then revisit PSF reconstruction only if the full image route fails.

## D-2026-11-24-02 — Reject Winbindex symbol-server output as exact identity when SHA differs

The three downloaded files retained timestamp/size but returned different file versions and hashes. Treat Winbindex index metadata as a lookup lead only; a binary is accepted only when its SHA-256 matches the captured archive or a trusted full-image/package extraction.

## D-2026-11-24-03 — Keep ACX bind-probe paused

No evidence yet demonstrates that ACX binding is the blocker. The immediate task is exact Win10 component extraction, INF/CBS/registry mapping, and static Server export compatibility. CI #248 and #255 remain closed.

## D-041 — Treat BtaMPM as a required package dependency, not a codec

The Windows 10 common A2DP INF includes BtaMpm.inf and needs BtaMPM.CopyFilesOnly. Candidate BthA2dp imports 10 BtaMPM functions. BtaMPM.sys is profile/multiprofile management, not the SBC/LDAC encoder. A package adaptation must include the matching BtaMPM dependency and registration.

## D-042 — Static export match is a gate, not a compatibility verdict

The non-exact Win10 symbol-server candidate has 129/149 BthA2dp imports matched against the available later Server 20348.5866 reference set and companion BtaMPM exports. Twenty imports remain untested because HAL/SleepStudyHelper/WDFLDR/ksecdd references were omitted. Candidate hashes differ from the captured files and the Server build differs from target 20348.5761. Do not declare compatibility until exact images and the complete dependency closure are audited.

## D-043 — Continue with existing Microsoft package before considering another transport

The first implementation hypothesis is to reuse the Windows 10 source/common A2DP INF, BthA2dp.sys and BtaMPM package components with existing Server KS/WDMAUDIO/MSSysFx dependencies, if exact imports, catalog and registration checks pass. Do not modify the kernel driver or create a shim unless a specific unresolved import/interface is proven.

## D-044 — Keep external LDAC projects as later alternatives only

BlueCaster is a user-mode BTstack+WinUSB stack, not a codec DLL for Microsoft A2DP; it takes over a USB radio, has no Server 2022 support claim and carries a personal/non-commercial BTstack license. OpenA2DP is pre-alpha and its kernel drivers have not been built/run against hardware. Neither replaces the current Win10 package/SBC investigation.

## D-045 — Never substitute a later BthA2dp import map for the captured package version

The captured DriverStore BthA2dp is 10.0.19041.4355 and E-119 reports direct imports from ntoskrnl only. The separate System32 copy and later symbol-server candidates have different hashes/import surfaces. All compatibility conclusions must be tied to the exact file SHA/version; revalidate the 19041.4355 package bytes against Server 20348.5761 before staging.

## D-046 — Stop searching for a hidden Microsoft/Sony inbox LDAC DLL

Sony's official support article says Windows has no system-level LDAC support regardless of Bluetooth controller. Keep the Windows 10 inbox package as the SBC milestone. For LDAC, evaluate a third-party A2DP transport/provider explicitly; do not spend more cycles searching arbitrary Windows 10 system folders for an inbox LDAC DLL.

## D-047 — BtaMPM import closure is promising but must be checked against exact Server 20348.5761

The captured BtaMPM 10.0.19041.5848 import set (42 symbols) matches the later 19041.7660 candidate and all names exist in Server 20348.5866 exports. Keep this as a partial static pass only. The target Server image is 20348.5761; exact exports and the exact BtaMPM export table are still required before staging.

## D-048 — Verify UUP image identity from the offline registry, not a DISM Version property

UUP audit #3 showed that the selected `Get-WindowsImage` object did not expose a `Version` property in the runner's DISM module. The script failed before mounting the image. The corrected path copies the mounted image's SOFTWARE hive to a temporary work file and checks CurrentBuild.UBR and EditionID. This verifies the actual image selected rather than relying on UUP metadata or a module-specific object property. The source image is mounted read-only.

## D-049 — Resolve BthA2dp profile-management imports against its matching Win10 BtaMPM companion

Server 2022 has no inbox BtaMPM.sys in the audited package set. If the Win10 BthA2dp binary imports BtaMPM entry points, those imports must be resolved against the matching Win10 companion BtaMPM.sys and then the companion's own imports resolved against Server exports. Do not count the absent Server BtaMPM as an unexplained kernel export gap.

## Experiment — UUP image audit #3 failure and rerun

- Run #3 / 45317582562 failed at the `Get-WindowsImage.Version` access before image mount; no PE/CBS/CAT result and no artifact.
- Commit 144d42105a26d5aa21f159ae068b17a047f724a9 added offline SOFTWARE-hive identity verification and HAL/SleepStudyHelper/WDFLDR/ksecdd references.
- Commit e947970356884ead996bcc7347fa0e5554aa770b added the matching Win10 BtaMPM companion to the reference directory.
- Runs #4 / 45325486392 and #5 / 45325586394 were in progress at this update. #5 is the latest experiment revision. No compatibility conclusion is accepted until exact image versions, hashes and reports are inspected.

## D-050 — Preserve Server Bluetooth core; evaluate the existing Win10 A2DP source/common INF as the minimal profile-layer adaptation

The archived Server 20348 `bth.inf` maps remote Audio Sink UUID 0x110B to a generic fallback hardware ID ending `_GENERIC`; its `BthGenericService.NT.Services` section installs a null associated service and its property section sets `GenericDriverInstalled`. It does not register the A2DP profile service.

The archived Win10 `microsoft_bluetooth_a2dp_src.inf` matches the base BTHENUM UUID 0x110B (remote A2DP Sink), then delegates to `microsoft_bluetooth_a2dp.inf` / `Common_BthA2dp_Install`. The common INF copies BthA2dp.sys, installs the demand-start BthA2dp service and registers KSCATEGORY_AUDIO interfaces while including the existing KS, WDMAUDIO, BtaMPM and MSSysFx registrations.

Therefore the first adaptation candidate is the existing Win10 A2DP source/common INF + its exact binaries, layered on Server's existing Bluetooth core. Do not replace BthPort/BthEnum or the radio miniport, and do not write a new driver unless later evidence proves a kernel blocker. This decision is limited to the static INF path; PE/CAT/CBS/rank compatibility and disposable-VM runtime remain gates.

## D-051 — Do not search for or register a Windows inbox LDAC provider DLL; the missing layer is A2DP transport/profile integration

The current fork already statically links Sony/AOSP libldac encoder 2.0.2 and its ABR helper into `ldacsvc_core`. Its `service/encoder.cpp` produces LDAC frames and hands them to the separate AVDTP media packetizer. The product does not need a separate LDAC encoder DLL.

The only decoder in the repo workflow is `libldacdec`, fetched and built by `tools/ldacverify` for offline verification. It is not a product dependency.

Incus Multicodec demonstrates a Windows `ldac.dll` build recipe, but the DLL is an encoder wrapper over the same libldac source, not a COM/KS codec provider or transport. Incus uses Bumble + WinUSB for its own A2DP stack; BlueCaster uses BTstack + WinUSB. These are user-mode alternatives that bypass the Windows A2DP profile and take over a USB adapter. Server 2022 support is unverified.

Therefore: finish the existing Win10 A2DP source/common INF path for SBC first. For LDAC, a real A2DP source must advertise the vendor codec in AVDTP and transport LDAC frames. Prefer evaluating the existing user-mode stack with a dedicated USB adapter over resuming the custom ACX driver. Do not attempt to register `ldac.dll` as an arbitrary Windows A2DP codec provider.


## D-052 — Treat absent PE delay-import hints as nullable metadata

Runs #4/#5 proved the UUP image identity path works for Server 20348.5761 but exposed a parser edge case: pefile can return a named delay-import symbol with `hint=None`. A missing hint is not a missing import and must not abort the audit or be coerced to zero. The isolated experiment parser now preserves null and has regression coverage. CI #6 passed the unit-test step; the UUP image audit remains pending. Do not infer any binary compatibility result from the #4/#5 harness failures.

## Experiment — UUP audit #4/#5 parser failure and #6 correction

- #4 / 45325486392 and #5 / 45325586394 both verified the Server 20348.5761 offline SOFTWARE hive, then failed at `int(None)` while parsing AudioEndpointBuilder.dll delay imports. No Win10 image, PE report, CAT/CBS result or artifact was produced.
- Isolated experiment commit `6778022b4453857e53acf8a18afe54bb7e46f5f5` added the nullable-hint fix and three regression tests; CI #6 / 45332165839 passed the tests.
- Full UUP audit #6 remains the active run. No driver/package staging, runtime test or physical-host action is authorized or performed.


## D-053 — Do not inject the full Client-Desktop-Required package into Server 2022

CI #463 MUM evidence shows that the Win10 A2DP common/source/sink and BtaMPM INF packages are declared as `dualModeDriver` entries owned by `Microsoft-Windows-Client-Desktop-Required-Package`. The Server KB5126655 catalog scan has no corresponding package references. This explains why the Server SKU lacks the profile package, but it does not establish whether the underlying signed driver package can be independently staged on Server.

Keep the minimal Win10 A2DP source/common package as the SBC candidate, but do not inject the entire client CBS package or manually copy SYS/INF files. First verify exact DriverStore/CAT membership, INF target decorations, OS applicability and whether PnPUtil/SetupAPI can stage the complete signed driver package independently in a disposable Server 2022 VM.


## D-054 — Exclude the reverse-direction A2DP sink INF from the SBC milestone

The user’s target is PC → OPPO Enco Buds2 playback. The Win10 source INF matches the remote A2DP Sink UUID 0x110B; the separate `microsoft_bluetooth_a2dp_snk.inf` installs the reverse direction (Windows acting as A2DP sink). The minimal candidate is `microsoft_bluetooth_a2dp_src.inf` + `microsoft_bluetooth_a2dp.inf` + required BtaMPM/KS/WDMAUDIO/MSSysFx dependencies. Do not stage the sink INF or HFP components. This is a static INF scope decision only; no staging/runtime result.


## D-055 — Keep third-party LDAC drivers as later-stage black-box candidates

Alternative A2DP Driver 1.8.3 is a ready commercial per-device A2DP driver with LDAC/SBC/ABR, using the Windows 10/11 inbox Bluetooth stack. Its official support matrix does not include Server 2022; its proprietary EULA prohibits redistribution and restricts reverse engineering/disassembly. Do not inspect, patch, redistribute or bypass licensing. If needed after SBC, evaluate only via the official trial in a disposable Server 2022 VM, with explicit user approval before any license purchase or physical-device change.

BlueCaster is an existing user-mode alternative using BTstack + WinUSB and a dedicated USB adapter. It takes the adapter away from Windows while active and its bundled BTstack is personal/non-commercial unless separately licensed. Keep it as a fallback, not the primary Microsoft-stack path.


## D-056 — Accept the exact Win10 A2DP binary static import-closure pass; proceed to catalog and staging gates

UUP audit #6 reproduced the exact archived Win10 DriverStore BthA2dp.sys 10.0.19041.4355 hash and showed all 149 static imports resolve against the exact Server 20348.5761 exports plus the matching Win10 BtaMPM.sys. Exact BtaMPM 10.0.19041.5848 has 42 imports/14 exports and all 42 imports resolve against Server. This removes a static import/export mismatch as the current blocker and supports testing the existing Win10 A2DP package without replacing Server's Bluetooth core.

The earlier E-119 claim that the exact DriverStore BthA2dp imports only ntoskrnl is superseded by E-169. Do not use the older report. Also correct the component map: BtaMpm.inf is CopyFilesOnly and does not register a separate service; BtaMPM.sys is an imported companion module, while BthA2dp is the demand-start service installed by the common INF.

This is not runtime compatibility proof. Catalog membership and SetupAPI applicability remain the immediate gates. Proceed only on a disposable Server 2022 CI/VM after the catalog audit; do not install or stage on the physical host. Keep server-2022-oppo and ACX work frozen.

## D-172 — Separate Win10 catalog membership from Server acceptance (2026-11-24)

CI #11 verifies that the five exact Win10 A2DP package files are members of one Win10 servicing catalog. This does not prove that Server 20348.5761 can validate the package: the A2DP INF files have no CatalogFile directive in the captured Version sections, and Microsoft documents that system-supplied INF signatures are validated against the OS's system-supplied catalogs. The Server catalog set must therefore be checked independently before any staging claim.

Decision:
- Preserve the original INF/SYS/CAT bytes.
- Do not add a CatalogFile line, regenerate a catalog, alter trust policy or touch the physical host.
- Run the isolated cross-SKU catalog audit; require positive Server controls.
- Only if catalog acceptance is still unresolved, test supported catalog registration/staging behavior in a disposable Server 2022 VM, without certificate-store changes.

The cross-SKU audit is implemented on experiment/win10-a2dp-cross-sku-catalog-audit-20261124; result pending.

## 2026-11-24 — cross-SKU catalog decision

**Decision:** Do not interpret the Server catalog no-match as proof that the original Win10 Microsoft CAT is untrusted. CI #12 proves only that the exact Win10 A2DP hashes are absent from the Server image's pre-registered system catalog set; it also proves the Server scan is valid via four Server Bluetooth positive controls.

**Next discriminating experiment:** On a disposable GitHub-hosted Server 2022 runner, explicitly verify the original Win10 CAT and its five members with SignTool. Then try PnPUtil staging of the original A2DP Source INF without /install. If the catalog is not discoverable, add the original CAT to the system component/driver catalog database using the documented SignTool catdb mechanism and retry; remove both the staged package and temporary catalog registration afterwards. This is a catalog-database experiment, not a certificate-store change. It is not authorized on the physical host.

The original INF/SYS/CAT bytes must remain unchanged. Do not add a CatalogFile line, fabricate a CAT, alter trust stores, enable test signing, or install/bind a device on the physical server.

Stage-smoke harness commits: 5b6ccfaed40ae75669ef74aad1e8de0d5284a0ef, 32fe8206781cdf41955348a18bf3671c998e71bb, 3305dddcb18f4e407e6b61762a2539a77412ea2d; workflow 692cb1a5e4df7de5ca0ebc72e61878c1c62df300. Run #1/#2 parser failures are harness-only; run #3 is in progress.


## 2026-11-24 — keep Server KS/WDMAUDIO components

CI #12 confirms Server ks.inf 10.0.20348.1 exposes KS.Registration and Server wdmaudio.inf 10.0.20348.5756 exposes WDMAUDIO.Registration and mssysfx.CopyFilesAndRegister. Their hashes differ from Win10, but the required INF sections exist in the target image.

Decision: do not transplant Win10 ks.inf, wdmaudio.inf, MSSysFx or related audio components. The minimal candidate package remains A2DP Source/common + BtaMPM companion, using the Server's existing KS/WDMAUDIO registration sections. This is static INF evidence only; staging/runtime remains unproven.


### Microsoft implementation references

- [INF Version section](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-version-section): system-supplied INF files omit CatalogFile because the OS validates them against system-supplied catalogs.
- [Installing a catalog with SignTool](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/installing-a-catalog-file-by-using-signtool): SignTool catdb adds/removes a catalog; by default it targets the system component and driver database.
- [PnPUtil command syntax](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax): /add-driver stages a package into DriverStore; /install is a separate flag that installs/updates matching devices. The stage-smoke harness deliberately omits /install.



## D-173 — Stage-smoke result must be labelled with the runner's actual UBR (2026-11-24 12:25 Europe/Kyiv)

The disposable workflow validates Windows Server 2022, CurrentBuild=20348 and InstallationType=Server, and records the runner UBR, but does not enforce UBR=5761. Therefore a successful stage result proves acceptance only on the exact UBR recorded in the artifact. If that UBR differs from the physical target's 5761, perform a separate exact-UBR disposable VM staging test before claiming 20348.5761-specific behavior. Do not change the active run's environment gate while it is executing.

## D-174 — Interpret SignTool catdb as catalog-database registration, not certificate-store modification

Microsoft documents that when neither `/d` nor `/g` is supplied, `signtool catdb` updates the system component and driver catalog database. `/u` only requests a unique catalog filename; it does not import a certificate or weaken trust policy. The stage-smoke operation remains limited to the disposable runner, with explicit cleanup. This does not authorize any equivalent operation on the physical Server.

## EXP-009 — Stage-smoke run #3 status review

Run [45371687882](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882), job 138367259323. Steps 1–6 passed; step 7 remains in progress. No package staging result or artifact is available yet. The experiment remains limited to original-CAT verification and DriverStore staging without `/install`; it does not test device binding, service start, driver load, endpoint or audio.

## D-175 — Treat stage-smoke #3 as a tooling failure, not a compatibility result

CI #3 [45371687882](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882) failed during offline image-audit collection with `The property 'Name' cannot be found on this object.` It mounted Win10 19045.5917 read-only, verified offline image identity and located the exact BtaMPM companion, but did not reach the stage-smoke function. There is no complete offline catalog-membership report or explicit stage-smoke/PnPUtil staging result. Do not classify this as rejection of the Microsoft A2DP package.

The outer catch had an unguarded `InvocationInfo.MyCommand.Name` access that could mask the originating error. Commit 4d5734fb adds safe error-field reads and per-subroutine markers. The exact failing subroutine remains unknown until CI #4's artifact/log is inspected.

## D-176 — Preserve the UBR boundary

The disposable CI #3 runner was 20348.5870, while the physical target is recorded as 20348.5761. A successful hosted staging result is evidence for its recorded UBR only. Do not claim exact 5761 acceptance without a disposable target matching that UBR. No OS update or physical-host action is authorized.


## 2026-11-24 — Do not hard-code one historical servicing CAT filename for stage smoke

CI #4 failed before SignTool/PnPUtil because the stage-only path required one exact historical CAT filename. CI #12 had previously verified the same five package files against that catalog, so CI #4 is a catalog-discovery inconsistency, not evidence that Server 2022 rejects the package. The experiment now searches Hidden/System catalog files and the CBS owner-package catalog candidates, verifies one common CAT against all five pinned file hashes, and records a blocked result with root inventory if no common catalog is found. Only after a common CAT and its signature verify on the disposable Server runner may PnPUtil staging without /install run. No changes to the original INF/SYS/CAT are permitted.
