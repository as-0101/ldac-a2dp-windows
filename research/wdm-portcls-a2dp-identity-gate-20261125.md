# OpenA2DP identity path — static gate (2026-11-25)

**Status:** source inspected; no installation, hardware test, or duplex call. Do not infer that building on a GitHub Windows-2022 runner proves Windows Server 2022 compatibility.

## Pinned code
Upstream: https://github.com/RafiMota/open-a2dp/tree/167ebc0e2c89fec570eec535fefdade72bd9e416 (MIT source; oa2dpaudio portions derived from Microsoft SysVAD MS-PL, retain notices).

- `driver/oa2dp/oa2dp.inf` blob `05a2714cf2f68ee94f86d23ecb5e4a0cee927f9e`: Bluetooth class, install HWID `BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}`, service `oa2dp`, KMDF 1.15; expects A2DP Sink service node.
- `driver/oa2dp/driver.c` blob `66ff210bc9dc95f2cab01383ec8c93ed76a368a0`, lines 150-203: dynamically creates static child PDO, assigns `OA2DP\\Render` to device ID and hardware ID, and assigns 12-hex-digit Bluetooth `RemoteAddress` as instance ID; sets `UniqueID=WdfTrue` and adds child via `WdfFdoAddStaticChild`. This gives a concrete candidate join key for correlating headset and render device (not standalone proof until PnP and address match are measured).
- `driver/oa2dpaudio/oa2dpaudio.inf` blob `dfc66e151f9e029d73fe5a8a7642aeaf43fb10ad`: MEDIA class, `OA2DP\\Render` HWID, `Include=ks.inf,wdmaudio.inf`, `Needs=KS.Registration,WDMAUDIO.Registration`; `KSCATEGORY_RENDER` wave/topology interfaces, no matching HFP capture endpoint.
- `driver/oa2dp/l2cap.c` blob `cc6168a6d9f21af30f3a86de92c7dc23e3c1866a`: BRB L2CAP communication via `IOCTL_INTERNAL_BTH_SUBMIT_BRB` and `BthAllocateBrb` callback.
- `driver/oa2dpaudio/adapter.cpp` blob `659c729353489120f8110dc9aecf8acb544fe67e`: PortCls WaveRT device, `PcRegisterSubdevice` and physical connection management.

## Key conclusion and gates
This two-SYS architecture uses existing Server Bluetooth transport as a potential substrate and does *not* depend on signing Windows 10 inbox A2DP INF; catalog generation / compilation were already verified in external CI [38632901913](https://github.com/RafiMota/open-a2dp/actions/runs/38632901913). **It is still unsigned for unattended protected Server deployment** and no on-device render sample has been collected. HFP capture and Audio Gateway remain independent missing requirements.

Next: statically compare drivers' PE imports and INF version applicability against saved Server 20348 evidence; verify presence of ks.inf/wdmaudio.inf sections and required provider exports on isolated target; then authorized protected signing/deployment if feasible. For identity capture collect `OA2DP\\Render\\<address>`, BTHENUM parent PnP instance, DEVPKEY_Device_ContainerId, matching HFP child and MMDevices render/capture IDs. Shared friendly name alone insufficient. Never change physical Server without separate authorization.
