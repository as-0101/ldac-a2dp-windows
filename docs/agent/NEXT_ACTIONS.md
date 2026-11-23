# NEXT_ACTIONS — current priority

**Updated:** 2026-11-23 23:40 Europe/Kyiv

## Only current external dependency

Run the already available read-only `Export-Win10-A2DP-Package.ps1` on the Windows 10 reference machine (`AS-KRM-WIN10`). The current Win10 archives are not a complete installable package: the source INF is present, but `microsoft_bluetooth_a2dp.inf` and its catalog are missing.

Library path: `/Bluetooth на Windows Sever 2022/Export-Win10-A2DP-Package.ps1`  
Command (elevated PowerShell, from the script directory):

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Export-Win10-A2DP-Package.ps1"`

Expected output: source and common A2DP INFs, complete containing DriverStore package directories, catalogs, `BthA2dp.sys`, INF Include/Needs report, file/version/signature inventory, SHA-256 manifest, and ZIP. The script is read-only. Do not run it on the physical Server 2022 host.

If the output does not contain `microsoft_bluetooth_a2dp.inf` plus its catalog, stop before installation and extend the read-only search to WinSxS. Do not manually copy only `BthA2dp.sys`.

## Exporter v1 audit — what it does and does not collect

The existing `Export-Win10-A2DP-Package.ps1` was inspected (Library file ID `file_00000000ae6c82108239f67bdde421be`, 5,108 bytes). It searches DriverStore and `%windir%\\INF`, copies matching package directories, captures `BthA2dp.sys`, and writes hashes, file versions, Authenticode status and the direct INF Include/Needs list. It is read-only.

It does **not** search WinSxS, recursively resolve every included INF, enumerate all codec/transport/provider DLLs or COM registrations, parse PE imports/exports/delay-imports, or verify CAT membership. If the common INF or CAT is absent, expand the read-only search to WinSxS; do not install or copy a partial package.

The wider collectors already in Library are available if broader system context is needed: `Collect-Win10-Bluetooth-A2DP.ps1 -IncludeDriverPackages` and `Collect-Bluetooth-A2DP-Compare.ps1`. Their output still needs offline PE/catalog analysis. Do not ask for the old archives again; the only missing deliverable is the complete targeted Win10 package export.

## Work after the package arrives

1. Verify every INF, CAT, SYS, DLL and related file: SHA-256, version resource, PE machine, imports, delay imports, exports, API-set references, OS assumptions, Authenticode/catalog signature, and catalog membership.
2. Resolve the full INF `Include` / `Needs` graph and service/interface registrations.
3. Compare every required binary with its Server 2022 counterpart and the Server runtime.
4. Create a disposable Server 2022 VM test plan. Do not install anything on the physical host.
5. Test in order: service start → BTHENUM enumeration → profile driver load → A2DP endpoint → SBC negotiation → actual SBC stream/audio.
6. Only after SBC passes, test LDAC with a different LDAC-capable receiver. Enco Buds2 is AAC/SBC-only.

## Parked

- ACX AudioCodec bind-probe and all new ACX/WDK bind experiments.
- New Bluetooth/A2DP driver development.
- Any physical Server 2022 driver install, device restart, BCD/test-signing/security/certificate change, OS update/rollback, or installer/upgrade/rollback script.
- HFP/microphone work.

> Historical action lists below are preserved for traceability. This section supersedes their old ACX next steps and any request to re-run already completed collectors.

---

# Current next action — resolve common Microsoft A2DP INF dependency (2026-11-23)

The newly received Win10 archive confirms the A2DP source INF is only a thin profile binding. It contains:
- BTHENUM service GUID 0x110B match;
- `Include=microsoft_bluetooth_a2dp.inf`;
- `Needs=Common_BthA2dp_Install`, `.Services`, and `.Interfaces`.

The current collector did **not** capture `microsoft_bluetooth_a2dp.inf`, its catalog, or its package directory. Do not attempt to install/copy only `microsoft_bluetooth_a2dp_src.inf` or BthA2dp.sys; that would omit the common install sections and signed package metadata.

