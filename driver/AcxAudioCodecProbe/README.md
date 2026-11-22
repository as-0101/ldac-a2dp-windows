# ACX 1.0 AudioCodec bind probe

Disposable hosted-runner experiment. Never install this package on the physical Windows Server 2022 host.

## Source baseline

The probe's `DriverEntry` ordering and WDF object setup follow the pinned Microsoft Windows-driver-samples AudioCodec implementation:

- Repository: `microsoft/Windows-driver-samples`
- Commit: `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69`
- File: `audio/Acx/Samples/AudioCodec/Driver/Driver.cpp`
- Blob: `452b0d99eaf24451d965bd1b0f3ef140417e6d98`

The probe preserves `WDF_OBJECT_ATTRIBUTES_INIT`, the unload callback, `WdfDriverCreate` followed by `AcxDriverInitialize`. It intentionally omits circuits, endpoints, and Bluetooth functionality. `EvtDeviceAdd` logs entry and returns `STATUS_NOT_SUPPORTED`.

## Required build provenance

- WDK/SDK NuGet: `10.0.26100.6584`
- Target platform: `Windows Driver`
- Architecture: x64
- ACX headers/stub: 1.0
- KMDF: 1.31
- Project is beneath `driver/Directory.Build.props` so the pinned NuGet WDK imports are discovered by MSBuild.

The workflow hard-fails unless evaluated properties match these values. The initial workflow stage is build-only; it does not sign, install, create a ROOT device, or load a driver. Runtime testing is a separate gated step and must not be inferred from a successful build.

## INF topology

The INF uses the Microsoft sample's MEDIA class and `ROOT\AudioCodec` hardware ID, with a unique service name `AcxAudioCodecProbe`. The test runner must be disposable and cleanup must run in `finally` if a later runtime stage is added.

## Interpretation

- DriverEntry + successful WDF and ACX initialization: continue by comparing bind metadata against the LDAC SYS from CI #248.
- Failure before DriverEntry with captured ACX 1.0 runtime and exact WDK provenance: investigate the ACX 1.0 stub/runtime contract; do not claim proof from a build-only run.
- Any run lacking runtime PnP/load evidence is build-only.
