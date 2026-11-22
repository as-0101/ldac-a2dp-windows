# ACX 1.0 sample-derived bind probe

**Status as of 2026-11-23:** CI #15 completed a successful build and hosted runtime harness, but the sample-derived ACX 1.0 client still fails PnP Code 37 / `0xC000000D` before DriverEntry. CI #16 is running a full-mirror/WDF class-bind diagnostic follow-up.

## Objective
Determine whether a minimal ACX 1.0 client derived from Microsoft's AudioCodec sample can bind on the same hosted Windows Server 2022 runtime as the LDAC candidate. This separates a common WDK ACX 1.0 stub/runtime incompatibility from LDAC-specific WDF/ACX metadata or initialization differences.

## Pinned sample and deliberate reductions
- Official source: [Microsoft Windows-driver-samples AudioCodec](https://github.com/microsoft/Windows-driver-samples/tree/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec), commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69.
- Shared Public.h blob: f1e9da3bd6101a503f620a31fa3d2ec471009161.
- The official project defaults to ACX 1.1 / KMDF 1.31, uses the Windows Kernel Mode Driver toolset, `SamplesCommon.lib` and `wpprecorder.lib`, and its DriverEntry initializes WPP and copies registry settings before `WdfDriverCreate`. The probe deliberately sets ACX 1.0 to match LDAC, keeps KMDF 1.31 and x64, and removes those nonessential paths plus all codec topology. Because the failure is before the driver's own DriverEntry, those body-level differences cannot explain the observed bind failure.
- INF is reduced to Class=MEDIA and root hardware ID ROOT\AudioCodec; no full codec topology, endpoints or KS graph.
- DriverEntry follows WdfDriverCreate then AcxDriverInitialize and emits markers. EvtDeviceAdd emits a marker and returns STATUS_NOT_SUPPORTED, isolating bind/entry from full codec topology.

## Build requirements and exact inputs
- Hosted Windows Server 2022 runner; Visual Studio 2022 MSBuild 17.14.60.43110.
- WDK NuGet 10.0.26100.6584; Windows SDK 10.0.26100.0; WindowsKernelModeDriver10.0 toolset; KMDF 1.31; ACX 1.0; x64.
- CI #11 build manifest records:
  - acxstub.lib: 1,362,352 bytes; SHA-256 9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74. This exactly matches the ACX 1.0 stub captured in CI #255.
  - acx.h: SHA-256 91877A614618A3A726E376A6014B99431C9E4EF54A804E9B48F1F7F8680F19FA.
  - WdfDriverEntry.lib: SHA-256 101BF4D30BBF773AC46FF96352EBFDE88A88C834C29F67C10065488CFE2F475C.
  - WdfLdr.lib: SHA-256 AF708DE43A0975239F976BDF5F2596CC6FD7219A076643B2C6C98BDD6C4FF530.
- The build script asserts the ACX stub length/hash and writes a build manifest with SYS/INF/CAT/PDB hashes.

## Hosted Server 2022 runtime baseline
CI #10 directly captured:
- OS: Windows Server 2022 Datacenter, build 20348, UBR 5870, hosted image 20261116.370.1.
- Acx01000.sys: file version 10.0.20348.5866, SHA-256 D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0.
- Wdf01000.sys: file version 1.33.20348.1, SHA-256 32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B.
- LiveKD directly showed ACX CLASS_MODULE v1.0, WDF client 1.31 and WDF runtime 1.33. BCD testsigning Yes was read-only evidence; no BCD changes were made.

CI #11's LiveKD mirror had a missing page. !wdfldr still showed WDF runtime 1.33 and a WDF 1.31 client row matching the Acx01000 image address, but could not display the class-module record in that dump. This is a dump visibility limitation, not proof that the runtime changed. sc.exe query showed Acx01000 was already RUNNING; WMI Win32_SystemDriver.Started incorrectly reported false. The probe now uses SCM query state.

## CI history
| Run | Build | Runtime result | Interpretation |
|---|---|---|---|
| #9, 45076309794 | Compile failed: missing INIT_CODE_SEG macro from sample shared header | Not attempted | Source adaptation issue; macro corrected from official Public.h. |
| #10, 45077156403 | Pass; artifact 14774844743 | Stopped at SignTool verify /kp; no PnP attempt | Not a driver bind failure. Self-signed test cert did not chain to Microsoft root. |
| #11, 45077797657 | Pass; artifact 14775454304 with exact build manifest | Stopped at strict !wdfldr class-version preflight; no PnP attempt | LiveKD missing-page and WMI service-state detection bugs. |
| #12, 45078310971 | PowerShell parser validation failed | Not attempted | Script-construction regression; current script restored and patched. |
| #13, 45078613003 | Pass; build job 137381366829 | Code 37 / 0xC000000D before DriverEntry | First confirmed minimal sample-derived negative bind result. |
| #14, 45081844225 | Pass | Same Code 37 / 0xC000000D; post-boot DbgPrintOn did not enable loader output | Instrumentation timing limitation; do not repeat post-boot registry write. |
| #15, 45082965356 | Pass; build job 137395027059 | Code 37 / 0xC000000D before DriverEntry; raw preinstall ACX01000 IFR present; native dump missing page | Confirms shared bind failure; structured IFR extraction bug found and fixed in CI #16. |

## SignTool correction
CI #10 used SignTool verify /kp, which rejected the self-signed test certificate. Microsoft documents SignTool verify /v /pa Catalog.cat and SignTool verify /v /pa /c Catalog.cat DriverFile for PnP driver-installation signature verification ([Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/verifying-the-signature-of-a-catalog-file-signed-by-a-commercial-relea)). The probe now verifies CAT, SYS and INF with /pa. This affects only hosted test preflight.

## CI #15 — hosted bind result and diagnostic limitations

- Run [45082965356](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45082965356), run number 15, commit `488ae8104eec960370c0887e07136a3e9e3846b5`; build job `137395027059`, runtime job `137395510513`, both workflow jobs succeeded.
- Runtime: Windows Server 2022 Datacenter build 20348 / UBR 5870, image `20261116.370.1`. `Acx01000.sys` 10.0.20348.5866, SHA-256 `D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0`; `Wdf01000.sys` 1.33.20348.1, SHA-256 `32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B`.
- PnP selected `oem13.inf` / service `AcxAudioCodecProbe` for `ROOT\DEVGEN\ACX_SAMPLE_BIND_PROBE_CI`; Code 37 / ProblemStatus `0xC000000D`; no DriverEntry marker. Runtime SYS SHA-256 `BAB3C54C0EAB186CC8C9D89B07BCA871112454175C0C45F8D199DA57927114B6` matches the build SYS byte-for-byte.
- The test started Acx01000 from STOPPED after enabling WDF `VerboseOn=1` / `LogPages=16`. The raw preinstall log includes WDF IFR entries for Acx01000. The sample driver's own WDF IFR cannot be queried because it never successfully loaded. `!wdfkd.wdfldr Acx01000.sys` hit a missing-page/access-violation limitation; `!wdfldr` still showed WDF runtime 1.33 and Acx01000 as a WDF 1.31 client. The same runtime file hashes match CI #10's direct CLASS_MODULE v1.0 capture.
- The CI #15 script's `runtime-result.json` extracted IFR lines only from the postinstall dump and therefore omitted the useful preinstall ACX01000 log. The raw dump was inspected manually; CI #16 corrects the extraction and uses a full `-m0x3FFF` preinstall mirror.
- Cleanup reports success: device and probe service removed, temporary certificate removed from LocalMachine stores, Acx01000 restored to STOPPED, WDF diagnostics restored, no private-key files/markers, private temp directory removed.

## WDK stub versus Server 2022 runtime

- CI #255's WDK 10.0.26100.6584 ACX 1.0 stub descriptor is version 1.0 / 210 functions / 62 structures. The extracted `.kmdfclassbind$b` descriptor is 0x78 (120) bytes. ACX 1.1 is 1.1 / 221 / 62. The exact ACX 1.0 stub library SHA-256 is `9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74`.
- WDF source commit `b6191d9543441329154da32f7ab9bdd97228dd3c` shows `FxGetNextClassBindInfo` validates descriptor size against `WDF_CLASS_BIND_INFO` or `WDF_CLASS_BIND_INFO2` and documents `WdfVersionBindClass` as the call that loads/references the class extension and links the client: [fxldr.h lines 186–259 and 438–451](https://github.com/microsoft/Windows-Driver-Frameworks/blob/b6191d9543441329154da32f7ab9bdd97228dd3c/src/framework/shared/inc/private/common/fxldr.h).
- Existing physical debug evidence records `WdfVersionBindClass` returning `0xC000000D`. The failure is known to occur at the class-bind call, after the client stub has located a descriptor; the exact runtime validation is still unknown. The runtime class function/structure counts have not been obtained.
- Microsoft documents ACX 1.0 as pre-release for Windows 10 1903 / KMDF 1.29, not Server 2022. WDK 26100.6584 is the recommended WDK when staying on VS2022 and supports building for Server 2016 and later; this does not establish ACX 1.0 runtime support on Server 2022 ([ACX version information](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/acx-version-overview), [WDK download](https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk)).

## Current next action
1. Inspect [CI #16 / run 45084678951](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45084678951), commit `9da48c3ecd5921f8cab47888325b156dc9a536f3`, for the full LiveKD preinstall mirror, dump hash/size/missing-page count, WDF class-bind PDB type queries, WDK header scan and cleanup.
2. Compare runtime class-bind information with the WDK ACX 1.0 stub descriptor 0x78 / 120 bytes, 210 functions / 62 structures. Do not infer runtime counts from the stub.
3. If CI #16 still cannot expose runtime class-bind fields, consider a hosted-only local kernel debugging setup with boot-time WDF loader diagnostics or a controlled older-WDK ACX 1.0 comparison. Do not repeat the post-boot DbgPrintOn write.
4. Keep the physical server unchanged. No user action is required.

## Safety boundary
All tests run on disposable GitHub-hosted Windows Server 2022 runners. No driver install, certificate change, BCD/security change, device restart, rollback or OS update has been performed on the physical server. No user action is required.
