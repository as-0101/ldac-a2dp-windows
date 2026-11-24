# Evidence register

Status labels: CONFIRMED = direct evidence; SUPPORTED = converging evidence, not conclusive; HYPOTHESIS = unproven; REFUTED = contradicted by a relevant test; UNTESTED = not checked; BLOCKED = needs external action.

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-001 | LDAC driver fails before its `DriverEntry` body; ACX class binding returns `0xC000000D`. | CONFIRMED | Notion journal, 21–22 Nov entries; DebugView `AS-KRM-WS.log` and `AS-KRM-WS(1).log`; Kernel-PnP ETW `LDAC-Trace.xml`. |
| E-002 | Kernel-PnP Event 227 records `STATUS_INVALID_PARAMETER` for the driver-init failure. | CONFIRMED | Notion journal; Library artifact `LDAC-Trace.xml`, file ID `file_00000000c3b08210ba662454ece33a1c`. |
| E-003 | Physical server's ACX class module reports version 1.0; its WDF client version is 1.31. | CONFIRMED | WinDbg `!wdfldr Acx01000.sys` output transcribed in Notion handoff. Distinguish CLASS_MODULE Version from WDF Version. |
| E-004 | Successful GitHub Actions run #129 requested ACX 1.1 and used WDK/SDK 10.0.26100.6584. | CONFIRMED | Branch project files and [run #129](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/44922058650). Actual run #126 (ID 44922013678) failed without artifacts. |
| E-005 | ACX 1.0 versus 1.1 mismatch explains the pre-DriverEntry binding error. | SUPPORTED | E-001 + E-003 + E-004; final proof requires physical-host test of ACX 1.0 build. |
| E-006 | ACX 1.0 experiment compiles successfully. | CONFIRMED | [CI run #133](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45044497961), head SHA `593e8f407ec18e72a332edbec323a4ddbbd27774`; all three jobs success. |
| E-007 | CI #133 package artifact was generated. | CONFIRMED | Artifact 14763242251, digest `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad`; artifact 14763157658, digest `1302c21c3278af9134b5959577a6daa629d0649fd1405148012e074e8147db9c`. |
| E-008 | CI #133 job ran on Windows Server 2022 build 20348; driver build and signability check passed with zero warnings/errors. | CONFIRMED | KMDF driver job 137276017983, logs; run #133. |
| E-009 | CI #133 resolves the ACX include and stub library specifically to 1.0. | SUPPORTED | Project file sets `ACX_VERSION_MINOR=0` and computes include/link paths from the macro; exact expanded path not printed in captured job log. Verify if needed. |
| E-010 | Driver passes ACX class binding on physical Server 2022. | UNTESTED | No ACX 1.0 package has been installed/tested on the physical server. |
| E-011 | KMDF 1.31 client versus WDF runtime 1.33 causes the pre-DriverEntry bind failure | REFUTED as a generic version mismatch | Microsoft KMDF version history; official `!acxkd` example shows client 1.31 / runtime 1.33 | This version pair is supported; investigate ACX class binding separately. |
| E-012 | ACX unload caused LDAC class-bind failure. | UNTESTED | ETW event order alone is not causal evidence. |
| E-013 | Universal target platform is unsupported on Windows Server 2022 and causes the ACX bind failure | REFUTED as an unsupported-platform claim; runtime effect remains untested | Microsoft Target Platforms; CI #143 build | Universal is supported on Server 2022. The successful alternate Windows Driver build does not prove either target's physical runtime behavior. |
| E-014 | Physical OPPO A2DP devnode remains on the failing ACX 1.1 driver from successful run #129 | CONFIRMED again on 2026-11-22 | User read-only PnP/status output | One present A2DP devnode; `oem75.inf`, `0.2.325.1600`, Code 37. No host mutation performed. |

## Artifact locations

Persistent source archive: Notion Files Library folder `/Bluetooth LDAC Research/Artifacts/`, Directory ID `6b0318b95f648191802d868fc1be5e96`. The handoff page contains exact Library IDs for legacy-named CI-126 ZIPs that actually belong to successful workflow run #129, plus diagnostic logs.

Current run #133 GitHub artifact URLs:
- [Test package 14763242251](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14763242251/zip)
- [Unsigned driver 14763157658](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14763157658/zip)
- [SDP probe 14762557767](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14762557767/zip)

All run #133 artifacts expire 2026-11-29. Their digests are in PROJECT_STATE.md.


| E-015 | CI #133 test package SYS is byte-identical to the unsigned artifact; package contents and hashes inspected. | CONFIRMED | Downloaded artifact 14763242251 and unsigned artifact 14763157658; local SHA-256 in [CI133_PACKAGE_REVIEW.md](CI133_PACKAGE_REVIEW.md). |
| E-016 | Successful run #129 PDB contains 221 ACX table-index symbols; CI #133 PDB contains 210; all 11 ACX 1.1-only DDI names are present in run #129 and absent in #133. | CONFIRMED | Binary/PDB comparison of artifacts 14714246739 and 14763157658; [Microsoft ACX version overview](https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview). Artifact 14714246739 belongs to workflow run #129, not run #126. |
| E-017 | All 36 distinct ACX calls used by the LDAC driver are present in the CI #133 PDB API table. | CONFIRMED | Source-call extraction and PDB symbol check; [CI133_PACKAGE_REVIEW.md](CI133_PACKAGE_REVIEW.md). |
| E-018 | ACX 1.0 is documented by Microsoft as pre-release and not recommended for new driver development; ACX 1.1 is current/public recommended version. | CONFIRMED | [Microsoft ACX version overview](https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview). |
| E-019 | Last recorded target OS build 20348.2849 is from 2024-11; newer Server 2022 cumulative build 20348.5873 published 2026-11-13. | CONFIRMED | [KB5046616](https://support.microsoft.com/en-us/servicing/os/windows-server/2024/11/november-12-2024-kb5046616-os-build-20348-2849); [KB5136487](https://support.microsoft.com/en-us/servicing/os/windows-server/2026/11/kb5136487-windows-server-2022-update). |
| E-020 | A later Server 2022 cumulative update changes Acx01000.sys or registered ACX class version. | UNTESTED | Public KB summary does not answer this; requires file-version/runtime comparison on a separately updated image or host. |
| E-021 | Current INF Class=Bluetooth is valid for this BTHENUM profile-driver installation. | SUPPORTED | [Microsoft Installing a Bluetooth Device](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/installing-a-bluetooth-device) says Bluetooth devices are members of the Bluetooth class; Audio endpoint is separately registered through KSCATEGORY_AUDIO. Physical endpoint behavior remains to be tested. |

## New evidence — 2026-11-22

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-015 | ACX service DriverInit returned status 0 before LdacA2dp failed with Event 227 / 0xC000000D. | CONFIRMED | Library DriverDiagnostic.xml, File ref turn141file0; event times 17:46:52.1553213–17:46:52.1569030. |
| E-016 | ACX unload completed 33.7 microseconds before LdacA2dp Event 227 in the 17:46 trace; a second trace shows 23.5 microseconds. Events share the kernel thread. | CONFIRMED timing; cleanup interpretation SUPPORTED | Library DriverDiagnostic.xml and LDAC-Trace.xml; refs turn141file0, turn103file0. Event order does not prove causation. |
| E-017 | LdacA2dp source contains none of the ACX 1.1-only DDI names listed in Microsoft's ACX version overview. | CONFIRMED source scan | Branch experiment/acx10-server2022-bind, files audio.c, driver.c, driver.h; scan performed 2026-11-22. |
| E-018 | LdacA2dp DriverEntry order matches the official AudioCodec sample's essential sequence: WdfDriverCreate, ACX_DRIVER_CONFIG_INIT, AcxDriverInitialize. | CONFIRMED | LdacA2dp driver.c; Microsoft AudioCodec Driver.cpp lines 602–634: https://github.com/microsoft/Windows-driver-samples/blob/main/audio/Acx/Samples/AudioCodec/Driver/Driver.cpp |
| E-019 | AudioCodec sample uses ACX 1.1, KMDF 1.31, Windows Driver target; LdacA2dp uses ACX 1.0 in experiment, KMDF 1.31, Universal target. | CONFIRMED | Microsoft AudioCodec.vcxproj lines 584–638 and LdacA2dp.vcxproj commit 593e8f4. |
| E-020 | Universal target is documented to run on Windows Server 2022; Universal vs Windows Driver is not an invalid-platform mismatch. | CONFIRMED | Microsoft Target Platforms: https://learn.microsoft.com/windows-hardware/drivers/develop/target-platforms |
| E-021 | AudioCodec INF and LdacA2dp INF use the same essential AddService/KmdfService/KmdfLibraryVersion pattern; setup classes differ because one is ROOT\AudioCodec/MEDIA and the other is a BTHENUM Bluetooth service devnode. | CONFIRMED | Microsoft AudioCodec.inf lines 476–548; repository LdacA2dp.inx lines 1–93. No concrete INF defect currently evidenced. |
| E-022 | Draft PR #3 tests only DriverTargetPlatform Universal to Windows Driver on top of ACX 1.0. | CONFIRMED | Commit 6656e2d1fcda8d731f6795bd2e7a2950d5ba8309; PR https://github.com/as-0101/ldac-a2dp-windows/pull/3. CI #143 run 45050062916 completed successfully; all three jobs passed. Test artifact 14764868818, SHA-256 a82e4fd60cec5ed17eaff3e4a0897cf4b8181674e4a5933da380565ac5e4f757; unsigned driver artifact 14764794032, SHA-256 8d324266491d4c943b270db8f09e8a01341c428fb51a08c7ebdd7884c6bf70dc. Both were copied to Files Library. |
| E-023 | ACX 1.0 is documented as pre-release/not recommended for new driver development; Microsoft version table does not list Server 2022. | CONFIRMED | Microsoft ACX version overview: https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview |
| E-024 | Independent Win10 19045 investigation reports ACX 1.0 (210 functions) vs 1.1 (221 functions) class-bind mismatch and success after building against 1.0. | SUPPORTED external corroboration only; not direct Server 2022 evidence | https://erfi.dev/guides/usb-audio2-acx-driver-without-wdk/ |

## Important limitation

The exact ACX function count in the Server 2022 10.0.20348.3451 class module has not been measured. Do not transfer the 210/221 counts from the Windows 10 19045 article to Server 2022. A Server 2022 PDB/bind-metadata inspection or physical ACX 1.0 test is still required.


| E-025 | CI #143 for the Windows Driver target-platform variant completed successfully; all 3 jobs passed; INF DriverVer 0.2.326.1734; signability and build reported 0 errors/warnings. | CONFIRMED | Run https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45050062916; KMDF job 137292983701; commit 6656e2d1fcda8d731f6795bd2e7a2950d5ba8309. |
| E-026 | CI #133 and #143 test/unsigned-driver artifacts were copied to persistent Files Library. | CONFIRMED | Files Library IDs listed in PROJECT_STATE.md; directory ID 6b0318b95f648191802d868fc1be5e96. |

| E-027 | Microsoft defines KmdfLibraryVersion as the KMDF framework version; it does not select the ACX class version. LdacA2dp's ACX version is selected by ACX_VERSION_MAJOR/MINOR and the acxstub.lib path in the project file. | CONFIRMED | Microsoft INF WDF directives: https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/specifying-wdf-directives-in-inf-files (KmdfLibraryVersion lines 248–253); LdacA2dp.vcxproj. |

| E-028 | The CI #133 package's prepare script changes certificate stores, IHVDRIVER debug filter and BCD testsigning; its upgrade tool is guarded by OS/MAC/single-device/current-service/version/rank checks and applies only the exact OPPO devnode; rollback selects inbox bth.inf. | CONFIRMED from source | tools/stand/package-oppo-test.ps1, prepare-oppo-host.cmd, oppo-driver-tool.cpp, upgrade-oppo.cmd, rollback-oppo.cmd, README_OPPO_TEST_RU.txt on experiment/acx10-server2022-bind. |

| E-029 | Microsoft's !acxkd example explicitly shows CLIENT_MODULE WDF 1.31 with Wdf01000.sys runtime 1.33 and CLASS_MODULE ACX 1.1; this WDF client/runtime pairing is valid and is not the observed mismatch on the target. | CONFIRMED | https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd lines 167–190. The target's class module is v1.0. |
| E-030 | An earlier historical snapshot recorded the OPPO A2DP profile devnode as Microsoft Bluetooth A2DP Source via microsoft_bluetooth_a2dp_src.inf. This is superseded by the later 20-36 PnP record E-132, which shows the project's custom oem75.inf / LdacA2dp driver bound with Code 37. | HISTORICAL — PRIOR SNAPSHOT; SUPERSEDED BY E-132 | Earlier user archive Drivers/PnP-Signed-Drivers.csv and Registry/Enum-BTHENUM.reg. |

## Evidence additions — 2026-11-22 20:28 Kyiv

| ID | Claim | Status | Source | Interpretation |
|---|---|---|---|---|
| E-031 | An earlier historical snapshot showed HFP/AVRCP components and BTAGService/BthAvctpSvc present. The later 2026-11-19 Server environment report E-133 shows BTAGService/BthAvctpSvc not installed, while bthserv, Audiosrv and AudioEndpointBuilder are running. | HISTORICAL — PRIOR SNAPSHOT; SUPERSEDED FOR SERVICE PRESENCE BY E-133 | Earlier user archive System/Kernel-Drivers.csv, System/Services.csv and service registry exports. |
| E-032 | Microsoft's WDF source identifies `WdfVersionBindClass` as the class-extension load/reference and client-link path | CONFIRMED | [Microsoft WDF fxldr.h](https://github.com/microsoft/Windows-Driver-Frameworks/blob/main/src/framework/shared/inc/private/common/fxldr.h) | Public source exposes the interface/header contract, not the WdfLdr implementation. |
| E-033 | KMDF 1.31 client on WDF runtime 1.33 is unsupported | REFUTED | [KMDF version history](https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history); [!acxkd example](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd) | This client/runtime pair is supported and explicitly shown in Microsoft's ACX debugger example. |
| E-034 | Universal drivers are unsupported on Windows Server 2022 | REFUTED | [Microsoft Target Platforms](https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/target-platforms); CI #143 run 45050062916 | Universal is a supported target; physical runtime effect remains untested. |
| E-035 | Bluetooth setup class in the LDAC INF is wrong because AudioCodec uses MEDIA | REFUTED | [Installing a Bluetooth Device](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/installing-a-bluetooth-device); Microsoft AudioCodec sample | Bluetooth is appropriate for BTHENUM; MEDIA in the sample reflects its ROOT audio-codec topology. |
| E-036 | Hosted Server 2022 runner has a newer ACX binary file version than the physical host | CONFIRMED | CI run 45050478308 and LiveKD report artifact 14766509597 | Runner `Acx01000.sys` is 10.0.20348.5866 versus host 10.0.20348.3451. File version does not establish class-module version. |
| E-037 | ACX service can be started on the disposable hosted runner | CONFIRMED | CI run 45054071166 and report artifact 14767070902 | `sc.exe start Acx01000` succeeded on the runner only; not executed on the physical host. |
| E-038 | LiveKD `-ml` can capture a Server 2022 kernel live dump without BCD local-debugging changes | CONFIRMED for capture | [Sysinternals LiveKD](https://learn.microsoft.com/en-us/sysinternals/downloads/livekd); CI run 45054287408 | Dump capture and KD processing succeeded; `!wdfkd.wdfldr` still lacked required WDF loader symbols from the public symbol set. |
| E-039 | The earlier `-kl` BAT is sufficient for local kernel debugging | REFUTED | [Microsoft local kernel debugging setup](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/setting-up-local-kernel-debugging-of-a-single-computer-manually) | `-kl` requires BCD `debug on`, local `dbgsettings`, and reboot; the BAT only launches WinDbg. |


## Evidence additions — 2026-11-22 20:37 Kyiv

| ID | Claim | Status | Source | Interpretation |
|---|---|---|---|---|
| E-040 | Physical PnP reports ProblemCode 37 and DEVPKEY_Device_ProblemStatus 3221225485 (0xC000000D) for the intended LdacA2dp service and oem75.inf. | CONFIRMED | Latest user read-only PnP output, 20-36.txt | Independently matches FxStubBindClasses / VersionBindClass and Event 227 status; does not alone prove ACX-version causality. |
| E-041 | The physical DriverVer 0.2.325.1600 matches the successful WDK 26100.6584 ACX 1.1 build from workflow run #129. | CONFIRMED version correlation; installed SYS hash not compared | Run #129 ID 44922058650, commit 4571873b505c52a93db4c785fe3d083eabf8499e; physical PnP properties | WDK 26100 pin alone did not eliminate the physical start error. |
| E-042 | GitHub Actions run #126 is ID 44922013678 and failed; successful artifact 14714246739 and its 221-symbol PDB baseline belong to run #129 / ID 44922058650. | CONFIRMED | GitHub Actions run metadata and artifact provenance | Corrects legacy CI #126 labels in Notion and older documentation. Existing Files Library filenames are legacy names only. |
| E-043 | LiveKD runs #6 and #7 were cancelled; logs show KD command-line usage rather than a valid WDF/ACX class query. Run #8 failed because LiveKD could not find kd.exe and created no dump. | CONFIRMED | Runs 45054673989, 45054866734, 45056354003; report artifacts 14767527142, 14767775337, 14767208063 | None of these runs provides an ACX class-module version for the hosted runner. |
| E-044 | Workflow-only fix commit 02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3 adds KD to PATH and uses a command file for inspection. | CONFIRMED commit; UNTESTED CI | research/acx-runtime-livekd branch | No CI run has yet been observed for this commit; do not claim the harness fix works. |
| E-045 | Current Bluetooth INF/service selection and Universal target are not leading causes. | SUPPORTED | Physical PnP properties; Microsoft Bluetooth device installation guidance; Microsoft Target Platforms | PnP selects LdacA2dp/oem75.inf, Bluetooth class matches BTHENUM, and Universal is supported on Server 2022. Physical class binding still fails. |


## Evidence additions — 2026-11-22 20:44 Kyiv

| ID | Claim | Status | Source | Interpretation |
|---|---|---|---|---|
| E-046 | Hosted Server 2022 LiveKD run #9 captured a native dump, KD opened it, and Acx01000 symbols loaded. Wdf01000 runtime is v1.33; an unnamed WDF client v1.31 has the exact Acx01000 image base and size. | CONFIRMED | [Run #9](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45056585788), artifact 14768155168 | Confirms the WDF client/runtime pairing on the hosted runner; does not reveal ACX CLASS_MODULE version. |
| E-047 | Microsoft documents !wdfldr acx01000 as the query that displays both CLIENT_MODULE and CLASS_MODULE, including the ACX Version field. | CONFIRMED | [Microsoft !acxkd documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd), example at lines 167–190 | The run #9 command !wdfkd.wdfldr Acx01000.sys is not equivalent and returned “Unable to find the specified WDF driver”. |
| E-048 | Research workflow commit 218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383 adds the exact !wdfldr acx01000 command to the KD command file. | CONFIRMED commit; UNTESTED CI | [Commit 218b457](https://github.com/as-0101/ldac-a2dp-windows/commit/218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383) | Await the corresponding workflow run before treating the hosted ACX class version as known. |


## Evidence additions — 2026-11-22 20:48 Kyiv

| ID | Claim | Status | Source | Interpretation |
|---|---|---|---|---|
| E-049 | Hosted Server 2022 run #10 reports ACX CLASS_MODULE Version v1.0, WDF Version v1.31, and CLIENT_MODULE Acx01000.sys WDF v1.31 bound to Wdf01000.sys runtime v1.33. | CONFIRMED | [Run #10](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45057090987), artifact 14768205866 | Independently matches the physical host's earlier ACX class v1.0 / WDF 1.31 / runtime 1.33 output. Strongly supports ACX 1.1 client versus ACX 1.0 class mismatch as the leading cause; not a complete proof of all binding metadata. |


## Evidence additions — 2026-11-22 21:02 Kyiv

| ID | Claim | Status | Source | Interpretation |
|---|---|---|---|---|
| E-050 | A more recently serviced hosted Server 2022 image (UBR 5870, KB5070761) has Acx01000.sys 10.0.20348.5866 and ACX CLASS_MODULE v1.0. | CONFIRMED | Metadata run #12 / 45057605446 and class query run #10 / 45057090987 | Physical host UBR 5761 / Acx01000.sys 10.0.20348.3451 also has class v1.0. OS update is not supported as a route to ACX 1.1 on current evidence; file version is not class version. |
| E-051 | CI #133 ACX 1.0 package preflight succeeds on a disposable Server 2022 runner: DriverVer 0.2.326.1634, expected SYS hash, expected test certificate, BCD testsigning Yes, DevGen available. | CONFIRMED | Preflight run #1 / 45058127024, artifact 14768550673 | A safe hosted load test can proceed without changing the physical host or BCD. |
| E-052 | Hosted ACX 1.0 load test job was added to build run #230 / 45058265287. | IN PROGRESS at this evidence timestamp | Commit 86a1d46aa7c4bc3561e96ded77442b03b34789f0 | Wait for PnP and ACX client-list result; no success/failure conclusion yet. |


## Evidence additions — 2026-11-22 (reorganization audit)

| ID | Claim | Status | Environment | Source / interpretation |
|---|---|---|---|---|
| E-053 | ACX 1.0 candidate still fails PnP start when Acx01000 is explicitly RUNNING before install. | CONFIRMED negative result | VM_TEST | CI #248 / run 45060225420, commit 3d1d5d7e179da3379013b10f9863066200c459b6; report artifact 14769048266. Synthetic SWD device selected oem13.inf / 0.2.326.1922; Code 37 / 0xC000000D; Event 219; no DriverEntry evidence. |
| E-054 | CI #248 candidate package version is 0.2.326.1922. | CONFIRMED | STATIC_ANALYSIS + VM_TEST | Report preflight.json and SetupAPI log. Corrects an older PROJECT_STATE line that said 0.2.326.1920. |
| E-055 | WDK 26100.6584 ACX 1.0 and 1.1 stubs encode distinct class-bind descriptors. | CONFIRMED | STATIC_ANALYSIS | CI #255 / run 45060819535, artifact 14769755224: ACX 1.0 = 1.0 / 210 functions / 62 structures; ACX 1.1 = 1.1 / 221 / 62. |
| E-056 | CI #246 candidate SYS contains ACX 1.0 / 210 / 62 descriptor. | CONFIRMED | STATIC_ANALYSIS | CI #255 report parses actual SYS descriptor. This rules out accidental ACX 1.1 stub descriptor in that binary, not all possible WDF/ACX bind metadata incompatibilities. |
| E-057 | Simple ACX 1.1-vs-1.0 version mismatch alone explains the bind failure. | REFUTED as sufficient explanation | VM_TEST | E-053: ACX 1.0 candidate still fails with same ProblemStatus after ACX service was started. Other bind metadata/runtime invariants remain unresolved. |
| E-058 | CI #255 ACX stub inspection workflow #1 produced a complete library/header report. | REFUTED | BUILD_ONLY | Run 45060793775 failed because the script assumed the NuGet WDK package had an Include directory; no artifact uploaded. Later successful CI #255 used a corrected approach. |


## E-059 — CI #10 sample-derived ACX 1.0 probe build
- Workflow run 45077156403, experiment commit 39c8844798485d97f06f40ab3c90f5ab00491733.
- Build succeeded with WDK 10.0.26100.6584, SDK 10.0.26100.0, KMDF 1.31, ACX 1.0, x64. Build artifact 14774844743; SHA-256 d79c6bf6ed04de54c3c073edfd8e91fcfbe9d98ac8537aef951f2d03dfd21dc7.
- SYS SHA-256 815fbcd4505e4b7253bccae361cc0bbd3d91cafa994dfb268df32749b39fc415. Durable Library copy: /LDAC Project/Incoming/CI-10-ACX10-Sample-Probe-Build.zip.

## E-060 — CI #10 hosted runtime preflight, no PnP attempt
- Runtime artifact 14775099125; SHA-256 cb9bbc178c58cf7fe6681267c86151b34030b72e77fb0730e81b2230f5fd635b; Library copy: /LDAC Project/Incoming/CI-10-ACX10-Sample-Probe-Runtime-Preflight.zip.
- Hosted OS: Windows Server 2022 Datacenter build 20348, UBR 5870, image 20261116.370.1. Acx01000.sys version 10.0.20348.5866, SHA-256 D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0. Wdf01000.sys version 1.33.20348.1, SHA-256 32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B.
- Read-only BCD output showed testsigning Yes. LiveKD directly showed ACX CLASS_MODULE v1.0, WDF client 1.31 and WDF runtime 1.33. The run failed at SignTool verify /kp because the self-signed test certificate did not chain to a Microsoft root. TestAttempted=false; no root device was created and no PnP bind result exists.

## E-061 — CI #11 exact build-input provenance
- Workflow run 45077797657, experiment commit 98800f0a88717cc93ef491fb5dff622b6fc4ff25. Build succeeded; artifact 14775454304; SHA-256 7a40925a5b291fcef290a2a47e8f8036410b5f623562cdb3228d34652ee6033e.
- SYS SHA-256 f8b3697b6b8a7a4a7fc5da134b3451e1dde1fad85e78e01efb59e6b8d12ae867; INF 5ea087bfde896a8d64fa9b203fb433caeb30e7144e2dc98bc8e9a23cc798e021; PDB aa64c6017f3677f6bf95b4daff973ca45df8389843bceeda110bb976bc02d97e.
- Build manifest records ACX 1.0 stub length 1,362,352 and SHA-256 9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74, exactly matching the CI #255 stub artifact. acx.h SHA-256 91877A614618A3A726E376A6014B99431C9E4EF54A804E9B48F1F7F8680F19FA; WdfDriverEntry.lib SHA-256 101BF4D30BBF773AC46FF96352EBFDE88A88C834C29F67C10065488CFE2F475C; WdfLdr.lib SHA-256 AF708DE43A0975239F976BDF5F2596CC6FD7219A076643B2C6C98BDD6C4FF530.
- Durable Library copy: /LDAC Project/Incoming/CI-11-ACX10-Sample-Probe-Build.zip.

## E-062 — CI #11 runtime preflight, incomplete LiveKD view
- Runtime artifact 14776440518; SHA-256 380638450711410885f785bb75d99feec19020a17ac46ee0cb05ce9e446e9c2d; Library copy: /LDAC Project/Incoming/CI-11-ACX10-Sample-Probe-Runtime-Preflight.zip.
- The pre-install dump reported a missing page; !wdfldr still showed WDF runtime 1.33 and a WDF 1.31 client row whose image address matched Acx01000.sys. The class-module v1.0 detail was not readable in this particular bitmap dump; this is not evidence of a different runtime.
- sc.exe query Acx01000 showed RUNNING before the probe. WMI Win32_SystemDriver.Started incorrectly returned false, so the old script misclassified the service as started by the probe and cleanup received STOP error 1061. No certificate or root device was created. The script now uses SCM query state and preserves incomplete LiveKD output as a warning.

## E-063 — CI #12 harness syntax regression
- Workflow run 45078310971, commit b74f7247017b4dcbe55b141604a5ae0073b4c0fd. PowerShell parser validation caught a malformed generated preflight block before runtime. No driver test, certificate or device creation occurred. The next commit restored the known-good script body and reapplied the changes in a shorter block.

## E-064 — CI #13 current attempt
- Workflow run 45078613003, experiment commit 35e700a3ecb74548b858f0479a1e15e31a2d110f. PowerShell validation and build passed; build job 137381366829 succeeded. Hosted runtime job 137381843080 was still in progress at the time of this update.


## E-001 — Minimal AudioCodec-derived ACX 1.0 client fails before DriverEntry (CI #13)

- **Claim:** the pre-DriverEntry Code 37 / 0xC000000D failure is not specific to LDAC's original INF topology or driver-specific code.
- **Environment:** VM_TEST — hosted Windows Server 2022; WDK 10.0.26100.6584; KMDF 1.31; ACX 1.0; root-enumerated MEDIA probe.
- **Source:** Microsoft Windows-driver-samples AudioCodec pinned commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69.
- **Run/commit:** CI #13, run 45078613003, commit 35e700a3ecb74548b858f0479a1e15e31a2d110f.
- **Observed:** build, InfVerif and Inf2Cat pass; PnP selects the probe INF; PnP Code 37 / ProblemStatus 0xC000000D; no DriverEntry marker.
- **Hashes:** probe SYS 70BA9899BF1B54989E7C6C3F6C0DEDAE2ADFCEF16D7AE6A9803192E7C86EDAA6; LDAC candidate SYS FF97EED8409A7FF9DADB8D9C7C7FB309E789F9A3225847793B39B7D97D8FB9A8.
- **Interpretation:** CONFIRMED negative runtime result. The internal WDF/ACX bind substage remains unknown.

## E-002 — ACX 1.0 descriptor parity between sample probe and LDAC candidate

- **Claim:** the minimal sample probe and LDAC candidate use the same ACX 1.0 stub descriptor family.
- **Evidence:** sample SYS descriptor major/minor 1.0, 210 functions, 62 structures; LDAC candidate SYS has the same 1.0 / 210 / 62 descriptor. WDK 10.0.26100.6584 ACX 1.0 stub library SHA-256 9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74. Sample build manifest also pins acx.h, WdfDriverEntry.lib and WdfLdr.lib hashes.
- **Environment:** STATIC_ANALYSIS / BUILD_ONLY. CI #13 run 45078613003, commit 35e700a3ecb74548b858f0479a1e15e31a2d110f.
- **Interpretation:** CONFIRMED descriptor parity; this does not prove every bind-related section or runtime ABI field is identical.

## E-003 — Post-boot DbgPrintOn did not enable WDF loader diagnostics (CI #14)

- **Claim:** the empty !dbgprint output in CI #14 is an instrumentation-timing limitation, not proof that the loader emitted no messages.
- **Evidence:** CI #14 run 45081844225, commit 04518a83900a7e7aa093fe56a7669f91349d7588; registry DbgPrintOn was set after the hosted OS booted; !dbgprint remained empty. Microsoft WDF source initializes WdfLdrDbgPrintOn in Wdf01000.sys DriverEntry and reads the registry there (pinned source commit b6191d9543441329154da32f7ab9bdd97228dd3c, lines 111–115 and 358).
- **Interpretation:** CONFIRMED that the registry write was too late for the already-loaded WDF runtime. Do not repeat this post-boot global setting.

## E-004 — ACX 1.0 support-matrix caveat

- **Claim:** ACX 1.0 on Server 2022 with WDK 26100 / KMDF 1.31 is not a documented supported tuple in the published ACX version table.
- **Evidence:** Microsoft ACX version information describes ACX 1.0 as pre-release and lists Windows 10 1903 / KMDF 1.29; Server 2022 is not listed. The official AudioCodec sample project defaults to ACX 1.1 / KMDF 1.31.
- **Interpretation:** SUPPORTED as a documentation caveat only; it is not proof that the runtime mismatch causes Code 37.

## New evidence — 2026-11-23 (CI #15 and WDK class-bind review)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-065 | A minimal Microsoft AudioCodec-derived ACX 1.0 client still fails on hosted Server 2022 before DriverEntry: PnP selects the root MEDIA probe INF, then reports Code 37 / `0xC000000D`. | CONFIRMED — VM_TEST | CI #15 / run 45082965356, commit `488ae8104eec960370c0887e07136a3e9e3846b5`; runtime artifact 14778137925; `runtime-result.json`, `pnp-result.json`. Probe SYS SHA-256 `BAB3C54C0EAB186CC8C9D89B07BCA871112454175C0C45F8D199DA57927114B6`. |
| E-066 | CI #15's hosted ACX/WDF runtime binaries are byte-identical to the earlier CI #10 baseline; CI #15's native dump still lacked a page needed to display the ACX class-module record. | CONFIRMED | CI #15 runtime artifact 14778137925 and CI #10 artifact 14775099125. `Acx01000.sys` SHA-256 `D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0`; `Wdf01000.sys` SHA-256 `32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B`. CI #10 directly displayed CLASS_MODULE v1.0 / WDF client 1.31 / runtime 1.33; CI #15 did not directly re-display CLASS_MODULE. |
| E-067 | CI #15 raw preinstall LiveKD output contains WDF IFR records for `Acx01000`; the probe's own WDF IFR is unavailable because its driver never loaded. The structured report field missed the preinstall records because it extracted only postinstall output. | CONFIRMED | CI #15 runtime artifact 14778137925: `preinstall-kd-output.txt`, `postinstall-kd-output.txt`, `runtime-result.json`, `cleanup-result.json`. The extraction defect was corrected in experiment commit `9da48c3ecd5921f8cab47888325b156dc9a536f3`. |
| E-068 | The WDK 10.0.26100.6584 ACX 1.0 stub descriptor is version 1.0, 210 functions / 62 structures, size 0x78 (120 bytes); ACX 1.1 is version 1.1, 221 / 62. | CONFIRMED — STATIC_ANALYSIS | CI #255 artifact 14769755224 (ZIP SHA-256 `8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce`); ACX 1.0 stub library SHA-256 `9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74`; extracted `.kmdfclassbind$b` object descriptor. |
| E-069 | WDF's client stub scans class-bind descriptors by validating `Size` against `WDF_CLASS_BIND_INFO` or `WDF_CLASS_BIND_INFO2`; `WdfVersionBindClass` is the call that loads/references the class extension and links the client. | CONFIRMED — SOURCE_REVIEW | Microsoft Windows-Driver-Frameworks commit `b6191d9543441329154da32f7ab9bdd97228dd3c`, `fxldr.h` lines 186–259 and 438–451: https://github.com/microsoft/Windows-Driver-Frameworks/blob/b6191d9543441329154da32f7ab9bdd97228dd3c/src/framework/shared/inc/private/common/fxldr.h. Existing physical trace E-001 records `WdfVersionBindClass` returning `0xC000000D`; the exact runtime validation remains unknown. |
| E-070 | The official AudioCodec project defaults to ACX 1.1 / KMDF 1.31 and uses WPP/SamplesCommon setup; the CI #15 probe is a deliberately reduced sample-derived client, not a full build of the complete sample. | CONFIRMED — SOURCE_REVIEW | Microsoft Windows-driver-samples commit `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`; `AudioCodec.vcxproj`, `Driver.cpp`, `AudioCodec.inf`; probe source in experiment commit `488ae8104eec960370c0887e07136a3e9e3846b5`. |
| E-071 | ACX 1.0 on Server 2022 / WDK 26100 / KMDF 1.31 is not a documented supported tuple; the WDK/VS2022 build-toolchain pairing itself is supported for building drivers targeting Server 2016 and later. | CONFIRMED — DOCUMENTATION | Microsoft ACX version information: https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/acx-version-overview; WDK download page: https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk. |


## New evidence — 2026-11-23 (CI #16 runtime PDB, Microsoft source/docs, artifact audit)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-072 | The actual hosted Server 2022 WDF runtime PDB reports x64 `WDF_CLASS_BIND_INFO` base size 0x50 and `WDF_CLASS_BIND_INFO2` size 0x78. The WDK 26100.6584 ACX 1.0 stub descriptor is 0x78 bytes, so the simple descriptor-size mismatch hypothesis is rejected. The same preinstall transcript shows ACX `CLASS_MODULE` v1.0, WDF client 1.31 and Wdf01000 runtime 1.33 already present before the probe. | CONFIRMED — VM_TEST / STATIC_ANALYSIS | CI #16 run 45084678951, commit `9da48c3ecd5921f8cab47888325b156dc9a536f3`, runtime artifact 14779107472. `preinstall-kd-output.txt` lines 177–215 and 283–315; full mirror 17,174,368,256 bytes, SHA-256 `0ADB390E23324838A0B0A65D3829B872D800A1359222162FEBA1C86E4193969F`, zero missing pages in `preinstall-livekd-capture.txt`. |
| E-073 | The pinned Microsoft AudioCodec sample solution is VS2019 16.0.31409.214; its project defaults to ACX 1.1 / KMDF 1.31, Windows Driver target, WPP/WPP Recorder and SamplesCommon. Its INF is MEDIA / ROOT\AudioCodec with an OS decoration 19041+. The minimal CI probe is sample-derived, not a full build of the complete sample. | CONFIRMED — SOURCE_REVIEW | Microsoft Windows-driver-samples commit `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`: `Driver/AudioCodec.sln`, `Driver/AudioCodec.vcxproj`, `Driver/Driver.cpp`, `Driver/AudioCodec.inf`, `Driver/ReadMe.txt`. |
| E-074 | Microsoft documents ACX 1.0 as pre-release for Windows 10 1903 / KMDF 1.29 and ACX 1.1 as the current/public version initially released for Windows 10 2004 / minimum KMDF 1.31. Server 2022 is absent from the ACX version table. The KMDF 1.31 row lists Windows 10 2004 and later, not Server 2022 explicitly; Server 2022 WDF 1.31-client / 1.33-runtime compatibility is directly observed in hosted CI #10 and #16. Microsoft also states that ACX binds to a specific KMDF version at runtime and the driver fails to load if the required min/max ACX DDI is unavailable. | CONFIRMED — DOCUMENTATION + VM_TEST | Microsoft [ACX Version Information](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/acx-version-overview), lines 40–80; [KMDF Version History](https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history), lines 34–38; CI #10/#16 `!wdfkd.wdfldr` output. |
| E-075 | WDK 20348.1 is listed as an unsupported legacy kit paired with VS2019. The legacy SDK/WDK installers for this release are marked as affected by CVE-2024-29187, while the EWDK distribution is marked not affected. The EWDK setup instructions require mounting the ISO and running LaunchBuildEnv.cmd; current WDK documentation additionally specifies SetupVSEnv. | CONFIRMED — DOCUMENTATION | Microsoft [Unsupported WDK versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/legacy-wdk-downloads), lines 31–47; [Using the Enterprise WDK](https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/using-the-enterprise-wdk), lines 31–45; [Download the WDK](https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk), lines 37–43. |
| E-076 | CI #16 build ZIP hash previously recorded in PROJECT_STATE was incorrect. Downloading GitHub artifact 14779061024 and materializing its durable Library copy independently produced the same 126,939-byte SHA-256 `d332fc338cbd8c4aa41f56338bb68104059b2956558067362d69b495a0ba8e72`. Runtime artifact 14779107472 and descriptor report hashes also match their durable Library copies. | CONFIRMED — ARTIFACT_INTEGRITY | GitHub artifacts 14779061024 / 14779107472; Library files `file_00000000bca08211bc1de8bfd1963463`, `file_00000000f95c8210885725aee73f1356`, and descriptor report `file_00000000373c8209b70496924c4066c6`; hashes recorded in ARTIFACT_INDEX.md. |


## New evidence — 2026-11-23 evening

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-022 | A minimal Microsoft AudioCodec-derived ACX 1.0 client fails on hosted Server 2022 before DriverEntry with PnP Code 37 / 0xC000000D. | CONFIRMED (VM_TEST) | CI #16 / [run 45084678951](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45084678951), commit 9da48c3ecd5921f8cab47888325b156dc9a536f3; runtime artifact 14779107472. |
| E-023 | Official EWDK 20348.1 image did not contain the ACX 1.0 stub needed by the minimal probe; no matching build or runtime bind test was produced. | CONFIRMED (BUILD_ONLY; runtime SKIPPED) | CI #17 / [run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058), commit 79460f03492a54444473589dd142da864a703a73; job 137638217372 log reports EWDK_ACX10_STUB_FOUND=false. EWDK ISO SHA-256 B962E5FB1D81E4BC419FB59F37D695172DD9B323DE772614C50F2B136B5B9AC1; artifact 14814207710 contains the small provenance report. |
| E-024 | OPPO Enco Buds2 model ETE41 officially lists AAC/SBC as its Bluetooth audio codecs; LDAC is not listed/supported by the manufacturer's specification. | CONFIRMED for model ETE41; physical model identity still requires confirmation | OPPO official specifications: https://www.oppo.com/ua/accessories/oppo-enco-buds2/specs/ and https://www.oppo.com/en/accessories/oppo-enco-buds2/specs/. |
| E-025 | A2DP Windows Bridge was renamed BlueCaster 3.0.0. Its documented platform support is Windows 10 22H2 / Windows 11, and it takes ownership of a USB Bluetooth adapter through WinUSB. | CONFIRMED from project documentation; Server 2022 compatibility UNTESTED/unsupported by published matrix | https://seiyafunaokajp.github.io/BlueCaster/ and https://seiyafunaokajp.github.io/BlueCaster/setup.html. |
| E-026 | BlueCaster's published verified-hardware list does not currently confirm OPPO Enco Buds2; it does confirm LDAC with other headset models/adapters. | CONFIRMED as documentation observation; Enco Buds2 compatibility UNTESTED | https://seiyafunaokajp.github.io/BlueCaster/hardware.html. |

Interpretation: if the physical headset is indeed OPPO Enco Buds2 ETE41, LDAC negotiation and LDAC-stream milestones are impossible with that receiver regardless of Windows driver implementation. The project objective must first be corrected to AAC/SBC playback, or the receiver must be changed to an LDAC-capable model. Do not interpret a BlueCaster/A2DPWB workaround as adding LDAC capability to ETE41.


## User hardware identification — 2026-11-23

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-027 | The user's supplied photos show the physical OPPO earbuds/case and the connected-device page in the phone settings explicitly names the product "OPPO Enco Buds2". The screenshots do not show a printed ETE41/ETE42 model code. | CONFIRMED product name; printed SKU not directly observed | User-uploaded photos in conversation, 2026-11-23. |
| E-028 | OPPO's official Enco Buds2 specification maps the earbuds to model ETE41 and charging case to ETE42, and lists Bluetooth codecs AAC/SBC only. | CONFIRMED official specification; applying ETE41 to user's set is strongly supported by the app product identity, but the printed code was not photographed | OPPO Ukraine: https://www.oppo.com/ua/accessories/oppo-enco-buds2/specs/ ; OPPO Global: https://www.oppo.com/en/accessories/oppo-enco-buds2/specs/. |

Interpretation: user has identified the connected product in the official phone UI as OPPO Enco Buds2. The official spec for that product lists AAC/SBC and no LDAC. Do not keep asking the user to find a model code on the earbuds; no such code is visible in the supplied photos. For engineering scope, treat this headset as AAC/SBC-only unless contrary model-specific evidence appears.



## New evidence — 2026-11-23 (working Windows 10 A2DP reference)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-027 | Reference machine AS-KRM-WIN10 is Windows 10 Enterprise x64, build 19045. | CONFIRMED | User archive `Win10-Bluetooth-A2DP-20261123-201418.zip`, MANIFEST.json and System/OS.txt. |
| E-028 | OPPO Enco Buds2 creates healthy Windows Audio A2DP Stereo and Hands-Free endpoints on the reference machine. | CONFIRMED | User screenshot; archive Devices/AudioEndpoints.txt; all reported `CM_PROB_NONE`. |
| E-029 | Microsoft Bluetooth A2DP profile driver is installed and running as kernel service `BthA2dp`; binary `BthA2dp.sys` version 10.0.19041.4355, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`. | CONFIRMED | User archive System/Kernel-Drivers.csv, Drivers/PnP-Signed-Drivers.csv, Files/Driver-Binary-Inventory.json and Registry/Service-BthA2dp.reg. |
| E-030 | An earlier historical snapshot recorded the OPPO A2DP profile devnode as Microsoft Bluetooth A2DP Source via microsoft_bluetooth_a2dp_src.inf. This is superseded by the later 20-36 PnP record E-132, which shows the project's custom oem75.inf / LdacA2dp driver bound with Code 37. | HISTORICAL — PRIOR SNAPSHOT; SUPERSEDED BY E-132 | Earlier user archive Drivers/PnP-Signed-Drivers.csv and Registry/Enum-BTHENUM.reg. |
| E-031 | An earlier historical snapshot showed HFP/AVRCP components and BTAGService/BthAvctpSvc present. The later 2026-11-19 Server environment report E-133 shows BTAGService/BthAvctpSvc not installed, while bthserv, Audiosrv and AudioEndpointBuilder are running. | HISTORICAL — PRIOR SNAPSHOT; SUPERSEDED FOR SERVICE PRESENCE BY E-133 | Earlier user archive System/Kernel-Drivers.csv, System/Services.csv and service registry exports. |
| E-032 | Classic A2DP is a Windows-provided profile-driver model; profile drivers communicate with BthPort using WDM/IRPs. | CONFIRMED (Microsoft architecture documentation) | Microsoft Learn: [Bluetooth Classic Audio](https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-classic-audio), [Bluetooth Driver Stack](https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-driver-stack), [Using the Bluetooth Driver Stack](https://learn.microsoft.com/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack). |
| E-033 | ACX is explicitly used in Microsoft's Bluetooth LE Audio VSAP architecture; classic A2DP uses a separate profile driver. | CONFIRMED (Microsoft architecture documentation) | [Bluetooth LE Audio](https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-low-energy-audio), [Bluetooth HFP Bypass Guidelines](https://learn.microsoft.com/windows-hardware/drivers/audio/bluetooth-bypass-guidelines). |
| E-034 | Microsoft states Windows Server SKUs do not include in-box Bluetooth wireless support; Windows 10 SKUs do. | CONFIRMED (published support statement) | [Bluetooth support in previous Windows versions](https://learn.microsoft.com/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions). |
| E-035 | Initial collector's `Relevant-PnP-Devices.csv` is empty due to a PnpDevice module/localization error; signed-driver and endpoint inventories still contain valid A2DP/HFP evidence. A2DP INF package files were not copied. | CONFIRMED | User archive MANIFEST.json, empty CSV, Collection.log and other inventories. |
| E-036 | Windows 10 archive alone does not establish which components are absent from physical Server 2022; a like-for-like Server inventory is required. | CONFIRMED (evidence limitation) | No contemporaneous Server inventory in uploaded archive. |

Interpretation: the strongest lead is to compare the complete classic Bluetooth profile stack and INF binding, not to copy an audio DLL. Reassess the ACX-only approach: ACX is not the documented classic A2DP profile-driver model. Do not import Win10 registry exports or transplant individual SYS/DLL files.


## New evidence — 2026-11-23 (archive re-upload verification and classic A2DP driver model)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-037 | The ZIP uploaded again at 20:37 is byte-identical to the earlier Win10 reference archive: 77 entries, SHA-256 `3bebbee156019cfa6e1c031e8158c8d1e230fd6f64dd57f3a3bc5aae991254cd`. It is not output from the corrected comparison collector. | CONFIRMED | Current uploaded ZIP; byte-for-byte comparison with prior conversation upload. |
| E-038 | The reference registry's MEDIA class instance `0000` identifies `Microsoft Bluetooth A2dp Source`, INF `microsoft_bluetooth_a2dp_src.inf`, section `BthA2dpSrc`, driver `BthA2dp.sys`, matching device ID `BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}`, and `KS=1`. | CONFIRMED | User archive Registry/Class-MEDIA.reg. |
| E-039 | A2DP service registry key is a kernel driver with ImagePath `\\SystemRoot\\System32\\drivers\\BthA2dp.sys`, Start=3, and Owners includes `microsoft_bluetooth_a2dp_src.inf`; its Enum child contains one 0x110B A2DP service devnode. | CONFIRMED | User archive Registry/Service-BthA2dp.reg and Registry/Enum-BTHENUM.reg. |
| E-040 | The A2DP MEDIA class instance records `IncludedInfs=ks.inf, wdmaudio.inf, BtaMpm.inf` (plus the listed Bluetooth A2DP INF); the reference machine therefore registers a Kernel Streaming / WDMAudio-based classic audio path, not an ACX class instance. | CONFIRMED for registry configuration; architecture interpretation SUPPORTED | User archive Registry/Class-MEDIA.reg; Microsoft Bluetooth audio APO INF example shows the same KS/WDMAUDIO/BtaMpm include/needs pattern: https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects. |
| E-041 | Microsoft's Bluetooth driver-stack documentation describes classic Bluetooth profile drivers as WDM profile drivers communicating with BthPort; A2DP is a separate profile driver, while the documented built-in audio kernel profile driver is for SCO/HFP. | CONFIRMED — DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-driver-stack ; https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack ; https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/bluetooth-bypass-guidelines. |
| E-042 | Microsoft documents Windows Server SKUs as lacking in-box Bluetooth support, while all Windows 10 SKUs include it. | CONFIRMED — DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions. |
| E-043 | The earlier Win10 collector's PnP CSV is empty and it did not copy the A2DP INF/DriverStore package; the signed-driver CSV, service registry, MEDIA class registry and endpoint dump nevertheless identify the working A2DP binding. | CONFIRMED | User archive MANIFEST.json, Devices/Relevant-PnP-Devices.csv, Drivers/PnP-Signed-Drivers.csv, Registry/Class-MEDIA.reg, Registry/Service-BthA2dp.reg. |

Interpretation / correction: the current custom ACX driver investigation is not following the documented Windows classic A2DP profile-driver model. Windows 10's working A2DP service is a WDM Bluetooth profile driver using the BthPort stack and Kernel Streaming/WDMAudio registration. ACX belongs to a different audio-extension path (notably the documented LE Audio VSAP architecture), so the repeated ACX class-bind experiments do not establish a route to a classic A2DP implementation. Stop spending cycles on ACX as the assumed A2DP foundation; inspect the actual Microsoft A2DP INF/package, service installation, BthPort binding, KS/WDMAudio dependencies and Server OS applicability. This is an architecture reassessment, not proof that transplanting the Win10 package onto Server will work.


## New evidence — 2026-11-23 (physical Windows Server 2022 comparison archive)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-044 | Physical target AS-KRM-WS is Windows Server 2022 Datacenter x64, build 20348. Read-only collection found 16 relevant PnP devices, 4 audio endpoints and 16 signed-driver entries. | CONFIRMED — PHYSICAL_HARDWARE_TEST (read-only inventory) | User archive `Bluetooth-A2DP-Compare-AS-KRM-WS-20261123-204114.zip`, MANIFEST.json. |
| E-045 | OPPO Enco Buds2 is paired/enumerated as a Bluetooth device. Its A2DP service UUID 0x110B devnode exists and reports PnP status OK / ConfigManagerErrorCode 0, but is bound to Microsoft `bth.inf` as generic `Audio Sink Service`, not to `microsoft_bluetooth_a2dp_src.inf` / `BthA2dp.sys`. | CONFIRMED | Archive Devices/PnP-Devices.csv, Drivers/PnP-Signed-Drivers.csv, Registry/Enum-BTHENUM.reg, Registry/Class-Bluetooth.reg, DriverStore/bth.inf. |
| E-046 | Server's in-box `bth.inf` maps service GUID 0x110B to `BthGenericService` with a null service install (`AddService = ,%SPSVCINST_ASSOCSERVICE%`) and only sets `GenericDriverInstalled=1`. The generic service is not an A2DP audio source implementation. | CONFIRMED — INF STATIC ANALYSIS | Archive Drivers/Published-INF/bth.inf and DriverStore/bth.inf package. |
| E-047 | Server archive contains DriverStore packages for `bth.inf`, `bthleenum.inf`, `tdibth.inf`, `audioendpoint.inf`, and `c_swdevice.inf`; it contains no `microsoft_bluetooth_a2dp_src.inf`, no `BthA2dp.sys`, and no BthA2dp service registry export. | CONFIRMED within collected DriverStore/binary inventory | Archive Drivers/DriverStore listing, Drivers/Relevant-INF.txt, Files/Binary-Inventory.csv, Registry exports. |
| E-048 | No OPPO Bluetooth AudioEndpoint is currently created on Server. Its four audio endpoints are NVIDIA HDMI, Microsoft GS wavetable synth, High Definition Audio speakers and S/PDIF. | CONFIRMED | Archive Devices/AudioEndpoints.csv and Devices/PnP-Devices.csv. |
| E-049 | Server has BthEnum, BthLEEnum, BTHPORT, BTHUSB and RFCOMM running. BthAudioHF is a third-party Realtek `RtkHfp.sys` service, stopped, and is not Microsoft's Win10 `BthHFAud.sys` implementation. | CONFIRMED | Archive Drivers/Kernel-Drivers.csv and Registry/Service-BthAudioHF.reg. |
| E-050 | Server SetupAPI log shows the 0x110B device's generic service configuration as `BthGenericService.NT`; it also records a prior LdacA2dp update attempt. Kernel-PnP event 219 records failed `LdacA2dp` load for the 0x110B devnode. | CONFIRMED | Archive Logs/SetupAPI-A2DP-HFP.txt and Logs/Relevant-System-Events.csv. |
| E-051 | Event 7040 at 20:32:29 says service "LDAC A2DP Source Profile Driver" startup was changed from Manual to Disabled. This is a configuration event and does not alone explain why the earlier LdacA2dp load failed. | CONFIRMED event; causal relation UNKNOWN | Archive Logs/Relevant-System-Events.csv. |
| E-052 | Archive reports PNPCount=16, AudioEndpointCount=4, SignedDriverCount=16, ReadOnly=true. The script's final SHA256SUMS.csv generation emitted a sharing violation because it attempted to hash the checksum CSV while that same CSV was being written; ZIP was nevertheless produced. | CONFIRMED | Archive MANIFEST.json and user PowerShell transcript. |
| E-053 | Server MMDevices-Audio registry export contains references to `microsoft_bluetooth_a2dp_src.inf` and A2DP endpoints for other Bluetooth instance IDs/MACs, but no live OPPO AudioEndpoint exists in current PnP endpoint enumeration. These are stale/historical records or otherwise non-live registrations, not proof the active Server stack has BthA2dp. | CONFIRMED observation; stale-record interpretation SUPPORTED | Archive Registry/MMDevices-Audio.reg, Devices/AudioEndpoints.csv, Devices/PnP-Devices.csv. |

### Interpretation — strongest discriminating result
The Bluetooth radio and classic BTH stack on Server are functioning far enough to pair/enumerate the headset and expose the A2DP service UUID 0x110B. The failure is at the profile-to-audio binding: Server binds 0x110B to the generic null-service entry in `bth.inf`, whereas the working Win10 reference binds it to `microsoft_bluetooth_a2dp_src.inf` / `BthA2dp.sys`, which then registers a Kernel Streaming MEDIA source and creates an AudioEndpoint. This is a much more precise lead than "Bluetooth is missing" or "a DLL is missing".

Next discriminating step: collect the corrected Win10 archive with DriverStore package capture. Inspect the exact Microsoft A2DP INF, catalog, source binary and dependencies, then compare target OS decorations and package applicability. Do not copy SYS/DLL or import registry data. Do not modify the physical Server. The current custom LdacA2dp driver's Kernel-PnP failure remains a separate unresolved failure and should not be conflated with the absence of the inbox A2DP package.


## E-044–E-048 — Windows 10 A2DP package capture (2026-11-23 20:49 Kyiv)

| ID | Observation | Status | Source |
|---|---|---|---|
| E-044 | New targeted Win10 archive is AS-KRM-WIN10, Windows 10 Enterprise x64 build 19045; collector manifest reports 26 PnP entries, 7 audio endpoints, 26 signed-driver records. | CONFIRMED | Uploaded archive `Bluetooth-A2DP-Compare-AS-KRM-WIN10-20261123-204910.zip`, MANIFEST.json. |
| E-045 | The paired A2DP profile devnode exists as `Microsoft Bluetooth A2dp Source`, class MEDIA, INF `microsoft_bluetooth_a2dp_src.inf`, version 10.0.19041.1, matching BTHENUM service GUID 0x110B. | CONFIRMED | Same archive, Drivers/PnP-Signed-Drivers.csv. |
| E-046 | The Windows 10 A2DP kernel driver binary is `BthA2dp.sys`, version 10.0.19041.4355, size 282,624 bytes, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`. | CONFIRMED | Same archive, Files/Binary-Inventory.csv and Files/Binaries/BthA2dp.sys. |
| E-047 | The captured `microsoft_bluetooth_a2dp_src.inf` is a thin model-specific/profile INF. Its [Microsoft.NTamd64] section matches BTHENUM 0x110B; [BthA2dpSrc] and .Services/.Interfaces delegate to `microsoft_bluetooth_a2dp.inf` via `Include` and `Needs=Common_BthA2dp_Install[.Services/.Interfaces]`. | CONFIRMED | Same archive, DriverStore/.../microsoft_bluetooth_a2dp_src.inf. |
| E-048 | The collector did not capture the referenced common INF `microsoft_bluetooth_a2dp.inf` or its package/catalog. Thus the actual common installation directives, service/file-copy operations, catalog and complete dependency chain are still unknown. The source INF's DriverStore folder contains only the INF in the archive. | CONFIRMED GAP | Same archive, full file listing and INF content. |

Important correction: the current Win10 `Kernel-Drivers.csv` reports BthA2dp/BthEnum/BthHFAud/BthHFEnum and other demand-start kernel drivers as Stopped/Manual at the instant of collection. Do not label those drivers currently Running from this CSV. The signed PnP driver inventory independently proves the A2DP profile devnode is installed and bound to the Microsoft INF. A demand-start service state is not by itself evidence that the package is absent.

Comparison with Server archive AS-KRM-WS, Server 2022 build 20348: BTHENUM 0x110B Audio Sink Service is present via generic `bth.inf`, but no A2DP MEDIA profile devnode, `microsoft_bluetooth_a2dp_src.inf` entry, `BthA2dp.sys` binary inventory row, or BthA2dp service entry is present. Bluetooth core (BTHPORT/BTHUSB/BthEnum) and Windows Audio/AudioEndpointBuilder are present. This localizes the difference to the profile-driver/package layer rather than proving a missing Bluetooth radio/core stack.

Next: targeted Win10 capture must resolve every INF Include/Needs dependency, especially `microsoft_bluetooth_a2dp.inf`, and collect its entire DriverStore directory including CAT. Also inspect `btampm.inf` only if dependency directives or package contents show it is required. Do not copy binaries or install packages on Server until OS decorations, package signing, dependencies, and Server applicability are verified.


## Evidence update — 2026-11-23 strategy reset

### E-077 — Microsoft Windows 10 A2DP codec matrix
- **Class:** Official platform capability
- **Observation:** Microsoft documents SBC and classic aptX for Windows 10 built-in A2DP. AAC is listed for Windows 11, not Windows 10; LDAC is not listed as an inbox codec.
- **Impact:** There is no Microsoft inbox LDAC codec DLL to transplant. The Windows 10 package path can establish SBC, not LDAC.
- **Source:** https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-classic-audio

### E-078 — Windows Server Bluetooth SKU support
- **Class:** Official platform support
- **Observation:** Microsoft states that Windows Server SKUs do not include in-box Bluetooth support; third-party IHV drivers may be available.
- **Impact:** Server core Bluetooth components do not imply that the A2DP profile package is supported or installed. Treat package adaptation as an unsupported research experiment in a disposable VM.
- **Source:** https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions

### E-079 — Microsoft Bluetooth profile-driver model
- **Class:** Official architecture
- **Observation:** Microsoft documents profile drivers as PnP-selected drivers that communicate with the Bluetooth port driver through WDM requests / Bluetooth Request Blocks.
- **Impact:** A2DP is a profile-driver/package binding problem, not a user-mode DLL loaded by the Bluetooth service. No public Microsoft A2DP codec-provider plug-in API has been identified.
- **Source:** https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack

### E-080 — OPPO Enco Buds2 codec capability
- **Class:** Official hardware specification
- **Observation:** OPPO identifies model ETE41 and lists Bluetooth codecs AAC/SBC.
- **Impact:** Enco Buds2 cannot negotiate LDAC. SBC is the common codec with Windows 10 built-in A2DP; use another sink for the later LDAC stage.
- **Source:** https://www.oppo.com/ua/accessories/oppo-enco-buds2/specs/

### E-081 — Current repository LDAC implementation is source/static, not a Win10 DLL
- **Class:** Repository source inspection
- **Observation:** `third_party/libldac` derives from AOSP `external/libldac`; `service/encoder.cpp` calls the LDAC encoder API; the current project builds/links the encoder as part of its own service. The custom driver implements its own AVDTP/L2CAP path and ACX endpoint.
- **Impact:** Reusable LDAC encoder source, but not a Windows 10 codec DLL and not a plug-in for Microsoft `BthA2dp.sys`. The custom driver path remains parked.
- **Sources:** https://github.com/as-0101/ldac-a2dp-windows/tree/server-2022-oppo/third_party/libldac ; https://github.com/as-0101/ldac-a2dp-windows/blob/server-2022-oppo/service/encoder.cpp ; https://github.com/as-0101/ldac-a2dp-windows/blob/server-2022-oppo/driver/LdacA2dp/driver.c

### E-082 — Alternative A2DP is a third-party driver, not a codec DLL
- **Class:** Existing implementation evidence
- **Observation:** Project reference docs identify Alternative A2DP Driver 1.8.3.1 (Luculent Systems) as `AltA2DP.sys` bound by `oem96.inf` in the MEDIA class on a separate Windows 11 laptop. It provided LDAC 96 kHz playback; it is not documented as part of the AS-KRM-WIN10 capture.
- **Impact:** A possible commercial driver reference, not a redistributable Windows 10 DLL. Its binary package is not currently in Library and Server 2022 compatibility is unproven.
- **Sources:** https://github.com/as-0101/ldac-a2dp-windows/blob/server-2022-oppo/docs/jbl-live-780nc.md ; https://github.com/as-0101/ldac-a2dp-windows/blob/server-2022-oppo/docs/real-machine.md

### E-083 — BlueCaster is a user-mode fallback, not the Microsoft stack
- **Class:** Existing upstream implementation
- **Observation:** BlueCaster uses WASAPI capture, codec encoders, BTstack A2DP/AVDTP/L2CAP and WinUSB to a selected adapter. Its published platform matrix is Windows 10 22H2 / Windows 11, not Server 2022. It takes ownership of the selected adapter.
- **Impact:** A ready fallback to evaluate only if the Microsoft package path fails, preferably with a dedicated USB adapter in a disposable VM. Server 2022 compatibility is unverified; distributed builds also have BTstack personal/non-commercial licensing constraints.
- **Source:** https://seiyafunaokajp.github.io/BlueCaster/

### E-084 — OpenA2DP is not a ready binary
- **Class:** Upstream survey
- **Observation:** OpenA2DP describes itself as pre-alpha and its driver path is still experimental / not validated with real headphones.
- **Impact:** Do not switch to another custom kernel-driver project while the existing Microsoft package path remains unexplored.
- **Source:** https://github.com/RafiMota/open-a2dp

### E-085 — Targeted Win10 package exporter inspected

- **Status:** CONFIRMED — STATIC_ANALYSIS
- **Observation:** `Export-Win10-A2DP-Package.ps1` (Library file ID `file_00000000ae6c82108239f67bdde421be`, Library ID `libfile_c5e086cd16e0819183aa8607e6c40e94`, 5,108 bytes / 95 lines) only searches DriverStore and `%windir%\\INF` for its fixed INF list. It copies matching package directories and `BthA2dp.sys`, and emits direct Include/Needs, file versions, hashes and Authenticode status.
- **Limitations:** no WinSxS search, recursive Include closure, full DLL/COM-provider inventory, PE imports/exports/delay-imports, or CAT membership verification.
- **Impact:** useful for recovering the missing common INF/package; not sufficient by itself for the requested full component map.

### E-086 — Existing broader Win10 collectors are available

- **Status:** CONFIRMED — LIBRARY_SOURCE
- **Observation:** `Collect-Win10-Bluetooth-A2DP.ps1` (file ID `file_00000000f4b08210aad8e3d4dd2e07eb`) supports `-IncludeDriverPackages` and records wider PnP/service/registry/system-driver context. `Collect-Bluetooth-A2DP-Compare.ps1` (file ID `file_00000000187482108c2566e9f9e8147f`) captures Win10/Server comparison data.
- **Impact:** do not create another collector before using these existing scripts; they do not replace offline PE and catalog analysis.

### E-087 — Microsoft A2DP stack is a WDM profile-driver path; no inbox LDAC codec

- **Status:** CONFIRMED — OFFICIAL_DOCUMENTATION
- **Observation:** Microsoft lists Windows 10 A2DP codecs as SBC and aptX Classic; its Bluetooth stack loads a profile driver by PnP/INF and the profile driver communicates with `Bthport.sys` through WDM IRPs/BRBs. Windows Server SKUs are documented as lacking in-box Bluetooth support.
- **Impact:** the Microsoft package is the SBC transport/profile route. A standalone LDAC DLL cannot be assumed to plug into `BthA2dp.sys`; no user-mode codec-provider DLL hook is documented.
- **Sources:** [Bluetooth Classic audio](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-classic-audio), [Using the Bluetooth driver stack](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack), [Previous Windows Bluetooth support](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions).

### E-088 — Alternative A2DP is a Windows 10-compatible third-party driver, not a DLL

- **Status:** CONFIRMED — OFFICIAL_VENDOR_DOCUMENTATION
- **Observation:** official version history lists Alternative A2DP 1.8.3 for Windows 10 22H2 and Windows 11 21H2–25H2. The vendor FAQ requires the Windows 10/11 inbox Bluetooth stack and per-device driver installation; Server 2022 is not in the supported matrix.
- **Impact:** possible licensed fallback/reference if its package is available, but not a Microsoft inbox codec DLL and not a supported Server 2022 solution.
- **Sources:** [Version history](https://www.bluetoothgoodies.com/a2dp/version-history/), [FAQ](https://www.bluetoothgoodies.com/a2dp/faq/).

### E-089 — BlueCaster is an existing user-mode alternative, not a Microsoft-stack plug-in

- **Status:** CONFIRMED — UPSTREAM_SOURCE
- **Observation:** BlueCaster 3.0.4 uses WASAPI capture, codec encoders including LDAC, BTstack A2DP/AVDTP/L2CAP and WinUSB. It takes over a USB Bluetooth adapter; published requirements are Windows 10 22H2 / Windows 11, not Server 2022.
- **Impact:** keep as a fallback for a disposable VM with a dedicated USB adapter; do not confuse it with a Windows 10 LDAC DLL or the Microsoft A2DP stack.
- **Source:** [BlueCaster repository](https://github.com/SeiyaFunaokaJP/BlueCaster), [architecture](https://seiyafunaokajp.github.io/BlueCaster/architecture).


## New evidence — 2026-11-23 23:49 Kyiv (complete Win10 A2DP package capture)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-049 | Targeted package capture completed on AS-KRM-WIN10, Windows 10 Enterprise build 19045; manifest reports 16 INF path records and 56 Include/Needs directive records. | CONFIRMED | Uploaded `Win10-A2DP-Package-20261123-234936.zip`, MANIFEST.json. |
| E-050 | The common A2DP INF `microsoft_bluetooth_a2dp.inf` is the actual installer definition: Class=MEDIA, DriverVer=04/12/2024 10.0.19041.4355; copies `BthA2dp.sys`, installs kernel service `BthA2dp` (demand start), and registers KSCATEGORY_AUDIO interfaces for A2DP source and sink. | CONFIRMED | Captured DriverStore INF. |
| E-051 | The common INF explicitly includes `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`; Needs `KS.Registration`, `WDMAUDIO.Registration`, `BtaMPM.CopyFilesOnly`, `mssysfx.CopyFilesAndRegister`. | CONFIRMED | Captured DriverStore INF. |
| E-052 | Source INF `microsoft_bluetooth_a2dp_src.inf` matches `BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}` and delegates installation, services and interfaces to the common INF. Sink INF matches remote A2DP source UUID 0x110A. | CONFIRMED | Captured DriverStore INFs. |
| E-053 | Captured A2DP binary `BthA2dp.sys` is 282,624 bytes, version 10.0.19041.4355, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`; Authenticode reports Valid, Microsoft Windows signer, catalog signature. | CONFIRMED | Metadata/File-Inventory.csv and BthA2dp-Signature.txt. |
| E-054 | Captured `BtaMPM.sys` is version 10.0.19041.5848, SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`; Microsoft signature Valid. | CONFIRMED | Metadata/File-Inventory.csv. |
| E-055 | The archive contains A2DP source/common/sink INFs, HFP INFs and binaries, AVRCP transport INF/binary, and BtaMPM INF/binary. It does not contain catalog (.cat) files; the captured SYS and INF files nevertheless have Valid catalog-based Authenticode status on the reference machine. | CONFIRMED | ZIP inventory and Metadata/File-Inventory.csv. |
| E-056 | The collection manifest is complete, but Logs/Collection.log is zero bytes; therefore no precise console warning/error from the collector can be reconstructed from this archive. | CONFIRMED | ZIP inventory. |

Interpretation: Windows 10's classic A2DP path is concretely a MEDIA-class WDM/Kernel Streaming audio function with explicit KS/WDMAUDIO/MSSysFx/BtaMPM dependencies, not an ACX client implementation. This package is now sufficient to analyze the reference install model. It does not prove the Win10 package is supported on Server 2022. Do not manually copy SYS files or import registry exports. Next, compare INF applicability and package identity with Server 2022 and obtain catalog-complete export only if required for a controlled VM test.


## Evidence update — 2026-11-24 (Server dependency inventory and full INF audit)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-090 | The newly uploaded `Win10-A2DP-DriverStore.zip` contains the three A2DP package directories: common INF + `BthA2dp.sys`, source INF, and sink INF. It does not contain CAT files. | CONFIRMED | Uploaded archive `Win10-A2DP-DriverStore.zip`, full ZIP inventory. |
| E-091 | The common Windows 10 INF is UTF-16LE, Class=MEDIA, DriverVer 10.0.19041.4355. It has an undecorated `[Microsoft.NTamd64]` manufacturer model section (no explicit Windows 10-only build decoration was found in the inspected INF). It installs service `BthA2dp` as a demand-start kernel driver and registers A2DP source/sink KSCATEGORY_AUDIO interfaces. | CONFIRMED — STATIC INF AUDIT | Uploaded `Win10-A2DP-Package-20261123-234936.zip`, `microsoft_bluetooth_a2dp.inf`. |
| E-092 | The common A2DP INF has direct dependencies `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`; Needs sections are `KS.Registration`, `WDMAUDIO.Registration`, `BtaMPM.CopyFilesOnly`, `mssysfx.CopyFilesAndRegister`. The package archive contains `btampm.inf` and `BtaMPM.sys`, but does not contain `mssysfx.inf`. | CONFIRMED | Uploaded package archive; exact INF text and ZIP inventory. |
| E-093 | The Server 2022 read-only inventory finds `ks.inf` and `wdmaudio.inf` in the active INF/DriverStore roots, but does not find `btampm.inf`, `mssysfx.inf`, `BthA2dp.sys`, or `BtaMPM.sys` in those roots. | CONFIRMED — ROOTS TESTED ONLY | User-provided PowerShell output, 2026-11-24. WinSxS file-level search is still pending. |
| E-094 | A separate Server WinSxS directory-name search for tokens `bta|a2dp|sysfx|bluetooth.*audio` found only unrelated `wwf-cwevbtargets` directories; the same command found no Microsoft BthA2dp/BtaMPM system-driver service. | CONFIRMED — LIMITED SEARCH | User-provided PowerShell output, 2026-11-24. This was a directory-name search, not a recursive file-name search. |
| E-095 | Microsoft's audio-driver documentation independently shows the same Bluetooth A2DP/HFP dependency chain: `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`, plus `mssysfx.CopyFilesAndRegister`; it describes the sample as supporting Bluetooth hands-free and stereo devices. | CONFIRMED — OFFICIAL DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects (lines 319–350, 381–400). |

### Interpretation and limits
- The Windows 10 package's core A2DP profile binding is now understood at INF level; the earlier claim that the common INF was still missing is obsolete.
- Server 2022 is missing the A2DP profile driver and at least the BtaMPM dependency from the searched active roots. The absence of `mssysfx.inf` is not yet proven across WinSxS.
- The INF's `NTamd64` model decoration alone does **not** prove Server 2022 support. Microsoft explicitly says Windows Server SKUs do not have in-box Bluetooth support. This remains an unsupported compatibility experiment.
- No catalog file was included in either archive. Do not treat this alone as evidence that the package is unsigned: the Win10-side inventory records valid Microsoft catalog-based Authenticode verification. Recover the original catalog only if required for an isolated package test.
- No physical Server files, services, devices, registry, BCD, or security settings have been changed.


## Evidence update — 2026-11-24 (Server WinSxS file-level search)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-096 | A recursive PowerShell file-name search of Server 2022 `%windir%\\WinSxS` for `btampm.inf`, `mssysfx.inf`, `BtaMPM.sys`, and `BthA2dp.sys` returned no paths for any of the four files. | CONFIRMED — USER-PROVIDED SEARCH OUTPUT | PowerShell output, 2026-11-24. |
| E-097 | A second independent search using `where /r %windir%\\WinSxS` for the same four file names also returned no paths. | CONFIRMED — USER-PROVIDED SEARCH OUTPUT | PowerShell output, 2026-11-24. |
| E-098 | The four named files are absent from the Server 2022 WinSxS file tree as tested. Combined with E-093, the Windows 10 A2DP profile driver and its BtaMPM dependency are absent from the searched active INF/DriverStore roots and WinSxS. This still does not establish whether an equivalent component exists under another name or package identity. | CONFIRMED — SEARCH SCOPE QUALIFIED | User-provided outputs, 2026-11-24. |

### Updated interpretation
The WinSxS file-level search closes the previously pending check from E-093/E-094: no matching A2DP/BtaMPM/MSSysFx files were found in the component store. The Server 2022 image therefore lacks the exact Windows 10 package payload/dependency files searched for. Next investigation should identify the Windows 10 component/package ownership and catalog/signing chain, then decide whether a catalog-complete, dependency-closed package can be evaluated in a disposable Server 2022 VM. This is not authorization to install on the physical Server, and it does not establish that cross-SKU installation is viable.


## Evidence update — 2026-11-24 (INF package semantics and catalog model)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-099 | The captured Windows 10 `btampm.inf` identifies Microsoft Bluetooth Multi-Profile Manager, Class=SYSTEM, DriverVer 10.0.19041.5848 (2025-04-28). Its only model install section is `BtaMPM.CopyFilesOnly`; comments explicitly state that this section exists so external INFs can indirectly reference its CopyFiles payload through Include/Needs. | CONFIRMED — DIRECT INF CONTENT | `Win10-A2DP-Package-20261123-234936.zip`, `WindowsINF\\btampm.inf`. |
| E-100 | The captured `btampm.inf` and `microsoft_bluetooth_a2dp.inf` Version sections contain no `CatalogFile` directive. Microsoft documents that system-supplied INFs do not carry CatalogFile entries because Windows validates them against system-supplied catalogs. Therefore the missing .cat files in the collector archive are not evidence of an incomplete or unsigned inbox package. | CONFIRMED — INF + OFFICIAL DOC | Captured INF files; [INF Version Section](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-version-section). |
| E-101 | `microsoft_bluetooth_a2dp.inf` also has no CatalogFile directive and directly requests `mssysfx.CopyFilesAndRegister` in addition to `KS.Registration`, `WDMAUDIO.Registration`, and `BtaMPM.CopyFilesOnly`. The current archive does not contain `wdmaudio.inf`, `ks.inf`, or a file named `mssysfx.inf`; the exact provider of the mssysfx section has therefore not yet been established from captured source files. | CONFIRMED — SCOPE QUALIFIED | Captured INF text and archive inventory. |

### Interpretation
The inbox package catalog model is now understood: the absence of a package-local CAT in the exported archive is expected for system-supplied INFs and must not be treated as a signing blocker. The dependency investigation remains open at the section-resolution level: identify which inbox INF/component exports `mssysfx.CopyFilesAndRegister`, and identify the servicing/package ownership of `BtaMPM.sys` on Windows 10. Do not generate a replacement catalog or modify INF files; either would change the signed package semantics. The exact Server 2022 file absence remains established only for the four searched filenames, not for equivalent sections/components under other names.


## Evidence update — 2026-11-24 (WinSxS component/package ownership)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-102 | A Windows 11 22H2 x64 WinSxS manifest identifies the BtaMPM component as `Product-onecore__dual_btampm.inf`, assembly version 10.0.22621.1, type `dualModeDriver`. Its manifest owns `btampm.inf` in DriverStore and `BtaMPM.sys` in System32\\drivers, and records DriverDatabase ownership/configuration for `BtaMPM.CopyFilesOnly`. | CONFIRMED — THIRD-PARTY OS IMAGE MIRROR | [WinSxS manifest mirror](https://github.com/colorsci/nickel-x64/blob/b3f8c9549e49f2a92b401b3809b210d5f78190ba/WinSxS/Manifests/amd64_product-onecore__dual_btampm.inf_31bf3856ad364e35_10.0.22621.1_none_35751b1e1189debf.manifest). |
| E-103 | The same Windows 11 22H2 x64 `Microsoft-Windows-Client-Desktop-Required-Package` MUM explicitly declares driver entries for `microsoft_bluetooth_a2dp.inf` and `btampm.inf`, each mapped to its own `Product-onecore__dual_*.inf` assembly. It also lists A2DP source/sink and HFP packages. | CONFIRMED — THIRD-PARTY OS IMAGE MIRROR | [Client Desktop Required package MUM](https://github.com/colorsci/nickel-x64/blob/b3f8c9549e49f2a92b401b3809b210d5f78190ba/servicing/Packages/Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.22621.1.mum). |

### Interpretation and limitations
This gives a concrete component ownership model for Windows 11 client: Bluetooth A2DP and BtaMPM are separate dual-mode driver components integrated by Client Desktop Required servicing metadata. This is a strong lead for why the payload may be absent from Server 2022, but it is not yet proof of the exact Windows 10 19045 or Server 2022 20348 package graph. No matching Server 2022 20348 manifest/MUM was found in this pass. The next discriminating comparison is the Win10 19045 and Server 2022 20348 servicing package metadata for these component identities, not another recursive file search. The `mssysfx.CopyFilesAndRegister` section is independently shown in Microsoft documentation to be exposed via `wdmaudio.inf` (Microsoft's Windows 11 APO guidance explicitly names `mssysfx.CopyFilesAndRegisterCapX` as coming from `wdmaudio.inf`); verify the exact legacy section in the captured Win10 `wdmaudio.inf` before marking the dependency closed.


## Evidence update — 2026-11-24 (BtaMPM INF semantics and A2DP INF dependency correction)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-104 | The captured Windows 10 `btampm.inf` identifies itself as the installer for **Bluetooth Multi-Profile Manager**, Class=SYSTEM, DriverVer 10.0.19041.5848. Its only install model is `BtaMPM.CopyFilesOnly`; that section copies `BtaMPM.sys` to directory 12 (System32\\drivers). | CONFIRMED — DIRECT PACKAGE TEXT | `Win10-A2DP-Package-20261123-234936.zip`, DriverStore\\btampm.inf, lines 1–46. |
| E-105 | The comments in `BtaMPM.CopyFilesOnly` explicitly say the section exists so external INFs can indirectly reference files via Include/Needs; the files are otherwise not used by a device-install section in this INF but must be copied to Driver Store. | CONFIRMED — DIRECT PACKAGE TEXT | Same INF, lines 32–38. |
| E-106 | The captured common A2DP INF includes exactly `ks.inf`, `wdmaudio.inf`, and `BtaMpm.inf`; its Needs list is `KS.Registration`, `WDMAUDIO.Registration`, `BtaMPM.CopyFilesOnly`, and `mssysfx.CopyFilesAndRegister`. It does **not** list `mssysfx.inf` in Include. | CONFIRMED — DIRECT PACKAGE TEXT | `microsoft_bluetooth_a2dp.inf`, lines 31–34. |
| E-107 | The same A2DP INF writes system-effects properties under the reserved inbox-only `MSFX\\0` registry namespace for the A2DP render endpoint, including stream/mode effect CLSIDs and processing-mode properties. | CONFIRMED — DIRECT PACKAGE TEXT | `microsoft_bluetooth_a2dp.inf`, lines 61–74; comments lines 65–66. |
| E-108 | Microsoft's APO documentation independently publishes the same Bluetooth A2DP Include/Needs pattern and explicitly describes the sample as supporting Bluetooth hands-free and stereo devices. A separate HFP example uses `MsApoFxProxy.Registration` as a WDMAUDIO-provided registration section. | CONFIRMED — OFFICIAL DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects |

### Interpretation / correction
The absence of a standalone file named `mssysfx.inf` must not be treated as a proven missing payload dependency. The actual captured A2DP INF does not Include that INF by filename; it requests the named section `mssysfx.CopyFilesAndRegister` from the INF section-resolution environment. We must identify which inbox INF/component supplies that section on the reference Windows 10 image (likely through the WDMAUDIO/APO infrastructure) before claiming a missing component or attempting to transplant anything. By contrast, `BtaMpm.inf` is explicitly included and its separate INF copies the concrete `BtaMPM.sys` dependency. The BtaMPM file absence on Server is therefore a stronger, direct package gap than the current `mssysfx.inf` filename search suggests.

Next: inspect the full reference `wdmaudio.inf` and relevant INF section-resolution/provider data on Win10, then compare package/component ownership with Server 2022. Do not infer a file named `mssysfx.inf` from the Needs section name. No physical Server changes.


## Evidence update — 2026-11-24 (MSSysFx provider resolved)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-109 | The Microsoft Bluetooth audio INF example declares `Include=ks.inf, wdmaudio.inf, BtaMpm.inf` and requests `mssysfx.CopyFilesAndRegister` in the same DDInstall context. Under INF Include/Needs resolution, this makes `wdmaudio.inf` the provider to inspect; no separate `mssysfx.inf` is implied. | CONFIRMED — OFFICIAL DOCUMENTATION + INF SEMANTICS | Microsoft Learn, Implementing Audio Processing Objects: https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects |
| E-110 | A published copy of Windows `wdmaudio.inf` shows section `[mssysfx.CopyFilesAndRegister]` with `CopyFiles=FX.CopyList` and `RegisterDlls=FX.RegisterDlls`; `FX.CopyList` names `WMALFXGFXDSP.dll` and `SysFxUI.dll`, and `FX.RegisterDlls` registers both. | SUPPORTED — THIRD-PARTY MIRROR OF INBOX INF | Public INF text mirror surfaced in research: https://www.runonpc.com/sound-card-microsoft-kernel-system-audio-device-driver-downloads-update/ . Must be verified against the actual Windows 10 and Server 2022 INF files before treating versions/contents as exact for those builds. |
| E-111 | Server 2022 already has `wdmaudio.inf` in `C:\\Windows\\INF` according to the user's earlier inventory, but the presence of the INF alone does not prove that it contains `mssysfx.CopyFilesAndRegister` or that the two referenced DLLs exist. | CONFIRMED — USER INVENTORY; CONTENT UNTESTED | User-provided Server 2022 INF inventory, 2026-11-24. |

### Updated interpretation
The prior search for a file named `mssysfx.inf` was not a valid test of this dependency. The dependency is a named section imported from `wdmaudio.inf`. The remaining Server-side check is narrowly scoped: inspect that section in the actual Server `C:\\Windows\\INF\\wdmaudio.inf` and check the two DLL payloads. If all three are present, MSSysFx is not a missing prerequisite; attention returns to the explicit BtaMPM and BthA2dp package gap. No host changes are needed for this check.


## Evidence update — 2026-11-24 (Server 2022 MSSysFx confirmed)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-112 | On the physical Server 2022 host, `C:\\Windows\\INF\\wdmaudio.inf` contains `[mssysfx.CopyFilesAndRegister]`, `[FX.CopyList]`, and `[FX.RegisterDlls]`; the copy list names `WMALFXGFXDSP.dll` and `SysFxUI.dll`. | CONFIRMED — USER-PROVIDED HOST OUTPUT | PowerShell Select-String output, 2026-11-24. |
| E-113 | Both referenced DLLs exist in `C:\\Windows\\System32`: `WMALFXGFXDSP.dll` (1,870,712 bytes) and `SysFxUI.dll` (401,408 bytes), both file version `10.0.20348.5756`. | CONFIRMED — USER-PROVIDED HOST OUTPUT | PowerShell Get-Item/VersionInfo output, 2026-11-24. |

### Updated interpretation
The Server 2022 image contains the legacy MSSysFx INF section and both payload DLLs. MSSysFx is therefore not a missing prerequisite in the current A2DP dependency investigation. This does not prove the full A2DP package is compatible or installable on Server 2022. The remaining explicit missing dependency/package lead is BtaMPM (`BtaMpm.inf` / `BtaMPM.sys`), followed by the Microsoft classic A2DP profile package (`microsoft_bluetooth_a2dp*.inf` / `BthA2dp.sys`). No system changes were made.


## Evidence update — 2026-11-24 (Win10 package capture re-audited; prior status corrected)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-114 | The uploaded `Win10-A2DP-Package-20261123-234936.zip` does contain the common `microsoft_bluetooth_a2dp.inf`, the thin source INF, `btampm.inf`, `BthA2dp.sys`, and `BtaMPM.sys`. The common INF and BtaMPM INF are in their corresponding DriverStore package directories. | CONFIRMED — DIRECT ARCHIVE INSPECTION | User-provided archive in current project runtime; archive MANIFEST identifies AS-KRM-WIN10, build 19045, captured 2026-11-23 23:49. |
| E-115 | The archive contains no .cat files (31 archive entries total). The captured system-supplied A2DP INFs have no CatalogFile directive; Microsoft documents that system-supplied INFs are validated using system catalogs. The BthA2dp SYS signature was reported valid on the reference machine, but the exact catalog identity/member list was not exported. Do not call the archive unsigned. Cross-SKU staging still requires the source system catalog and CBS/component ownership to be identified. | CONFIRMED — DIRECT ARCHIVE INSPECTION + OFFICIAL INF RULE | Archive listing; Metadata/BthA2dp-Signature.txt; https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-version-section |
| E-116 | The captured `btampm.inf` is Class=SYSTEM, DriverVer 10.0.19041.5848, x64-only Manufacturer decoration `NTamd64`; its sole install purpose is the `BtaMPM.CopyFilesOnly` section copying `BtaMPM.sys` to `System32\\drivers`. It explicitly says it exists to satisfy external INF Include/Needs references and otherwise has no device-install section. | CONFIRMED — DIRECT INF INSPECTION | Captured DriverStore btampm.inf, SHA-256 `c657a6b32ac8ccfdeef3c12630686b87c973dd114bee73aec288d86b989961ef`. |
| E-117 | The captured common A2DP INF is Class=MEDIA, DriverVer 10.0.19041.4355, x64-only `NTamd64`; it includes `ks.inf`, `wdmaudio.inf`, and `BtaMpm.inf`, then installs `BthA2dp.sys` as a demand-start kernel service and registers KS audio source/sink interfaces. No explicit Server target decoration was observed in the inspected Manufacturer section. | CONFIRMED — DIRECT INF INSPECTION | Captured DriverStore microsoft_bluetooth_a2dp.inf, SHA-256 `4f3b988b658e1e7f8b97e645c1c92be0ba270d4db76832dab871516eedcbcf0c`. |
| E-118 | Microsoft documentation states that all Windows Server SKUs do not have in-box Bluetooth wireless technology support; this describes product support policy, but does not by itself establish that the client A2DP binaries are technically incompatible with Server 2022. | CONFIRMED — OFFICIAL DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions |

### Correction to earlier project notes
Some prior notes incorrectly said the common A2DP INF/package folder was missing from the 23:49 targeted archive. Direct inspection proves that statement false: the common INF and both core SYS binaries are present. What remains missing is the CAT file and complete servicing/component provenance. Do not ask the user to rerun the targeted package exporter merely to recover the common INF.

### Updated interpretation
The INF package is now sufficiently captured for static analysis. The key unresolved question is no longer whether the Windows 10 files exist, but how Windows 10 image servicing owns and stages these files, and whether the INF/package is applicable to Server 2022. The next discriminating evidence is the original image component/package metadata (CBS manifests/MUMs and DriverStore package catalog), not another search of the installed Server file system. The absence of a Server target decoration in the INF is not proof of incompatibility; NTamd64 alone is also not proof of Server compatibility.


## Evidence update — 2026-11-24 (static PE header/import audit)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-119 | Captured `BthA2dp.sys` is PE32+ x64, native kernel subsystem, no delay-import directory; its direct imports are from `ntoskrnl.exe`. The import list includes feature-configuration routines such as `RtlRegisterFeatureConfigurationChangeNotification` / `RtlQueryFeatureConfiguration`, alongside standard kernel and I/O routines. | CONFIRMED — STATIC PE INSPECTION | GNU objdump `-p` against captured archive binary; SHA-256 in E-114. |
| E-120 | Captured `BtaMPM.sys` is PE32+ x64, native kernel subsystem, no delay-import directory; imports from `ntoskrnl.exe`, `cng.sys`, and `WppRecorder.sys`. Its imports include WNF/feature-configuration routines and timer APIs. | CONFIRMED — STATIC PE INSPECTION | GNU objdump `-p` against captured archive binary; SHA-256 in E-114. |

### Interpretation limits
PE headers and import names establish architecture and static dependencies only. They do not prove that every imported routine is exported by the exact Server 2022 kernel build, nor that runtime contracts/feature state are compatible. Next discriminating comparison is against the Server 2022 20348 kernel exports and the component manifests/package applicability from original images. Do not infer compatibility from x64/native PE alone.


## Evidence update — 2026-11-24 01:42 (PE provenance, codecs and licensing)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-121 | A separate System32 BthA2dp.sys copy is 279,040 bytes, SHA-256 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737, PE32+ x64, with 8 import descriptors / 144 imported functions: ntoskrnl.exe, HAL.dll, ks.sys, btampm.sys, WppRecorder.sys, SleepStudyHelper.sys, WDFLDR.SYS and ksecdd.sys. This is not the 282,624-byte DriverStore package copy in E-119. | CONFIRMED — STATIC PE REPORT | Library files a2dp_pe_imports_report(2).txt / (3).txt; file IDs file_0000000033e482109479f740ed5a8030 and file_000000008d708210bada16b6cb44c429. |
| E-122 | Microsoft's Windows 10 Classic Audio codec documentation lists SBC and aptX Classic. It does not list LDAC or AAC for the Windows 10 inbox A2DP path. | CONFIRMED — OFFICIAL DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-classic-audio |
| E-123 | OPPO's official Enco Buds2 specification lists AAC and SBC; LDAC is not listed. The ETE41 target can validate SBC but cannot be used for LDAC negotiation/audio. | CONFIRMED — OFFICIAL PRODUCT SPECIFICATION | https://www.oppo.com/uk/accessories/enco-buds2/specs/ |
| E-124 | Alternative A2DP Driver public version history advertises LDAC in version 1.8.3 (2026-06-22) and lists Windows 10 22H2 / Windows 11 21H2–25H2. Its EULA restricts reverse engineering, decompilation, disassembly, modification and transfer, and describes a hardware-bound/non-transferable license. The EULA's Additional Terms list AOSP as OSS but do not identify bundled files or grant rights to the proprietary driver. | CONFIRMED — VENDOR DOCUMENTATION / EULA | https://www.bluetoothgoodies.com/a2dp/version-history/ ; https://www.bluetoothgoodies.com/a2dp/eula/ |
| E-125 | Microsoft describes APOs as user-mode COM objects that implement audio DSP effects. The mssysfx/FX registration path is therefore an audio-effects path, not evidence of an LDAC codec-provider DLL. | CONFIRMED — OFFICIAL DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/audio-processing-object-architecture |
| E-126 | GitHub metadata identifies as-0101/ldac-a2dp-windows as a fork of yariktop133/ldac-a2dp-windows; the upstream main branch is one commit ahead. The upstream README describes a complete replacement A2DP source driver/encoder service, not a Windows 10 inbox codec DLL. | CONFIRMED — GITHUB REPOSITORY METADATA / README | https://github.com/as-0101/ldac-a2dp-windows ; https://github.com/yariktop133/ldac-a2dp-windows |
| E-127 | The current Library recursive inventory contained no ISO, WIM, ESD, CAB or MSU media. The original Windows 10/Server 2022 image metadata is therefore not available in the currently indexed Library files. | CONFIRMED — CURRENT LIBRARY INVENTORY ONLY | Files Library recursive listing, 2026-11-24. This does not rule out media stored outside the accessible Library. |
| E-128 | The open-source Dependencies tool supports direct, forwarded and delay-load dependencies plus API-set schema parsing; its documented limitation is that arbitrary dynamic LoadLibrary calls are not discovered. It is a suitable existing tool for the next static PE pass, with runtime tracing kept separate. | CONFIRMED — TOOL DOCUMENTATION | https://github.com/lucasg/Dependencies |


| E-129 | Secondary Windows 10 driver inventories list a 279,040-byte BthA2dp.sys as version 10.0.19041.1 dated 2019-12-06/07, matching the size of the separate System32 copy in E-121. A Windows 10 22H2 DriverStore inventory also lists btampm.inf 10.0.19041.5848, microsoft_bluetooth_a2dp.inf 10.0.19041.4355 and source/sink INFs 10.0.19041.1. The forum inventories do not publish the 0442... SHA, so the hash-to-version match remains provisional. | SECONDARY CORROBORATION — NOT PRIMARY BINARY PROVENANCE | https://us.forums.blizzard.com/en/d2r/t/tried-everything-but-still-crashing-since-last-update/63966 ; https://www.tenforums.com/threads/frequent-bsods-when-idle.223390/ |
| E-130 | The newer DriverStore BthA2dp package copy (282,624 bytes / SHA 5FBA... / version 10.0.19041.4355) has a static import report with ntoskrnl.exe only, while the separate 279,040-byte System32 copy (SHA 0442...) has 8 import descriptors / 144 functions. This is a material binary-generation difference and makes the DriverStore package copy the primary compatibility candidate; it does not rule out dynamic dependencies or INF/KS/MSSysFx requirements. | CONFIRMED — STATIC PE REPORT COMPARISON; COMPATIBILITY NOT YET TESTED | E-119, E-121; WIN10_COMPONENT_AUDIT.md |

| E-131 | The read-only precheck recorded one present A2DP devnode and current INF oem75.inf. The PnP record identifies the remote A2DP Sink service UUID 0x110B; the node was enumerated before driver start failed. | CONFIRMED — HISTORICAL READ-ONLY SNAPSHOT | Library ldac-precheck.txt (file_000000007b088210b26633c565ab08df); 20-36.txt (file_00000000f64082108f18eca5ae6a2fb0). |
| E-132 | The recorded oem75.inf binding is the project's own LDAC A2DP Project package: provider LDAC A2DP Project, service LdacA2dp, section LdacA2dp_Device.NT, DriverVer 0.2.325.1600, ProblemCode 37 and ProblemStatus 0xC000000D. This is a custom-driver start failure, not a test of Microsoft's BthA2dp package. | CONFIRMED — HISTORICAL READ-ONLY PNP RECORD | Library 20-36.txt and ldac-precheck.txt; file refs above. |
| E-133 | The archived Server 2022 environment report records bthserv, Audiosrv and AudioEndpointBuilder running; BTAGService and BthAvctpSvc not installed; bthport.sys, bthusb.sys, bthenum.sys and bthmini.sys present; btha2dp.sys absent from System32\\drivers. The report is historical, not a fresh host query. | CONFIRMED — ARCHIVED ENVIRONMENT SNAPSHOT | Library A2DP_Server2022_Environment_20261119_180132.txt (file_000000006424821088aec377a93ea3a3). |
| E-134 | Microsoft defines the LOCALMFG tag in a BTHENUM hardware ID as the manufacturer of the local Bluetooth radio. Bluetooth SIG company ID 0x0002 is Intel and 0x005D is Realtek. Therefore the current node's LOCALMFG&0002 refers to the host radio, not OPPO; the legacy Realtek rtka2dp.inf IDs ending LOCALMFG&005D target Realtek local radios. | CONFIRMED — OFFICIAL PNP-ID DOCUMENTATION + BLUETOOTH SIG ASSIGNED NUMBERS; REALTEK PACKAGE VERSION UNVERIFIED | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/installing-a-bluetooth-device ; https://www.bluetooth.com/wp-content/uploads/Files/Specification/HTML/Assigned_Numbers/out/en/index-en.html ; https://www.treexy.com/driver/rtka2dp-inf/ |
| E-135 | A DriverStore folder rtka2dp.inf_amd64_0fd0faf5e73b2466 is present, but the captured A2DP_INF_Investigation has an empty A2DP INF FILES section and no INF bytes/version. It is not the current oem75 binding; treat it as an unverified leftover Realtek package, not an OPPO or LDAC candidate. | CONFIRMED — ARCHIVED INVENTORY; PACKAGE CONTENTS NOT CAPTURED | Library A2DP_INF_Investigation.txt (file_0000000004ec8210a7a7c2273d7e5dbe); A2DP_Server2022_Environment_20261119_180132.txt (file_000000006424821088aec377a93ea3a3). |


## Evidence additions — 2026-11-24 02:19 (codec ownership, source provenance and parser audit)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-136 | Microsoft's current Classic Audio table lists Windows 10 A2DP codecs as SBC and aptX Classic. AAC is not supported on Windows 10; LDAC is not listed. This rules out a Microsoft inbox LDAC codec DLL/provider in the documented Windows 10 A2DP path. | CONFIRMED — OFFICIAL DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-classic-audio |
| E-137 | The public symbol index for the older BthA2dp.sys 10.0.17763.168 binary (SHA-256 DFB24CB4F18C0AA1A5BFD99419D85302B75DAAFEB253DD4A5CA22DFF65BA3385) lists internal `A2dpSbcCodec`, `AptXCodec` and AVDTP symbols; no `Ldac` text occurs among its 997 named symbols. This supports codec ownership inside the profile driver for that build, but is not a symbol map for the captured 10.0.19041.4355 package binary. | SECONDARY — OLDER PUBLIC PDB SYMBOL INDEX | https://lise.pnfsoftware.com/winpdb/DFB24CB4F18C0AA1A5BFD99419D85302B75DAAFEB253DD4A5CA22DFF65BA3385-BthA2dp.html |
| E-138 | The current `server-2022-oppo` source vendors AOSP `external/libldac` at upstream commit `eeee1a3f`; CMake builds `ldacBT_enc` and `ldacBT_abr` as static libraries, and `service/encoder.cpp` calls the LDAC APIs. This is an existing source implementation, not a Windows 10 DLL or Microsoft-stack codec provider. | CONFIRMED — REPOSITORY SOURCE / COMMIT HISTORY | https://github.com/as-0101/ldac-a2dp-windows/commit/95bb92866b0d77de20ee94694eb4be2979635947 |
| E-139 | The Library script `pe_imports_a2dp.py` reads the same IMAGE_IMPORT_DESCRIPTOR repeatedly because its loop does not advance `pos` by 20 bytes. The 1,315,472-byte `a2dp_pe_imports_report.txt` therefore repeats the first descriptor and is invalid for descriptor counts or dependency conclusions. Reports (2)/(3) are separate 8,098-byte outputs, but their corrected generating source was not found in the Library and they still need an independent reproducible pass. | CONFIRMED — SOURCE CODE REVIEW; LEGACY REPORT INVALIDATED | Library file `file_000000002c8c821081ba77ee9d223c6f` / `libfile_6bda9621e34481918defd5640143d3de`; report file `file_00000000f33882109a6b1f79c3aaf72d`. |
| E-140 | BlueCaster v3.0.4 (published 2026-11-23) is an existing user-mode A2DP transmitter advertising LDAC 330/660/990 kbps. Its README requires Windows 10 22H2 or Windows 11 and a USB Bluetooth adapter assigned to WinUSB; it bypasses the Windows Bluetooth stack. Server 2022 is not in its published support matrix. The x64 portable release asset is 16,494,671 bytes, SHA-256 3C27828065D6A20ABEF3B19B435B71D8F6053768CC0900934E15FD112346A024; not downloaded or installed in this pass. | CONFIRMED — UPSTREAM README / RELEASE METADATA; SERVER RUNTIME UNTESTED | https://github.com/SeiyaFunaokaJP/BlueCaster ; https://github.com/SeiyaFunaokaJP/BlueCaster/releases/tag/v3.0.4 |
| E-141 | BlueCaster's README states that the distributed programs include BTstack, whose license permits personal, non-commercial use only unless a separate commercial license is obtained. This is a material constraint on using or redistributing that alternative. | CONFIRMED — UPSTREAM LICENSE NOTICE | https://github.com/SeiyaFunaokaJP/BlueCaster |
| E-142 | The vendored AOSP libldac NOTICE says certification is required to use LDAC in products; Sony's official AOSP page provides a corporate licensing inquiry. This is a product-distribution/certification gate, not proof that a local lab encode/negotiation test is prohibited. | CONFIRMED — PROJECT NOTICE + OFFICIAL SONY PAGE; WINDOWS PRODUCT TERMS NEED CLARIFICATION | https://www.sony.net/Products/LDAC/aosp/ ; https://github.com/as-0101/ldac-a2dp-windows/blob/server-2022-oppo/third_party/libldac/NOTICE |


## Evidence additions — 2026-11-24 02:35 (Microsoft public symbol-index hash cross-check)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-143 | Winbindex's x64 hash-only index lists the exact captured DriverStore `BthA2dp.sys` SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3` under `btha2dp.sys`. This independently confirms that the exact binary hash is present in the Winbindex x64 corpus. The simplified hash page does not provide file version, PE timestamp, OS/update identity or catalog membership. | CONFIRMED — HASH INDEX ONLY | https://winbindex.m417z.com/hashes/5f.html |
| E-144 | Winbindex's x64 hash-only index lists the exact 279,040-byte System32 `BthA2dp.sys` SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737` under `btha2dp.sys`. This confirms the older/secondary copy is a distinct indexed binary, not the 282,624-byte DriverStore file. | CONFIRMED — HASH INDEX ONLY | https://winbindex.m417z.com/hashes/04.html |
| E-145 | Winbindex's x64 hash-only index lists the exact `BtaMPM.sys` SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD` under `btampm.sys`. This confirms the captured BtaMPM binary hash is indexed. | CONFIRMED — HASH INDEX ONLY | https://winbindex.m417z.com/hashes/da.html |

Winbindex's README states that its generated binary download links point to Microsoft's public symbol server (msdl.microsoft.com); Winbindex indexes the metadata needed to construct those links. The hash-only pages above confirm exact SHA-256 presence but do not expose the PE timestamp/virtual size or full per-build metadata. The actual binaries were not downloaded in this pass. Source: https://github.com/m417z/winbindex


## Evidence additions — 2026-11-24 02:48 (Server 2022 Bluetooth support nuance)

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-146 | Microsoft explicitly states that all Windows Server SKUs do not have in-box Bluetooth wireless technology support, while third-party Bluetooth drivers may be available from IHVs. The same page lists A2DP 1.3.2 and AVDTP 1.3 among Windows 10 in-box profiles, not Server profiles. | CONFIRMED — OFFICIAL MICROSOFT DOCUMENTATION | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions |
| E-147 | Microsoft's Bluetooth component guidelines list QD ID 130847 for Windows Server 2022 as a Host Subsystem qualification, the same QD ID used for Windows 10 22H2. This is evidence of a qualified host-subsystem target, not proof that Windows Server 2022 ships the Bluetooth stack or A2DP profile in-box. It does not contradict E-146. | CONFIRMED — OFFICIAL MICROSOFT DOCUMENTATION; SCOPE DISTINCTION | https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/bluetooth |

Operational implication: keep three layers separate in the Server analysis: (1) the radio/vendor transport and third-party host stack that may exist on the machine, (2) the Microsoft Bluetooth core/host subsystem interfaces, and (3) the missing in-box A2DP profile package. Presence of a Bluetooth radio or a certified host-subsystem target does not prove that an A2DP endpoint/codec driver is installed.


## E-148 — Windows 10 A2DP update payloads are PSF deltas (2026-11-24)

Source: GitHub Actions CI #463, run 45311922753, artifact microsoft-catalog-a2dp-audit.zip.

- KB5036979 contains A2DP component version 10.0.19041.4355; the extracted f/btha2dp.sys payload is 11,840 bytes and does not begin with PE MZ.
- KB5126657 contains A2DP component version 10.0.19041.7802 and BtaMPM 10.0.19041.7725; extracted f/btha2dp.sys (15,766 bytes) and f/btampm.sys (7,952 bytes) are not complete PE images.
- These files are forward-delta payloads. Package discovery/version evidence is valid; imports/exports cannot be read from these payloads without reconstruction.

## E-149 — Server 2022 KB5126655 lacks the A2DP profile package (2026-11-24)

Source: GitHub Actions CI #463, run 45311922753, artifact microsoft-catalog-a2dp-audit.zip.

The Server 2022 build 20348.5761 package scan found no microsoft_bluetooth_a2dp*.inf, BthA2dp.sys, BtaMPM.sys, or matching A2DP/BtaMPM CBS manifest hits. It did find Microsoft-OneCore-Bluetooth-Package and Microsoft-OneCore-Connectivity-Bluetooth-Package plus other Bluetooth core/input/WinRT packages. This is evidence of a client A2DP profile-package gap in the Server update, not evidence that third-party A2DP is impossible.

## E-150 — Winbindex symbol-server downloads are not exact target binaries (2026-11-24)

Source: CI #463 artifact win10-a2dp-symbol-audit-metadata.zip.

All 3 exact identities failed SHA-256 verification. The symbol server returned BthA2dp 10.0.19041.6392 instead of 4355, BthA2dp 10.0.19041.1030 instead of 19041.1, and BtaMPM 10.0.19041.7660 instead of 5848, while retaining the indexed timestamp/size. Do not use those downloads for exact-version PE compatibility claims.

## E-151 — Exact UUP image extraction started (2026-11-24)

Source: UUP image audit run #3, isolated branch experiment/win10-a2dp-uup-image-audit-20261124.

The run targets Windows 10 19045.5917 x64 and Server 20348.5761 x64. It is in progress after adding a narrowly scoped SHA-256 fallback to the UUP downloader helper. No runtime installation or physical-host action is part of this run.


## E-148 — Windows 10 A2DP update payloads are PSF deltas (2026-11-24)

Source: GitHub Actions CI #463, run 45311922753, artifact microsoft-catalog-a2dp-audit.zip.

- KB5036979 contains A2DP component version 10.0.19041.4355; the extracted f/btha2dp.sys payload is 11,840 bytes and does not begin with PE MZ.
- KB5126657 contains A2DP component version 10.0.19041.7802 and BtaMPM 10.0.19041.7725; extracted f/btha2dp.sys (15,766 bytes) and f/btampm.sys (7,952 bytes) are not complete PE images.
- These files are forward-delta payloads. Package discovery/version evidence is valid; imports/exports cannot be read from these payloads without reconstruction.

## E-149 — Server 2022 KB5126655 lacks the A2DP profile package (2026-11-24)

Source: GitHub Actions CI #463, run 45311922753, artifact microsoft-catalog-a2dp-audit.zip.

The Server 2022 build 20348.5761 package scan found no microsoft_bluetooth_a2dp*.inf, BthA2dp.sys, BtaMPM.sys, or matching A2DP/BtaMPM CBS manifest hits. It did find Microsoft-OneCore-Bluetooth-Package and Microsoft-OneCore-Connectivity-Bluetooth-Package plus other Bluetooth core/input/WinRT packages. This is evidence of a client A2DP profile-package gap in the Server update, not evidence that third-party A2DP is impossible.

## E-150 — Winbindex symbol-server downloads are not exact target binaries (2026-11-24)

Source: CI #463 artifact win10-a2dp-symbol-audit-metadata.zip.

All 3 exact identities failed SHA-256 verification. The symbol server returned BthA2dp 10.0.19041.6392 instead of 4355, BthA2dp 10.0.19041.1030 instead of 19041.1, and BtaMPM 10.0.19041.7660 instead of 5848, while retaining the indexed timestamp/size. Do not use those downloads for exact-version PE compatibility claims.

## E-151 — Exact UUP image extraction started (2026-11-24)

Source: UUP image audit run #3, isolated branch experiment/win10-a2dp-uup-image-audit-20261124.

The run targets Windows 10 19045.5917 x64 and Server 20348.5761 x64. It is in progress after adding a narrowly scoped SHA-256 fallback to the UUP downloader helper. No runtime installation or physical-host action is part of this run.

## E-152 — Corrected PE parser recovered (2026-11-24)

Library file `pe_imports_a2dp_fixed.py`, ID `file_000000006ac88210b1f6b3d695278455`, advances IMAGE_IMPORT_DESCRIPTOR by 20 bytes. Reports (2) and (3), IDs `file_0000000033e482109479f740ed5a8030` and `file_000000008d708210bada16b6cb44c429`, are byte-identical and analyze the 279,040-byte System32 BthA2dp copy (SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`), not the 282,624-byte DriverStore copy. The fixed parser does not capture exports, delay imports, API-set host mapping, PE OS-version fields or CAT membership. Repo `tools/research/audit_pe_binary.py` is the fuller parser.

## E-153 — Non-exact Win10 candidate import comparison (CI #463)

Candidate BthA2dp 10.0.19041.6392, 282,624 bytes, SHA-256 `3d026ae46f46c2323e9e70b194f1fb5eb32974c42c4fd1f9a24e44214dafd4ec`: 149 imports. Candidate BtaMPM 10.0.19041.7660, 43,008 bytes, SHA-256 `7e9c0cfcf073d501fe4cbdf632fc9f3a22c088abaccc73f9735a603a4c9951dd`: 14 named exports, including all 10 required by BthA2dp. BtaMPM's 42 imports resolve against available Server 20348.5866 exports. 129/149 BthA2dp imports matched that later Server reference set plus companion BtaMPM; 20 imports from HAL/SleepStudyHelper/WDFLDR/ksecdd were not compared because those references were omitted. These candidates do not match captured hashes and are not proof for Server 20348.5761.

## E-154 — Existing LDAC implementations compared

[BlueCaster](https://github.com/SeiyaFunaokaJP/BlueCaster) is user-mode BTstack+WinUSB, takes over a USB radio, has no Server 2022 support claim and includes BTstack under a personal/non-commercial license; not a codec DLL. [OpenA2DP](https://github.com/RafiMota/open-a2dp) is pre-alpha and its kernel drivers have not been built with WDK or run against a headset; not a ready binary. Neither is selected over the existing Microsoft package path.

## E-155 — UUP image audit #3

Run 45317582562, experiment branch `experiment/win10-a2dp-uup-image-audit-20261124`, commit `e9900fc894772997526995feeaecfff4a9ec5ff0`, targets Win10 19045.5917 and Server 20348.5761. In progress at this update; no package or image installation.

## E-156 — Existing Project Source archives

The Win10 A2DP package and DriverStore archives are already indexed. The Project file object did not expose an authorized raw-byte materialization path in this runtime; this is an access-path limitation, not a missing artifact. Continue with existing text reports and official UUP images; do not ask the user to resend files.

## E-157 — BthA2dp import surface is version-dependent

The captured DriverStore BthA2dp 10.0.19041.4355 (282,624 bytes, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`) is recorded by E-119/GNU objdump as PE32+ x64, native kernel, no delay-import directory and direct imports from `ntoskrnl.exe` only. The separate System32 copy is 279,040 bytes, SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`, with 8 import descriptors / 144 functions. CI #463's non-exact 19041.6392 symbol-server candidate is 282,624 bytes but has 8 descriptors / 149 imports and a different hash. These are distinct files/builds; never transfer import conclusions between them. The exact 19041.4355 report should be reproduced with the full PE parser when its bytes are extracted from the matching UUP image.

## E-158 — Sony confirms no system-level LDAC support in Windows (2025-03-11)

Sony's official support article states that Microsoft Windows and Apple macOS do not support Bluetooth LDAC at the operating-system level, regardless of the PC Bluetooth controller. This supports the conclusion that there is no Microsoft/Sony inbox Windows LDAC codec/provider DLL to transplant. Third-party implementations are separate A2DP drivers or alternate user-mode transports, not a hidden Windows codec DLL.

Source: [Sony Support article 00260277](https://www.sony.ru/electronics/support/articles/00260277), last modified 2025-03-11.

## E-159 — Exact BtaMPM 19041.5848 imports resolve in later Server 20348.5866 reference set

The exact captured BtaMPM.sys 10.0.19041.5848 (43,008 bytes; SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`) in reports (2)/(3) imports 42 symbols: 37 from ntoskrnl.exe, 1 (`SystemPrng`) from cng.sys and 4 from WppRecorder.sys. Its exact import-name set is identical to the non-exact 10.0.19041.7660 symbol-server candidate analyzed in CI #463. All 42 names are present in the available later Server 20348.5866 export reference set. This is a static import-closure pass for the later Server build only; exact Server 20348.5761 exports and the exact BtaMPM export table remain pending.

## E-160 — UUP image audit #3 stopped before image mount because DISM object lacked Version

Run [45317582562](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562), commit `e9900fc894772997526995feeaecfff4a9ec5ff0`, job `138188044012`, failed at `tools/research/extract_uup_image_a2dp.ps1:370` with: `The property 'Version' cannot be found on this object.` The failure occurred while reading `$selected.Version`, before the selected image was mounted. The log shows UUP download/conversion work, but no image-component audit was completed. The workflow cleanup removed temporary image/payload files, and the run produced no metadata artifact. This is a harness/API-shape failure only; it provides no evidence for or against binary compatibility.

## E-161 — Corrected offline image identity and dependency-reference path submitted for CI

- Commit `144d42105a26d5aa21f159ae068b17a047f724a9` replaces the nonexistent `Get-WindowsImage.Version` assumption with exact verification from a temporary copy of the mounted image's offline SOFTWARE hive. It checks CurrentBuild.UBR and EditionID and records ProductName, InstallationType and BuildLabEx. The source WIM remains mounted read-only.
- The same commit adds HAL.dll, SleepStudyHelper.sys, WDFLDR.SYS and ksecdd.sys to the Server export-reference set.
- Commit `e947970356884ead996bcc7347fa0e5554aa770b` adds the Win10 image's DriverStore-preferred BtaMPM.sys as a companion export reference before auditing BthA2dp imports.
- Verification runs: #4 `45325486392` (offline-hive + kernel-reference fix) and #5 `45325586394` (latest companion-BtaMPM fix). Both were in progress at evidence capture. No successful image identity, PE match, catalog membership or runtime result is claimed until their logs and metadata artifacts are inspected.

## E-162 — Server generic A2DP UUID fallback versus Win10 dedicated source INF

The archived INF comparison transcript `00-33.txt` shows Server 2022 `bth.inf` mapping BTHENUM Audio Sink UUID `{0000110b-0000-1000-8000-00805f9b34fb}` to `BthGenericService` with a hardware ID ending `_GENERIC`. The same INF's `BthGenericService.NT.Services` section has a null `AddService` and its AddProp section sets only `GenericDriverInstalled`; it does not register `BthA2dp`.

The same transcript shows Win10 `microsoft_bluetooth_a2dp_src.inf` matching the base BTHENUM 0x110B UUID (comment: remote A2DP Sink GUID), then chaining its install, Services and Interfaces sections to `microsoft_bluetooth_a2dp.inf` / `Common_BthA2dp_Install`. Transcript `00-34.txt` shows the common INF including `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`; requiring KS/WDMAUDIO/BtaMPM/MSSysFx registrations; copying `BthA2dp.sys`; registering a demand-start BthA2dp kernel service; and exposing KSCATEGORY_AUDIO source/sink interfaces.

This identifies a concrete, minimal **candidate**: add the existing Win10 A2DP source/common profile package on top of Server's existing Bluetooth core, rather than replacing BthPort/BthEnum/radio components or writing a new driver. It is not yet a runtime result: exact PE compatibility, package rank, CBS/system catalog membership, staging, service start, endpoint, SBC negotiation and audio remain unverified. No INF was staged or installed; physical Server 2022 remains untouched.

## E-163 — Existing LDAC encoder, decoder and DLL/transport boundaries

- Fork identity: GitHub repository API confirms `as-0101/ldac-a2dp-windows` is a fork of `yariktop133/ldac-a2dp-windows`. Parent README targets Windows 11 / ACX 1.1 and test signing; it is not a Windows 10 LDAC DLL package.
- The current fork's `CMakeLists.txt` declares `ldacBT_enc` and `ldacBT_abr` as STATIC libraries and links them into `ldacsvc_core`. `service/encoder.cpp` calls `ldacBT_get_handle`, `ldacBT_init_handle_encode`, `ldacBT_encode`, `ldac_ABR_Proc` and then uses the separate AVDTP media packetizer. `ldacBT_get_version()` returns 2.0.2.
- Header source API: 12 unique `ldacBT_*` encoder functions and 5 `ldac_ABR_*` functions are declared. The encoder header describes encode processing; no decoder API is declared there.
- Decoder path is verification-only: `tools/ldacverify/build-ldacdec.py` fetches `anonymix007/libldacdec` at `c90094b15e25aef0e47c6d775fa94aceb36cabbc` and builds `ldacdec_wav.exe`; it is not included in the product.
- External Windows DLL recipe: [Incus Multicodec](https://github.com/incustechsupport/incus-multicodec) uses `btmulticodec/ldac.py` ctypes bindings and `native/build.cmd` to build `ldac.dll` from libldac with MSVC `/LD /MT` and export macros. It declares 12 encoder + 5 ABR functions through the source headers; no prebuilt DLL is checked into the repo, so no binary SHA/import/export table was verified. The DLL is codec encoding only, not A2DP transport or a Windows codec provider.
- Incus transport is Bumble + WinUSB; BlueCaster transport is BTstack + WinUSB. Both bypass Windows A2DP and require ownership of a USB adapter; Server 2022 support is unverified. The current project already has the same encoder source statically, so replacing it with the Incus DLL adds no capability.
- Result: no Microsoft inbox LDAC codec/provider DLL has been identified. The Windows 10 BthA2dp profile package is the SBC/aptX transport path; LDAC requires an A2DP source stack that advertises and transports LDAC, not merely an encoder DLL. No runtime LDAC negotiation or audio is claimed.


## E-164 — UUP audits #4/#5 reached Server image identity, then failed in the PE parser

Runs [#4 / 45325486392](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325486392), job `138213952436`, and [#5 / 45325586394](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325586394), job `138214282805`, both verified the mounted offline image as Windows Server 2022 Datacenter, build 20348.5761, EditionID ServerDatacenter, InstallationType Server. Both then failed at `audit_pe_binary.py:77` on `AudioEndpointBuilder.dll`: a named delay-import entry exposed `hint=None`, and the parser attempted `int(None)`. The audit stopped before Win10 image extraction, PE reports, INF/CBS/CAT reports or artifact upload. This is a tooling defect only; it is not evidence of missing imports or binary incompatibility.

## E-165 — Missing PE delay-import hint handled and regression-tested

Isolated experiment commit [6778022b4453857e53acf8a18afe54bb7e46f5f5](https://github.com/as-0101/ldac-a2dp-windows/commit/6778022b4453857e53acf8a18afe54bb7e46f5f5) changes `collect_import_table()` to preserve absent hints as null, adds tests for named delay imports with no hint, ordinal imports with no hint and named imports with a numeric hint, and runs them before UUP download. CI #6 / [45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839), job `138235648697`, passed the regression-test step. The full image audit was still running at evidence capture. This confirms the parser fix only; it does not confirm any target binary, PE closure, CAT/CBS membership or runtime behavior.


## E-166 — Win10 A2DP driver package is CBS-owned by Client-Desktop-Required

CI #463 artifact `microsoft-catalog-a2dp-audit.zip`, workflow artifact ID `14883494285`, ZIP SHA-256 `2cd35a38abcdcde42fb0e175dfa042715aae8bb7e6eb2adf9c40c475886c9d38`, is stored in Library `/LDAC Project/Incoming/CI-463-microsoft-catalog-a2dp-audit.zip`. Its `manifest-search-hits.json` SHA-256 is `f40acc6f4af0df375c9e1553600e8e611e3b21c95bc3add5a475b2b9aa70c24c`; `catalog-package-results.json` SHA-256 is `2e52f5e8846f9186a1d426fb21710e3c653b42a205dd59787ff0849cee28cc0b`.

For KB5036979 / captured package version 10.0.19041.4355, the MUM `Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.4355.mum` declares:
- `microsoft_bluetooth_a2dp.inf` → `Product-onecore__dual_microsoft_bluetooth_a2dp.inf`, version 10.0.19041.4355, type `dualModeDriver`;
- `btampm.inf` → `Product-onecore__dual_btampm.inf`, version 10.0.19041.1;
- `microsoft_bluetooth_a2dp_snk.inf` and `microsoft_bluetooth_a2dp_src.inf` → corresponding `dualModeDriver` assemblies version 10.0.19041.1.

For KB5126657, the MUM declares A2DP common 10.0.19041.7802 and BtaMPM 10.0.19041.7725. The Server KB5126655 catalog scan has no matching A2DP/BtaMPM package/MUM hits. This confirms Win10 client CBS ownership and Server package absence in the scanned update; it does not prove that the driver package cannot be independently staged on Server. Full image CAT/registry/INF applicability and disposable-VM staging remain untested.


## E-167 — Only the A2DP source INF is required for PC-to-OPPO playback

The archived Win10 INF comparison and `WIN10_A2DP_PIPELINE.md` establish that `microsoft_bluetooth_a2dp_src.inf` matches the remote A2DP Sink UUID 0x110B and is the host-to-headphones playback direction. `microsoft_bluetooth_a2dp_snk.inf` is the reverse-direction profile (Windows as A2DP sink) and is not required for the OPPO playback milestone. The source INF chains to the common A2DP INF; the common INF requires BtaMPM, KS, WDMAUDIO and MSSysFx registration/copy sections. This narrows the candidate package set but does not prove staging or runtime. No INF was staged.


## E-168 — Existing LDAC-capable A2DP implementations and their boundaries

Official Alternative A2DP Driver version history lists v1.8.3 (2026-06-22) for x64 Windows 10 22H2 and Windows 11 21H2–25H2; no Server 2022 support is listed. Its FAQ says it uses the Windows 10/11 inbox Bluetooth stack, installs per-device as an A2DP driver, requires administrator privileges for package/device-driver changes, and its trial becomes silent after seven days. It supports LDAC and ABR (version history notes LDAC ABR fixes). The official EULA licenses proprietary object code, binds the license to hardware, prohibits redistribution and restricts reverse engineering/disassembly. No installer or binary was downloaded or analyzed; it is a black-box candidate only.

BlueCaster's public README states Windows 10 22H2/Windows 11, user-mode BTstack over WinUSB, and exclusive takeover of the USB Bluetooth adapter while active (Windows loses use of that adapter). Source is Apache-2.0/MIT, but bundled BTstack is personal/non-commercial unless separately licensed. The `YoshKoz/LDACast` search result returned 404 on direct open and is not counted as a verified candidate.


## E-169 — Exact Win10 A2DP PE closure against Server 20348.5761 (UUP audit #6)

Run: [45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839), commit 6778022b4453857e53acf8a18afe54bb7e46f5f5, job 138235648697.
Artifact: ID 14895876155, 328,218 bytes, SHA-256 c1792bd8e5bcdf2a583c3738eeb22bdf27a64ba6ad2701ad70aa8f879d045209.

Exact images: Win10 Pro 19045.5917 x64, UUP ID 598d27dc-ad81-41aa-8c83-42b88e60c823, ISO SHA 29485CBF6A9B33C47675521F999B17E46083A19517564DBAF33E028A2EFF6EF4; Server 2022 Datacenter 20348.5761 x64, UUP ID 008aacce-b0b7-4aeb-a3b2-43286434832c, ISO SHA 1FC3AFBBFC6AADF39B4F8A2B39DAEA64DE417C8B4B471880A5CE09244791B130. Server identity: EditionID ServerDatacenter, InstallationType Server.

| Binary | Version / size | SHA-256 | PE |
|---|---|---|---|
| DriverStore BthA2dp.sys | 10.0.19041.4355 / 282,624 B | 5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3 | AMD64 PE32+, WDM_DRIVER, 149 imports/8 descriptors, no delay/API-set imports, no exports |
| System32 BthA2dp.sys | 10.0.19041.1 / 279,040 B | 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737 | Distinct older copy, 144 imports/8 descriptors |
| BtaMPM.sys | 10.0.19041.5848 / 43,008 B | DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD | AMD64, 42 imports/3 descriptors, 14 exports |

BthA2dp imports: ntoskrnl 75; HAL 1; ks 40; btampm 10; WppRecorder 4; SleepStudyHelper 8; WDFLDR 4; ksecdd 7. All 149 imports resolve against exact Server 20348.5761 exports plus the exact Win10 BtaMPM companion. BtaMPM imports ntoskrnl 37, cng 1 (SystemPrng), WppRecorder 4; all 42 resolve against Server. BthA2dp consumes 10 BtaMPM exports.

Server reference files:
- ntoskrnl.exe 10.0.20348.5756 SHA 3C3D81A2B2AA910E6B4BA4845A7A65D77906A6D32A0811834143987FAA3EE68C
- HAL.dll 10.0.20348.5499 SHA D05F979E55E2FF11FA3587D70987C8591E6DE520BD6960BE5A7C238DF936DD7D
- ks.sys 10.0.20348.5756 SHA DF6F0CB329F7BE7857EC47A90DAC6896C74D85C20D5803C71A9B0CF829757A9B
- WppRecorder.sys 10.0.20348.1 SHA 922A219688B60CCA5CC665FEE7A0751DCE1903F24BE7668704D8BF345EBF55C6
- SleepStudyHelper.sys 10.0.20348.1 SHA 67C91B1753B4AD8C9DA3700E2A955E7FE77C66933AB3D50F21680A2D28772BE2
- WdfLdr.sys 1.33.20348.2849 SHA E6C17ADE3876A6BFE25148878F65E7705BA51E77BE051E22C83800411C214FCD
- ksecdd.sys 10.0.20348.5756 SHA EAA2257B3DCF02CA3EDE8226F1B6CE7ACFFF8B8EBA652242D7CEF34A9AD5A284
- cng.sys 10.0.20348.5756 SHA F84E664B1674FC6B2712B3E649E304C0C6030470AC98D9B5B5A7AEB5F3565926

INF identities:
- microsoft_bluetooth_a2dp_src.inf 10.0.19041.1 SHA B97D1DD53BB6FD040CE5C2527015A09416C29FCBD6B528802D595CBDEEAD4A6A
- microsoft_bluetooth_a2dp.inf 10.0.19041.4355 SHA 4F3B988B658E1E7F8B97E645C1C92BE0BA270D4DB76832DAB871516EEDCBCF0C
- btampm.inf 10.0.19041.5848 SHA C657A6B32AC8CCFDEEF3C12630686B87C973DD114BEE73AEC288D86B989961EF

The source INF matches remote A2DP Sink UUID 0x110B. Common INF includes ks.inf, wdmaudio.inf and BtaMpm.inf; needs KS.Registration, WDMAUDIO.Registration, BtaMPM.CopyFilesOnly and mssysfx.CopyFilesAndRegister; copies BthA2dp.sys; installs demand-start BthA2dp (StartType=3); creates KSCATEGORY_AUDIO source/sink interfaces. BtaMpm.inf is Class SYSTEM and CopyFilesOnly to %12%; no AddService. BtaMPM.sys is a companion module imported by BthA2dp, not a separate service.

Server 20348.5761 has its own ks.inf 10.0.20348.1 SHA 88EA223C8DB5F1DD17381F64BD264CCBFE946F1D1EF2DBA06A0992F60FF3ED94 and wdmaudio.inf 10.0.20348.5756 SHA 63BCE2D74EC4DCC08ACA21B2CDFC1E981906F3A48BEF61FB96D2446014C7B833; both contain the required registration sections. Server bth.inf 10.0.20348.5756 SHA 38302B73607B829CBD94D60D25320924B8727BF55CAD940052444FC22D475459 maps UUID 0x110B to BthGenericService with _GENERIC suffix and a null associated-service install.

Correction: earlier E-119 claim that exact DriverStore BthA2dp imported only ntoskrnl is superseded; exact UUP file has 149 imports. Get-AuthenticodeSignature NotSigned on SYS means no embedded signature, not absence of catalog signature. UUP #6 did not inspect WinSxS/CatRoot/servicing catalogs; membership remains unknown. Static imports do not prove ABI/runtime, WDF bind, BRB behavior, PnP rank, service start or audio. No package staging, driver load, endpoint, SBC negotiation, audio or physical-host access occurred.

UUP audit #7 [45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564), isolated branch experiment/win10-a2dp-catalog-registry-audit-20261124, adds offline catalog membership and read-only SYSTEM service inventory.