1. Run `Export-Win10-A2DP-Package.ps1` on the working Windows 10 machine as Administrator. It is read-only and exports any located A2DP/HFP/AVRCP INF package folders, catalogs, BthA2dp.sys, Include/Needs relationships, hashes and signature metadata.
2. Inspect whether `microsoft_bluetooth_a2dp.inf` exists in DriverStore or Windows INF, and identify its referenced INF dependencies. Record catalog and OS decorations.
3. Compare the complete package against Server 2022 component store/DriverStore. Verify Server applicability and signing before considering a disposable-VM installation test.
4. Do not modify the physical Server 2022 host.

Current Win10 source package facts and Server comparison are in E-044–E-048 of [EVIDENCE](docs/agent/EVIDENCE.md).

# Current continuation — 2026-11-23 (physical Server inventory reviewed)

**Decisive finding:** the physical Server pairs/enumerates OPPO and sees A2DP UUID 0x110B, but binds it to generic `bth.inf` / `BthGenericService.NT` ("Audio Sink Service"). This is a null-service placeholder that only sets `GenericDriverInstalled=1`. Unlike Win10, the Server DriverStore snapshot has no `microsoft_bluetooth_a2dp_src.inf` or `BthA2dp.sys`; no OPPO AudioEndpoint is created. The Server's radio/BTHPORT/BthEnum/BTHUSB are running, so the fault is now localized to A2DP profile-to-audio binding.

Server archive: `Bluetooth-A2DP-Compare-AS-KRM-WS-20261123-204114.zip`; build 20348; PnP 16; AudioEndpoints 4; SignedDrivers 16. The MMDevices registry contains A2DP references for other IDs/MACs, but these are not live OPPO endpoints. `BthAudioHF` is a stopped third-party Realtek RtkHfp.sys service, not Microsoft BthHFAud. SetupAPI shows prior custom LdacA2dp binding; Kernel-PnP event 219 reports its load failure. A later event 7040 changed its startup from Manual to Disabled; causality is not established.

**Next action:** collect the corrected Win10 DriverStore package (the previous Win10 archive did not include it). Need `microsoft_bluetooth_a2dp_src.inf`, its CAT/package folder, `BthA2dp.sys`, INF OS decorations, dependencies and signatures. Compare first; do not install/copy/import anything yet. Keep the physical Server unchanged.

Collector note: the Server archive is usable. Its final SHA256SUMS.csv self-hash attempt failed due to a sharing violation while writing that same CSV; this does not invalidate the collection. Fix by excluding SHA256SUMS.csv from its own hash enumeration.

See EVIDENCE.md entries E-044–E-053 and PROJECT_STATE latest section.

---

# Current continuation — 2026-11-23 (classic A2DP architecture correction)

**Stop treating ACX as the foundation for the Windows 10-style A2DP profile.** The reference Windows 10 machine proves the working path uses:
- `BthA2dp.sys` service `BthA2dp` (RUNNING), INF `microsoft_bluetooth_a2dp_src.inf`;
- BTHENUM A2DP service GUID `0000110B-0000-1000-8000-00805F9B34FB`;
- MEDIA class, section `BthA2dpSrc`, `KS=1`;
- `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf` included in the class registration;
- separate HFP components `BthHFEnum`/`BthHFAud`, AVRCP transport, BTAGService, BthAvctpSvc, bthserv, Audiosrv and AudioEndpointBuilder.

Microsoft documents classic A2DP as a WDM profile driver communicating with BthPort; ACX is not the documented classic A2DP profile-driver model. ACX is used in a separate LE Audio architecture. The repeated ACX class-bind failures therefore do not answer how to enable Windows 10-style classic A2DP on Server.

**Latest uploaded ZIP is a duplicate** of the earlier Win10 archive (SHA-256 `3bebbee156019cfa6e1c031e8158c8d1e230fd6f64dd57f3a3bc5aae991254cd`); it is not the output of `Collect-Bluetooth-A2DP-Compare.ps1`. It contains no Server inventory and did not capture the A2DP INF/DriverStore package. The old PnP CSV is empty, but signed-driver/registry/endpoint evidence is valid.

