#include <ntddk.h>
#include <wdf.h>
#include <acx.h>

extern "C" DRIVER_INITIALIZE DriverEntry;
EVT_WDF_DRIVER_DEVICE_ADD AcxAudioCodecProbeEvtDeviceAdd;
EVT_WDF_DRIVER_UNLOAD AcxAudioCodecProbeEvtDriverUnload;

_Use_decl_annotations_
VOID AcxAudioCodecProbeEvtDriverUnload(WDFDRIVER Driver)
{
    PAGED_CODE();
    UNREFERENCED_PARAMETER(Driver);
    DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: EvtDriverUnload REACHED\n");
}

_Use_decl_annotations_
NTSTATUS AcxAudioCodecProbeEvtDeviceAdd(WDFDRIVER Driver, PWDFDEVICE_INIT DeviceInit)
{
    UNREFERENCED_PARAMETER(Driver);
    UNREFERENCED_PARAMETER(DeviceInit);
    DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: EvtDeviceAdd REACHED; returning STATUS_NOT_SUPPORTED intentionally\n");
    return STATUS_NOT_SUPPORTED;
}

INIT_CODE_SEG
_Use_decl_annotations_
NTSTATUS DriverEntry(PDRIVER_OBJECT DriverObject, PUNICODE_STRING RegistryPath)
{
    WDF_OBJECT_ATTRIBUTES attributes;
    WDF_DRIVER_CONFIG wdfConfig;
    ACX_DRIVER_CONFIG acxConfig;
    WDFDRIVER wdfDriver = WDF_NO_HANDLE;
    NTSTATUS status;

    PAGED_CODE();
    DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: DriverEntry ENTER\n");

    // Preserve the Microsoft AudioCodec sample's WDF attributes, unload callback,
    // and WDF-before-ACX initialization order.
    WDF_OBJECT_ATTRIBUTES_INIT(&attributes);
    WDF_DRIVER_CONFIG_INIT(&wdfConfig, AcxAudioCodecProbeEvtDeviceAdd);
    wdfConfig.EvtDriverUnload = AcxAudioCodecProbeEvtDriverUnload;

    status = WdfDriverCreate(DriverObject, RegistryPath, &attributes, &wdfConfig, &wdfDriver);
    DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: WdfDriverCreate STATUS=0x%08X\n", status);
    if (!NT_SUCCESS(status)) {
        DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
            "AcxAudioCodecProbe: DriverEntry EXIT after WdfDriverCreate failure STATUS=0x%08X\n", status);
        return status;
    }

    ACX_DRIVER_CONFIG_INIT(&acxConfig);
    DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: AcxDriverInitialize CALL\n");
    status = AcxDriverInitialize(wdfDriver, &acxConfig);
    DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: AcxDriverInitialize STATUS=0x%08X\n", status);
    DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL,
        "AcxAudioCodecProbe: DriverEntry EXIT STATUS=0x%08X\n", status);
    return status;
}
