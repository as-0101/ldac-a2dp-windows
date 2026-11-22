# ACX 1.0 Microsoft AudioCodec sample-derived bind probe

## Purpose

This is a disposable hosted-CI experiment to distinguish a general WDK 10.0.26100.6584 ACX 1.0 client/runtime bind failure from an LDAC-specific WDF/ACX bind-metadata problem. It is not a production driver and must never be installed on the physical Server 2022 host.

## Pinned Microsoft source

The source baseline is microsoft/Windows-driver-samples commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69:

- AudioCodec Driver.cpp: WDF_OBJECT_ATTRIBUTES_INIT, WDF_DRIVER_CONFIG_INIT, unload callback, WdfDriverCreate, then ACX_DRIVER_CONFIG_INIT / AcxDriverInitialize.
- AudioCodec.vcxproj: x64 KMDF driver, WindowsKernelModeDriver10.0 toolset, ACX 1.1, KMDF 1.31, Windows Driver target platform, WPP and SamplesCommon.lib.
- AudioCodec.inf: MEDIA class, root hardware ID ROOT\AudioCodec, KMDF service registration, and audio interface registrations.

The pinned upstream sample commit itself uses WDK NuGet 10.0.28000.2526 and ACX 1.1. This experiment does not build the complete sample with that newer kit. It uses the sample's DriverEntry/WDF initialization sequence and MEDIA/root-enumerated INF topology, while compiling against the project's pinned WDK/SDK 10.0.26100.6584 and ACX 1.0 so the runtime comparison matches CI #248.

## Deliberate reduction

- Preserve the sample's WDF object attributes, unload callback, WdfDriverCreate then AcxDriverInitialize order.
- Omit WPP, registry-path copying, Device.cpp, SamplesCommon.lib, ACX circuits, pins, streams, endpoints, and audio interface registration. Those are outside a class-bind discriminator.
- INF remains Class=MEDIA and ROOT\AudioCodec, with KMDF 1.31 service registration.
- EvtDeviceAdd logs that it was reached and deliberately returns STATUS_NOT_SUPPORTED. Reaching DriverEntry, successful WdfDriverCreate, successful AcxDriverInitialize, and EvtDeviceAdd is a successful ACX bind even though PnP later reports a failed device start by design.

## Exact build contract

- Runner: GitHub-hosted windows-2022 (Windows Server 2022).
- WDK NuGet assembly: 10.0.26100.6584.
- SDK target: 10.0.26100.0.
- Architecture: x64.
- ACX: 1.0.
- KMDF client: 1.31.
- Target platform: Windows Driver.
- The project is under driver/AcxAudioCodecProbe so MSBuild discovers driver/Directory.Build.props. The MSBuild target hard-fails unless the evaluated WDK assembly and other properties match exactly.
- The package is cataloged for Server2022_X64 with Inf2Cat, then must pass InfVerif /w before any runtime test.

## Runtime prerequisites and safety

1. The runtime job uses a fresh hosted Windows Server 2022 runner. It records OS build/UBR and Acx01000.sys / Wdf01000.sys versions and SHA-256.
2. Acx01000 must be RUNNING before the test device is created. Its file must match CI #248 baseline SHA-256 D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0. Wdf01000 must match the hosted LiveKD baseline SHA-256 32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B.
3. A pre-install LiveKD mirror and !wdfldr acx01000 query must confirm CLASS_MODULE Version v1.0, ACX client WDF v1.31, and WDF runtime v1.33. If the class version or runtime hashes differ, the workflow stops before creating a certificate or device.
4. The runner must already have testsigning Yes. The workflow never changes BCD.
5. ACX 1.0 uses a non-exportable ephemeral code-signing certificate in the runner's LocalMachine\My store. SignTool signs the catalog directly from that store; only the public CER is exported and imported into Root/TrustedPublisher. No PFX/private-key file is created or uploaded.
6. A DevGen ROOT-enumerated device uses the sample hardware ID ROOT\AudioCodec. Microsoft documents ROOT devices as persistent across reboot and recommends SWD for ordinary tests; ROOT is used here because sample topology is the required controlled variable. The device exists only on the disposable runner, no reboot is performed, and the exact instance is removed in finally plus a second cleanup guard.
7. DriverEntry markers use DbgPrintEx with DPFLTR_IHVDRIVER_ID and DPFLTR_ERROR_LEVEL (level 0); no debug-filter registry change or reboot is needed. The workflow restores the ACX service to its pre-test state. No BCD, certificate, device, driver, registry, or security change is made on the physical server.
8. The test package is removed from DriverStore only if PnP selected the exact candidate INF. Artifacts are scanned for private-key files/markers before upload.

## Interpretation contract

- Bind success: DriverEntry marker, WdfDriverCreate=STATUS_SUCCESS, AcxDriverInitialize=STATUS_SUCCESS; EvtDeviceAdd marker is expected and returns STATUS_NOT_SUPPORTED intentionally.
- WDF failure: DriverEntry reached, but WdfDriverCreate returns nonzero.
- ACX initialization failure: DriverEntry and WDF creation succeeded, but AcxDriverInitialize returns nonzero.
- Pre-entry candidate: exact INF selected, ACX 1.0 class module confirmed before install, PnP start attempted, no DriverEntry marker, and PnP reports 0xC000000D. This is consistent with a pre-DriverEntry bind failure; the report must not claim the exact internal bind check unless debugger evidence exposes it.
- Inconclusive: candidate INF not selected, runtime version/class mismatch, or no reliable stage markers.

If the probe binds, compare its actual .kmdfclassbind$b descriptor and WDF bind sections with the CI #248 LDAC SYS (SHA-256 FF97EED8409A7FF9DADB8D9C7C7FB309E789F9A3225847793B39B7D97D8FB9A8). If it fails similarly, investigate the WDK 26100.6584 ACX 1.0 stub/runtime contract; do not infer Microsoft-supported Server 2022 compatibility from this single experiment.

## Compatibility caveat

Microsoft's ACX version table labels ACX 1.0 pre-release and lists Windows 10 version 1903 with KMDF 1.29. It is not recommended for new driver development and does not document Server 2022 as a supported ACX 1.0 target. This probe intentionally tests that undocumented combination because it matches the runtime evidence; it is diagnostic only.

## Microsoft documentation and source

- ACX version information: https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/acx-version-overview
- WDK downloads/versioning: https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk
- WDK NuGet: https://learn.microsoft.com/en-us/windows-hardware/drivers/install-the-wdk-using-nuget
- Driver target platforms: https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/building-a-driver
- InfVerif /w: https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/validating-universal-drivers
- DevGen ROOT/SWD semantics: https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devgen-command-syntax
- Pinned Microsoft Driver.cpp: https://github.com/microsoft/Windows-driver-samples/blob/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec/Driver/Driver.cpp
- Pinned Microsoft AudioCodec.vcxproj: https://github.com/microsoft/Windows-driver-samples/blob/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec/Driver/AudioCodec.vcxproj
- Pinned Microsoft AudioCodec.inf: https://github.com/microsoft/Windows-driver-samples/blob/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec/Driver/AudioCodec.inf
