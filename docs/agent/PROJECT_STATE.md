# Current state — 2026-11-24 02:19 Europe/Kyiv

**Priority:** prove the existing Microsoft Windows 10 A2DP package on Server 2022 for SBC stereo before any LDAC work. ACX/WDK bind-probe remains parked.

## Confirmed strategy correction

- Windows 10 inbox A2DP documents SBC and aptX Classic only; no LDAC or AAC. There is no Microsoft inbox LDAC DLL/provider to transplant.
- Microsoft explicitly says all Windows Server SKUs lack in-box Bluetooth wireless support, while third-party IHV drivers may be available. A separate component-guidelines page lists QD ID 130847 for Windows Server 2022 as a Host Subsystem qualification. That is not an in-box A2DP profile; keep vendor radio/host stack, core host subsystem and A2DP profile as separate layers (E-146/E-147).
- The captured common/source INF path installs `BthA2dp.sys` as a kernel A2DP profile driver; `BtaMPM.sys` is profile management. MSSysFx/APO DLLs are audio effects, not LDAC encoders.
- The Microsoft Bluetooth stack's documented extension point is a PnP-loaded profile driver communicating with `BthPort.sys` through WDM IRPs/BRBs; no supported user-mode LDAC codec plug-in contract was found in the reviewed docs/INFs.
- Older public BthA2dp symbols show internal `A2dpSbcCodec` and `AptXCodec` classes and AVDTP code; this is secondary evidence from 10.0.17763.168, not the captured 10.0.19041.4355 binary.
- The repository already vendors AOSP `external/libldac` at `eeee1a3f`, builds it as static `ldacBT_enc`/`ldacBT_abr` libraries, and calls it from `service/encoder.cpp`. It is not a Windows 10 DLL.
- OPPO ETE41 supports AAC/SBC only; it is suitable for SBC, not LDAC.
- The legacy PE import script lacks the 20-byte descriptor increment; its 1.3 MB report is invalid. Reports (2)/(3) need a retained parser/source and independent verification.
- BlueCaster v3.0.4 is a ready user-mode A2DP/LDAC alternative using BTstack+WinUSB, but it requires a USB adapter, takes it over from Windows, does not list Server 2022 support, and bundles BTstack with a personal/non-commercial license.
- Winbindex's x64 hash-only index now confirms the exact SHA-256 values for the 282,624-byte DriverStore BthA2dp.sys, the separate 279,040-byte System32 copy, and BtaMPM.sys. This confirms hash presence in the Microsoft public-symbol index, but does not supply PE timestamp/virtual size, OS/update mapping or catalog membership; see E-143–E-145.

## Remaining blockers

1. Exact source system catalog and CBS/component ownership of the Win10 source/common A2DP and btampm packages.
2. Complete PE exports/imports/delay/API-set and dynamic dependency analysis of the exact DriverStore package binaries.
3. Symbol resolution against the exact Server 2022 20348.5761 kernel and dependency exports.
4. Disposable-VM validation of service start → enumeration → driver load → A2DP endpoint → SBC negotiation → actual stereo audio.
5. A separate LDAC-capable sink and a legally supportable transport path for the later LDAC milestone.

## This research pass

No source code or driver package was changed; no build, CI run, runtime test or fresh physical-host query was performed. The physical host remains read-only. No BCD/security/test-signing/certificate/OS changes and no install/restart scripts were executed. The 2026-11-19 Server and latest PnP records remain historical snapshots, not current-state claims.

See [WIN10_COMPONENT_AUDIT.md](WIN10_COMPONENT_AUDIT.md), [WIN10_A2DP_PIPELINE.md](WIN10_A2DP_PIPELINE.md), [NEXT_ACTIONS.md](NEXT_ACTIONS.md), and E-136–E-142 in [EVIDENCE.md](EVIDENCE.md).

---



## Investigation update — 2026-11-24 (A2DP INF dependency audit)

- The new `Win10-A2DP-DriverStore.zip` was opened and inventoried. It contains the common A2DP INF + `BthA2dp.sys`, source INF, and sink INF. The larger targeted archive additionally contains `btampm.inf` + `BtaMPM.sys`, HFP and AVRCP components.
- The common INF is MEDIA / x64, DriverVer 10.0.19041.4355, installs demand-start `BthA2dp`, and registers source/sink audio interfaces. Its explicit dependency chain is `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`, and `mssysfx.CopyFilesAndRegister`.
- On the physical Server 2022, the user's read-only search found `ks.inf` and `wdmaudio.inf`, but not `btampm.inf`, `mssysfx.inf`, `BthA2dp.sys`, or `BtaMPM.sys` in INF/System32 drivers/DriverStore. A WinSxS directory-name search was inconclusive for individual files.
- Microsoft's official APO documentation reproduces the same Bluetooth A2DP/HFP dependency chain and says the sample supports stereo and hands-free endpoints.
- The A2DP package is no longer missing from our research inputs; the next technical question is whether the dependency components are present in Server WinSxS/component store and whether the Windows 10 INF's package can be staged on a disposable Server 2022 VM. Matching `NTamd64` decoration is not proof of Server support.
- The physical Server remains unchanged. Realtek artifacts are explicitly excluded as unrelated residue from the user's lost USB dongle experiment.
- Evidence details: E-090 through E-095 in `docs/agent/EVIDENCE.md`.

# Current state — 2026-11-23 23:40 Europe/Kyiv

**Priority reset:** the project is now on the Windows 10 A2DP package-adaptation path. No new Bluetooth/ACX driver work is authorized as the next step.

## Current result

