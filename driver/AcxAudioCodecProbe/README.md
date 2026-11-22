# ACX 1.0 Microsoft AudioCodec sample-derived bind probe

## Purpose

This is a disposable hosted-CI experiment to distinguish a general WDK 10.0.26100.6584 ACX 1.0 client/runtime bind failure from an LDAC-specific WDF/ACX bind-metadata problem. It is not a production driver and must never be installed on the physical Server 2022 host.

## Pinned Microsoft source

The source baseline is microsoft/Windows-driver-samples commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69:

- AudioCodec Driver.cpp: WDF_OBJECT_ATTRIBUTES_INIT, WDF_DRIVER_CONFIG_INIT, unload callback, WdfDriverCreate, then ACX_DRIVER_CONFIG_INIT / AcxDriverInitialize.
- AudioCodec.vcxproj: x64/ARM64 KMDF driver, WindowsKernelModeDriver10.0 toolset, ACX 1.1, KMDF 1.31, Windows Driver target platform, WPP and SamplesCommon.lib. It uses $(LatestTargetPlatformVersion) and does not pin a WDK NuGet version in the project file.
- AudioCodec.sln also builds the shared audio/Acx/Samples/Common/SamplesCommon.vcxproj; the full sample includes helper code and WPP dependencies that are intentionally excluded from this minimal discriminator.
- AudioCodec.inf: MEDIA class, root hardware ID ROOT\AudioCodec, KMDF service registration, and audio interface registrations.

The probe retains the sample's DriverEntry/WDF initialization sequence and MEDIA/root-enumerated INF identity, but does not build the complete sample solution. It compiles against the experiment's pinned WDK/SDK 10.0.26100.6584 and ACX 1.0 so the runtime comparison matches CI #248. The upstream project file itself does not establish a specific WDK NuGet package version.

## Deliberate reduction

- Preserve the sample's WDF object attributes, unload callback, WdfDriverCreate then AcxDriverInitialize order.
- Omit WPP, registry-path copying, Device.cpp, SamplesCommon.lib, ACX circuits, pins, streams, endpoints, and audio interface registration. Those are outside a class-bind discriminator.
- INF remains Class=MEDIA and ROOT\AudioCodec, with KMDF 1.31 service registration.
- EvtDeviceAdd logs that it was reached and deliberately returns STATUS_NOT_SUPPORTED. Reaching DriverEntry, successful WdfDriverCreate, successful AcxDriverInitialize, and EvtDeviceAdd is a successful ACX bind even though PnP later reports a failed device start by design.

## Exact build contract

- Build runner: GitHub-hosted `windows-2025` (Windows Server 2025 + Visual Studio 2026); runtime runner: GitHub-hosted `windows-2022` (Windows Server 2022).
- Microsoft WDK NuGet guidance currently lists Windows 11 or newer and Visual Studio 2026 with Desktop development with C++ plus the Windows Driver Kit component. The build job uses the Server 2025 / VS2026 image; Microsoft does not explicitly enumerate Server 2025 in that prerequisite sentence, so this remains an environment-documentation caveat.
- The build invokes 64-bit MSBuild and adds the pinned WDK NuGet `c\bin\10.0.26100.0\x64` and `x86` tool directories to PATH; this is required for WDK tool discovery (including StampInf).
- WDK NuGet assembly: 10.0.26100.6584.
- SDK target: 10.0.26100.0.
- Architecture: x64.
- ACX: 1.0.
- KMDF client: 1.31.
- Target platform: Windows Driver.
- The project is under driver/AcxAudioCodecProbe, beneath driver/Directory.Build.props. The WDK props are imported explicitly before the C++/WDK targets; automatic Directory.Build.props import is disabled for this project to avoid duplicate imports. WDKContentRoot is normalized with a trailing separator for WDK target path concatenation.
- The MSBuild target hard-fails unless the pinned NuGet path is active, DDK include/library paths target 10.0.26100.0, SDK target matches, ACX is 1.0, KMDF is 1.31, architecture is x64, and target platform is Windows Driver.
- After build, the script requires the WDK targets to report WdkVersion 10.0.26100.0 and WdkAssemblyVersion 10.0.26100.6584 in the catalog-attribute output. It preserves the WDK-generated catalog or uses Inf2Cat Server2022_X64 as a fallback, then requires InfVerif /w to pass before runtime testing.

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
- DbgPrintEx filtering and default component mask: https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/reading-and-filtering-debugging-messages
- Pinned Microsoft Driver.cpp: https://github.com/microsoft/Windows-driver-samples/blob/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec/Driver/Driver.cpp
- Pinned Microsoft AudioCodec.vcxproj: https://github.com/microsoft/Windows-driver-samples/blob/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec/Driver/AudioCodec.vcxproj
- Pinned Microsoft AudioCodec.inf: https://github.com/microsoft/Windows-driver-samples/blob/d49bb7d72f3651952b2b6e4ad28d14fe2247eb69/audio/Acx/Samples/AudioCodec/Driver/AudioCodec.inf
