# Project state — LDAC / OPPO Enco Buds2 on Windows Server 2022

**Snapshot date:** 2026-11-22  
**Status:** ACTIVE — ACX 1.0 experiment compiled successfully; physical-server bind test pending.  
**Scope:** Documentation and technical investigation for this project only.

## Goal

Achieve reliable Bluetooth A2DP audio playback using LDAC on the user's physical Windows Server 2022 Datacenter host with OPPO Enco Buds2. First acceptance milestone: stable SBC stereo. Do not enable HFP/microphone as part of this milestone.

## Target environment

- OS: Windows Server 2022 Datacenter, build 20348.2849 (recorded in the Notion handoff).
- Headphones: OPPO Enco Buds2.
- Target A2DP devnode instance ends with peer MAC `840F2A13E3E2`.
- Last recorded active package after CI #126 upgrade: `oem75.inf`, driver version `0.2.325.1600`.
- Last recorded device state: Problem Code 37 / `CM_PROB_FAILED_DRIVER_ENTRY`.
- No physical-server changes were made by the ACX 1.0 documentation/CI investigation.

## Root failure — confirmed

The LDAC driver does not reach the first statement of `DriverEntry`. WDF class binding fails first:

`FxStubBindClasses / VersionBindClass / class Acx → 0xC000000D (STATUS_INVALID_PARAMETER)`

Kernel-PnP ETW Event 227 reported the same status. The earlier Driver Diagnostic also showed ACX initialization as a separate successful step and LDAC DriverEntry failure. Do not misstate this as a failure inside `AcxDriverInitialize`: the observed class-bind error occurs before the driver's `DriverEntry` body.

## Strongest explanation — supported, not yet proven

WinDbg `!wdfldr Acx01000.sys` on the physical host showed:
- WDF client version: 1.31.
- ACX `CLASS_MODULE Version`: 1.0.

The prior driver build in CI #126 requested ACX 1.1:
- `ACX_VERSION_MAJOR=1`, `ACX_VERSION_MINOR=1`;
- include path resolves to `acx/km/1.1`;
- link dependency resolves to `acx/km/1.1/acxstub.lib`.

This mismatch is consistent with the pre-DriverEntry ACX class-bind failure. It is not yet proven to be the sole cause.

## ACX 1.0 experiment — new verified CI result

- Branch: [experiment/acx10-server2022-bind](https://github.com/as-0101/ldac-a2dp-windows/tree/experiment/acx10-server2022-bind)
- Experiment commit: [593e8f407ec18e72a332edbec323a4ddbbd27774](https://github.com/as-0101/ldac-a2dp-windows/commit/593e8f407ec18e72a332edbec323a4ddbbd27774)
- Change scope: only `driver/LdacA2dp/LdacA2dp.vcxproj` and `driver/LdacA2dp/driver.c`; ACX minor version and runtime availability gate set to 0 / 1.0. PR #2 changed-file listing independently confirms those two paths.
- PR: [#2 — Test ACX 1.0 class binding on Server 2022](https://github.com/as-0101/ldac-a2dp-windows/pull/2), draft; do not merge.
- CI: [run #133](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45044497961), completed / success, 2026-11-22.
- CI head SHA: `593e8f407ec18e72a332edbec323a4ddbbd27774`.
- CI checked out PR merge commit: `c82dd8ab85496afce4d5b1000bd0ba1bdad87544` (merge of experiment commit into base `4571873b505c52a93db4c785fe3d083eabf8499e`).
- Jobs: KMDF driver — success; protocol core/codecs/service/tests — success; settings utility — success.
- KMDF job ran on Windows Server 2022 runner, OS build 20348, and restored WDK/SDK NuGet 10.0.26100.6584.
- Driver build emitted `LdacA2dp.sys`; Signability test reported no errors and no warnings; final build log reported 0 warnings and 0 errors.
- Stamped INF version: `0.2.326.1634`.
- The project still declares `DriverTargetPlatform=Universal`; it was intentionally not changed.

### Run #133 artifacts

| Artifact | ID | Size | SHA-256 digest | Retention |
|---|---:|---:|---|---|
| `ldac-a2dp-oppo-server2022-test` | 14763242251 | 195,308 B | `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad` | expires 2026-11-29 |
| `ldac-a2dp-driver-unsigned` | 14763157658 | 336,195 B | `1302c21c3278af9134b5959577a6daa629d0649fd1405148012e074e8147db9c` | expires 2026-11-29 |
| `bluetooth-sdp-probe` | 14762557767 | 99,600 B | `682207e171ef4be02328e28e7020b2da8344f9c3c1673246433fcce3598123fc` | expires 2026-11-29 |

The test ZIP was downloaded into this ChatGPT conversation as `ldac-acx10-server2022-run133-test.zip` (uploaded file ID `file_000000005ce88210aee5ec8ca8456b1b`). GitHub artifacts are temporary; preserve a durable copy before expiry if needed.

## What CI success proves — and does not prove

Proves: the ACX 1.0 code compiles with the pinned WDK/SDK; the CI driver package is assembled; the three workflow jobs complete successfully.

Does not prove: the physical host loads this package, ACX class binding succeeds, `DriverEntry` executes, ACX device/circuit creation succeeds, or Bluetooth audio works.

The CI job log does show a Windows Server 2022 build runner (10.0.20348), NuGet restore of WDK/SDK 10.0.26100.6584, successful `build_driver.cmd Release`, and zero warnings/errors. The job log does not print the expanded MSBuild include/link paths, so the exact resolved `acx/km/1.0` path should still be verified from build diagnostics or the downloaded package/build metadata rather than claimed as directly logged.

## Caveats and excluded directions

- KMDF 1.31 client versus WDF runtime 1.33 is not established as the cause.
- ACX runtime `Acx01000.sys` successfully initialized/registered as a WDF client; do not label runtime startup itself as the cause.
- ACX unload immediately before the LDAC failure is temporal correlation only.
- `DriverTargetPlatform=Universal` is not the current leading suspect; keep it constant during the ACX version experiment.
- INF device matching has been exercised and the device bound to `oem75.inf`; current failure is driver start/class binding, not discovery.
- Certificate / Secure Boot is not the current branch of investigation; do not reopen absent new evidence.
- `PeerInitialize()` was reviewed and was not a plausible NTSTATUS source in the observed pre-DriverEntry failure.

## Canonical research sources

- [Notion research journal](https://app.notion.com/p/41f769fff636810fbd50c285bc3d33f6)
- [Notion handoff and artifact index](https://app.notion.com/p/420769fff636812ab023c0fb67c66a5a)
- [CI #126 — ACX 1.1 / WDK 26100 baseline](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/44922058650)
- [CI #133 — ACX 1.0 experiment](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45044497961)
- [Draft PR #2](https://github.com/as-0101/ldac-a2dp-windows/pull/2)
- [Microsoft !acxkd documentation](https://learn.microsoft.com/windows-hardware/drivers/debuggercmds/-acxkd)
- [Microsoft ACX version overview](https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview)
