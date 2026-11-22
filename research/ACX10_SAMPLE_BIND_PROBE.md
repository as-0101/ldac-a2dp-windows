# ACX 1.0 sample-derived bind probe

**Status as of 2026-11-23:** probe build is green; hosted runtime preflight has been corrected after two harness-only stops. CI #13 build passed and its runtime job was still in progress at the last check. No ACX sample PnP bind result is claimed yet.

## Objective
Determine whether a minimal ACX 1.0 client derived from Microsoft's AudioCodec sample can bind on the same hosted Windows Server 2022 runtime as the LDAC candidate. This separates a common WDK ACX 1.0 stub/runtime incompatibility from LDAC-specific WDF/ACX metadata or initialization differences.

## Pinned sample and deliberate reductions
- Official source: [Microsoft Windows-driver-samples AudioCodec](https://github.com/microsoft/Windows-driver-samples/tree/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec), commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69.
- Shared Public.h blob: f1e9da3bd6101a503f620a31fa3d2ec471009161.
- The official project defaults to ACX 1.1. The probe deliberately sets ACX 1.0 to match LDAC, while keeping KMDF 1.31 and x64.
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
| #13, 45078613003 | Pass; build job 137381366829 | Runtime job 137381843080 in progress at last check | Next decisive attempt. |

## SignTool correction
CI #10 used SignTool verify /kp, which rejected the self-signed test certificate. Microsoft documents SignTool verify /v /pa Catalog.cat and SignTool verify /v /pa /c Catalog.cat DriverFile for PnP driver-installation signature verification ([Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/verifying-the-signature-of-a-catalog-file-signed-by-a-commercial-relea)). The probe now verifies CAT, SYS and INF with /pa. This affects only hosted test preflight.

## Current next action
1. Wait for CI #13 runtime job 137381843080 and inspect its report/artifact.
2. If the probe reaches DriverEntry, record the exact markers and compare WDF/ACX bind metadata and DriverEntry order with LDAC.
3. If it fails with PnP Code 37 / 0xC000000D before DriverEntry, use !dbgprint, !wdfldr, service state and pinned build/runtime hashes to isolate the WDF/ACX bind stage.
4. If runtime preflight fails again, fix only the hosted harness and do not classify it as a driver result.

## Safety boundary
All tests run on disposable GitHub-hosted Windows Server 2022 runners. No driver install, certificate change, BCD/security change, device restart, rollback or OS update has been performed on the physical server. No user action is required.
