# Microsoft ACX AudioCodec sample — comparison with LdacA2dp

**Reviewed:** 2026-11-22  
**Scope:** class binding, ACX/KMDF versions, DriverEntry order, INF/service registration, target platform.  
**Reference sample:** [microsoft/Windows-driver-samples — audio/Acx/Samples/AudioCodec/Driver](https://github.com/microsoft/Windows-driver-samples/tree/main/audio/Acx/Samples/AudioCodec/Driver)

## Findings

### 1. ACX and KMDF versions

Microsoft AudioCodec sample:
- `ACX_VERSION_MAJOR=1`, `ACX_VERSION_MINOR=1`.
- `KMDF_VERSION_MAJOR=1`, `KMDF_VERSION_MINOR=31`.
- ACX include path and stub library are selected from the same version macros: `acx/km/$(ACX_VERSION_MAJOR).$(ACX_VERSION_MINOR)`.

LdacA2dp baseline successful GitHub Actions run #129 (legacy artifact filenames may say CI-126):
- Also targeted ACX 1.1 and KMDF 1.31.
- Physical Server 2022 host's WinDbg `!wdfldr Acx01000.sys` reported `CLASS_MODULE Version v1.0`; its WDF client version was 1.31.
- Driver class bind failed before DriverEntry with `FxStubBindClasses / VersionBindClass class Acx → 0xC000000D`.

**Interpretation:** the official sample's ACX 1.1 / KMDF 1.31 configuration is not proof that ACX 1.1 is available on every Server 2022 image. The target's actual ACX class module version must govern the compatibility experiment. The ACX class version is distinct from the KMDF version.

### 2. DriverEntry sequence

Microsoft AudioCodec sample sequence:
1. `WDF_DRIVER_CONFIG_INIT`.
2. `WdfDriverCreate`.
3. `ACX_DRIVER_CONFIG_INIT`.
4. `AcxDriverInitialize`.

LdacA2dp follows the same essential order. It adds `PeerInitialize()` between WDF driver creation and ACX initialization, then calls `AcxDriverIsVersionAvailable` after `AcxDriverInitialize`.

**Important:** WDF/ACX class binding occurs in the framework stub before the driver's `DriverEntry` body. Therefore neither `PeerInitialize()` nor the runtime version check can cause or prevent the observed pre-DriverEntry bind failure. The runtime version check is useful only after the class binding succeeds.

### 3. INF and service registration

Microsoft AudioCodec sample:
- `Class=MEDIA`, MEDIA class GUID.
- Root-enumerated device `ROOT\\AudioCodec`.
- `AddService`, kernel-driver service type, demand start, binary in DIRID 13.
- `KmdfService` and `KmdfLibraryVersion=$KMDFVERSION$`.

LdacA2dp:
- `Class=Bluetooth`, Bluetooth class GUID, because this is the function driver for a `BTHENUM` A2DP service devnode, not a root-enumerated standalone audio device.
- Matches the BTHENUM service UUID / target-compatible ID, then creates audio endpoint interfaces through `AddInterface`.
- Uses the same service installation pattern: `AddService`, kernel-driver service type, demand start, binary in DIRID 13, `KmdfService`, and `KmdfLibraryVersion=$KMDFVERSION$`.

**Interpretation:** the different setup class and hardware ID are expected for the different PnP topology. The active device was successfully matched to `oem75.inf` and reached driver start; the recorded failure is at ACX class binding. No concrete INF/service-registration defect is currently evidenced. Do not change the Bluetooth class or replace the BTHENUM match with the sample's MEDIA/root ID.

### 4. DriverTargetPlatform

- Microsoft AudioCodec sample uses `DriverTargetPlatform=Windows Driver`.
- LdacA2dp baseline uses `DriverTargetPlatform=Universal`.
- Microsoft Target Platforms documentation lists Windows Server 2022 as supported for both Universal drivers and Windows Drivers.

**Interpretation:** Universal is not excluded or invalid for Server 2022. The sample's Windows Driver setting is a valid difference worth an isolated A/B build, but not a proven cause of ACX class binding. Do not change production configuration based on the sample alone.

An isolated branch was created:
- Branch: [experiment/acx10-windowsdriver-platform](https://github.com/as-0101/ldac-a2dp-windows/tree/experiment/acx10-windowsdriver-platform)
- Commit: `6656e2d1fcda8d731f6795bd2e7a2950d5ba8309`
- Base: ACX 1.0 experiment commit `593e8f407ec18e72a332edbec323a4ddbbd27774`.
- Only source change: `DriverTargetPlatform` Universal → Windows Driver.
- Draft PR: [#3](https://github.com/as-0101/ldac-a2dp-windows/pull/3), opened for CI only; never merge automatically.
- CI run #143: [run 45050062916](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45050062916), completed successfully; all three jobs passed.

### 5. ACX 1.0 API surface

Microsoft's ACX version overview lists the DDI additions in ACX 1.1. The LdacA2dp sources `audio.c`, `driver.c`, and `driver.h` were scanned against that list; none of the listed ACX 1.1-only APIs are used.

The ACX 1.0 branch changes:
- `ACX_VERSION_MINOR=0`;
- include path expression to `acx/km/1.0`;
- link dependency expression to `acx/km/1.0/acxstub.lib`;
- runtime version gate to 1.0.

The successful CI #133 build is evidence that this code compiles and links against the selected ACX 1.0 build configuration. It does not prove runtime binding on the Server 2022 host.

## WDF class-binding evidence

Microsoft's public Windows-Driver-Frameworks source (`fxldr.h`) shows WDF bind metadata contains a version and function count, and documents class binding through `WdfVersionBindClass` as loading/referencing the class extension and linking it to the client. The implementation of the private class-bind routine is not exposed in that header.

An independent, non-Microsoft investigation on Windows 10 19045 reports the same pre-DriverEntry failure:
- ACX runtime class 1.0.0 / 210 functions.
- Driver bind metadata built against ACX 1.1 / 221 functions.
- `VersionBindClass` rejects the bind with `STATUS_INVALID_PARAMETER`.
- Building against ACX 1.0 and its stub allowed that driver to pass class binding.

Source: [Building a USB Audio 2.0 ACX driver without the WDK — G1](https://erfi.dev/guides/usb-audio2-acx-driver-without-wdk/).

This is strong corroboration for the class-version/function-table mismatch hypothesis, but it is a different Windows build. Do not copy its function counts onto Server 2022 without inspecting the Server 2022 ACX PDB or bind metadata.

## ETW timeline: ACX unload is not established as the cause

The archived Kernel-PnP Driver Diagnostic XMLs show:
- 2026-11-21 17:46:52.1553213 — ACX DriverInit begins.
- 2026-11-21 17:46:52.1561974 — ACX DriverInit ends with status 0.
- 2026-11-21 17:46:52.1563309 — ACX unload completes with status 0.
- 2026-11-21 17:46:52.1568091 — LdacA2dp Event 227 ends DriverInit with decimal 3221225485 = `0xC000000D`.
- A second trace on 2026-11-21 shows ACX unload completes at 23:02:22.6188112 and LdacA2dp Event 227 follows at 23:02:22.6188347, a 23.5 µs gap.

In both traces the events share the kernel thread that processes the driver initialization. This ordering is consistent with ACX class-library teardown/cleanup after the failed client bind. It does **not** prove that the unload caused the failure. The observed ACX service initialization itself completed successfully.

## ACX 1.0 support caveat

Microsoft's ACX version overview says:
- ACX 1.1 is the current version and recommended for new driver development; its initial public release is listed for Windows 10 version 2004 with minimum KMDF 1.31.
- ACX 1.0 is described as pre-release and not recommended for new driver development; the table lists Windows 10 version 1903 with KMDF 1.29.

The table does not list Windows Server 2022. The fact that this specific Server 2022 host registers ACX class module 1.0 is direct host evidence, but it does not establish that ACX 1.0 is a generally supported production development target for all Server 2022 systems. Treat the ACX 1.0 branch as a host-specific compatibility experiment until the physical bind test and broader support assessment are complete.

## Current conclusion

**Leading hypothesis (SUPPORTED, not proven):** the driver was compiled against ACX class 1.1 while the physical Server 2022 host registers ACX class 1.0. The WDF class-bind stub rejects the client before DriverEntry. The ACX 1.0 CI build is the best current candidate, but only a controlled physical-host test can confirm the diagnosis.

**Not current causes:** ACX service startup failure, KMDF 1.31 vs WDF runtime 1.33, INF matching failure, Secure Boot/signature, `PeerInitialize()`, and ACX unload ordering.

## Sources

- [Microsoft ACX version overview](https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview)
- [Microsoft !acxkd / !wdfldr output example](https://learn.microsoft.com/windows-hardware/drivers/debuggercmds/-acxkd)
- [Microsoft Target Platforms](https://learn.microsoft.com/windows-hardware/drivers/develop/target-platforms)
- [Microsoft AudioCodec DriverEntry](https://github.com/microsoft/Windows-driver-samples/blob/main/audio/Acx/Samples/AudioCodec/Driver/Driver.cpp)
- [Microsoft AudioCodec project](https://github.com/microsoft/Windows-driver-samples/blob/main/audio/Acx/Samples/AudioCodec/Driver/AudioCodec.vcxproj)
- [Microsoft AudioCodec INF](https://github.com/microsoft/Windows-driver-samples/blob/main/audio/Acx/Samples/AudioCodec/Driver/AudioCodec.inf)
- [Microsoft WDF loader header fxldr.h](https://github.com/microsoft/Windows-Driver-Frameworks/blob/main/src/framework/shared/inc/private/common/fxldr.h)
- [Independent ACX 1.0 class-bind investigation](https://erfi.dev/guides/usb-audio2-acx-driver-without-wdk/)

### 6. What KmdfLibraryVersion does — and does not do

Microsoft's INF documentation defines KmdfLibraryVersion as the KMDF framework version (major.minor) selected for the KMDF driver; the WDK substitutes $KMDFVERSION$ during build. It does not select the ACX class-extension version.

In this project, ACX class version is selected in the .vcxproj by ACX_VERSION_MAJOR / ACX_VERSION_MINOR, which form both the ACX include directory and the acxstub.lib dependency path. Thus changing the INF KmdfLibraryVersion cannot turn an ACX 1.1 class bind into ACX 1.0. The current KMDF 1.31 setting matches the official AudioCodec sample and should remain fixed while testing ACX.

Microsoft reference: https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/specifying-wdf-directives-in-inf-files (KmdfLibraryVersion, lines 248–253).

### 7. Official !wdfldr example separates KMDF runtime from ACX class version

Microsoft's own !acxkd documentation shows a valid example with CLIENT_MODULE WDF Version v1.31, Wdf01000.sys runtime v1.33, and CLASS_MODULE WDF Version v1.31 with ACX Version v1.1. This is the same WDF client/runtime pairing observed on the target server. Therefore WDF 1.31 client over WDF runtime 1.33 is not, by itself, evidence of a defect. The material difference in the target's captured output is CLASS_MODULE Version v1.0 rather than v1.1.

Microsoft also notes that the !acxkd extension has only partial functionality under ACX 1.0. If the ACX 1.0 test passes class binding, continue to rely on kernel debug output, breakpoints and Kernel-PnP events; do not treat missing !acxkd details as a driver failure.

Reference: https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd (the sample !wdfldr output and ACX 1.0 debugger limitation).

## WDF class-binding stage refinement — 2026-11-22

The preserved failure string names `VersionBindClass WDF_CLASS_BIND_INFO`, class `Acx`, and `STATUS_INVALID_PARAMETER`. This is the WDF `WdfVersionBindClass` path, not a `ClientBindClass` failure message. Microsoft's WDF source header [fxldr.h](https://github.com/microsoft/Windows-Driver-Frameworks/blob/main/src/framework/shared/inc/private/common/fxldr.h) describes this API as loading/referencing the class extension and linking it into the framework library list. The public WDF source does not include the WdfLdr implementation, so the exact internal return condition remains unknown.

Two candidate explanations are now demoted:
- KMDF 1.31 versus runtime 1.33 is supported by Microsoft's [KMDF version history](https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history); the official [!acxkd example](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd) shows the same client/runtime pair.
- Universal is a supported Server 2022 target per [Target Platforms](https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/target-platforms). CI #143's Windows Driver target is an alternate compile experiment, not proof that Universal caused the bind failure.

The Bluetooth INF class remains appropriate for the BTHENUM profile device; MEDIA in the AudioCodec sample reflects its ROOT-enumerated audio-codec topology. The leading unresolved variable remains ACX class version (driver 1.1 versus host class 1.0).