# Current continuation — 2026-11-22 (after CI #255)

**Current blocker:** ACX 1.0 driver still fails before DriverEntry on hosted Server 2022 even when Acx01000 is explicitly RUNNING. The simple ACX class-version mismatch hypothesis is not sufficient.

1. Build a minimal ACX 1.0 client derived from Microsoft's official AudioCodec sample, using the same WDK 10.0.26100.6584, KMDF 1.31, and hosted Windows Server 2022 runtime. Keep INF topology intentionally simple (MEDIA/root-enumerated sample topology) and instrument the exact first failing stage.
2. Capture pre-install `!wdfldr acx01000` and relevant runtime/client bind metadata; capture PnP/Kernel-PnP and debugger output after install. Ensure the ACX runtime remains running at the time the driver is started.
3. If minimal sample binds, compare its WDF/ACX bind descriptor and DriverEntry sequence with LDAC; isolate project-specific descriptor, build settings, or initialization metadata. If it fails identically, investigate WDK 26100 ACX 1.0 stub versus Server 2022 ACX 1.0 runtime compatibility.
4. Correct stale comment in `build_driver.cmd` on the experimental branch only if still present; do not change production code as part of documentation reorganization.
5. Preserve CI #248 report (artifact 14769048266, digest e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb) and CI #255 stub report (artifact 14769755224, digest 8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce) before GitHub artifact expiry.
6. Do not ask for or perform physical server changes. No driver install, certificate changes, BCD changes, device restart, rollback or OS update. Physical testing remains a separate authorization-gated decision.

See [BUILD_REGISTRY](../../research/BUILD_REGISTRY.md), [TEST_MATRIX](../../research/TEST_MATRIX.md), and [ARTIFACT_INDEX](../../research/ARTIFACT_INDEX.md). The earlier next-action sections below are retained as history and are superseded by this block.

---

## Current continuation — 2026-11-22 20:28 Kyiv

**Current blocker:** finish the hosted LiveKD debugger experiment without changing the physical server.

1. CI #6 (`45054673989`) and #7 (`45054866734`) were cancelled; their logs show KD command-line usage rather than a class query. CI #8 (`45056354003`) failed because LiveKD could not find kd.exe and created no dump. Workflow fix commit `02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3` is not yet verified by CI. CI #5 remains the only successful capture; public WDF symbols still blocked class enumeration.
2. Do not infer the runner's ACX class version from `Acx01000.sys` file version `10.0.20348.5866`. The physical host's previously recorded class version is ACX 1.0.
3. If a fresh physical-host snapshot is needed, prepare a corrected LiveKD-based capture using the user's existing debugger/symbol environment. No BCD changes, driver installation, device restart, or OS update.
4. Do not ask the user to repeat the completed `status` pre-check; the package is extracted and the one-A2DP / `oem75.inf` / Code 37 baseline is confirmed.
5. Do not run `prepare-oppo-host.cmd`, `upgrade-oppo.cmd`, `install-oppo.cmd`, or `rollback-oppo.cmd` without separate explicit authorization.

Previous action lists below are historical snapshots; this section is the current continuation.

# Next actions — exact continuation

**Current blocker:** no physical-host test of the successful ACX 1.0 package has been performed. Do not touch the user's server without explicit authorization.

1. Preserve run #133 artifacts before their expiry (2026-11-29): test package artifact 14763242251 and unsigned driver artifact 14763157658. Record SHA-256 digests from PROJECT_STATE.md.
2. Inspect the downloaded test package and unsigned driver package contents: confirm INF DriverVer, SYS binary, package identity and that the driver was built from the ACX 1.0 experiment. The build job log shows INF stamp 0.2.326.1634.
3. Verify the effective ACX 1.0 include and link inputs from build diagnostics or package metadata. Current project file sets ACX_VERSION_MINOR=0 and constructs both paths from this macro; captured CI log does not echo the expanded paths.
4. Prepare a controlled physical-host test plan with a precise rollback to the previously active package. Do not execute it until the user explicitly authorizes the server-side test.
5. If authorized, capture Kernel Debug Output / WinDbg before restarting only the OPPO devnode. Primary success signal: `LdacA2dp: DriverEntry started`; primary failure signal: the same ACX class-bind status.
6. Interpret only the first actual failing stage. If DriverEntry is reached, the next layer is `WdfDriverCreate`, then `AcxDriverInitialize`, then ACX device/circuit initialization. Do not jump directly to Bluetooth protocol debugging.
7. Update this state, evidence register, experiment record and Notion journal with exact observed data. Keep the journal append-only.

## One read-only user action needed

The latest PnP properties already confirm the active driver and failure status. To validate the extracted CI #133 candidate package before any proposed physical test, request only this read-only status command (no prepare/upgrade/restart/rollback):

```powershell
& 'C:\\LDAC-Test\\ACX10-Universal\\oppo-driver-tool.exe' status 2>&1 | Tee-Object -FilePath "$env:USERPROFILE\\Desktop\\ldac-acx10-precheck.txt"
```

Do not proceed to any system-changing operation without separate explicit authorization.


## New work after package review