- Windows 10 reference machine `AS-KRM-WIN10` has a Microsoft A2DP source profile binding through `microsoft_bluetooth_a2dp_src.inf` version `10.0.19041.1`.
- The captured `BthA2dp.sys` is version `10.0.19041.4355`, size `282,624`, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`.
- The source INF is a thin binding and delegates through `Include` / `Needs` to `microsoft_bluetooth_a2dp.inf`. That common INF and the package catalog are missing from the current capture. No package installation or compatibility conclusion is allowed until they are recovered.
- The read-only exporter `Export-Win10-A2DP-Package.ps1` is already in Library. Its output is the only current external dependency.
- Microsoft's Windows 10 built-in A2DP codecs are SBC and classic aptX; no inbox LDAC or AAC. OPPO Enco Buds2 ETE41 supports AAC/SBC only, so SBC is the first and only common codec for this receiver.
- Windows Server 2022 build 20348 / UBR 5761 is not an in-box Bluetooth-supported SKU. The latest recorded Server snapshot is 2026-11-23 20:41 Kyiv, not a live check. It shows the 0x110B A2DP service enumerating through generic `bth.inf` / `BthGenericService`, with no Microsoft A2DP source package. The last recorded custom target node was `oem75.inf`, version `0.2.325.1600`, Code 37 / `0xC000000D`.
- The current repository's LDAC encoder is AOSP `third_party/libldac`, built as static code and used by `service/encoder.cpp`; it is not a Windows 10 LDAC DLL. The current `LdacA2dp.sys` is a custom replacement profile driver with its own AVDTP/L2CAP path and ACX 1.1 endpoint. It is parked.
- The only documented third-party LDAC driver in project evidence is Alternative A2DP Driver 1.8.3.1 on a separate Windows 11 laptop (`AltA2DP.sys`, `oem96.inf`); it is a kernel driver, not a DLL, and its package is not in the Windows 10 archive. BlueCaster is a user-mode WinUSB/BTstack alternative, but its supported OS matrix is Windows 10/11, not Server 2022.

## Current gate

**Blocked before package staging:** complete source/common INF + catalog not yet captured. No Server 2022 package install, profile-driver load, endpoint, SBC negotiation, or actual audio test was run in this cycle.

## Next action

Run the existing read-only `Export-Win10-A2DP-Package.ps1` on `AS-KRM-WIN10`; then audit the full package before any disposable-VM test.

## Safety / paused work

No physical Server 2022 changes. No driver installation, device restart, BCD/security/test-signing changes, certificate changes, OS update/rollback, or install/upgrade/rollback script execution. CI #248 and #255 are closed historical evidence; no new ACX bind-probe. All code changes, if later proven necessary, must be on a separate experimental branch; documentation stays on `docs/project-source-reorg`.

> All following state entries are historical snapshots. This section supersedes their older ACX-first next steps.

---

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


## 2026-11-23 — ACX 1.0 sample-derived bind test and WDF diagnostics

### CI #13 — confirmed hosted runtime failure
- Run: [45078613003](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45078613003); run number 13; repository commit `35e700a3ecb74548b858f0479a1e15e31a2d110f`.
- Source: Microsoft Windows-driver-samples AudioCodec, pinned commit `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`. The probe deliberately used ACX 1.0, KMDF 1.31 and WDK 10.0.26100.6584, with a root-enumerated MEDIA INF.
- Build succeeded; `InfVerif /w` and `Inf2Cat` returned 0. Runtime on hosted Server 2022 selected the probe INF and attempted PnP start, but returned Code 37 / `0xC000000D`; no DriverEntry marker.
- The probe SYS hash is `70BA9899BF1B54989E7C6C3F6C0DEDAE2ADFCEF16D7AE6A9803192E7C86EDAA6`; the LDAC ACX 1.0 candidate SYS hash is `FF97EED8409A7FF9DADB8D9C7C7FB309E789F9A3225847793B39B7D97D8FB9A8`. Both contain ACX 1.0 descriptor 210 functions / 62 structures. WDK ACX 1.0 stub hash: `9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74`.
- This rules out an LDAC-only INF/topology cause for the pre-DriverEntry failure. It does not identify the internal bind stage.

### CI #14 — DbgPrintOn timing limitation
- Run: [45081844225](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45081844225); run number 14; commit `04518a83900a7e7aa093fe56a7669f91349d7588`.
- Build and runtime harness succeeded; sample bind again returned Code 37 / `0xC000000D` before DriverEntry.
- The probe set global `DbgPrintOn=1` after OS boot, but `!dbgprint` remained empty. This is not evidence that the WDF loader emitted no messages: Microsoft WDF source initializes `WdfLdrDbgPrintOn` from the registry in `Wdf01000.sys` DriverEntry (lines 111–115, read at line 358), which has already executed before the hosted job starts. Do not repeat a post-boot registry write.
- CI #14 cleanup reports device removed, temporary certificate removed, Acx01000 restored to its prior stopped state, and temporary private-key directory removed.

### Compatibility evidence
- The official AudioCodec project defaults to ACX 1.1 / KMDF 1.31. Microsoft ACX version information lists ACX 1.0 as pre-release for Windows 10 1903 / KMDF 1.29; Server 2022 is not listed for ACX 1.0. The tested ACX 1.0 + WDK 26100 + KMDF 1.31 + Server 2022 tuple is therefore not documented as supported. This is a compatibility caveat, not a proven cause.
- WDF client 1.31 with Server 2022 WDF runtime 1.33 is a separate version relationship from ACX class-module 1.0.

### CI #15 — next diagnostic in progress
- Run: [45082965356](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45082965356); run number 15; commit `488ae8104eec960370c0887e07136a3e9e3846b5`.
- Removed the ineffective global post-boot DbgPrintOn modification. Added per-driver WDF `VerboseOn=1` and `LogPages=16` in the probe INF and temporarily for Acx01000 before service start, with snapshot/restore.
- LiveKD capture uses native `-ml` dumps with all-regions mirror fallback; KD commands dump WDF IFR logs for Acx01000, AcxAudioCodecProbe and WDF. Runtime result pending.
- No physical server driver, certificate, BCD/security, device or OS state has been changed.

## 2026-11-23 — CI #15 completed: minimal ACX 1.0 sample still fails before DriverEntry

- **Run:** [CI #15 / 45082965356](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45082965356), workflow run number 15, branch `experiment/acx10-sample-bind-probe-v2`, commit `488ae8104eec960370c0887e07136a3e9e3846b5`. Build job `137395027059` and hosted runtime job `137395510513` both completed successfully as workflow jobs. The green workflow means the experiment completed; it does not mean the driver bound.
- **Environment:** hosted Windows Server 2022 Datacenter build 20348 / UBR 5870, image `20261116.370.1`. `Acx01000.sys` 10.0.20348.5866, SHA-256 `D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0`; `Wdf01000.sys` 1.33.20348.1, SHA-256 `32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B`.
- **Build tuple:** WDK NuGet 10.0.26100.6584 / SDK 10.0.26100.0 / VS2022 MSBuild 17.14.60.43110 / KMDF 1.31 / ACX 1.0 / x64 / `DriverTargetPlatform=Windows Driver`. INF is `Class=MEDIA`, hardware ID `ROOT\AudioCodec`, `KmdfLibraryVersion=1.31`, `DriverVer=11/22/2026,23.24.24.909`.
- **PnP result:** synthetic `ROOT\DEVGEN\ACX_SAMPLE_BIND_PROBE_CI` selected `oem13.inf` and service `AcxAudioCodecProbe`; ProblemCode 37, ProblemStatus `0xC000000D`; no DriverEntry marker, no `WdfDriverCreate` or `AcxDriverInitialize` status, and no `EvtDeviceAdd`. Probe SYS is 8,704 bytes, SHA-256 `BAB3C54C0EAB186CC8C9D89B07BCA871112454175C0C45F8D199DA57927114B6`; INF `CC2A09F6D2F8590DA5395CB366FE62C83164D48EF8B227E3B0004447E0112DC7`; signed runtime CAT `9A120CCB4D5B8781EED86D50C096A5A95CC59140954A5A1E9830F0875A42ABD8`; PDB `4FDC48C1C86C33DC6939A8130E8CD594016E80EA64DB3ADADE846D083B03CCB7`.
- **Artifacts:** build artifact 14778450384, ZIP SHA-256 `8e701ee7f69f1d9c855f5b2c3d4c06de39628dfb7e955ecb12877fc9f811e449`, 123,115 bytes; runtime artifact 14778137925, ZIP SHA-256 `aa63c8dfbce7b9b319d9117e1be7b8db1565ff85a0d56c08e57c9de98710e59b`, 152,791 bytes. Both originals were copied to Library and rematerialized; SHA-256 matched byte-for-byte. Library IDs: `libfile_c72211f203f88191a5895df8e19daf32` and `libfile_553acf157ff88191b459dfdf42911d8a`.
- **WDF diagnostics:** the probe started `Acx01000` from its previous STOPPED state after setting `VerboseOn=1` / `LogPages=16`. The raw preinstall LiveKD log contains WDF IFR entries for `Acx01000`; the probe driver's own IFR is unavailable because the driver never successfully loaded. `!wdfkd.wdfldr Acx01000.sys` hit a missing-page/access-violation limitation; `!wdfldr` still showed WDF runtime 1.33 and ACX01000 as a WDF 1.31 client. The same ACX/WDF runtime hashes match CI #10, which directly displayed ACX CLASS_MODULE v1.0. CI #15 itself did not directly re-display the class-module record.
- **Harness defect found:** the raw preinstall dump contains ACX runtime IFR, but the CI #15 `runtime-result.json` `WdfIfrLines` field extracted only postinstall output, after `Acx01000` was no longer available to that query. The script was corrected in CI #16 to preserve preinstall and postinstall IFR separately.
- **Cleanup:** `cleanup-result.json` reports `Success=true`, device removed, probe service removed, temporary certificate removed from all LocalMachine stores, ACX service restored to its prior STOPPED state, WDF diagnostics restored, no private-key files/markers, and private temporary directory removed. No physical server action occurred.

### WDK ACX stub versus Server 2022 runtime

- The exact WDK 10.0.26100.6584 ACX 1.0 stub hash remains `9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74`. CI #255's parsed descriptor is ACX 1.0 / 210 functions / 62 structures; the corresponding ACX 1.1 descriptor is 1.1 / 221 / 62. The 1.0 object section `.kmdfclassbind$b` is 0x78 (120 bytes).
- WDF source at commit `b6191d9543441329154da32f7ab9bdd97228dd3c`, `src/framework/shared/inc/private/common/fxldr.h`, shows `FxGetNextClassBindInfo` accepts a descriptor only when `Size` matches `sizeof(WDF_CLASS_BIND_INFO)` or `sizeof(WDF_CLASS_BIND_INFO2)` (lines 186–259). Its `WdfVersionBindClass` comment says that call loads/references the class extension and links the client into the class library (lines 438–451).
- Existing physical debug evidence records `WdfVersionBindClass` returning `0xC000000D`. This places the known failure at the class-bind call, after the client stub has located a class-bind descriptor; it does not identify which runtime validation rejects it. The Server 2022 runtime class's actual function/structure counts remain UNKNOWN.
- Official ACX version information lists ACX 1.0 as pre-release on Windows 10 1903 / KMDF 1.29 and ACX 1.1 as the public release on Windows 10 2004 / KMDF 1.31; Server 2022 is not listed for ACX 1.0. WDK 26100.6584 is the Microsoft-recommended WDK when staying on VS2022 and supports building for Server 2016 and later. The build toolchain is valid; ACX 1.0 runtime support on Server 2022 is not documented.

### CI #16 — full-mirror follow-up

- Commit `9da48c3ecd5921f8cab47888325b156dc9a536f3` on `experiment/acx10-sample-bind-probe-v2`; [workflow run #16 / 45084678951](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45084678951) was started. It uses a preinstall LiveKD mirror `-m0x3FFF`, records dump hash/size/missing-page count, queries WDF class-bind types in the runtime PDB, preserves preinstall/postinstall IFR separately, and scans the WDK include tree for class-bind declarations.
- Physical Server 2022 remains unchanged: no driver installation, certificate change, BCD/security change, device restart, rollback or OS update.


## Continuation update — 2026-11-23 12:xx Kyiv (CI #16 complete; WDK 20348.1 control pending)

### CI #16 — minimal Microsoft AudioCodec-derived ACX 1.0 probe

- [GitHub Actions run 45084678951](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45084678951), branch `experiment/acx10-sample-bind-probe-v2`, commit `9da48c3ecd5921f8cab47888325b156dc9a536f3`. Build and hosted runtime jobs both completed successfully as harness jobs; the driver did not bind.
- Build tuple: WDK NuGet 10.0.26100.6584, Windows SDK 10.0.26100.0, VS2022 MSBuild 17.14.60.43110, KMDF 1.31, ACX 1.0, x64, Windows Driver target. INF verification and Server2022 catalog generation passed.
- Probe SYS SHA-256: `F7BAE855C1B184ABCF0BFCBC258EF11740700788BC08270A3C22041E76860E37`. Build artifact 14779061024, 126,939 bytes, SHA-256 `d332fc56eaf4d14c2b8a7dbbd8b6f56e82b39e32e8b1d16ac0f6c989cb3e9e85`, preserved at `/LDAC Project/Incoming/CI-16-ACX10-Sample-Bind-Build.zip`.
- Runtime artifact 14779107472, 162,186 bytes, SHA-256 `7d53835ecaababca7451c19e0ce79bab7186f9e59568fcc3a3b047efa3e95214`, preserved at `/Bluetooth LDAC Research/Artifacts/CI-16-ACX10-Sample-Bind-Runtime.zip`.
- Hosted Server2022 build 20348.5870: PnP selected `oem13.inf` and service `AcxAudioCodecProbe`, then returned Code 37 / `0xC000000D`. DriverEntry, WdfDriverCreate, AcxDriverInitialize and EvtDeviceAdd were not reached. Runtime Acx01000.sys 10.0.20348.5866 / class module 1.0 / WDF client 1.31; Wdf01000.sys runtime 1.33.20348.1.
- Full LiveKD mirror captured 17,174,368,256 bytes with zero missing pages. The JSON summary fields for dump length and missing pages are null despite the raw capture log; raw log is authoritative. WDF IFR captured runtime entries (including FxInitialize) but no definitive class-bind failure. The PnP module emitted a localized-data warning; the WDK20348 harness replaces PnpDevice cmdlets with CIM/registry/PnPUtil diagnostics.

### WDF bind descriptor comparison

- CI #255 run 45060819535 / commit `085705abb4bf8e52dd5bcb5bccb532352fbb132e` artifact 14769755224, SHA-256 `8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce`. WDK 26100.6584 ACX 1.0 stub `acxstub.lib`: 1,362,352 bytes, SHA-256 `9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74`; descriptor 0x78 bytes, version 1.0, 210 functions, 62 structures. ACX 1.1 descriptor is 0x78 bytes, version 1.1, 221 functions, 62 structures.
- CI #16 Server2022 Wdf01000 public PDB resolves `WDF_CLASS_BIND_INFO2` size 0x78, with offsets 0x00–0x70 matching the ACX stub descriptor fields. The base `WDF_CLASS_BIND_INFO` is 0x50 bytes; `WDF_CLASS_BIND_INFO2` extends it to 0x78 bytes. This weakens the simple descriptor-size mismatch hypothesis but does not prove pointer targets, version semantics, ACX-specific ClassBindInfo, function/structure counts, or runtime expectations are compatible.
- Microsoft WDF source commit `b6191d9543441329154da32f7ab9bdd97228dd3c`, blob `e7630f7bfbc1050b84835351386942d11b4554e7`, shows `FxGetNextClassBindInfo` accepts records whose Size matches WDF_CLASS_BIND_INFO or (stub version >=25) WDF_CLASS_BIND_INFO2. Existing physical trace records the later `WdfVersionBindClass` call returning `0xC000000D`; if that attribution is correct, a simple pre-call size rejection is less likely. The offending parameter remains unknown.
- Durable analysis report: `/LDAC Project/Incoming/CI-16-255-Descriptor-Compatibility-Analysis.md`, SHA-256 `8523e7f5063c829541adae3fcacad0fe97e6f7eee4c39a914d16d7dce86bac5a`.

### Official AudioCodec sample and toolchain boundary

- Pinned Microsoft sample commit: `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`. The official AudioCodec solution uses VS2019 `16.0.31409.214`; its project defaults to ACX 1.1 / KMDF 1.31, WindowsKernelModeDriver10.0, Windows Driver target, WPP/WPP Recorder and SamplesCommon. Its MEDIA/root-enumerated INF targets 19041+, which includes Server2022 build 20348.
- The probe intentionally reduces the sample to ACX 1.0 / KMDF 1.31 / x64 / MEDIA / root enumeration to match the observed Server2022 ACX class-module version 1.0. The full sample's ACX 1.1 default would not match that runtime class-module version.
- Microsoft ACX documentation labels ACX 1.0 pre-release (Windows 10 1903 / KMDF 1.29) and ACX 1.1 the public release (Windows 10 2004 / KMDF 1.31); Server2022 is not explicitly listed in the ACX table. Microsoft's KMDF version table lists KMDF 1.31 drivers as running on Windows 10 version 2004 and later; its 1.31 row does not explicitly name Server 2022. CI #10 and CI #16 directly observed a KMDF 1.31 client bound to the KMDF 1.33 runtime on hosted Server 2022. Therefore generic KMDF 1.31 runtime compatibility is supported; ACX 1.0 support on Server2022 remains a legacy/undocumented boundary.

### CI #17 — WDK 20348.1 / VS2019 control (pending)

- Separate code branch `experiment/acx10-wdk20348-control`, commit `79460f03492a54444473589dd142da864a703a73`; [workflow run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058).
- The workflow's PowerShell parser and project XML gates passed. The build job is acquiring the official Microsoft EWDK 20348.1 and checking for ACX 1.0 header/stub and KMDF 1.31 libraries. No build/runtime outcome is claimed yet.
- This is a toolchain-bundle comparison (WDK 26100/VS2022 → WDK 20348.1/VS2019), not a pure WDK-only variable. The EWDK is used instead of the legacy MSI installer; this unsupported kit is research-only.
- If the old stub is present, build the same source/INF and test on a fresh hosted Server2022 runner. If it binds, compare DriverEntry/WDF/ACX sequence with LDAC; if it fails similarly, inspect the 20348 stub against Server2022 ACX1.0 runtime. No physical host changes.

### Safety status

Physical Server2022 remains untouched. No driver install, certificate change, BCD/security change, device restart, rollback, reboot or OS update was performed. Root cause remains UNRESOLVED.


## Continuation update — 2026-11-23 12:53 Kyiv (CI #17 active; CI #16 source/artifact audit)

### CI #16 — exact runtime class-bind layout and artifact integrity

- Re-downloaded GitHub build artifact **14779061024** and materialized the durable Library copy. The original and Library copy are byte-identical at **126,939 bytes**, SHA-256 `d332fc338cbd8c4aa41f56338bb68104059b2956558067362d69b495a0ba8e72`. This corrects the earlier PROJECT_STATE digest `d332fc56...`, which was a transcription error.
- Re-downloaded GitHub runtime artifact **14779107472** and compared it with the durable Library copy: **162,186 bytes**, SHA-256 `7d53835ecaababca7451c19e0ce79bab7186f9e59568fcc3a3b047efa3e95214`; exact match.
- Descriptor analysis report: **6,016 bytes**, SHA-256 `8523e7f5063c829541adae3fcacad0fe97e6f7eee4c39a914d16d7dce86bac5a`.
- Build manifest: probe SYS SHA-256 `F7BAE855C1B184ABCF0BFCBC258EF11740700788BC08270A3C22041E76860E37`; INF `25C1E5AAEF51FB417E6E0ED2113C33841A08D4DDC05DABF60AA7AFB1BF41CD39`; PDB `7B2FEDE81388EDA93FD930B2B88A47FDFB72BC8686A7C47D7967A449D7863855`. The WDK 26100.6584 ACX 1.0 stub remains SHA-256 `9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74`.
- Re-read the raw CI #16 preinstall debugger transcript. The Server 2022 WDF runtime PDB reports `WDF_CLASS_BIND_INFO` base size **0x50** and `WDF_CLASS_BIND_INFO2` fields at offsets 0x50, 0x58, 0x60, 0x68 and 0x70; V2 ends at **0x78**. The ACX 1.0 stub's 0x78-byte descriptor therefore matches the runtime's V2 structure size. The prior statement that the base structure was 0x68 bytes was incorrect and is corrected here and in the sample probe note.
- The same preinstall transcript directly shows `CLASS_MODULE` ACX version 1.0, WDF class/client version 1.31, and Wdf01000 runtime 1.33. The class module exists before the probe; its empty ClientsList is the expected pre-install state. The full LiveKD mirror was 17,174,368,256 bytes, SHA-256 `0ADB390E23324838A0B0A65D3829B872D800A1359222162FEBA1C86E4193969F`, with zero missing pages. The 17-GB dump itself was not included in the ZIP; the debugger transcript and capture metadata were.
- CI #16 still ended with PnP Code 37 / `0xC000000D` before DriverEntry. The exact internal rejection inside `WdfVersionBindClass` remains UNKNOWN. The simple descriptor-size mismatch and missing-ACX-class-module explanations are rejected for this CI #16 preinstall state; pointer values, ACX-specific bind semantics, class-version resolution and callback behavior remain open.

### Official Microsoft AudioCodec sample — source review

- Pinned source: Microsoft `Windows-driver-samples` commit `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`. `Driver/AudioCodec.sln` declares VS2019 `16.0.31409.214`; `AudioCodec.vcxproj` defaults to ACX 1.1 / KMDF 1.31, uses `WindowsKernelModeDriver10.0`, the Windows Driver target, WPP/WPP Recorder and the `SamplesCommon` project/library.
- Official INF: `Class=MEDIA`, root hardware ID `ROOT\AudioCodec`, OS decoration `NTamd64.10.0...19041`, and `KmdfLibraryVersion=$KMDFVERSION$`. Server 2022 build 20348 satisfies the INF OS decoration; this is not proof of ACX 1.0 runtime support.
- Official DriverEntry sequence is `WdfDriverCreate` followed by `AcxDriverInitialize`. The sample's device-add path then uses `AcxDeviceInitInitialize`, `WdfDeviceCreate`, `AcxDeviceInitialize`, and circuit creation. The CI probe deliberately retains only the minimal WDF-before-ACX DriverEntry path and returns `STATUS_NOT_SUPPORTED` from EvtDeviceAdd to isolate the pre-DriverEntry bind.
- Microsoft ACX version table: ACX 1.1 is the current/public version, initially listed for Windows 10 2004 with minimum KMDF 1.31; ACX 1.0 is explicitly pre-release for Windows 10 1903 / KMDF 1.29 and is not recommended for new driver development. Server 2022 is not listed in the ACX table. Microsoft KMDF history lists KMDF 1.31 on Windows 10 2004 and later, but the 1.31 row does not explicitly name Server 2022; the Server 2022 WDF 1.31-client / 1.33-runtime pairing is directly observed in CI #10 and #16, not inferred from that row.
- Microsoft lists WDK 20348.1 as an unsupported legacy kit paired with VS2019. Its SDK/WDK installers are affected by CVE-2024-29187; the EWDK distribution is explicitly listed as not affected. This run uses the official EWDK ISO only, for research, and must not be treated as a production toolchain. Official EWDK setup documentation says to mount the ISO and run `LaunchBuildEnv.cmd`, then `SetupVSEnv`. CI #17's script prefers `SetupBuildEnv.cmd` if it exists; verify the actual chosen script and captured environment before accepting a build result.

### CI #17 — WDK 20348.1 / VS2019 control (still running)

- Branch `experiment/acx10-wdk20348-control`, commit `79460f03492a54444473589dd142da864a703a73`; [workflow run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058), build job `137638217372`.
- At 12:53 Kyiv, PowerShell parser and project XML gates had passed. Step 4, “Download EWDK 20348.1, inspect ACX 1.0 stub, and build”, remained in progress. No artifact, ACX 1.0 stub discovery, build result or hosted runtime result is claimed yet.
- The workflow is isolated to GitHub-hosted Windows Server 2022 runners. The runtime job runs only if the build produces a verified probe. No physical-server operation was performed.

### Safety status

Physical Server 2022 remains untouched: no driver install, certificate change, BCD/security change, device restart, rollback, reboot or OS update. Root cause remains UNRESOLVED.


## Investigation update — 2026-11-23 evening (CI #17 closed; headset capability audit)

### CI #17 — EWDK 20348.1 control
- Run [45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058), commit `79460f03492a54444473589dd142da864a703a73`, build job `137638217372`.
- The official EWDK 20348.1 ISO downloaded and mounted; SHA-256 `B962E5FB1D81E4BC419FB59F37D695172DD9B323DE772614C50F2B136B5B9AC1`.
- The build script reported `EWDK_ACX10_STUB_FOUND=false`. It uploaded a 2,156-byte provenance artifact (ID `14814207710`, ZIP SHA-256 `2c8f73e08ce5ba7e24ac6d61198a4b03932f482e9527614eed84b4ecb4c9a3f6`) and correctly skipped the runtime job.
- Workflow/job conclusion SUCCESS means the inspection script completed as designed; it does **not** mean an ACX 1.0 driver was built or loaded.
- Result: this Server-2022-era EWDK bundle does not provide the required ACX 1.0 stub at the inspected paths. Stop this particular toolchain branch unless a separately verified ACX 1.0 stub source is found.

### Headset codec capability — critical project constraint
- OPPO's official specifications for Enco Buds2 model ETE41 list Bluetooth codecs AAC/SBC only: https://www.oppo.com/ua/accessories/oppo-enco-buds2/specs/ and https://www.oppo.com/en/accessories/oppo-enco-buds2/specs/.
- If the physical receiver is ETE41, it cannot negotiate LDAC. No Windows driver, ACX implementation, USB adapter, or user-mode A2DP stack can add a codec that the headset does not implement.
- Treat exact model identity as pending until the headset/box label is confirmed. If ETE41 is confirmed, revise the target from LDAC to stable AAC/SBC, or use an LDAC-capable receiver for LDAC milestones.

### Alternative architecture — BlueCaster (formerly A2DP Windows Bridge)
- The project is now named BlueCaster (3.0.0); it uses a dedicated USB Bluetooth adapter assigned to WinUSB and runs the Bluetooth/A2DP path in user mode, bypassing the Windows inbox A2DP/ACX driver path.
- Published platform matrix: Windows 10 22H2 / Windows 11; Windows Server 2022 is not listed. Treat Server 2022 compatibility as UNTESTED, not supported.
- Separate USB adapter is recommended so Windows retains its existing Bluetooth radio for HID. While BlueCaster owns an adapter, Windows Bluetooth cannot use that adapter.
- Verified hardware includes LDAC with selected Sony/other headsets, but not OPPO Enco Buds2. This is a possible alternate path for an LDAC-capable receiver, not a solution to the ETE41 codec limitation.
- Sources: https://seiyafunaokajp.github.io/BlueCaster/ ; https://seiyafunaokajp.github.io/BlueCaster/setup.html ; https://seiyafunaokajp.github.io/BlueCaster/hardware.html.

### Current interpretation and next actions
1. First resolve the hardware premise: confirm whether the connected headset is OPPO Enco Buds2 ETE41. If yes, stop LDAC-specific driver work for this receiver.
2. For the existing ETE41, investigate stable AAC/SBC playback. BlueCaster may be tested only as an isolated Server 2022 compatibility experiment with a spare USB adapter; do not install or rebind anything on the physical host.
3. If LDAC remains a hard requirement, test with a receiver whose official specifications explicitly include LDAC, then evaluate BlueCaster's user-mode USB-radio architecture versus the current ACX kernel-driver route.
4. Keep physical Server 2022 unchanged. No driver, certificate, BCD, security, Bluetooth-device, or OS changes have been made.


### User confirmed headset identity — 2026-11-23
- User supplied photos of the physical earbuds/case and the phone's connected-device settings. The phone UI identifies the connected product as **OPPO Enco Buds2**. The supplied photos show only OPPO branding on the hardware; they do not expose a printed ETE model code.
- OPPO's official specification for Enco Buds2 identifies earbuds as ETE41 and case as ETE42, and explicitly lists Bluetooth codecs AAC/SBC only: https://www.oppo.com/ua/accessories/oppo-enco-buds2/specs/ and https://www.oppo.com/en/accessories/oppo-enco-buds2/specs/.
- Therefore the user's headset is identified as Enco Buds2, whose official codec specification does not include LDAC. Treat it as AAC/SBC-only for this project. Do not ask the user to locate ETE41 printed on the earbuds; the photos do not show such a code and the official product page supplies the model mapping.



## Investigation update — 2026-11-23 (Windows 10 reference archive reviewed)

- Reference machine AS-KRM-WIN10: Windows 10 Enterprise x64 build 19045.
- OPPO Enco Buds2 has a healthy Stereo endpoint and Hands-Free endpoints; all AudioEndpoint instances report `CM_PROB_NONE`.
- Earlier historical snapshot (E-030) recorded the classic A2DP profile devnode on microsoft_bluetooth_a2dp_src.inf. The later 2026-11-23 PnP record (E-132) supersedes it: the present/enumerated A2DP node is bound to the project's custom oem75.inf / LdacA2dp driver and fails at driver start with Code 37.
- `BthA2dp.sys` is running, version 10.0.19041.4355, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`.
- An earlier snapshot showed HFP/AVRCP components and BTAGService/BthAvctpSvc present. The later 2026-11-19 Server environment report (E-133) shows BTAGService/BthAvctpSvc not installed, while bthserv, Audiosrv and AudioEndpointBuilder are running.
- Microsoft documents classic A2DP as a Windows profile driver communicating with BthPort through WDM/IRPs. ACX is used in the documented Bluetooth LE Audio VSAP architecture, not as the classic A2DP profile-driver model.
- Microsoft states Windows Server SKUs do not include in-box Bluetooth support. Therefore the leading investigation is missing classic Bluetooth/profile package support and INF/service binding on Server, not an isolated missing DLL.
- Collector limitation: optional PnpDevice module localization errors produced an empty Relevant-PnP-Devices.csv; signed-driver inventory and endpoint dump remain valid. The actual A2DP INF and DriverStore package were not captured.

