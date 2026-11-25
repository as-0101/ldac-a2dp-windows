# HFP microphone on Windows Server 2022 — 2026-11-25

On hosted Datacenter 20348.5870, the inventory found no files or package names matching the Windows 10 HFP profile family or the candidate HFP components in five inspected directories. The BthHfEnum, BthHfAud, BthHFSrv and BTAGService service keys were absent. Bluetooth transport and Windows Audio service definitions were present. The targeted content search covered eight Bluetooth-related DriverStore INFs. The WinSxS check covered manifest filenames.

The server's bth.inf contains the generic Hands-Free service mapping for UUID 0x111E. In the saved physical Server 20348.5761 capture that node appears in class Bluetooth and the CSV contains no BTHHFENUM node. The Win10 19045.6456 capture contains the corresponding MEDIA child. Its SetupAPI excerpt logs successful configuration of Common_BthHfAud_Install, names the BthHFAud service and identifies microsoft_bluetooth_hfp.inf and BthHfAud.sys (log lines 1429–1455). No capture endpoint or microphone stream was exercised on the hosted runner. The physical host was not contacted.

The first inventory used component and service names. The repeated run added the exact INF family found in the client log. Judge any future Server-applicable candidate by presence of the profile INF, binding to the headset, a Windows audio capture endpoint and audio samples. Keep the A2DP staging outcome independent.

- [Retest](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45580831045)
- [First run](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45580784826)

```text
TARGET=20348.5870
INVENTORY path=C:\Windows\INF entries=856 PROFILE_MATCHES=0
INVENTORY path=C:\Windows\System32\drivers entries=437 PROFILE_MATCHES=0
INVENTORY path=C:\Windows\System32 entries=4360 PROFILE_MATCHES=0
INVENTORY path=C:\Windows\System32\DriverStore\FileRepository entries=649 PROFILE_MATCHES=0
INVENTORY path=C:\Windows\WinSxS\Manifests entries=24246 PROFILE_MATCHES=0
SERVICE BthPort present=True type=1 start=3 image=\SystemRoot\System32\drivers\BTHport.sys
SERVICE BthEnum present=True type=1 start=3 image=\SystemRoot\System32\drivers\BthEnum.sys
SERVICE BTHUSB present=True type=1 start=3 image=\SystemRoot\System32\drivers\BTHUSB.sys
SERVICE bthserv present=True type=32 start=3 image=C:\Windows\system32\svchost.exe -k LocalService -p
SERVICE AudioSrv present=True type=16 start=3 image=C:\Windows\System32\svchost.exe -k LocalServiceNetworkRestricted -p
SERVICE AudioEndpointBuilder present=True type=32 start=3 image=C:\Windows\System32\svchost.exe -k LocalSystemNetworkRestricted -p
SERVICE BthHfEnum present=False
SERVICE BthHfAud present=False
SERVICE BthHFSrv present=False
SERVICE BTAGService present=False
SERVICE BthAvctpSvc present=False
SERVICE BthA2dp present=False
SERVICE BtaMPM present=False
GENERIC line=%BTHENUM\{0000111e-0000-1000-8000-00805f9b34fb}%= BthGenericService, BTHENUM\{0000111e-0000-1000-8000-00805f9b34fb}_GENERIC
GENERIC line=HKR,"Parameters\ServiceGroups","MonoAudio", 0x00010000, "{0000111e-0000-1000-8000-00805f9b34fb}", "{00001108-0000-1000-8000-00805f9b34fb}"
GENERIC line=HKR,"Parameters\HciBypassServices", "{0000111E-0000-1000-8000-00805f9b34fb}",0x00010003,1
GENERIC line=BTHENUM\{0000111e-0000-1000-8000-00805F9B34FB}="Handsfree Handsfree Service"
DRIVER_INF inspected=8
```