## Immediate actions
1. Run the corrected `Collect-Bluetooth-A2DP-Compare.ps1` on Windows 10 and Server 2022; it captures signed INF packages and driver-store folders for a like-for-like comparison.
2. Compare BthA2dp, BthPort, BthEnum, BthUSB, HFP, AVRCP, BTAGService, BthAvctpSvc, AudioEndpointBuilder, KS/WDMAudio and the A2DP INF/registry binding.
3. Inspect INF OS decorations, package catalog/signature and dependencies before considering any reuse. Never copy SYS/DLL files or import Win10 registry exports directly.
4. Keep the physical Server unchanged. No driver install, service/device changes, certificate/BCD/security changes, or reboot.

Microsoft sources:
- https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-driver-stack
- https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack
- https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/bluetooth-bypass-guidelines
- https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects
- https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions

---

# Current continuation — 2026-11-23 evening (hardware codec audit)

**Critical finding now confirmed at product level:** the user's phone settings identify the connected headset as OPPO Enco Buds2. OPPO's official specification maps Enco Buds2 to earbud model ETE41 / case ETE42 and lists AAC/SBC only, not LDAC. The photos do not show a printed ETE code, but the app identity plus official product spec are sufficient to scope this headset as AAC/SBC-only.

1. Verify the exact headset model from its label/box. ETE41 is the Enco Buds2 earbud model; ETE42 is the charging-case model.
2. If ETE41 is confirmed, stop LDAC-specific tests for this headset. Re-scope the first goal to stable AAC/SBC A2DP playback, or use a receiver whose official specs explicitly include LDAC.
3. CI #17 / [run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058) is complete. The official EWDK 20348.1 ISO contained no ACX 1.0 stub at the inspected paths (`EWDK_ACX10_STUB_FOUND=false`); no probe build or runtime test occurred. Do not describe the workflow's green status as a driver test. Stop the WDK 20348.1 branch unless a verified ACX 1.0 stub source is found.
4. BlueCaster 3.0.0 (formerly A2DP Windows Bridge) is a credible alternate architecture: it takes a dedicated USB Bluetooth adapter through WinUSB and runs A2DP in user mode, bypassing ACX. Its published OS matrix is Windows 10 22H2 / Windows 11; Windows Server 2022 is not listed. Server 2022 compatibility is therefore UNTESTED. Do not install it on the physical host; first design an isolated test with a spare USB adapter.
5. BlueCaster's verified-hardware list does not list OPPO Enco Buds2. It cannot add LDAC to ETE41; for LDAC tests use an LDAC-capable headset.
6. Keep the physical server unchanged: no driver installation, certificate changes, BCD/security changes, Bluetooth rebind/restart, rollback, reboot, or OS update.

Sources:
- OPPO official Enco Buds2 specs: https://www.oppo.com/ua/accessories/oppo-enco-buds2/specs/
- BlueCaster platform/setup/hardware: https://seiyafunaokajp.github.io/BlueCaster/ ; https://seiyafunaokajp.github.io/BlueCaster/setup.html ; https://seiyafunaokajp.github.io/BlueCaster/hardware.html
- CI #17: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058

---

# Current continuation — 2026-11-23 (CI #16 complete; CI #17 WDK 20348.1 control)

**Current status (2026-11-23 12:53 Kyiv):** CI #16 / [run 45084678951](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45084678951), commit `9da48c3ecd5921f8cab47888325b156dc9a536f3`, completed its build and hosted runtime harness. The minimal Microsoft AudioCodec-derived ACX 1.0 client still fails PnP Code 37 / `0xC000000D` before DriverEntry. The candidate INF was selected as `oem13.inf`. The CI #16 runtime PDB now confirms `WDF_CLASS_BIND_INFO` size 0x50 and `WDF_CLASS_BIND_INFO2` size 0x78, matching the ACX 1.0 descriptor size; the simple size-mismatch explanation is rejected. CI #17 / [run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058), commit `79460f03492a54444473589dd142da864a703a73`, is still in build step 4 (official EWDK 20348.1 download/stub inspection/build); parser and project-XML gates passed, but no artifact or runtime result exists yet.