### Next actions
1. Run corrected read-only collector on Windows 10 and physical Server 2022 to capture like-for-like PnP, signed-driver, INF, DriverStore, service and binary inventories.
2. Compare BthA2dp, BthPort, BthEnum, BthUSB, HFP, AVRCP and AudioEndpointBuilder presence, package metadata, OS target decorations, versions and hashes.
3. Inspect catalog/signature and INF applicability before considering package reuse. Do not copy individual system binaries or import registry exports.
4. Reassess the ACX-only custom driver direction against the classic A2DP WDM profile-driver architecture.
5. Keep the physical Server unchanged; collection is read-only.


## Architecture reassessment — 2026-11-23 (Windows 10 classic A2DP reference)

The re-uploaded archive is byte-identical to the first reference archive (SHA-256 `3bebbee156019cfa6e1c031e8158c8d1e230fd6f64dd57f3a3bc5aae991254cd`); it is not the output of the corrected comparison collector. No new Server 2022 inventory is present.

### Confirmed Windows 10 reference path
- Windows 10 Enterprise x64 build 19045, machine AS-KRM-WIN10.
- Device Manager screenshot shows OPPO Enco Buds2 and separate Stereo / Hands-Free endpoints.
- A2DP service: `BthA2dp`, RUNNING, `BthA2dp.sys` 10.0.19041.4355, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`.
- Profile INF: `microsoft_bluetooth_a2dp_src.inf`; BTHENUM service GUID `0000110B-0000-1000-8000-00805F9B34FB`; class MEDIA, section `BthA2dpSrc`.
- MEDIA class registration lists `KS=1` and IncludedInfs `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`.
- A2DP service registry key has Start=3 and Owners=`microsoft_bluetooth_a2dp_src.inf`; its Enum child contains the OPPO A2DP profile devnode.
- Earlier service snapshot only: HFP/AVRCP components and BTAGService/BthAvctpSvc were reported present. The later 2026-11-19 environment report (E-133) records BTAGService/BthAvctpSvc absent and bthserv/Audiosrv/AudioEndpointBuilder running.
- The PnP inventory CSV is empty because the initial collector's PnpDevice module call failed; signed-driver CSV and registry/endpoint exports are still useful. The A2DP INF/DriverStore package itself was not captured.

### Critical architecture correction
Microsoft's classic Bluetooth documentation describes A2DP as a Bluetooth profile driver communicating with BthPort via the WDM/IRP model. The Windows 10 reference confirms a Kernel Streaming / WDMAudio registration pattern for the A2DP MEDIA device. The Microsoft A2DP INF/WDMAudio example includes `ks.inf`, `wdmaudio.inf`, and `BtaMpm.inf`. ACX is not the documented classic A2DP profile-driver foundation; Microsoft's Bluetooth LE Audio VSAP architecture is a separate path. Therefore the current ACX-only driver branch is not the right foundation for replicating Windows 10 classic A2DP. Do not continue ACX bind experiments as the presumed solution to classic A2DP.

### Next actions
1. Run `Collect-Bluetooth-A2DP-Compare.ps1` on Windows 10 to capture the missing signed INF/DriverStore package; run the same read-only collector on Server 2022 for a like-for-like inventory.
2. Compare presence and versions of BthA2dp, BthPort, BthEnum, BthUSB, BthHFEnum/BthHFAud, AVRCP, BTAGService, BthAvctpSvc, AudioEndpointBuilder, KS/WDMAudio components and the profile INF registrations.
3. Inspect the exact Microsoft A2DP INF decorations, catalog signature, package dependencies and supported OS targets. No copying binaries or importing registry files.
4. Design a classic A2DP WDM profile-driver installation/enablement experiment only after the missing package and OS compatibility are understood. Prefer disposable VM/clone first.
5. Keep the physical Server 2022 unchanged. No driver install, certificate changes, PnP rebinding, service changes, BCD/security changes, or reboot.


## Physical Server 2022 comparison — 2026-11-23

Read-only archive `Bluetooth-A2DP-Compare-AS-KRM-WS-20261123-204114.zip` reviewed. Manifest: Server 2022 Datacenter build 20348, 16 PnP devices, 4 audio endpoints, 16 signed-driver entries.

### Decisive difference from Windows 10
- The OPPO is paired and enumerates on Server; A2DP service UUID 0x110B exists and PnP status is OK.
- Server binds 0x110B to generic `bth.inf` / `BthGenericService.NT` ("Audio Sink Service"). The INF's service install is null and only marks `GenericDriverInstalled=1`.
- The Server DriverStore snapshot contains `bth.inf`, `bthleenum.inf`, `tdibth.inf`, `audioendpoint.inf`, `c_swdevice.inf`; it does not contain `microsoft_bluetooth_a2dp_src.inf` or `BthA2dp.sys`.
- No OPPO AudioEndpoint exists. Four enumerated endpoints are NVIDIA HDMI, GS wavetable synth, HD Audio speakers and S/PDIF.
- BthEnum, BthLEEnum, BTHPORT, BTHUSB and RFCOMM run. `BthAudioHF` is third-party Realtek `RtkHfp.sys`, stopped; it is not Microsoft's `BthHFAud.sys`.
- SetupAPI confirms the 0x110B generic binding and prior custom LdacA2dp update. Kernel-PnP event 219 records failure to load `LdacA2dp`. A later event 7040 records its service start type changed Manual -> Disabled; this is not established as the original cause.
- MMDevices registry export contains A2DP source references for other Bluetooth IDs/MACs, but these do not correspond to a live OPPO endpoint and are not evidence of a running A2DP source on this Server.

### Conclusion
The radio and classic Bluetooth stack work sufficiently to pair and enumerate the headset. The missing layer is the A2DP-to-audio profile binding: Windows 10 uses `microsoft_bluetooth_a2dp_src.inf` / `BthA2dp.sys`; this Server uses the generic null-service `bth.inf` entry. This is now the primary investigation target, not a generic missing Bluetooth DLL.

### Next
1. Run the corrected collector on Windows 10 only; the previous Win10 archive did not capture the A2DP DriverStore package. Need `microsoft_bluetooth_a2dp_src.inf`, its CAT and package folder, plus BthA2dp.sys and dependency metadata.
2. Compare INF OS decorations, catalog trust, package dependencies, target-build compatibility and class registration. Do not install/copy anything yet.
3. Keep physical Server untouched. Treat the custom LdacA2dp load failure separately from the in-box package absence.
4. The collector's SHA256SUMS.csv finalization has a benign self-read/write sharing bug; it does not invalidate collected files or archive. Exclude SHA256SUMS.csv from its own hash enumeration in the next script revision.


## Windows 10 package comparison — 2026-11-23 20:49 Kyiv

New Win10 archive received and inspected: AS-KRM-WIN10 / Windows 10 Enterprise x64 / build 19045. Manifest: 26 PnP entries, 7 AudioEndpoint entries, 26 signed-driver entries.

### Confirmed A2DP package facts
- PnP devnode: `Microsoft Bluetooth A2dp Source`, class MEDIA, device ID begins `BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}`, INF `microsoft_bluetooth_a2dp_src.inf`, version 10.0.19041.1.
- Binary: `BthA2dp.sys`, file version 10.0.19041.4355, 282,624 bytes, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`.
- Crucial INF structure: `microsoft_bluetooth_a2dp_src.inf` matches BTHENUM service 0x110B, but the install sections are delegated to `microsoft_bluetooth_a2dp.inf` via Include/Needs. The source INF is not a complete self-contained install package.
- The current capture lacks `microsoft_bluetooth_a2dp.inf`, its catalog, and its complete package directory. This is the next missing evidence item.