1. **Do not install yet.** The CI #133 package is verified as a genuine ACX 1.0 build, but ACX 1.0 is documented by Microsoft as pre-release/not recommended for new driver development.
2. The target host's last recorded build is 20348.2849 (2024-11); newer cumulative build 20348.5873 exists (2026-11-13). Investigate separately whether a fully serviced Server 2022 image has a different `Acx01000.sys` version or ACX `CLASS_MODULE Version`. Current KB summaries do not prove a runtime change.
3. If an updated image/VM is available, capture `(Get-Item "$env:windir\\System32\\drivers\\Acx01000.sys").VersionInfo | Format-List FileVersion,ProductVersion` and WinDbg `!wdfldr Acx01000.sys`. Compare against the existing host's exact values. Do not combine OS update and LDAC driver installation in one experiment.
4. If the updated image still reports ACX class 1.0, proceed to prepare the isolated physical test/rollback plan for CI #133, requiring explicit user authorization before any server change.
5. If it reports ACX 1.1, revisit the ACX 1.1 branch first; do not install the 1.0 experiment merely because it compiled.
6. Review the stale `docs/stage5-audio-options.md` statement that INF class is MEDIA against current `LdacA2dp.inx` (Bluetooth class); preserve the current class until a discriminating test justifies change.

## Updated continuation — 2026-11-22

1. CI #143 / run 45050062916 completed successfully. All 3 jobs passed; the Windows Driver variant generated a test package and unsigned driver. Compare the two variants only if a package-level difference becomes relevant; neither build proves physical class binding.
2. Keep PR #3 draft and never merge it automatically. The A/B build only checks target-platform build/package effects, not runtime class binding.
3. Preserve CI #133 and #143 artifacts with their artifact IDs and SHA-256 digests before the 2026-11-29 expiry.
4. The strongest next discriminator remains a controlled physical-server load of the ACX 1.0 package, with a verified rollback package and Kernel Debug Output capture. Do not install or restart any device until the user explicitly authorizes the test.
5. On physical test, success is the first LdacA2dp DriverEntry debug message and absence of FxStubBindClasses class Acx 0xC000000D. If DriverEntry is reached, move to WdfDriverCreate, AcxDriverInitialize, ACX device/circuit creation, then A2DP/SBC.
6. If the ACX 1.0 test fails before DriverEntry, obtain the Server 2022 ACX PDB/bind metadata and measure the actual class function count; do not reuse the Windows 10 19045 counts.

## Physical test runbook

Read [PHYSICAL_TEST_RUNBOOK.md](PHYSICAL_TEST_RUNBOOK.md) before any user-side action. First request only the read-only status output after the CI #133 package is extracted to C:\\LDAC-Test\\ACX10-Universal. Do not ask the user to run prepare/upgrade until explicit authorization. The package's rollback returns to inbox bth.inf, not the successful run #129 WDK 26100 baseline package.


## Continuation correction — 2026-11-22 20:37 Kyiv

- Successful WDK 26100.6584 ACX 1.1 baseline is GitHub Actions run #129, ID 44922058650, commit 4571873b505c52a93db4c785fe3d083eabf8499e. Actual run #126, ID 44922013678, failed without artifacts. Existing Library names CI-126-* are legacy labels for run #129 artifacts; use run #129 in new references.
- Latest physical PnP output: LdacA2dp / oem75.inf / DriverVer 0.2.325.1600 / Code 37 / ProblemStatus 0xC000000D. The version matches run #129, so WDK 26100 pinning alone did not resolve the start failure.
- Read [2026-11-22 run #129 / PnP / LiveKD update](2026-11-22-RUN129-PNP-LIVEKD-UPDATE.md) for exact artifact hashes, run IDs and confidence status.
- Root-cause status: ACX class-version mismatch remains SUPPORTED, not proven. INF/service selection, Bluetooth class, Universal target and WDF 1.31/runtime 1.33 are not leading suspects.
- Next blocker: read-only status pre-check for CI #133 / Universal / ACX 1.0. Do not execute preparation, certificate import, upgrade, device restart, rollback, BCD change or OS update.


## Physical ACX 1.0 test — 2026-11-22 20:48 Kyiv

1. Hosted Server 2022 run #10 is complete. The documented !wdfldr acx01000 query returned CLASS_MODULE Version v1.0, WDF 1.31, and CLIENT_MODULE WDF 1.31 bound to Wdf01000 runtime v1.33. This matches the physical host's earlier class v1.0 result.
2. The leading explanation is now STRONGLY SUPPORTED: the active LDAC binary requests ACX 1.1 while the Server 2022 class module is ACX 1.0. The pre-DriverEntry STATUS_INVALID_PARAMETER is consistent with this mismatch; other bind metadata is not excluded.
3. Next discriminating test: CI #133 / Universal / ACX 1.0 on the physical host. Before any install, obtain only the read-only status pre-check after extraction to C:\\LDAC-Test\\ACX10-Universal:

   `& 'C:\\LDAC-Test\\ACX10-Universal\\oppo-driver-tool.exe' status 2>&1 | Tee-Object -FilePath "$env:USERPROFILE\\Desktop\\ldac-acx10-precheck.txt"`

4. Do not run prepare/upgrade/install, import certificates, restart the device, change BCD, rollback or update the OS without separate explicit authorization. The rollback script selects inbox bth.inf, not the previous run #129 baseline package.


## UBR 5870 / hosted ACX 1.0 test — 2026-11-22 21:02 Kyiv

1. Hosted Server 2022 UBR 5870 (KB5070761) still reports ACX CLASS_MODULE v1.0, matching the physical host at UBR 5761. Do not recommend OS update as the fix on current evidence.
2. CI #133 package preflight passed on a disposable runner: testsigning Yes, certificate and hashes verified, DevGen available.
3. Inspect build run #230 / 45058265287 on experiment/acx10-hosted-load. The job creates a temporary SWD device, installs the ACX 1.0 candidate, and queries the ACX class client list. Record whether LdacA2dp reaches the class client list and its PnP ProblemStatus.
4. If hosted load succeeds, the only physical blocker is the read-only package status pre-check. Then request separate explicit authorization before any physical install.
5. If hosted load fails, inspect the exact PnP status and Kernel-PnP events before changing the driver or asking for a physical test.
