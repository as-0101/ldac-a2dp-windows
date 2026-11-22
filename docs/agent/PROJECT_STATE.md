## Investigation update — 2026-11-22 20:28 Kyiv

### WDF class-binding stage
- The preserved diagnostic is `FxStubBindClasses: VersionBindClass WDF_CLASS_BIND_INFO ..., class Acx, returned status 0xC000000D`. It names the `WdfVersionBindClass` path, not a `ClientBindClass` failure message.
- Microsoft's WDF source header `fxldr.h` describes `WdfVersionBindClass` as loading/referencing the class extension and linking it into the framework library list. The public WDF source repository does not include the WdfLdr implementation; the exact internal check returning `STATUS_INVALID_PARAMETER` remains unknown.
- ACX class-version mismatch remains the leading explanation (physical host class module Version 1.0 versus the successful run #129 client built against ACX 1.1). CI #133 ACX 1.0 is the isolated experiment; physical binding remains untested.

### Ruled out or demoted
- KMDF 1.31 client / WDF runtime 1.33 is supported by Microsoft's KMDF version history; the official `!acxkd` example shows the same client/runtime pair. Do not treat this as the cause.
- Universal is a supported driver target on Server 2022. CI #143 also built the Windows Driver target, but neither target has been physically compared. The claim that Universal is unsupported is false; runtime effect remains untested.
- `Class=Bluetooth` is appropriate for the BTHENUM profile devnode. The AudioCodec sample uses MEDIA because it is ROOT-enumerated; do not change the LDAC INF class based on that sample.
- ACX unload immediately before Event 227 remains correlation only, not causation.

### Current physical-host snapshot — read-only
- Windows Server 2022 Datacenter, build 20348, UBR 5761; `Acx01000.sys` file version 10.0.20348.3451.
- Test signing is already `Yes`.
- One present OPPO A2DP devnode; active INF `oem75.inf`, driver `0.2.325.1600`, Code 37 / `CM_PROB_FAILED_DRIVER_ENTRY`.
- CI #133 package is extracted under `C:\LDAC-Test\ACX10-Universal`. No certificate import, driver install, device restart, BCD change, or OS update has been performed.

### Hosted Server 2022 runner / LiveKD
- GitHub `windows-2022` runner build 20348 has `Acx01000.sys` file version 10.0.20348.5866 and `Wdf01000.sys` file version 1.33.20348.1. File version does not establish ACX class-module version.
- `Acx01000` is stopped by default on the hosted runner; `sc.exe start Acx01000` succeeded on the disposable runner only.
- CI #5 [45054287408](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054287408), commit `40d40d4b0300b708388c25f83e3fb2bc00c7b19e`, successfully captured a native LiveKD `-ml` dump and opened it with KD. `!wdfkd.wdfldr` could not resolve `wdfldr!WdfLdrGlobals` and required private WDF type information from the public symbol set; no runner `CLASS_MODULE` version was returned.
- Run #4 report 14767070902 is in Files Library at `/Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run4-report.zip` (Library ID `libfile_1c51ba296db8819195bef7905d6b0bb2`). Run #5 report 14766509597 is at `/Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run5-report.zip` (Library ID `libfile_f6b3dc250e70819180b85bfe0f78d3df`).
- Diagnostic branch: [research/acx-runtime-livekd](https://github.com/as-0101/ldac-a2dp-windows/tree/research/acx-runtime-livekd), latest workflow-only fix commit [02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3](https://github.com/as-0101/ldac-a2dp-windows/commit/02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3). CI #6/#7 were cancelled; CI #8 failed because LiveKD could not find kd.exe and did not create the expected dump. The fix commit has no observed CI run yet. No driver source or production branch changed.

### Debugger safety correction
- The earlier `Launch-WinDbg-Kernel.bat` launches WinDbg with `-kl` only. It does not configure local kernel debugging. Microsoft requires BCD `debug on`, local `dbgsettings`, and a reboot for `-kl`; do not run it as-is or enable BCD debugging on the physical host without separate authorization.
- Preferred alternative: Sysinternals LiveKD `-ml` native live-dump mode. CI #5 validated dump capture without BCD changes, but WDF loader symbol availability still blocks the runner class query.

### Immediate continuation
1. Finish CI #6/#7 and inspect whether direct LiveKD mode plus the configured symbol path changes the WDF extension result.
2. If public symbols still cannot expose `WdfLdrGlobals`, do not infer runner class version from `Acx01000.sys` file version. The physical host's prior `!wdfldr` output remains the direct evidence for that host.
3. If a fresh physical-host snapshot is needed, prepare a corrected LiveKD-based BAT using the user's existing debugger/symbol environment; it must not change BCD, install a driver, restart the OPPO devnode, or update Windows.
4. Do not run `prepare-oppo-host.cmd`, `upgrade-oppo.cmd`, `install-oppo.cmd`, or rollback without separate explicit authorization.

Repository probe record: [ACX_RUNTIME_LIVEKD_PROBE.md](ACX_RUNTIME_LIVEKD_PROBE.md).

## Investigation update — 2026-11-22 20:15 Kyiv

- The complete Notion research journal was re-read (18,840 characters); older status/action lists are historical and superseded by this snapshot and the current START HERE page.
- The physical host's ACX class module was previously observed as v1.0; the WDF client version was 1.31. The user has since launched WinDbg, but the current start page does not prove a live kernel attachment. Reconfirm `!wdfldr Acx01000.sys` in a genuine kernel-debugger session. Do not confuse ACX class version with WDF/KMDF version.
- CI #133 proves the ACX 1.0 branch compiles, links and packages on a Windows Server 2022 runner using WDK/SDK NuGet 10.0.26100.6584. The project selects ACX 1.0 headers and acxstub.lib through ACX_VERSION_MINOR=0; the captured build log does not echo expanded paths, but compile/link success is consistent with that selection. CI #133 is not a physical bind test.
- The LdacA2dp sources use none of the ACX 1.1-only DDIs listed in Microsoft's ACX version overview; scans of audio.c, driver.c and driver.h found no matches. CI #133 additionally compiles/links the full driver against the ACX 1.0 configuration.
- The Microsoft AudioCodec sample uses ACX 1.1, KMDF 1.31 and DriverTargetPlatform=Windows Driver; LdacA2dp uses KMDF 1.31 and Universal. Microsoft lists Server 2022 as supported for Universal drivers too, so this difference is not a proven cause. A one-variable A/B branch changes only the target platform.
- CI #143 / https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45050062916 for branch experiment/acx10-windowsdriver-platform, commit 6656e2d1fcda8d731f6795bd2e7a2950d5ba8309, completed successfully: all three jobs passed, including KMDF driver. The driver built on a Windows Server 2022 runner; signability reported no errors/warnings; final build reported 0 warnings and 0 errors. INF DriverVer was 0.2.326.1734. Draft PR #3: https://github.com/as-0101/ldac-a2dp-windows/pull/3; do not merge.
- Archived ETW shows ACX DriverInit returned status 0, then ACX unload completed; LDAC Event 227 returned 0xC000000D 23.5–33.7 microseconds later on the same kernel thread. This supports interpreting ACX unload as possible failed-bind cleanup, not as the cause; causality is not proven.
- Microsoft ACX version overview describes ACX 1.0 as pre-release and not recommended for new driver development; it lists ACX 1.1 as the public release for Windows 10 2004. The table does not list Server 2022. Treat ACX 1.0 as a host-specific compatibility experiment, not a general supported target.

# Project state — LDAC / OPPO Enco Buds2 on Windows Server 2022

**Snapshot date:** 2026-11-22  
**Status:** ACTIVE — ACX 1.0 experiment compiled successfully; physical-server bind test pending.  
**Scope:** Documentation and technical investigation for this project only.

## Goal

Achieve reliable Bluetooth A2DP audio playback using LDAC on the user's physical Windows Server 2022 Datacenter host with OPPO Enco Buds2. First acceptance milestone: stable SBC stereo. Do not enable HFP/microphone as part of this milestone.

## Target environment

- OS: Windows Server 2022 Datacenter, build 20348, UBR 5761 (read directly from the physical host on 2026-11-22).
- Headphones: OPPO Enco Buds2.
- Target A2DP devnode instance ends with peer MAC `840F2A13E3E2`.
- Last recorded active package after successful run #129 build: `oem75.inf`, driver version `0.2.325.1600`.
- Last directly observed device state (2026-11-22): `CM_PROB_FAILED_DRIVER_ENTRY`, Problem Code 37; `Get-PnpDevice` reports Status `Error`.
- `Acx01000.sys` file version: `10.0.20348.3451`. This is not the ACX class-module version.
- BCD `testsigning` is already `Yes`; the Windows test-mode watermark is visible. Do not enable it again.
- CI #133 package is extracted to `C:\LDAC-Test\ACX10-Universal`; INF version `0.2.326.1634` and driver SYS SHA-256 `435905e1553cb06d089f1477d1cff57c15bbeb84ef3141ca1b3b500a73898f3e` were verified. Read-only status reports the expected target instance, `oem75.inf`, and one present A2DP devnode.
- No physical-server changes were made by the ACX 1.0 documentation/CI investigation.

## Root failure — confirmed

The LDAC driver does not reach the first statement of `DriverEntry`. WDF class binding fails first:

`FxStubBindClasses / VersionBindClass / class Acx → 0xC000000D (STATUS_INVALID_PARAMETER)`

Kernel-PnP ETW Event 227 reported the same status. The earlier Driver Diagnostic also showed ACX initialization as a separate successful step and LDAC DriverEntry failure. Do not misstate this as a failure inside `AcxDriverInitialize`: the observed class-bind error occurs before the driver's `DriverEntry` body.

## Strongest explanation — supported, not yet proven

WinDbg `!wdfldr Acx01000.sys` on the physical host showed:
- WDF client version: 1.31.
- ACX `CLASS_MODULE Version`: 1.0.

The prior driver build in successful run #129 requested ACX 1.1:
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
- [GitHub Actions run #129 — ACX 1.1 / WDK 26100 baseline](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/44922058650)
- [CI #133 — ACX 1.0 experiment](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45044497961)
- [Draft PR #2](https://github.com/as-0101/ldac-a2dp-windows/pull/2)
- [Microsoft !acxkd documentation](https://learn.microsoft.com/windows-hardware/drivers/debuggercmds/-acxkd)
- [Microsoft ACX version overview](https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview)


## CI #133 package/binary review — 2026-11-22

Detailed static review: [CI133_PACKAGE_REVIEW.md](CI133_PACKAGE_REVIEW.md).

- Inspected nested test ZIP and compared its `LdacA2dp.sys` byte-for-byte with the CI #133 unsigned artifact; they are identical.
- Package INF DriverVer: `0.2.326.1634`; SYS SHA-256: `435905e1553cb06d089f1477d1cff57c15bbeb84ef3141ca1b3b500a73898f3e`.
- Compared PDBs: successful run #129 exposes 221 ACX `*TableIndex` symbols; CI #133 exposes 210. All 11 Microsoft-documented ACX 1.1-only DDI names occur in run #129 and are absent from #133. All 36 ACX calls used by this project are present in the CI #133 PDB table. This is strong binary evidence of a genuine ACX 1.0 API/stub build.
- Microsoft documents ACX 1.0 as pre-release (Windows 10 1903) and not recommended for new driver development; ACX 1.1 is the public release/current recommended version. Thus ACX 1.0 is a target-specific compatibility experiment, not a production-support claim.
- Current INF uses Class=Bluetooth; old `docs/stage5-audio-options.md` saying MEDIA is stale. Microsoft Bluetooth profile driver docs support the Bluetooth class; do not change class without a separate test.
- Earlier handoff recorded build 20348.2849 (2024-11), but direct host inspection on 2026-11-22 reports build 20348 / UBR 5761 and `Acx01000.sys` file version 10.0.20348.3451. These direct observations supersede the older host snapshot. Whether further servicing changes the ACX runtime/class module is UNKNOWN; treat OS servicing as a separate experiment and inspect `Acx01000.sys` / `!wdfldr` before deciding.
- No CI #133 package preparation, certificate import, BCD/testsigning change, device restart, driver installation, rollback, or OS update was performed. The already-existing `testsigning Yes` state was only read, not changed.


### CI #143 artifacts — persisted in Files Library

| Artifact | GitHub ID | SHA-256 | Files Library path | library_file_id |
|---|---:|---|---|---|
| Test package | 14764868818 | a82e4fd60cec5ed17eaff3e4a0897cf4b8181674e4a5933da380565ac5e4f757 | /Bluetooth LDAC Research/Artifacts/CI-143-ACX10-WindowsDriver-test.zip | libfile_4373693dd6488191ae530414a6771b2a |
| Unsigned driver | 14764794032 | 8d324266491d4c943b270db8f09e8a01341c428fb51a08c7ebdd7884c6bf70dc | /Bluetooth LDAC Research/Artifacts/CI-143-ACX10-WindowsDriver-driver-unsigned.zip | libfile_a459d41b27348191a9515efe8d31b3fc |

### CI #133 artifacts — persisted in Files Library

| Artifact | GitHub ID | SHA-256 | Files Library path | library_file_id |
|---|---:|---|---|---|
| Test package | 14763242251 | f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad | /Bluetooth LDAC Research/Artifacts/CI-133-ACX10-Universal-test.zip | libfile_fac18af78e50819181cc6ed246a9bb4a |
| Unsigned driver | 14763157658 | 1302c21c3278af9134b5959577a6daa629d0649fd1405148012e074e8147db9c | /Bluetooth LDAC Research/Artifacts/CI-133-ACX10-Universal-driver-unsigned.zip | libfile_950a60b65b38819193414b34670af657 |


## Physical test preparation — safety facts

- First candidate is CI #133 / Universal / ACX 1.0 because it isolates ACX version while keeping the original target platform. Do not use CI #143 for the first runtime test because it also changes DriverTargetPlatform.
- The test package's prepare script imports a CI-generated certificate into LocalMachine Root and TrustedPublisher, enables IHVDRIVER debug output (0xF), and sets BCD testsigning on; reboot required. It is a system-changing step and has not been executed.
- The upgrade tool requires an explicit confirmation token and checks exact OPPO MAC, single A2DP devnode, current LdacA2dp service/manufacturer, Server 2022 build 20348, candidate version and rank. It uses DiInstallDevice for the exact devnode.
- The package rollback selects inbox bth.inf; it does not restore the successful run #129 WDK 26100 baseline package. After rollback, testsigning and the test certificate require separate cleanup.
- See docs/agent/PHYSICAL_TEST_RUNBOOK.md. The package was copied/extracted and read-only diagnostics were run on the physical host; no driver/system configuration change has been made as part of this CI #133 test.

- Microsoft's official !acxkd sample shows CLIENT_MODULE WDF 1.31 over Wdf01000.sys runtime 1.33 with CLASS_MODULE ACX 1.1. This validates the observed WDF client/runtime pairing; the target's material difference is ACX CLASS_MODULE v1.0. Microsoft also warns that !acxkd has partial functionality under ACX 1.0.


## Continuation update — 2026-11-22 18:40 Kyiv

- Fresh physical PnP properties for the OPPO A2DP devnode: `oem75.inf`, driver `0.2.325.1600`, service `LdacA2dp`, Code 37 / `CM_PROB_FAILED_DRIVER_ENTRY`, and `DEVPKEY_Device_ProblemStatus=3221225485=0xC000000D (STATUS_INVALID_PARAMETER)`. This matches the earlier WDF class-bind status but does not alone prove the ACX-version mismatch.
- CI #6 (run 45054673989) and CI #7 (run 45054866734) were cancelled. LiveKD did start ACX on the disposable hosted runner and create a native live dump, but the interactive KD stage never produced WDF/ACX output; the uploaded report's debugger log contained only the log-open marker. Do not count these runs as class-version evidence.
- A further workflow-only correction was committed on research/acx-runtime-livekd as `02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3`: it adds the KD directory to PATH and uses a command file (-cf) for the separate KD inspection. No CI run has yet verified this change. CI #8 run 45056354003 failed: LiveKD reported Error finding kd.exe and the expected dump was not created; report artifact 14767208063.
- Microsoft documents `!wdfkd.wdfldr [DriverName]` in Wdfkd.dll; explicit `.load wdfkd.dll` may be needed. References: https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-wdfkd-wdfldr and https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/debugger-extensions-for-kmdf-drivers.
- Physical host remains unchanged: no driver install, cert import, BCD change, device restart, rollback, or OS update. CI #133 / Universal / ACX 1.0 remains first physical candidate, but installation still requires separate explicit authorization.


## Run provenance correction and current continuation — 2026-11-22 20:37 Kyiv

The successful WDK 26100.6584 ACX 1.1 baseline is GitHub Actions run #129, ID 44922058650, commit 4571873b505c52a93db4c785fe3d083eabf8499e. Actual workflow run #126 is ID 44922013678, commit ee417569fb4f7d14779af2597bc383b0ee53041a, and failed without artifacts. Existing Files Library filenames beginning CI-126 are legacy/mislabelled filenames for artifacts from run #129; use run #129 in new references. The PDB count of 221 ACX table-index symbols belongs to run #129.

Latest physical PnP properties: LdacA2dp / oem75.inf / DriverVer 0.2.325.1600 / ProblemCode 37 / ProblemStatus 0xC000000D. The DriverVer matches the successful run #129 build, but the installed SYS hash has not been compared. The successful WDK 26100 build and continuing error demote WDK pinning alone as the fix.

Latest full analysis: [2026-11-22 run #129 / PnP / LiveKD update](2026-11-22-RUN129-PNP-LIVEKD-UPDATE.md). It contains the exact run/artifact IDs, hashes, CI #6–#8 results, Library IDs and next action.

Current root-cause assessment: ACX class version mismatch (driver 1.1 versus physical host class 1.0) remains SUPPORTED, not proven. INF/service selection, Bluetooth setup class, Universal target and KMDF 1.31/runtime 1.33 are not leading suspects.

Next action: read-only status pre-check for CI #133 / Universal / ACX 1.0 after extraction to C:\\LDAC-Test\\ACX10-Universal. No prepare, certificate import, upgrade, device restart, rollback, BCD change, driver change or OS update without separate explicit authorization.


## LiveKD run #9 and next class query — 2026-11-22 20:44 Kyiv

[Run #9](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45056585788), commit 02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3, completed successfully. LiveKD captured a native dump; KD opened it and loaded Acx01000.sys symbols. Unqualified !wdfldr showed Wdf01000.sys runtime v1.33 and 43 associated clients. The first unnamed client was WDF v1.31 at the exact Acx01000.sys image base and size. This is consistent with ACX being a WDF 1.31 client on WDF runtime 1.33 on the hosted runner, but does not reveal the ACX CLASS_MODULE version.

The command !wdfkd.wdfldr Acx01000.sys returned “Unable to find the specified WDF driver”. Microsoft's official [!acxkd documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd) demonstrates the correct class-binding query as !wdfldr acx01000, which prints CLIENT_MODULE and CLASS_MODULE including the ACX Version field.

Follow-up workflow commit [218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383](https://github.com/as-0101/ldac-a2dp-windows/commit/218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383) adds that exact command to the KD script. No CI run had yet been observed for this commit. Hosted runner ACX class version remains UNKNOWN.

Run #9 artifact 14768155168, SHA-256 bb29ddd8613eb94d350c6ad08818369d8c169ebd962ec6796f28939955687d8c, Files Library ID libfile_574b6bc225f08191acf43df2c939095c, path /Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run9-report.zip. Full analysis: [2026-11-22-LIVEKD-RUN9-UPDATE.md](2026-11-22-LIVEKD-RUN9-UPDATE.md).

Next action: inspect the run triggered by commit 218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383. Do not infer hosted ACX class version from file version or from unqualified !wdfldr output. Physical server remains unchanged; the CI #133 ACX 1.0 test is still gated by read-only pre-check and explicit authorization.