### Server comparison
Server archive AS-KRM-WS / Windows Server 2022 Datacenter / build 20348 contains the generic BTHENUM Audio Sink Service through `bth.inf`, but the captured PnP signed-driver list has no Microsoft Bluetooth A2DP Source MEDIA devnode and no `microsoft_bluetooth_a2dp_src.inf`. Its binary inventory has no `BthA2dp.sys`; service inventory has no `BthA2dp`. Core BTHPORT/BTHUSB/BthEnum and Windows Audio/AudioEndpointBuilder are present.

### State-reporting correction
Win10 Kernel-Drivers.csv shows BthA2dp and other demand-start kernel drivers as Stopped/Manual at collection time. This must not be described as currently running; the signed PnP driver record proves installed/bound profile presence, while service state is only a point-in-time observation.

### Next action
Run targeted read-only `Export-Win10-A2DP-Package.ps1` to recursively locate/copy every available A2DP-related INF package directory (especially `microsoft_bluetooth_a2dp.inf`), catalogs and BthA2dp.sys, and emit Include/Needs dependency list plus hashes/signature metadata. Then inspect INF decorations and package catalog before any Server-side experiment. No Server changes.

## 2026-11-23 23:40 — component-path audit

- The targeted Win10 exporter was inspected directly from Library. It is read-only and can recover named A2DP INF package folders from DriverStore / Windows INF locations, but it is not a full component-closure collector. It does not search WinSxS, enumerate arbitrary codec/provider DLLs or COM registrations, parse PE imports/exports/delay-imports, or verify CAT membership.
- Existing broader collectors are already in Library: `Collect-Win10-Bluetooth-A2DP.ps1` with optional `-IncludeDriverPackages`, and `Collect-Bluetooth-A2DP-Compare.ps1`. They add PnP, service, registry and selected system-driver context; PE and catalog verification remain offline tasks.
- Current repository CMake explicitly builds `ldacBT_enc` and `ldacBT_abr` as STATIC libraries and links them into `ldacsvc_core`; `service/encoder.cpp` calls the encoder API. This is source/static code, not a Windows 10 LDAC DLL.
- Microsoft documents Windows 10 A2DP codecs as SBC and aptX Classic; its profile driver is selected by INF/PnP and communicates with `Bthport.sys` using WDM IRPs/BRBs. No user-mode codec-provider DLL extension point is documented in that model.
- Official Alternative A2DP 1.8.3 supports Windows 10 22H2 and Windows 11 21H2–25H2; its FAQ requires the Windows 10/11 inbox Bluetooth stack and per-device driver installation. It is a third-party driver, not a DLL, and does not list Server 2022.
- BlueCaster 3.0.4 is an existing open-source alternative using WASAPI capture, codec encoders, BTstack A2DP/AVDTP/L2CAP and WinUSB. It requires a USB adapter and takes ownership of it; its published support is Windows 10 22H2 / Windows 11, not Server 2022.
- No new build, CI run, driver install, physical-host query, or host mutation occurred in this pass. The package-export dependency remains open.


