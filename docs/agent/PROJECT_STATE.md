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


## Hosted Server 2022 ACX class version — 2026-11-22 20:48 Kyiv

[LiveKD run #10](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45057090987), commit 218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383, successfully executed the documented !wdfldr acx01000 query. It returned CLIENT_MODULE Acx01000.sys with WDF v1.31 bound to Wdf01000.sys runtime v1.33, and CLASS_MODULE Acx01000.sys with WDF v1.31 / Version v1.0. The class module's client list is empty on the runner because no ACX client driver was loaded.

This matches the physical host's earlier CLASS_MODULE Version v1.0 / WDF 1.31 / runtime 1.33 output. The hosted Server 2022 image independently confirms ACX class v1.0. Therefore the ACX 1.1 LDAC client versus ACX 1.0 Server 2022 class mismatch is STRONGLY SUPPORTED as the leading explanation for the pre-DriverEntry STATUS_INVALID_PARAMETER; other binding metadata mismatches are not excluded.

Run #10 artifact 14768205866, SHA-256 aed85ff189ca817191383edb38945f69c27e50a86832ea8819c2e3b42674ade7, Files Library ID libfile_4ab21e3426e0819190b2fa201822980c, path /Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run10-report.zip. Full report: [2026-11-22-LIVEKD-RUN10-ACX-VERSION.md](2026-11-22-LIVEKD-RUN10-ACX-VERSION.md).

Hosted class-version uncertainty is resolved. Next discriminating test is CI #133 / Universal / ACX 1.0 on the physical host, gated by the read-only package status pre-check and separate explicit authorization. No physical server changes have been made.


## UBR 5870 comparison and hosted ACX 1.0 load test — 2026-11-22 21:02 Kyiv

Metadata run #12 / 45057605446 confirms a more recently serviced hosted Server 2022 Datacenter image: UBR 5870, KB5070761 installed 2026-11-19, Acx01000.sys 10.0.20348.5866 (SHA-256 D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0), Wdf01000.sys 1.33.20348.1 (SHA-256 32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B), BCD testsigning Yes. Run #10 measured CLASS_MODULE v1.0 on this image. Physical host UBR 5761 / Acx01000.sys 10.0.20348.3451 also has CLASS_MODULE v1.0. This strongly weakens OS servicing as a route to ACX 1.1; file version is not class version.

Separate branch experiment/acx10-hosted-load preflight run #1 / 45058127024 verified the CI #133 package, DriverVer 0.2.326.1634, SYS SHA-256 435905E1553CB06D089F1477D1CFF57C15BBEB84EF3141CA1B3B500A73898F3E, test certificate thumbprint 4A4E17BFC74DBE7220CA0606763FB81BA85A947B, test signing Yes, and DevGen availability.

Build run #230 / 45058265287 on commit 86a1d46aa7c4bc3561e96ded77442b03b34789f0 adds a disposable-runner ACX 1.0 load test: create an SWD device with BTHENUM A2DP IDs, import the test certificate, install the INF, capture PnP state/events, then inspect !wdfldr acx01000 clients. No prepare script or BCD change is used. Run #230 was in progress at the time of this update.

Full report: [2026-11-22-UBR5870-ACX10-HOSTED-PREFLIGHT.md](2026-11-22-UBR5870-ACX10-HOSTED-PREFLIGHT.md). Next: inspect run #230; if it proves ACX 1.0 driver binding on the hosted image, request only the read-only pre-check for the physical package before any separate authorization.


## LiveKD mirror dump: direct ACX class version confirmed — 2026-11-22 21:11 Kyiv

- [CI #15](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45058924588), commit `d12012c29d8b35b4bac23e84d43fa00ebedebb6d`, completed successfully. LiveKD switched from native `-ml` dump to kernel mirror `-m`; captured a 698,843,136-byte mirror dump; KD inspection and artifact upload succeeded.
- Artifact [acx-runtime-livekd-report](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45058924588/artifacts/14768915976), ID `14768915976`, SHA-256 `d3545973de7d13d2d864172c790cfcfecaf65fddb344b1e3ddab21aa2027a580`.
- Direct `!wdfkd.wdfldr Acx01000.sys` and `!wdfldr acx01000` output: CLIENT_MODULE `Acx01000.sys`, WDF v1.31; CLASS_MODULE `Acx01000.sys`, WDF v1.31, **Version v1.0**. WDF runtime `Wdf01000.sys` v1.33. Hosted Server 2022 runner UBR 5870, `Acx01000.sys` file version 10.0.20348.5866. Physical host's previous direct WinDbg output also showed CLASS_MODULE v1.0 at UBR 5761 / file version 10.0.20348.3451.
- ACX 1.1 client versus ACX 1.0 class mismatch is strongly supported as the leading explanation for pre-DriverEntry `STATUS_INVALID_PARAMETER`; it is not yet proven as the sole cause. Do not conflate WDF client/runtime versions with ACX class version.

## Disposable hosted ACX 1.0 load probe — 2026-11-22 21:11 Kyiv

- Initial run [#230](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45058265287), commit `86a1d46aa7c4bc3561e96ded77442b03b34789f0`, built the three standard jobs successfully, but hosted-load preflight failed before certificate import or synthetic device creation. The workflow hardcoded DriverVer `0.2.326.1634`, while the package generated by that run had DriverVer `0.2.326.1901`. This was a workflow validation defect, not a driver failure. No driver install was attempted.
- Follow-up changed preflight to parse the actual four-part DriverVer and verify ACX_VERSION_MAJOR=1 / ACX_VERSION_MINOR=0. Latest branch commit [4072681ae7d68c4dd9aabd34d613a3fa2f15487b](https://github.com/as-0101/ldac-a2dp-windows/commit/4072681ae7d68c4dd9aabd34d613a3fa2f15487b).
- Corrected run [#243](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45059251135) is in progress; three build jobs passed and hosted-load job reached WDK tool discovery at last observation. Await result before deciding next correction.
- Physical host remains unchanged: no driver install, certificate import, BCD change, device restart, rollback, or OS update.

## Continuation update — 2026-11-22 21:30 Kyiv

### New hosted runtime baseline and official documentation
- LiveKD run #15: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45058924588, commit d12012c29d8b35b4bac23e84d43fa00ebedebb6d, artifact 14768915976 (SHA-256 d3545973de7d13d2d864172c790cfcfecaf65fddb344b1e3ddab21aa2027a580). On hosted Server 2022 build 20348 / UBR 5870, Acx01000.sys 10.0.20348.5866 and WDF runtime 1.33; !wdfldr acx01000 showed ACX CLIENT_MODULE WDF 1.31 and CLASS_MODULE version 1.0. Full LiveKD mirror and KD inspection succeeded. This is hosted-runner evidence, not a refresh of the physical host.
- Microsoft ACX Version Information: ACX 1.1 is current/recommended; ACX 1.0 is pre-release and not recommended for new driver development. Microsoft says the ACX version range is specified at compile time and the driver fails to load if the runtime lacks the required range. This strongly supports, but does not yet prove, ACX 1.1 client versus ACX 1.0 class module as the reason for pre-DriverEntry STATUS_INVALID_PARAMETER. https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/acx-version-overview
- Microsoft target-platform docs explicitly list Universal driver support on Windows Server 2022 and say any driver target category can call DDIs documented as Universal. https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/target-platforms
- Microsoft !acxkd docs say ACX debugger extension functionality is partial under ACX 1.0. Use !wdfkd.wdfldr / !wdfldr acx01000 for the decisive binding/version query. https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd

### Artifact-level comparison: DriverTargetPlatform is demoted
- CI #133 Universal package artifact 14763242251, outer SHA-256 f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad, SYS SHA-256 435905e1553cb06d089f1477d1cff57c15bbeb84ef3141ca1b3b500a73898f3e.
- CI #143 Windows Driver package artifact 14764868818, outer SHA-256 a82e4fd60cec5ed17eaff3e4a0897cf4b8181674e4a5933da380565ac5e4f757, SYS SHA-256 27ec20f477735d5271ffc70955fcae051647b788c4b7abecfd48ba577b237fa0.
- Both SYS files are 60,928 bytes with identical section sizes, SizeOfImage 0x15000, entry point 0xA380, and imports. Only 24 bytes differ, all PE timestamp/checksum and debug/PDB metadata; no code-section difference. The two INF files are 5,030 bytes and byte-identical after normalizing the generated DriverVer line.
- CI #243's ACX 1.0 / Universal SYS is likewise identical to CI #133 except those 24 build/debug metadata bytes; its INF is identical after DriverVer normalization. Therefore the hosted candidate carries the same code as the original CI #133 physical-test candidate; only generated build metadata and per-build catalog signature/certificate differ.
- Result: DriverTargetPlatform Universal -> Windows Driver did not materially change the SYS or INF in these builds. It is very unlikely to explain FxStubBindClasses. Do not spend another runtime run on this variable absent contrary evidence.

### Hosted ACX 1.0 load-probe attempts
- CI #230 / run 45058265287, commit 86a1d46aa7c4bc3561e96ded77442b03b34789f0: build/package succeeded, but preflight failed because generated DriverVer was 0.2.326.1901, not stale pinned 0.2.326.1634. No cert import, DevGen, driver install or load attempt.
- Corrected preflight in commit 4072681ae7d68c4dd9aabd34d613a3fa2f15487b; it parses DriverVer and asserts ACX 1.0 source. CI #243 / run 45059251135 built package DriverVer 0.2.326.1912, SYS SHA-256 c9db4758bb39a2f4196d429daa83030a3a715db61c9583034cee4fea77a4a6c9. Preflight passed version/source assertions but failed because workflow pinned the certificate thumbprint to CI #133's old value.
- tools/stand/package-oppo-test.ps1 calls New-SelfSignedCertificate on each build, so each package has a new SHA-1 thumbprint. CI #243's expected-subject self-signed cert had thumbprint 36244BA5976015FBAEC9A795A7447021C41F6831; this is normal per-build variation. CI #243 report artifact 14769201114, SHA-256 67b767c6ed629c4ea940aa2e66498e7ae1b1088affbc82aa9311e6efc06c510d. It contains no ACX or LDAC module because install was skipped; it is not a driver test result.
- Commit da1beefc54454d85aa6aa59429860f49cb4b63f7 removes unnecessary WDK NuGet restore from hosted test job, locates preinstalled DevGen, enables IHVDRIVER DbgPrint on disposable runner, adds !dbgprint, and fixes DevGen removal to use actual instance ID. CI #245 / run 45059537525 also stopped at stale thumbprint check before device creation.
- Latest correction commit a0f16887e9241734d2c9b41903f77f850d18861c: validate exact certificate subject/self-signed issuer/validity, record dynamic thumbprint, verify it again before import, and remove that exact thumbprint during cleanup. CI #246 https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45059761087 is running this version; no load result yet.

### Microsoft AudioCodec sample comparison
- Official sample AudioCodec.vcxproj blob 0cdc9e6154c6340d384c8b07550d6ecf11a2e6d3: ACX 1.1, KMDF 1.31, DriverTargetPlatform=Windows Driver, acxstub.lib from ACX 1.1.
- AudioCodec.inf blob 0bc5fe2314b32e30e13827e3d421911048d8f579: Class=MEDIA, KmdfService and KmdfLibraryVersion. Our Bluetooth driver should remain Class=Bluetooth; sample's MEDIA class is not a template for BTHENUM.
- Driver.cpp blob 452b0d99eaf24451d965bd1b0f3ef140417e6d98 calls WdfDriverCreate before AcxDriverInitialize, matching our DriverEntry order. Current failure is before DriverEntry, so later function-body ordering cannot explain it.

### Exact next action
1. Poll CI #246 / run 45059761087, wait for the ACX 1.0 driver load on disposable Server 2022 runner job, and inspect preflight JSON, DevGen output, pnputil result, PnP properties, Kernel-PnP 219/227, WDF binding output and !dbgprint.
2. Only count the test if candidate INF was actually selected for the synthetic device and a load attempt occurred. An empty ACX ClientsList with no package selection/device start is not evidence.
3. If pnputil does not select the candidate, inspect driver ranking and use an isolated CI-only SetupAPI selection path if needed; do not relax physical-host guards.
4. Keep fix/server2022-acx-wdk-26100 unchanged (head 4571873b505c52a93db4c785fe3d083eabf8499e). Physical server remains unchanged: no certificate import, BCD change, driver install, device restart, rollback, reboot or OS update.

## Continuation update — 2026-11-22 21:40 Kyiv

### CI #246: first actual ACX 1.0 PnP install attempt
- Run 45059761087, commit a0f16887e9241734d2c9b41903f77f850d18861c, workflow-level conclusion success. Hosted job created the SWD device and PnPUtil installed the candidate package on it; this was not a package-selection failure.
- Test package artifact 14768758339, outer SHA-256 183d99aef49ac8e54d42b63d76d84b248e5fef3a1d36f2c281bc4525b9f16642. DriverVer 0.2.326.1917, ACX source 1.0, INF SHA-256 3D15A01E64DD74A59DDFE79AF934F8F9AF1E47350CB8CE1176511EFEFC100E32, SYS SHA-256 557A2F15AF6002F6EB2CCE0092D9689CC66CD2E97A5E4796FAF767ABDA3270A0, per-build certificate thumbprint 7F5222BB765A61F1B6EEDB6A55283BE5E5E12D24.
- PnP selected oem13.inf, DriverVersion 0.2.326.1917, Provider LDAC A2DP Project, Service LdacA2dp. Device SWDDEVGENLDAC_A2DP_CI_TEST: CM_PROB_FAILED_DRIVER_ENTRY / Code 37, ProblemStatus 0xC000000D. System Kernel-PnP Event 219 reported LdacA2dp failed to load. Service LdacA2dp remained STOPPED (Win32 exit 1077).
- Post-load mirror dump: no Acx01000.sys or LdacA2dp.sys in loaded-module list; WDF debugger could not find either; !dbgprint buffer empty. No DriverEntry evidence.
- Critical caveat: this run did not start Acx01000 before installing the candidate. Thus the dump did not establish that ACX CLASS_MODULE v1.0 was active during the test. The 0xC000000D is concerning and matches the physical host, but this is not yet a conclusive rejection of ACX 1.0 compatibility.
- Report artifact 14769346346, SHA-256 4816e9c80583597c546b720fa173f679271f8baf1d1981f85738ff4fe86f597e. DevGen removal returned 0x490; cleanup fallback is being added.

### Next controlled test
- Workflow commit 3d1d5d7e179da3379013b10f9863066200c459b6 starts Acx01000 explicitly on the disposable runner before pnputil, verifies RUNNING, records the runtime SYS version/hash and service state before/after, queries enabled Kernel-PnP event logs 219/227, and captures the SetupAPI install log.
- Cleanup falls back to pnputil /remove-device if DevGen /remove fails, then checks whether the synthetic device remains.
- CI #248 / run 45060225420 is queued for this exact revision. Poll it next. If Acx01000 remains active and CLASS_MODULE v1.0 is shown during the load attempt but the ACX 1.0 client still gets 0xC000000D before DriverEntry, the simple ACX-version mismatch hypothesis is insufficient; investigate the actual WDF bind metadata and service configuration. If DriverEntry appears, the previous hosted run was invalid because ACX runtime was not active.
- Source check: current driver.c explicitly logs DriverEntry started, WdfDriverCreate, AcxDriverInitialize(ACX 1.0), AcxDriverIsVersionAvailable(1.0), and DriverEntry completed. The project file has a single ACX_VERSION_MAJOR=1 / ACX_VERSION_MINOR=0 property, include path and acxstub.lib path are parameterized by those values. build_driver.cmd comment still says ACX 1.1; it is stale documentation only and should be corrected on the experiment branch.
- Physical host unchanged. No user-server certificate import, driver installation, BCD change, device restart, rollback, reboot, or OS update.

## Continuation update — 2026-11-22 21:45 Kyiv

### CI #248: ACX service started before driver load; ACX 1.0 candidate still fails
- Run 45060225420, commit 3d1d5d7e179da3379013b10f9863066200c459b6. The hosted job explicitly started Acx01000 and verified RUNNING before installing the candidate.
- ACX runtime file on runner: 10.0.20348.5866, SHA-256 D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0. This is exactly the same file/hash as LiveKD baseline #15, where !wdfldr reported ACX CLASS_MODULE v1.0 and ACX's WDF client v1.31 over WDF runtime 1.33.
- PnP selected the candidate oem13.inf (DriverVer 0.2.326.1920, provider LDAC A2DP Project, service LdacA2dp). SetupAPI confirms it outranked inbox bth.inf (rank 00FF2000 versus 00FF3001), and the device start was attempted.
- Device still ended at Code 37 / CM_PROB_FAILED_DRIVER_ENTRY, ProblemStatus 0xC000000D. Kernel-PnP Event 219 reported the load failure. No Event 227 was found in the queried event logs.
- After the failed attempt, Acx01000 service was STOPPED with Win32 exit 31 (0x1F); LdacA2dp also stopped. Post-load full mirror had neither module; WDF debugger could not find them; !dbgprint buffer empty. No DriverEntry evidence. ACX unload after failure is timing evidence only, not causality.
- Cleanup: DevGen /remove failed; pnputil /remove-device fallback succeeded. Report artifact 14769048266, SHA-256 e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb. Test package artifact 14768714620, SHA-256 b1ac0c4bd52bc965e549de18c584655331e7c7d58cdc9a02acb35e17528f175c; unsigned driver artifact 14769077870, SHA-256 a021fbdd49e803e88f1e7860859d9299ab5112394b39e2204107e72d6400fbc8.

### Interpretation
- This is a valid negative test for the actual ACX 1.0 driver binary with Acx01000 active before PnP start. The simple ACX 1.1-versus-1.0 mismatch hypothesis is insufficient by itself: ACX 1.0 build still fails before DriverEntry.
- INF/service registration and package selection are substantially demoted: SetupAPI selected the exact Bluetooth INF, created the LdacA2dp service, and attempted device start. DriverTargetPlatform is demoted by the CI #133/#143 artifact comparison. WDF 1.31 over runtime 1.33 is still not implicated by evidence.
- Current source check: driver.c logs DriverEntry started, WdfDriverCreate, AcxDriverInitialize(ACX 1.0), AcxDriverIsVersionAvailable(1.0), and DriverEntry completed. The project has one ACX_VERSION_MAJOR=1 / ACX_VERSION_MINOR=0 property and parameterized 1.0 include/link paths. The binary contains the ACX 1.0 strings and matches CI #133 code except PE/debug metadata.

### Next investigation
1. Inspect the actual WDK 26100 ACX 1.0 and 1.1 acxstub.lib files from the restored WDK package: exact paths, SHA-256, size, archive members, symbol/object contents. Determine what class-bind metadata the 1.0 stub contributes; do not rely only on DDI table-name comparison.
2. Build a minimal official-Microsoft-AudioCodec-sample-based ACX 1.0 bind probe (MEDIA class, KMDF 1.31) on the same hosted Server 2022 runtime. If it also fails with 0xC000000D, suspect WDK 26100 ACX 1.0 stub/runtime compatibility; if it binds, isolate our Bluetooth driver’s WDF/ACX bind metadata or INF-specific setup.
3. Optionally capture a pre-install LiveKD dump in the same run to show CLASS_MODULE v1.0 immediately before the LDAC load attempt; current preinstall service/file check plus identical baseline hash is strong but indirect.
4. Correct stale ACX 1.1 comment in build_driver.cmd on the ACX 1.0 experiment branch; it is documentation only.
- Physical host remains unchanged: no certificate import, driver install, BCD change, device restart, rollback, reboot or OS update.

## Continuation update — 2026-11-22 22:00 Kyiv

### WDK 26100 ACX stub library / bind metadata
- CI #255 run 45060819535, branch experiment/acx10-hosted-load, head commit 085705abb4bf8e52dd5bcb5bccb532352fbb132e, succeeded. Artifact 14769755224, SHA-256 8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce, contains the actual WDK stub libraries and manifest.
- WDK NuGet package Microsoft.Windows.WDK.x64 10.0.26100.6584:
  - ACX 1.0 acxstub.lib path c/Lib/10.0.26100.0/km/x64/acx/km/1.0/acxstub.lib; 1,362,352 bytes; SHA-256 9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74.
  - ACX 1.1 acxstub.lib path c/Lib/10.0.26100.0/km/x64/acx/km/1.1/acxstub.lib; 1,366,656 bytes; SHA-256 86F1A9A63A1A6D1F232C70AA98623ECE9A61A1299444399F170F5426C6234A87.
- GNU ar/objdump inspection of each stub.obj shows .kmdfclassbind$b descriptor size 0x78. ACX 1.0 encodes class major/minor 1.0, 210 function-table entries (0xD2), 62 structures (0x3E); ACX 1.1 encodes 1.1, 221 functions (0xDD), 62 structures. Both Pch.obj copies encode WDF minimum version 0x1F (31 = KMDF 1.31).
- Parsed actual CI #246 LdacA2dp.sys descriptor at file offset 0xC240: ACX major/minor 1.0, function count 210, structure count 62. This proves the linked candidate uses the 1.0 class-bind descriptor, not merely 1.0 source macros. Its WDF minimum version 1.31 is compatible with runtime 1.33 and matches ACX runtime's WDF client 1.31.
- Therefore the persistent 0xC000000D is not explained by the candidate accidentally requesting ACX 1.1 or by a too-high WDF minimum. Remaining key question: whether Server 2022 Acx01000.sys CLASS_MODULE v1.0 exposes the same 210-function/62-structure interface expected by the WDK 26100 ACX 1.0 stub, or whether another bind-info/registration invariant differs.

### Next exact actions
1. Inspect the public Acx01000.pdb / runtime symbols on the hosted Server 2022 runner for ACX class bind function count, structure count, and minimum-version fields. Use the same runtime file hash D10924E8... and preserve the class module v1.0 observation.
2. If the public PDB does not expose the data, build a minimal official AudioCodec-sample-based ACX 1.0 client (MEDIA class, KMDF 1.31) and test it on the same hosted runner with Acx01000 explicitly started. This separates WDK stub/runtime compatibility from the Bluetooth driver.
3. Do not change physical host. No certificate import, driver installation, BCD change, device restart, rollback, reboot or OS update.


## Documentation reorganization reconciliation — 2026-11-22

- New canonical entry point: [START_HERE.md](../../START_HERE.md); portable ChatGPT Source map: [LDAC_Project_Source_START_HERE.md](../../LDAC_Project_Source_START_HERE.md). Specialized registries: [BUILD_REGISTRY](../../research/BUILD_REGISTRY.md), [TEST_MATRIX](../../research/TEST_MATRIX.md), [HARDWARE_SAFETY](../../research/HARDWARE_SAFETY.md), [ARTIFACT_INDEX](../../research/ARTIFACT_INDEX.md).
- CI #248 / run 45060225420 / commit 3d1d5d7e179da3379013b10f9863066200c459b6 is a **valid negative hosted test**. Acx01000 was explicitly started and verified RUNNING before PnP install. Candidate DriverVer is 0.2.326.1922 (the earlier line in this state saying .1920 is corrected by preflight.json and SetupAPI output). PnP selected oem13.inf, attempted device start, and returned Code 37 / ProblemStatus 0xC000000D; Kernel-PnP Event 219 records \\Driver\\LdacA2dp failure. No DriverEntry or loaded LdacA2dp/Acx01000 module was present in the post-failure mirror dump; debugger could not find WDF clients. This does not identify the exact internal bind check.
- CI #248 report artifact 14769048266, digest e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb. Candidate SYS SHA-256 FF97EED8409A7FF9DADB8D9C7C7FB309E789F9A3225847793B39B7D97D8FB9A8; INF 0111FD38ED61DCA2D3D9691CB6BC70675AD588A9B6B2778113B2CFBDBFFC4B6C; CAT F40C19BF69B43DFE91C49CBA67ED7DA18BF4147B6F065C7BC132B97969C22D94.
- CI #255 / run 45060819535 / commit 085705abb4bf8e52dd5bcb5bccb532352fbb132e succeeded. It directly inspected WDK 10.0.26100.6584 stub libraries: ACX 1.0 descriptor 1.0 / 210 functions / 62 structures; ACX 1.1 descriptor 1.1 / 221 / 62. Parsed CI #246 candidate SYS descriptor is 1.0 / 210 / 62. This rules out accidental ACX 1.1 descriptor selection in that binary; it does not prove the runtime exposes every required bind invariant.
- CI #248 therefore demotes/refutes the simple hypothesis that changing only the LDAC client from ACX 1.1 to ACX 1.0 fixes the failure. Root cause remains unresolved. Next discriminator: minimal official Microsoft AudioCodec-sample-derived ACX 1.0 client on the same hosted Server 2022 runtime; compare bind behavior before changing LDAC code.
- CI #255 ACX stub metadata artifact 14769755224, digest 8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce. See [BUILD_REGISTRY](../../research/BUILD_REGISTRY.md) and [ARTIFACT_INDEX](../../research/ARTIFACT_INDEX.md).
- CI #230/#243/#245 harness failures are not evidence of driver failure: #230 stopped on hardcoded version validation; #243/#245 failed in test harness setup. CI #248 is the first meaningful ACX 1.0 PnP start test.
- Physical host remains unchanged. No driver installation, cert changes, BCD changes, restart, rollback or OS update.


## 2026-11-23 — ACX 1.0 sample-derived bind probe: build proven, runtime preflight being hardened

The separate experiment branch is experiment/acx10-sample-bind-probe-v2, current head 35e700a3ecb74548b858f0479a1e15e31a2d110f. The probe is derived from Microsoft's pinned AudioCodec sample commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69, but explicitly compiles against ACX 1.0 and KMDF 1.31. The INF is MEDIA / root-enumerated ROOT\AudioCodec; EvtDeviceAdd deliberately returns STATUS_NOT_SUPPORTED after logging.

CI #10 and #11 both built the probe successfully with WDK 10.0.26100.6584 / SDK 10.0.26100.0. CI #11's manifest confirms the exact ACX 1.0 stub hash is 9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74, identical to CI #255. The manifest also pins the ACX header, WdfDriverEntry.lib and WdfLdr.lib hashes.

Runtime attempt #10 did not reach PnP: SignTool /kp rejected the self-signed test certificate. This was corrected to documented /pa PnP-installation verification. Runtime attempt #11 did not reach PnP: LiveKD's bitmap dump lacked a page needed to display the ACX class-module record, and WMI misreported an already-running Acx01000 service. The current script uses SCM query state and records incomplete LiveKD output rather than failing the experiment. CI #12 caught a script parser regression before runtime; the current commit restores the known-good body and reapplies the fixes.

CI #13 run 45078613003 on commit 35e700a3ecb74548b858f0479a1e15e31a2d110f: build job 137381366829 passed; hosted runtime job 137381843080 was in progress at update time. No PnP result is claimed yet.

Durable artifacts and verified hashes are in ARTIFACT_INDEX. No physical server has been modified; all runtime work is on disposable GitHub-hosted Server 2022.
