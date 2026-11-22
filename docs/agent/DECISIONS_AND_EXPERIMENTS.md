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
- CI run #143: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45050062916; core and utility jobs passed, KMDF driver job still running at snapshot.
- This experiment is build/package-only. It cannot prove physical ACX class binding.
- Microsoft Target Platforms documentation explicitly lists Server 2022 for Universal drivers, so Universal is valid; the sample difference remains a low-priority A/B check.
- Result: PENDING CI completion.
