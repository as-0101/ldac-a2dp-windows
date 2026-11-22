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