## Win10 A2DP package capture — 2026-11-23 23:49 Kyiv

The targeted package collector completed on reference machine AS-KRM-WIN10 (Windows 10 Enterprise build 19045). Archive: `Win10-A2DP-Package-20261123-234936.zip`.

Confirmed install model:
- Source INF `microsoft_bluetooth_a2dp_src.inf` matches BTHENUM UUID 0x110B and delegates to `microsoft_bluetooth_a2dp.inf`.
- Common INF class MEDIA, DriverVer 10.0.19041.4355 (2024-04-12), copies `BthA2dp.sys`, installs kernel service BthA2dp with demand start, and registers KSCATEGORY_AUDIO source/sink interfaces.
- Common INF includes `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`; needs KS.Registration, WDMAUDIO.Registration, BtaMPM.CopyFilesOnly and mssysfx.CopyFilesAndRegister.
- `BthA2dp.sys`: version 10.0.19041.4355, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`, Authenticode Valid / Microsoft Windows / catalog signature.
- `BtaMPM.sys`: version 10.0.19041.5848, SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`, signature Valid.
- HFP and AVRCP package definitions and binaries were also captured.
- CAT files are not in the archive; the captured INF/SYS files are nevertheless signature-valid on the reference machine. Collection.log is empty, so the exact console warning user mentioned cannot be diagnosed from this archive; the manifest confirms successful capture.

