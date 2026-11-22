#include <ntddk.h>
#include <wdf.h>
#include <acx.h>

DRIVER_INITIALIZE DriverEntry;
EVT_WDF_DRIVER_DEVICE_ADD AcxAudioCodecProbeEvtDeviceAdd;
EVT_WDF_DRIVER_UNLOAD AcxAudioCodecProbeEvtDriverUnload;

_Use_decl_annotations_
NTSTATUS
AcxAudioCodecProbeEvtDeviceAdd(
    WDFDRIVER Driver,
    PWDFDEVICE_INIT DeviceInit
)
{
    UNREFERENCED_PARAMETER(Driver);
    UNREFERENCED_PARAMETER(DeviceInit);

    DbgPrintEx(
        DPFLTR_IHVDRIVER_ID,
        DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: EvtDeviceAdd reached; returning STATUS_NOT_SUPPORTED\n"
    );

    // Device/circuit/endpoint creation is deliberately outside this bind probe.
    return STATUS_NOT_SUPPORTED;
}

_Use_decl_annotations_
VOID
AcxAudioCodecProbeEvtDriverUnload(
    WDFDRIVER Driver
)
{
    UNREFERENCED_PARAMETER(Driver);

    DbgPrintEx(
        DPFLTR_IHVDRIVER_ID,
        DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: EvtDriverUnload reached\n"
    );
}

_Use_decl_annotations_
NTSTATUS
DriverEntry(
    PDRIVER_OBJECT DriverObject,
    PUNICODE_STRING RegistryPath
)
{
    WDF_DRIVER_CONFIG wdfConfig;
    WDF_OBJECT_ATTRIBUTES attributes;
    WDFDRIVER wdfDriver = WDF_NO_HANDLE;
    ACX_DRIVER_CONFIG acxConfig;
    NTSTATUS status;

    DbgPrintEx(
        DPFLTR_IHVDRIVER_ID,
        DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: DriverEntry reached\n"
    );

    // Preserve the official Microsoft AudioCodec sample's WDF setup pattern.
    WDF_OBJECT_ATTRIBUTES_INIT(&attributes);
    WDF_DRIVER_CONFIG_INIT(&wdfConfig, AcxAudioCodecProbeEvtDeviceAdd);
    wdfConfig.EvtDriverUnload = AcxAudioCodecProbeEvtDriverUnload;

    status = WdfDriverCreate(
        DriverObject,
        RegistryPath,
        &attributes,
        &wdfConfig,
        &wdfDriver
    );

    DbgPrintEx(
        DPFLTR_IHVDRIVER_ID,
        DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: WdfDriverCreate=0x%08X\n",
        status
    );

    if (!NT_SUCCESS(status))
    {
        return status;
    }

    ACX_DRIVER_CONFIG_INIT(&acxConfig);
    status = AcxDriverInitialize(wdfDriver, &acxConfig);

    DbgPrintEx(
        DPFLTR_IHVDRIVER_ID,
        DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: AcxDriverInitialize=0x%08X\n",
        status
    );

    return status;
}