1. Continue monitoring [CI #17 / run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058), branch `experiment/acx10-wdk20348-control`, commit `79460f03492a54444473589dd142da864a703a73`, build job `137638217372`. At the last check, parser/XML gates passed and step 4 (download/inspect/build) was still running; no artifact or outcome is available yet.
2. If EWDK 20348.1 contains ACX 1.0 headers/stub and KMDF 1.31 libraries, build the same source/INF with its matching SDK/WDK and VS2019, then test on a fresh hosted Server 2022 runner. Treat this as a toolchain-bundle comparison because both WDK and compiler generation change.
3. Audit the captured EWDK entrypoint before interpreting the build: Microsoft documents mounting the ISO, running `LaunchBuildEnv.cmd`, then `SetupVSEnv`; the current script prefers `SetupBuildEnv.cmd` if present. Inspect the actual selected script and captured environment in the artifact. Do not assume this path is correct until verified.
4. Compare the old and current ACX 1.0 stub hashes, descriptor size/version, function/structure counts, WDF minimum version, relocation targets, and resulting SYS/PDB. If the probe reaches DriverEntry, compare the WDF/ACX bind descriptor and DriverEntry sequence with LDAC. If it fails similarly, focus on ACX runtime class-bind validation, not INF topology.
5. CI #16's Server 2022 runtime PDB resolves `WDF_CLASS_BIND_INFO` as 0x50 bytes and `WDF_CLASS_BIND_INFO2` as 0x78 bytes. The ACX 1.0 descriptor is 0x78 bytes, so the simple descriptor-size mismatch is rejected. The ACX 1.0 class module is present before the probe. Exact pointer values, ACX-specific bind semantics and the internal failing operation remain unknown.
6. Keep the physical server unchanged: no driver installation, certificate changes, BCD/security changes, device restart, rollback or OS update. No user action is currently required.

CI #16 build/runtime artifacts and the descriptor compatibility report are durably preserved and indexed in `research/ARTIFACT_INDEX.md`. The CI #16 runtime artifact remains in `/Bluetooth LDAC Research/Artifacts/`; the build artifact and descriptor report are in `/LDAC Project/Incoming/`.

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
# Current continuation — 2026-11-23 (Windows 10 A2DP reference archive reviewed)

**Strongest finding:** Windows 10's working OPPO path uses the classic Microsoft Bluetooth A2DP profile driver `BthA2dp.sys` (service `BthA2dp`) installed by `microsoft_bluetooth_a2dp_src.inf`. Its BTHENUM service GUID is 0x110B. The Stereo and Hands-Free audio endpoints are healthy.

- Reference: Windows 10 Enterprise x64 build 19045.
- `BthA2dp.sys` 10.0.19041.4355, service RUNNING.
- HFP: `BthHfEnum`/`BthHFAud`; AVRCP: `Microsoft.Bluetooth.AvrcpTransport.sys`.
- BTAGService, BthAvctpSvc, bthserv, Audiosrv and AudioEndpointBuilder RUNNING.
- Microsoft documents classic A2DP as a separate WDM profile driver communicating with BthPort; ACX is documented for Bluetooth LE Audio VSAP. Microsoft also states Windows Server SKUs lack in-box Bluetooth support.
- Initial Win10 collector's optional PnpDevice call failed localization and left one CSV empty; the signed-driver inventory and endpoint dump are valid. A2DP INF/DriverStore package still needs capture.

**Next:** run the corrected read-only `Collect-Bluetooth-A2DP-Compare.ps1` on both Win10 and Server 2022. Compare package files, INF target decorations, services, PnP bindings and hashes. Do not copy individual SYS/DLL files or import registry exports. No changes to the physical Server.

Microsoft references:
- https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-classic-audio
- https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-driver-stack
- https://learn.microsoft.com/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack
- https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-low-energy-audio
- https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions

---