This establishes the Windows 10 classic A2DP package structure but does not establish Server 2022 compatibility. Continue with INF OS applicability, package servicing/build provenance, and Server-side dependency comparison. No driver transplant or physical Server changes.


## Current state — 2026-11-24 01:42 Kyiv — Win10 A2DP component audit

The Windows 10 package capture is complete enough for static INF/PE work. This corrects the earlier 20:49/23:40 notes that said the common INF was still missing.

### Confirmed package graph
- Win10 19045 archive Win10-A2DP-Package-20261123-234936.zip contains source/common/sink A2DP INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys.
- The common INF (Class=MEDIA, 10.0.19041.4355) includes ks.inf, wdmaudio.inf and BtaMpm.inf; Needs KS.Registration, WDMAUDIO.Registration, BtaMPM.CopyFilesOnly and mssysfx.CopyFilesAndRegister. It registers BthA2dp as a demand-start kernel service and registers KSCATEGORY_AUDIO interfaces.
- btampm.inf (Class=SYSTEM, 10.0.19041.5848) is a CopyFilesOnly dependency for BtaMPM.sys.
- The source INF matches remote A2DP Sink UUID 0x110B. The sink INF is the reverse direction and is not required for playback to earbuds.
- The .cat absence is not proof of an unsigned package: the system-supplied INFs have no CatalogFile directive and Windows validates them against system catalogs. The source catalog identity and CBS component ownership are still required for cross-SKU staging.

### PE provenance and limits
- DriverStore BthA2dp.sys: 10.0.19041.4355, 282,624 bytes, SHA-256 5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3; E-119 reports PE32+ x64, native kernel, no delay-import directory, direct imports from ntoskrnl.exe only.
- A separate System32 BthA2dp.sys report is 279,040 bytes, SHA-256 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737, with 8 import descriptors / 144 imported functions. Secondary public inventories list a 279,040-byte BthA2dp.sys as 10.0.19041.1, but do not publish the hash; the 0442-to-version mapping remains provisional. Do not merge this with the DriverStore report. Prioritize the 10.0.19041.4355 DriverStore copy for compatibility analysis.
- BtaMPM.sys: 10.0.19041.5848, 43,008 bytes, SHA-256 DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD; PE32+ x64, imports ntoskrnl.exe, cng.sys and WppRecorder.sys.
- Export tables and complete Server-side import/export compatibility are not yet proven.

