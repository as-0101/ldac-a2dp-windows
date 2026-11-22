# Decisions and experiment ledger

## Decisions

| ID | Decision | Rationale | State |
|---|---|---|---|
| D-001 | Keep the physical user's Server 2022 unchanged during investigation. | Avoid risking production Bluetooth/audio and system stability. | ACTIVE |
| D-002 | Keep ACX version as the isolated experimental variable. | Do not simultaneously alter DriverTargetPlatform, INF matching or KMDF version. | ACTIVE |
| D-003 | Keep `DriverTargetPlatform=Universal` for the ACX 1.0 experiment. | Avoid confounding variables; current evidence does not make Universal the leading cause. | ACTIVE |
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
