# Server 2022 Bluetooth deployment audit

On hosted Windows Server 2022 Datacenter build 20348.5870, the installed Microsoft-OneCore-Bluetooth-Deployment manifest (20348.5866) uses DCM/PA30. The [first decoder run](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45510432442) failed while printing Unicode on Windows. With Python UTF-8 enabled, the [repeat](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45510564303) decoded the manifest with the dictionary from local wcp.dll 20348.5859 and verified the assembly identity.

The [child manifest run](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45510701533) resolved all ten direct dependencies and inspected fifteen matching manifest files, including variants. No file declared in those manifests matched A2DP or BtaMPM. BthRadioMedia.dll is present in a direct child. The checks cover direct child file declarations in this installed build. They do not cover grandchildren, binary internals, or the separate Server 2022 Languages and Optional Features ISO. No donor package was installed and no hardware or physical host was accessed.

## Log evidence

```text
DECODED amd64_microsoft-onecore-bluetooth-deployment_31bf3856ad364e35_10.0.20348.5866_none_579489505d67c34f.manifest wcp=10.0.20348.5859
CHILD Microsoft-OneCore-Bluetooth-BthServ files=bthserv.dll profile=0
CHILD Microsoft-OneCore-Bluetooth-Proxy files=Microsoft.Bluetooth.Proxy.dll profile=0
CHILD Microsoft-OneCore-Bluetooth-Proxy files=Microsoft.Bluetooth.Proxy.dll profile=0
CHILD Microsoft-OneCore-Bluetooth-Proxy-Marshalers files= profile=0
CHILD Microsoft-OneCore-Bluetooth-Proxy-Marshalers files= profile=0
CHILD Microsoft-OneCore-Bluetooth-Service files=Microsoft.Bluetooth.Service.dll profile=0
CHILD Microsoft-OneCore-Bluetooth-UserApis files=wshbth.dll,BluetoothApis.dll profile=0
CHILD Microsoft-OneCore-Bluetooth-UserApis files=wshbth.dll,BluetoothApis.dll profile=0
CHILD Microsoft-Windows-Bluetooth-Capabilities files= profile=0
CHILD Microsoft-Windows-Bluetooth-RFCOMM-Registration files= profile=0
CHILD Microsoft-Windows-CoreSystem-Bluetooth-DAFProvider files=dafBth.dll profile=0
CHILD Microsoft-Windows-CoreSystem-Bluetooth-RadioMediaProvider files=BthRadioMedia.dll profile=0
CHILD Microsoft-Windows-CoreSystem-Bluetooth-RadioMediaProvider files=BthRadioMedia.dll profile=0
CHILD Microsoft-Windows-CoreSystem-Bluetooth-Telemetry files=BthTelemetry.dll profile=0
CHILD Microsoft-Windows-CoreSystem-Bluetooth-Telemetry files=BthTelemetry.dll profile=0
COVERAGE dependencies=10 manifests=15 unresolved=0 profile_files=0
```