### Codec and product boundary
- Microsoft Windows 10 Classic Audio documents SBC and aptX Classic, not LDAC or AAC.
- OPPO Enco Buds2 ETE41 documents AAC/SBC only. It can validate SBC, not LDAC.
- Alternative A2DP Driver advertises LDAC but is proprietary, hardware-licensed and restricted by its EULA; the published OS matrix excludes Server 2022. Do not transplant or reverse-engineer it.
- The as-0101 repository is a fork of yariktop133/ldac-a2dp-windows. That upstream is a separate replacement-driver project, not a Windows 10 DLL package. No code changes were made.

### Server 2022 and next gate
- Archived Server 20348.5761 evidence has ks.inf, wdmaudio.inf, WMALFXGFXDSP.dll and SysFxUI.dll, but not the Microsoft A2DP profile package. This is consistent with Microsoft's documented lack of in-box Bluetooth support for Server SKUs, but technical binary compatibility is not yet established.
- The current Library inventory contains no ISO/WIM/ESD/CAB/MSU media. The next discriminating input is the original Windows 10 22H2 and Server 2022 image/component metadata (CBS MUMs/manifests, system catalogs, package identity and applicability).
- The last recorded OPPO BTHENUM 0x110B node was present on the local Intel Bluetooth radio (LOCALMFG&0002) and bound to the project's own oem75.inf (provider LDAC A2DP Project, service LdacA2dp, DriverVer 0.2.325.1600); Code 37 / 0xC000000D occurred at custom driver start. This is not a Microsoft BthA2dp package test. The Server snapshot also had bthserv, Audiosrv and AudioEndpointBuilder running; BTAGService/BthAvctpSvc were absent. No fresh live physical-host check, build, CI run, runtime test, driver install or host mutation occurred in this pass.
- Next runtime work, if WIM and PE compatibility pass, belongs in a disposable Server 2022 VM and must keep service start, enumeration, driver load, endpoint, SBC negotiation and actual audio as separate gates. LDAC requires a different sink.

Detailed file-level map: [WIN10_COMPONENT_AUDIT.md](WIN10_COMPONENT_AUDIT.md).


## 2026-11-24 — exact component recovery replaces symbol-server guessing

GitHub Actions CI #463 (run 45311922753) completed successfully and produced the Windows 10/Server 2022 Catalog audit artifacts. It established that the A2DP SYS entries extracted from KB5036979 and KB5126657 are PSF forward-delta payloads, not full PE images. The Server 2022 KB5126655 package scan found core Bluetooth packages but no A2DP INF/SYS or BtaMPM CBS manifest references.

The Winbindex symbol-server download path returned files with matching PE timestamp and size but different file versions and SHA-256 hashes from the captured 19041.4355 / 19041.1 / 19041.5848 targets. Those PE reports are not accepted as exact target evidence.

