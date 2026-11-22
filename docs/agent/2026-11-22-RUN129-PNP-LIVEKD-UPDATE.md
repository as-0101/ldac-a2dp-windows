# LDAC research update — 2026-11-22 20:37 Kyiv

## Scope

This update reconciles the full Notion research journal with the current repository, the WDK 26100 branch, physical PnP output, and the latest hosted LiveKD CI attempts. No physical-server changes were made.

## Physical host: latest read-only PnP evidence

The latest PnP output for the OPPO A2DP devnode reports:

- Service: LdacA2dp
- Active INF: oem75.inf
- Provider: LDAC A2DP Project
- Driver version: 0.2.325.1600
- Problem code: 37 / CM_PROB_FAILED_DRIVER_ENTRY
- DEVPKEY_Device_ProblemStatus: decimal 3221225485 = 0xC000000D / STATUS_INVALID_PARAMETER

This independently matches the saved FxStubBindClasses -> VersionBindClass, class Acx, status 0xC000000D, and the earlier Kernel-PnP Event 227. It confirms that PnP selected the intended service/INF and that driver start failed with the same NTSTATUS. It does not by itself prove the ACX-version hypothesis.

## WDK 26100 branch and CI provenance correction

Branch: [fix/server2022-acx-wdk-26100](https://github.com/as-0101/ldac-a2dp-windows/tree/fix/server2022-acx-wdk-26100)

- Current head: [4571873b505c52a93db4c785fe3d083eabf8499e](https://github.com/as-0101/ldac-a2dp-windows/commit/4571873b505c52a93db4c785fe3d083eabf8499e), “Use VS2022 runner for WDK 26100 driver build”.
- Successful workflow run: [#129 / ID 44922058650](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/44922058650). All three jobs passed.
- The driver job restored WDK/SDK NuGet packages 10.0.26100.6584, built LdacA2dp.sys, passed signability and produced the OPPO Server 2022 test package.
- The build's DriverVer is 11/21/2026, 0.2.325.1600, matching the physical PnP version. This is a strong provenance correlation, not a byte-for-byte installed SYS hash comparison.
- Successful run #129 artifacts: unsigned driver 14714246739 (SHA-256 722deed96747cbba8c81922ef74427fd19bf81c3080e36d5b463a56d4b269f5c); test package 14714177078 (SHA-256 4b7bc2a856c0aa51ca58f902acf5a2b1dbd74780e714d75326194253840098f8).
- The project uses ACX_VERSION_MAJOR=1 / ACX_VERSION_MINOR=1 and the ACX 1.1 include/link path acx/km/1.1/acxstub.lib.

**Run-number correction:** the successful run at ID 44922058650 is GitHub Actions workflow run #129. Actual workflow run #126 is ID 44922013678, commit ee417569fb4f7d14779af2597bc383b0ee53041a, and failed without artifacts. The unsigned artifact 14714246739 and PDB count of 221 ACX table-index symbols belong to successful run #129. Existing Files Library names beginning CI-126 are legacy/mislabelled filenames; do not use that label for new references.

The physical device's matching DriverVer and continued 0xC000000D failure demote “WDK 26100 pin alone” as the fix. They do not rule out every toolchain interaction.

## INF, service, target and sample findings

- INF Class=Bluetooth and the Bluetooth class GUID are appropriate for the BTHENUM A2DP profile device. The Server 2022 model section targets build 20348 and uses the A2DP _GENERIC compatible ID. PnP reports the intended service and INF as active.
- The INF's KmdfService / KmdfLibraryVersion pattern matches Microsoft's AudioCodec sample. The INF does not select ACX 1.0/1.1; the project file's ACX_VERSION_MINOR, include path and acxstub.lib do.
- Microsoft lists Universal as a supported driver target for Windows Server 2022. CI #143 / run 45050062916 built the alternate Windows Driver target, but neither target build proves runtime class binding.
- KMDF 1.31 client / WDF runtime 1.33 is supported; this is distinct from ACX class-module version.
- Microsoft's AudioCodec sample uses ACX 1.1, KMDF 1.31 and DriverTargetPlatform=Windows Driver. Its WdfDriverCreate -> AcxDriverInitialize order matches LDAC. Its MEDIA setup class is for a ROOT-enumerated codec, not a BTHENUM profile device.
- ACX 1.0 is documented as pre-release/not recommended for new development; CI #133 remains a diagnostic compatibility experiment only.

References:
- [ACX version overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/acx-version-overview)
- [KMDF version history](https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history)
- [Target platforms](https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/target-platforms)
- [Bluetooth device installation](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/installing-a-bluetooth-device)
- [Microsoft AudioCodec sample](https://github.com/microsoft/Windows-driver-samples/tree/main/audio/Acx/Samples/AudioCodec)

## Hosted LiveKD attempts: runs #6–#8

- [Run #6 / ID 45054673989](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054673989) was cancelled. Artifact 14767527142, SHA-256 f793ea378ba1e57df6a1f7102a1f21e8bc3acce76e9d6646d9551bd69967af1c.
- [Run #7 / ID 45054866734](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054866734) was cancelled. Artifact 14767775337, SHA-256 bb8764e5cb2d789981bd36cda3053f4ec91f83f29359f8fe27e738d238b3a5a1.
- Both logs show KD command-line usage output after LiveKD invocation. Neither produced a valid !wdfkd.wdfldr class-module result. Do not treat them as symbol-resolution tests.
- [Run #8 / ID 45056354003](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45056354003) failed: LiveKD reported “Error finding kd.exe”; the expected dump was not created. Artifact 14767208063, SHA-256 b9cf8c3a224d0c370305ae1270de369b3bfd6c885d038488a5ede475115427ea.
- The three report ZIPs are preserved in Files Library: run #6 library ID libfile_3fcc773af2ec8191899040f1ab2f0021 (duplicate-safe filename ends in run6-report(1)); run #7 ID libfile_70550aca71088191b2940b0f11fb92ab; run #8 ID libfile_5fe724c427a08191a924c877c0c16ba2.
- Workflow-only correction: [commit 02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3](https://github.com/as-0101/ldac-a2dp-windows/commit/02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3) on research/acx-runtime-livekd adds the KD directory to PATH and uses a command file (-cf) for KD inspection. No CI run has yet been observed for this commit; it is unverified and changes only the research workflow.
- CI #5 remains the only successful native LiveKD capture/KD processing attempt. Public WDF loader symbols still blocked class enumeration; hosted runner ACX class-module version remains unknown.

## Root-cause status

- CONFIRMED: physical PnP ProblemStatus 0xC000000D; active LdacA2dp/oem75.inf selection; WDK 26100.6584 ACX 1.1 build; supported KMDF 1.31/runtime 1.33 pairing; Universal target support.
- SUPPORTED, not proven: ACX class version mismatch (driver 1.1 versus physical host class 1.0) remains the leading explanation for pre-DriverEntry class binding failure.
- DEMOTED: WDK 26100 pin alone; Bluetooth INF class mismatch; Universal target alone; generic WDF 1.31/runtime 1.33 incompatibility.
- UNTESTED: physical CI #133 ACX 1.0 package; effect of a newer Server 2022 cumulative update on the physical ACX class version.

## Exact continuation

1. The next discriminating test remains CI #133 / Universal / ACX 1.0 on the physical host. Before any install, obtain the read-only package status pre-check after extraction to C:\LDAC-Test\ACX10-Universal:
   `& 'C:\LDAC-Test\ACX10-Universal\oppo-driver-tool.exe' status 2>&1 | Tee-Object -FilePath "$env:USERPROFILE\Desktop\ldac-acx10-precheck.txt"`
2. No prepare, certificate import, upgrade, device restart, rollback, BCD change, driver change or OS update without separate explicit authorization.
3. If the physical test remains blocked, inspect a separately updated Server 2022 VM/image for ACX class version. Do not update the physical host or combine OS servicing with the driver experiment.
4. If ACX 1.0 reaches DriverEntry, continue in order: WdfDriverCreate, AcxDriverInitialize, ACX device/circuit, A2DP, then stable SBC before LDAC.

No physical-server configuration was changed during this investigation.
