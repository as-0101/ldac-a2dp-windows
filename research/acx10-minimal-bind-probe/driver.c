#include <ntddk.h>
#include <wdf.h>
#include <acx.h>
DRIVER_INITIALIZE DriverEntry;
EVT_WDF_DRIVER_DEVICE_ADD AcxBindProbeEvtDeviceAdd;
_Use_decl_annotations_
NTSTATUS AcxBindProbeEvtDeviceAdd(WDFDRIVER Driver, PWDFDEVICE_INIT DeviceInit) {
 UNREFERENCED_PARAMETER(Driver); UNREFERENCED_PARAMETER(DeviceInit);
 DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_INFO_LEVEL, "AcxBindProbe: EvtDeviceAdd reached\n");
 return STATUS_NOT_SUPPORTED;
}
_Use_decl_annotations_
NTSTATUS DriverEntry(PDRIVER_OBJECT DriverObject, PUNICODE_STRING RegistryPath) {
 WDF_DRIVER_CONFIG wdfConfig; WDFDRIVER wdfDriver = WDF_NO_HANDLE; ACX_DRIVER_CONFIG acxConfig; NTSTATUS status;
 DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_INFO_LEVEL, "AcxBindProbe: DriverEntry reached\n");
 WDF_DRIVER_CONFIG_INIT(&wdfConfig, AcxBindProbeEvtDeviceAdd);
 status = WdfDriverCreate(DriverObject, RegistryPath, WDF_NO_OBJECT_ATTRIBUTES, &wdfConfig, &wdfDriver);
 DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_INFO_LEVEL, "AcxBindProbe: WdfDriverCreate=0x%08X\n", status);
 if (!NT_SUCCESS(status)) return status;
 ACX_DRIVER_CONFIG_INIT(&acxConfig);
 status = AcxDriverInitialize(wdfDriver, &acxConfig);
 DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_INFO_LEVEL, "AcxBindProbe: AcxDriverInitialize=0x%08X\n", status);
 return status;
}
