# Evidence register

Status labels: CONFIRMED = direct evidence; SUPPORTED = converging evidence, not conclusive; HYPOTHESIS = unproven; REFUTED = contradicted by a relevant test; UNTESTED = not checked; BLOCKED = needs external action.

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-001 | LDAC driver fails before its `DriverEntry` body; ACX class binding returns `0xC000000D`. | CONFIRMED | Notion journal, 21–22 Nov entries; DebugView `AS-KRM-WS.log` and `AS-KRM-WS(1).log`; Kernel-PnP ETW `LDAC-Trace.xml`. |
| E-002 | Kernel-PnP Event 227 records `STATUS_INVALID_PARAMETER` for the driver-init failure. | CONFIRMED | Notion journal; Library artifact `LDAC-Trace.xml`, file ID `file_00000000c3b08210ba662454ece33a1c`. |
| E-003 | Physical server's ACX class module reports version 1.0; its WDF client version is 1.31. | CONFIRMED | WinDbg `!wdfldr Acx01000.sys` output transcribed in Notion handoff. Distinguish CLASS_MODULE Version from WDF Version. |
| E-004 | CI #126 build requested ACX 1.1 and used WDK/SDK 10.0.26100.6584. | CONFIRMED | GitHub CI #126 and branch project files; [run #126](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/44922058650). |
| E-005 | ACX 1.0 versus 1.1 mismatch explains the pre-DriverEntry binding error. | SUPPORTED | E-001 + E-003 + E-004; final proof requires physical-host test of ACX 1.0 build. |
| E-006 | ACX 1.0 experiment compiles successfully. | CONFIRMED | [CI run #133](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45044497961), head SHA `593e8f407ec18e72a332edbec323a4ddbbd27774`; all three jobs success. |
| E-007 | CI #133 package artifact was generated. | CONFIRMED | Artifact 14763242251, digest `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad`; artifact 14763157658, digest `1302c21c3278af9134b5959577a6daa629d0649fd1405148012e074e8147db9c`. |
| E-008 | CI #133 job ran on Windows Server 2022 build 20348; driver build and signability check passed with zero warnings/errors. | CONFIRMED | KMDF driver job 137276017983, logs; run #133. |
| E-009 | CI #133 resolves the ACX include and stub library specifically to 1.0. | SUPPORTED | Project file sets `ACX_VERSION_MINOR=0` and computes include/link paths from the macro; exact expanded path not printed in captured job log. Verify if needed. |
| E-010 | Driver passes ACX class binding on physical Server 2022. | UNTESTED | No ACX 1.0 package has been installed/tested on the physical server. |
| E-011 | KMDF 1.31 client versus WDF runtime 1.33 causes the pre-DriverEntry bind failure | REFUTED as a generic version mismatch | Microsoft KMDF version history; official `!acxkd` example shows client 1.31 / runtime 1.33 | This version pair is supported; investigate ACX class binding separately. |
| E-012 | ACX unload caused LDAC class-bind failure. | UNTESTED | ETW event order alone is not causal evidence. |
| E-013 | Universal target platform is unsupported on Windows Server 2022 and causes the ACX bind failure | REFUTED as an unsupported-platform claim; runtime effect remains untested | Microsoft Target Platforms; CI #143 build | Universal is supported on Server 2022. The successful alternate Windows Driver build does not prove either target's physical runtime behavior. |
| E-014 | Physical OPPO A2DP devnode remains on the failing CI #126 driver | CONFIRMED again on 2026-11-22 | User read-only PnP/status output and `ldac-acx10-precheck.txt` | One present A2DP devnode; `oem75.inf`, `0.2.325.1600`, Code 37. No host mutation performed. |

## Artifact locations

Persistent source archive: Notion Files Library folder `/Bluetooth LDAC Research/Artifacts/`, Directory ID `6b0318b95f648191802d868fc1be5e96`. The handoff page contains exact Library IDs for CI #126 ZIPs and diagnostic logs.

Current run #133 GitHub artifact URLs:
- [Test package 14763242251](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14763242251/zip)
- [Unsigned driver 14763157658](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14763157658/zip)
- [SDP probe 14762557767](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14762557767/zip)

All run #133 artifacts expire 2026-11-29. Their digests are in PROJECT_STATE.md.


| E-015 | CI #133 test package SYS is byte-identical to the unsigned artifact; package contents and hashes inspected. | CONFIRMED | Downloaded artifact 14763242251 and unsigned artifact 14763157658; local SHA-256 in [CI133_PACKAGE_REVIEW.md](CI133_PACKAGE_REVIEW.md). |
| E-016 | CI #126 PDB contains 221 ACX table-index symbols; CI #133 PDB contains 210; all 11 ACX 1.1-only DDI names are present in #126 and absent in #133. | CONFIRMED | Binary/PDB comparison of downloaded artifacts 14714246739 and 14763157658; [Microsoft ACX version overview](https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview). |
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
| E-021 | AudioCodec INF and LdacA2dp INF use the same essential AddService/KmdfService/KmdfLibraryVersion pattern; setup classes differ because one is ROOT\\AudioCodec/MEDIA and the other is a BTHENUM Bluetooth service devnode. | CONFIRMED | Microsoft AudioCodec.inf lines 476–548; repository LdacA2dp.inx lines 1–93. No concrete INF defect currently evidenced. |
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
