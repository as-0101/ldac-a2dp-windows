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
| E-030 | Microsoft says !acxkd has only partial functionality under ACX 1.0. | CONFIRMED | Same Microsoft !acxkd page, lines 46–48. |

## Evidence additions — 2026-11-22 20:28 Kyiv

| ID | Claim | Status | Source | Interpretation |
|---|---|---|---|---|
| E-031 | The exact WDF error is logged as `VersionBindClass` for class `Acx`, status `0xC000000D` | CONFIRMED | Preserved kernel debug log in the Notion journal | Failure is reported by the `WdfVersionBindClass` path before the driver's own `DriverEntry`; exact internal return condition remains unknown. |
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
| E-030 | OPPO A2DP profile devnode is `BTHENUM\{0000110B-0000-1000-8000-00805F9B34FB}_LOCALMFG&0002\...`, installed as `Microsoft Bluetooth A2dp Source` by `microsoft_bluetooth_a2dp_src.inf`. | CONFIRMED | User archive Drivers/PnP-Signed-Drivers.csv and Registry/Enum-BTHENUM.reg. |
| E-031 | HFP uses `BthHFEnum`/`BthHFAud`; AVRCP uses `Microsoft.Bluetooth.AvrcpTransport.sys`. BTAGService, BthAvctpSvc, bthserv, Audiosrv and AudioEndpointBuilder are running. | CONFIRMED | User archive System/Kernel-Drivers.csv, System/Services.csv and service registry exports. |
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
