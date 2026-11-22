# Minimal ACX 1.0 bind probe

Disposable CI-only experiment. Derived from the Microsoft AudioCodec sample's DriverEntry ordering, reduced to WDF driver creation followed by ACX initialization. It intentionally does not create an ACX device, circuit, endpoint, or Bluetooth device.

Build target: WDK/SDK 10.0.26100.6584, x64, KMDF 1.31, ACX 1.0. INF uses a root-enumerated MEDIA device. The callback logs if PnP reaches EvtDeviceAdd and returns STATUS_NOT_SUPPORTED because topology is outside this probe.

Success discriminator: DriverEntry debug message, then logged WdfDriverCreate and AcxDriverInitialize statuses. Failure before DriverEntry remains evidence of loader/class binding incompatibility. This is not a production driver and must never be installed on the physical server.

Microsoft source: https://github.com/microsoft/Windows-driver-samples/tree/main/audio/Acx/Samples/AudioCodec/Driver