A new isolated branch, experiment/win10-a2dp-uup-image-audit-20261124, now runs an offline UUP image audit for Win10 19045.5917 and Server 20348.5761. GitHub Actions run 45317582562 (workflow run #3) is in progress after a narrow Get-FileHash compatibility fix. No binary payloads are uploaded, and no physical host is touched.

Current stage remains package/static research only. No A2DP endpoint, SBC negotiation, or actual audio has been demonstrated. See WIN10_UUP_IMAGE_AUDIT.md.


## 2026-11-24 — exact component recovery replaces symbol-server guessing

GitHub Actions CI #463 (run 45311922753) completed successfully and produced the Windows 10/Server 2022 Catalog audit artifacts. It established that the A2DP SYS entries extracted from KB5036979 and KB5126657 are PSF forward-delta payloads, not full PE images. The Server 2022 KB5126655 package scan found core Bluetooth packages but no A2DP INF/SYS or BtaMPM CBS manifest references.

The Winbindex symbol-server download path returned files with matching PE timestamp and size but different file versions and SHA-256 hashes from the captured 19041.4355 / 19041.1 / 19041.5848 targets. Those PE reports are not accepted as exact target evidence.

A new isolated branch, experiment/win10-a2dp-uup-image-audit-20261124, now runs an offline UUP image audit for Win10 19045.5917 and Server 20348.5761. GitHub Actions run 45317582562 (workflow run #3) is in progress after a narrow Get-FileHash compatibility fix. No binary payloads are uploaded, and no physical host is touched.

Current stage remains package/static research only. No A2DP endpoint, SBC negotiation, or actual audio has been demonstrated. See WIN10_UUP_IMAGE_AUDIT.md.

## 2026-11-24 05:20 — static package compatibility lead; exact UUP audit pending

- Re-read Project Source entry point, canonical docs and relevant repo tree. Existing Win10 package archives were not requested again.
- Read-only branch check: `server-2022-oppo` remains `39eea45ab5d93c09836819db75f2a64177fbf09a`; no code changes there.
- CI #463 (45311922753; commit `4459e152886cec3c2d4a2f0458a5467469c7b3dc`) succeeded. Catalog SYS payloads are PSF deltas, not complete PE files. Server KB5126655 has Bluetooth core but no A2DP/BtaMPM profile package references.
- Non-exact symbol-server candidate BthA2dp 10.0.19041.6392 (SHA-256 `3d026ae46f46c2323e9e70b194f1fb5eb32974c42c4fd1f9a24e44214dafd4ec`) has 8 import descriptors / 149 symbols. Companion BtaMPM 10.0.19041.7660 (SHA-256 `7e9c0cfcf073d501fe4cbdf632fc9f3a22c088abaccc73f9735a603a4c9951dd`) exports all 10 symbols imported by BthA2dp from btampm.sys.
- 129/149 BthA2dp imports matched the available later Server 20348.5866 reference set or companion BtaMPM exports. The remaining 20 imports are from HAL (1), SleepStudyHelper (8), WDFLDR (4), ksecdd (7); those Server reference files were omitted, so they are untested, not missing. This is not the captured 19041.4355 binary or target 20348.5761.
- Found corrected `pe_imports_a2dp_fixed.py` in Library. Reports (2)/(3) are byte-identical and target the separate 279,040-byte System32 copy. The script only emits direct imports.
- UUP audit #3 (45317582562; commit `e9900fc894772997526995feeaecfff4a9ec5ff0`) is still in progress for Win10 19045.5917 and Server 20348.5761.
- Common INF includes ks.inf, wdmaudio.inf, BtaMpm.inf; Needs KS.Registration, WDMAUDIO.Registration, BtaMPM.CopyFilesOnly and mssysfx.CopyFilesAndRegister; AddService BthA2dp is demand-start and KSCATEGORY_AUDIO interfaces are registered. Existing Server comparison already has generic KS/WDMAUDIO/MSSysFx dependencies. Package-level adaptation remains the preferred hypothesis pending exact checks.
- No driver/device/endpoint/audio runtime stage was tested; no physical-host query or mutation occurred.

## 2026-11-24 05:25 — exact package version differs from later symbol-server candidate

- The captured DriverStore BthA2dp 10.0.19041.4355 (282,624 bytes; SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`) is recorded in E-119/GNU objdump as importing directly from `ntoskrnl.exe` only.
- The separate System32 BthA2dp copy is 279,040 bytes, SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`, and has 8 descriptors / 144 imports. It is not the DriverStore package binary.
- CI #463's symbol-server BthA2dp 10.0.19041.6392 candidate is also 282,624 bytes but has 8 descriptors / 149 imports and a different SHA. This proves the import surface can change across file versions; the 19041.6392 candidate must not be used as a proxy for 19041.4355.
- Exact package BtaMPM 10.0.19041.5848 remains a separate 3-descriptor / 42-import binary. Its imports are ntoskrnl, cng and WppRecorder; its exact exports still need to be compared against Server 20348.5761.
- UUP 19045.4355 x64 is a candidate image for reproducing the captured BthA2dp version if the current 19045.5917 image does not contain matching hashes. No new UUP run started in this pass.

## 2026-11-24 05:27 — official LDAC support boundary confirmed

- Sony Support article 00260277 (last modified 2025-03-11) explicitly states that Windows/macOS do not support LDAC at OS level, regardless of the Bluetooth controller. This closes the search for a hidden Microsoft/Sony inbox LDAC DLL.
- Windows 10 A2DP package remains the primary SBC path. A later LDAC milestone requires an explicit third-party A2DP provider/transport or an alternate user-mode stack; AOSP libldac alone is only an encoder library.
- No change to code branches or physical host.

## 2026-11-24 05:30 — exact BtaMPM import closure cross-check

- Parsed the exact BtaMPM 10.0.19041.5848 import list from reports (2)/(3): 37 ntoskrnl, 1 cng/SystemPrng and 4 WppRecorder imports (42 total).
- The exact 42-name set matches the 19041.7660 symbol-server candidate from CI #463. All 42 names are present in the available later Server 20348.5866 export references. This strengthens the package-compatibility lead for BtaMPM imports, but it is not a pass for target Server 20348.5761; the exact BtaMPM export table is still missing.
- No driver/device/audio runtime test and no physical-host access.

## 2026-11-24 06:16 Europe/Kyiv — UUP audit #3 failure triage and corrected reruns

- **CONFIRMED / CI-only harness failure:** UUP image audit run #3, [45317582562](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562), commit `e9900fc894772997526995feeaecfff4a9ec5ff0`, job `138188044012`, failed at `extract_uup_image_a2dp.ps1:370`: PowerShell reported that the selected `Get-WindowsImage` object had no `Version` property. The error occurred before `Mount-WindowsImage`; no PE, INF, registry, CAT or compatibility result was produced, and the run uploaded no artifact. This is a script/API-shape failure, not a Windows binary or Server compatibility failure.
- **Corrective code commit:** [144d42105a26d5aa21f159ae068b17a047f724a9](https://github.com/as-0101/ldac-a2dp-windows/commit/144d42105a26d5aa21f159ae068b17a047f724a9) removes reliance on the absent DISM property and verifies exact image identity from a temporary copy of the offline SOFTWARE hive (`CurrentBuild`, `UBR`, `EditionID`, product and installation type). It also adds `HAL.dll`, `SleepStudyHelper.sys`, `WDFLDR.SYS` and `ksecdd.sys` to the PE/reference set.
- **Companion dependency correction:** [e947970356884ead996bcc7347fa0e5554aa770b](https://github.com/as-0101/ldac-a2dp-windows/commit/e947970356884ead996bcc7347fa0e5554aa770b) copies the Win10 image's DriverStore-preferred `BtaMPM.sys` into the reference set before auditing Win10 `BthA2dp.sys`, so profile-management imports are not incorrectly reported as unresolved merely because Server 2022 lacks inbox BtaMPM.
- Follow-up UUP audit run #4 [45325486392](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325486392) uses the offline-hive and expanded kernel-reference fix. Run #5 [45325586394](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325586394) uses the latest companion-BtaMPM fix. Both were in progress at this update; no result is claimed.
- The previously captured Win10 package archive remains the source of the exact expected SHA values. It was not re-exported. No physical-host access or changes, package staging, driver installation, device restart, runtime audio test or ACX bind-probe occurred.
- Next gate: exact image identity → exact hashes → complete PE import/export closure → offline SYSTEM/SOFTWARE registrations and system catalog membership. Only then consider disposable-VM package staging. SBC/endpoint/audio remain untested.

## 2026-11-24 06:24 Europe/Kyiv — exact Windows 10 vs Server 2022 A2DP INF binding delta

- **CONFIRMED from archived INF comparison:** Server 2022 `bth.inf` maps BTHENUM Audio Sink UUID `{0000110b-0000-1000-8000-00805f9b34fb}` to `BthGenericService` using a hardware ID with the `_GENERIC` suffix. The `BthGenericService.NT.Services` section uses a null `AddService`; `BthGenericService.NT.AddProp` only sets `GenericDriverInstalled`. It does not register the `BthA2dp` service.
- **CONFIRMED from archived Win10 INF comparison:** `microsoft_bluetooth_a2dp_src.inf` matches the base BTHENUM UUID 0x110B (commented `REMOTE A2DP SNK GUID`). Its install section includes `microsoft_bluetooth_a2dp.inf` and needs `Common_BthA2dp_Install`; its Services and Interfaces sections chain to the common sections.
- The Win10 common INF includes `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`; needs `KS.Registration`, `WDMAUDIO.Registration`, `BtaMPM.CopyFilesOnly`, `mssysfx.CopyFilesAndRegister`; copies `BthA2dp.sys`; registers a demand-start kernel service (`StartType=3`, `%12%\\BthA2dp.sys`) and KSCATEGORY_AUDIO source/sink interfaces.
- **Engineering implication:** the smallest plausible Server adaptation is not a new radio/core stack or new ACX driver. It is the existing Win10 A2DP source/common INF + its exact package files, layered on the existing Server Bluetooth core. This is a static INF-path finding and a candidate only; driver rank, CBS/catalog ownership, exact PE compatibility, package staging and runtime are still unverified.
- Evidence source: existing Library comparison transcripts `00-33.txt` (file `file_000000004d5882109961f477df8a1c48`) and `00-34.txt` (file `file_000000004c208210bec65c68b97e9b69`). No new package collection was performed.
- No INF was installed or staged. No physical-host query or mutation, driver install, device restart, BCD/security/certificate/OS change, runtime audio test or ACX bind-probe occurred.

## 2026-11-24 06:32 Europe/Kyiv — LDAC codec and A2DP transport separated; existing DLL option assessed

- The current repository is confirmed as a fork of `yariktop133/ldac-a2dp-windows`. Its parent project is a KMDF/ACX A2DP source driver; the upstream README targets Windows 11 and ACX 1.1 with test-signing. This is not a Windows 10 codec DLL or a compatible Server 20348 drop-in. The Server 2022 work branch remains unchanged at `39eea45ab5d93c09836819db75f2a64177fbf09a`.
- The fork already contains Sony/AOSP `libldac` version **2.0.2**. `CMakeLists.txt` builds `ldacBT_enc` and `ldacBT_abr` as STATIC libraries and links them into `ldacsvc_core`; `service/encoder.cpp` calls `ldacBT_encode` and packetizes frames with the separate AVDTP media layer. There is no product `ldac.dll` in this build.
- Source-declared encoder API: `ldacBT_get_handle`, `ldacBT_free_handle`, `ldacBT_close_handle`, `ldacBT_get_version`, `ldacBT_get_sampling_freq`, `ldacBT_get_bitrate`, `ldacBT_init_handle_encode`, `ldacBT_set_eqmid`, `ldacBT_get_eqmid`, `ldacBT_alter_eqmid_priority`, `ldacBT_encode`, `ldacBT_get_error_code`. ABR API: `ldac_ABR_get_handle`, `ldac_ABR_free_handle`, `ldac_ABR_Init`, `ldac_ABR_set_thresholds`, `ldac_ABR_Proc`. These are C API declarations; no built DLL PE export table/hash was produced in this pass.
- Decoder is separate: `tools/ldacverify/build-ldacdec.py` fetches `anonymix007/libldacdec` at commit `c90094b15e25aef0e47c6d775fa94aceb36cabbc` and builds `ldacdec_wav.exe` for verification only. It is not part of the product or Windows Bluetooth stack.
- Existing external DLL recipe found in [Incus Multicodec](https://github.com/incustechsupport/incus-multicodec): `btmulticodec/ldac.py` loads `bin/ldac.dll`; `native/build.cmd` builds it from Sony/AOSP libldac with MSVC `/LD /MT` and `__declspec(dllexport)` for LDACBT/ABR APIs. The repository does not commit a prebuilt DLL, so no PE hash/import table is available. This is an encoder DLL only, not a COM/KS A2DP provider or Bluetooth transport.
- Incus Multicodec implements transport separately with Bumble + WinUSB and WASAPI loopback; no kernel driver, but it takes over a USB Bluetooth adapter and bypasses the Windows A2DP profile stack. It targets Windows 10/11; Server 2022 is not declared supported. [BlueCaster](https://github.com/SeiyaFunaokaJP/BlueCaster) uses BTstack + WinUSB with similar adapter takeover; its BTstack license is personal/non-commercial. [OpenA2DP](https://github.com/RafiMota/open-a2dp) remains pre-alpha with unbuilt/untested drivers.
- **Engineering conclusion:** the missing piece is A2DP profile/transport integration, not an LDAC encoder DLL. Keep the Win10 source/common INF path as the primary SBC milestone. For LDAC, evaluate an existing user-mode stack with a dedicated USB adapter only after SBC is stable; do not try to register `ldac.dll` as a Windows A2DP codec provider. The custom ACX driver remains suspended.
- No DLL was built, no package staged, no physical-host query/mutation, no driver installation, no runtime negotiation/audio test and no ACX experiment occurred.
