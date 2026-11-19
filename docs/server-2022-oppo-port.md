# Windows Server 2022 / OPPO Enco Buds2 port

## Goal

Enable stereo A2DP playback from Windows Server 2022 Datacenter (build 20348) to OPPO Enco Buds2. The first supported codec is SBC. Microphone/HFP, LDAC tuning, AVRCP buttons and absolute volume are out of scope until reliable playback works.

## Safety rules

- Do not install or test an unsigned/test-signed kernel driver on the production Server 2022 host.
- Do not replace, copy over, or patch inbox Bluetooth components (BTHUSB, BTHPORT, BTHENUM, bth.inf).
- Do not bind a broad A2DP compatible ID without a device-specific safety check.
- Test first in a disposable VM with a USB Bluetooth adapter passed through and a snapshot.
- Keep the upstream repository and its main branch unchanged. All adaptation work belongs on branch `server-2022-oppo`.

## Confirmed target-system findings

- OS: Windows Server 2022 Datacenter, Desktop Experience, build 20348 x64.
- Bluetooth radio: Intel Wireless Bluetooth, USB VID_8087 / PID_0032, driver 23.50.0.2.
- Keyboard and mouse already work over Bluetooth.
- OPPO Enco Buds2 pairs, but Windows fails when asked to connect the audio service; no audio endpoint appears.
- The OPPO A2DP service node (UUID 110B) and Hands-Free node (UUID 111E) are enumerated by BthEnum, but their Service field is empty and the selected inbox INF is bth.inf / BthGenericService (null service).
- The OPPO A2DP instance observed on this host:
  `BTHENUM\\{0000110B-0000-1000-8000-00805F9B34FB}_LOCALMFG&0002\\7&384EA00A&0&840F2A13E3E2_C00000000`
- The observed remote Bluetooth address encoded in that instance is `84:0F:2A:13:E3:E2`.
- The captured Hardware ID has `_LOCALMFG&0002` but no `_VID&..._PID&...` suffix. Therefore the current Windows enumeration did not expose a remote-specific Device ID pair for this OPPO instance.
- Important ID clarification from Microsoft's Bluetooth PnP documentation: `_LOCALMFG&0002` identifies the **local Bluetooth radio manufacturer**, not OPPO. It is therefore not a unique OPPO identifier and must not be treated as one.
- The host has `Acx01000.sys`, version 10.0.20348.3451, and `portcls.sys`, version 10.0.20348.5756. These file versions are useful evidence, but runtime DDI availability still needs verification.

## Source-project findings

- Upstream project: https://github.com/yariktop133/ldac-a2dp-windows
- License: Apache-2.0 (verify all notices remain with redistributed source).
- The project contains a KMDF driver using BthPort BRBs for L2CAP, an AVDTP/A2DP source implementation, an ACX render endpoint, and a user-mode encoder service.
- Existing driver INF currently contains hardware IDs for JBL Live 780NC only:
  - A2DP: `BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}_VID&000102b0_PID&0000`
  - AVRCP and AVRCP target IDs for the same JBL identity.
- Therefore the current INF does not match the OPPO node observed on the Server 2022 host. Do not install the unmodified package expecting it to bind to OPPO.
- Upstream README documents actual operation with JBL Live 780NC on Windows 11, not Server 2022. Its test procedure uses test signing and Secure Boot changes on a test machine. That is not approval to apply those settings to the production host.
- The upstream project requests KMDF 1.31 and ACX 1.1. Microsoft's version tables list KMDF 1.31 as supported on Windows 10 2004 and later, and Windows Server 2022 includes KMDF 1.33. Microsoft's ACX version overview lists ACX 1.1 with minimum KMDF 1.31 and Windows 10 2004 support. This makes the framework versions plausible for Server 2022; it is not yet proof that every DDI and the complete driver work on build 20348.
- The upstream GitHub Actions run inspected during this porting review successfully built the KMDF driver, protocol/service tests and settings utility. This verifies the upstream CI build, not OPPO compatibility or Server 2022 runtime operation.

## Porting work plan

1. **Compatibility audit**
   - KMDF 1.31 / ACX 1.1 are no longer presumed blockers: Microsoft documents KMDF 1.31 on Windows 10 2004 and later, Server 2022 includes KMDF 1.33, and ACX 1.1 has a documented Windows 10 2004 baseline with KMDF 1.31.
   - Still verify each ACX DDI used by `driver/LdacA2dp/audio.c` and the BthPort/BthEnum interfaces on build 20348.
   - Fix the driver's INF target decoration: upstream currently declares `NT$ARCH$.10.0...22621`, while Server 2022 is build 20348. Create a Server 2022-compatible model section only after confirming all required APIs are available; do not merely lower the INF number to force installation.
2. **OPPO device matching — currently the main blocker**
   - Microsoft's Bluetooth PnP rules are explicit: `_LOCALMFG&nnnn` identifies the local Bluetooth radio manufacturer, not the remote headset. A `VID/PID` pair is generated only when the remote device publishes a Device ID through SDP.
   - The captured OPPO A2DP Hardware ID contains `_LOCALMFG&0002` but no remote `_VID&..._PID&...` pair. The current evidence therefore does not give the INF a unique OPPO hardware ID.
   - Adding `_LOCALMFG&0002` to the INF would match A2DP services on that local Intel radio, not only OPPO. It could take over audio for other paired headsets. **Do not put this broad match in a production package.**
   - There is a useful next diagnostic: Microsoft documents `IOCTL_INTERNAL_BTHENUM_GET_ENUMINFO`, whose `BTH_ENUMERATOR_INFO` contains `Vid`, `Pid`, `Mfg`, `LocalMfg`, and `VidType`. `Vid`/`Pid`/`Mfg` are remote values obtained from SDP; `LocalMfg` is the local radio. We should query this from the profile driver's own device stack and record the result before deciding whether the OPPO publishes a usable Device ID. This query is documented for profile drivers and does not require changing BthPort or BthEnum.
   - If remote `Vid`/`Pid` are nonzero, compare them with the PnP IDs and determine whether they can provide a specific INF match. If they are zero, no unique remote VID/PID has been exposed by SDP.
   - If no remote-specific PnP ID is available, the safest first hardware test is an isolated VM with a dedicated passed-through Bluetooth adapter and only the OPPO sink paired. A production installation remains blocked until we have a safe selection strategy.
3. **Minimal A2DP path**
   - Disable/omit AVRCP and HFP initially.
   - Negotiate SBC only, open AVDTP signaling and media L2CAP channels, and stream test audio.
   - Confirm disconnect/reconnect and clean removal.
4. **Build and package**
   - Build with a WDK/toolset compatible with the target OS.
   - Generate a package with a clear install and rollback path.
   - Keep test signing confined to the disposable test VM.
5. **Acceptance**
   - OPPO appears as a Windows stereo playback device.
   - A known test WAV plays continuously without dropouts.
   - Pairing/connecting/disconnecting works repeatedly.
   - Other Bluetooth peripherals and unrelated A2DP sinks remain unaffected.
   - Uninstall restores the inbox driver selection for the OPPO devnode.


### Framework and INF targeting review (2026-11-19)

- The project currently requests KMDF 1.31 and ACX 1.1. Microsoft documents ACX 1.1 as the public ACX release with a minimum KMDF 1.31; the ACX 1.1 DDI list includes a finite set of newer APIs. The KMDF version-history table explicitly lists KMDF 1.33 in Windows Server 2022 and says drivers using it run on Server 2022. This makes the KMDF requirement plausible on build 20348; it does **not** by itself prove that every ACX DDI used by this driver is exported/available in the Server 2022 ACX runtime.
- The target machine has `Acx01000.sys` version `10.0.20348.3451` (captured previously). File presence/version alone does not establish the ACX runtime DDI set. Before any load test, compare the imported ACX symbols used by the driver against the target runtime or use a debugger/runtime load test in a disposable VM.
- The INF still has only a Windows build 22621+ target decoration. It will not select Server 2022 build 20348 as currently written. Once a safe OPPO-specific ID is established, prepare a separate 20348-targeted INF section and validate it with InfVerif/Inf2Cat. Do not simply lower the minimum build while the hardware ID still matches only JBL.
- GitHub Actions currently reports zero workflow runs for the PR head and zero repository workflow runs. Therefore no compile/test result is available yet; the source changes remain uncompiled. Added a `workflow_dispatch` trigger so the build can also be started manually once Actions are enabled for this fork.

## Current status

- [x] User-created fork confirmed: `as-0101/ldac-a2dp-windows`.
- [x] Dedicated adaptation branch created: `server-2022-oppo`.
- [x] Initial source/INF review completed.
- [x] Initial KMDF/ACX version comparison against Microsoft documentation.
- [ ] Compare ACX imports against the Server 2022 runtime and verify BthPort DDIs on build 20348.
- [ ] Create and validate a separate INF target decoration for build 20348, only after safe remote identity matching is established.
- [ ] Correct and validate the INF target OS decoration for Server 2022.
- [x] Clarified Bluetooth `_LOCALMFG` ID semantics from Microsoft documentation.
- [x] Added a non-fatal `IOCTL_INTERNAL_BTHENUM_GET_ENUMINFO` query and exposed remote SDP identity in the service status output (source changes only; not yet built or run).
- [ ] OPPO SDP and device identity capture / determine whether a remote-specific VID/PID exists.
- [ ] Safe OPPO-specific driver installation strategy.
- [x] Enable GitHub Actions for the fork (confirmed by user on 2026-11-19).
- [ ] Trigger the first CI run after Actions were enabled and obtain a real build result.
- [ ] SBC-only playback in isolated test VM.
- [ ] Verified install/rollback package for the target host.

## Important distinction

A successful CI build is not a working driver on Server 2022. The finish line is verified stereo playback through OPPO Enco Buds2 on the target OS, with a safe rollback path. The current broad-ID route is not safe for production because it could replace the audio driver for other Bluetooth headsets on the same Intel radio. The new SDP identity diagnostic is source-complete but has not yet been compiled or run on hardware.


### CI activation note (2026-11-19)

- The repository Actions page showed zero workflow runs after Actions were enabled. The branch contains a `push` / `pull_request` workflow and the PR is open; the default branch also contains the build workflow.
- The next safe trigger is a documentation-only commit on `server-2022-oppo`, which will generate a fresh push / pull-request synchronization event. This does not modify `main` or install/run a driver on any machine.
- No CI result is claimed until the run actually appears and completes.


## Runtime compatibility diagnostics added (2026-11-19)

- `driver.c`: after `AcxDriverInitialize`, calls `AcxDriverIsVersionAvailable` for ACX 1.1. If unavailable, DriverEntry returns `STATUS_REVISION_MISMATCH`; it logs the result. This proves runtime ACX version availability only, not that every imported DDI or the complete audio circuit works on Server 2022.
- `driver.c`: after `WdfFdoQueryForInterface`, validates that `BthInitializeBrb` is present and logs interface-query success/failure.
- `l2cap.c`: logs results of `IOCTL_INTERNAL_BTHENUM_GET_DEVINFO`, optional `GET_ENUMINFO`, and `BRB_HCI_GET_LOCAL_BD_ADDR`, including SDP identity fields when available.

These diagnostics do not install the driver and do not change inbox Bluetooth components. They must be built and reviewed before any test. The next gate is CI compilation; after that, runtime evidence must come from a disposable Server 2022 VM with a dedicated USB Bluetooth adapter. No production-host installation is authorized.


## Safer OPPO identity discovery before driver binding

Do not use a generic A2DP hardware ID to load the custom kernel driver on the production host. The current upstream INF still targets Windows build 22621+ and a JBL-specific VID/PID; it does not target Server 2022 build 20348 or OPPO Enco Buds2.

A safer next experiment is a standalone user-mode SDP probe using the documented Winsock Bluetooth namespace APIs (`WSALookupServiceBegin`, `WSALookupServiceNext`, `WSALookupServiceEnd`) with `NS_BTH`, the known remote Bluetooth address, `LUP_FLUSHCACHE`, and `LUP_RETURN_BLOB`. Microsoft's advanced-query path supports `BTH_QUERY_SERVICE` and returning raw SDP records. Query the Bluetooth Device ID service (UUID 0x1200) and parse its Device ID attributes (vendor ID, product ID, vendor ID source, version). This path should be validated on the Server 2022 host before attempting any kernel driver installation; it does not require binding a custom driver to the headphones.

References:
- https://learn.microsoft.com/en-us/windows/win32/bluetooth/bluetooth-and-wsalookupservicebegin-for-service-discovery
- https://learn.microsoft.com/en-us/windows/desktop/api/Ws2bth/ns-ws2bth-bth_query_service
- https://learn.microsoft.com/en-us/windows/win32/api/bluetoothapis/nf-bluetoothapis-bluetoothsdpgetattributevalue

This is a proposed diagnostic path, not yet implemented or verified against OPPO. If the Device ID SDP record is absent, we must use a separate safe discovery route rather than guessing VID/PID or widening the INF match.


## User-mode Device ID SDP probe implemented (2026-11-19)

Added `tools/stand/sdp-probe.cpp` and `tools/stand/build-sdp-probe.cmd`. The probe uses Winsock Bluetooth service discovery (`WSALookupServiceBegin/Next/End`) with the Device ID service UUID 0x1200, forces an over-the-air query with `LUP_FLUSHCACHE`, requests the raw SDP record with `LUP_RETURN_BLOB`, and reads standard Device ID attributes 0x0201 (Vendor ID), 0x0202 (Product ID), 0x0203 (Version), and 0x0205 (Vendor ID source) using `BluetoothSdpGetAttributeValue`.

Default peer address is the previously observed OPPO address `84:0F:2A:13:E3:E2`; an alternate address can be passed as the first command-line argument. This is user-mode only and does not install or bind a kernel driver. The build workflow now compiles this probe in the Settings utility job.

Limitations: the tool has not yet been run against the actual OPPO earbuds. Some devices may omit the Device ID SDP service or individual attributes; absence is inconclusive and must not be converted into a guessed VID/PID or a broad INF match. SDP values are remote-reported identity data and must be cross-checked before generating a device-specific INF.


## Actual OPPO SDP and PnP results (2026-11-19) — supersedes earlier pending identity checks

The standalone probe was built and run against OPPO Enco Buds2 at Bluetooth address 84:0F:2A:13:E3:E2.

- The first Device ID-only query (service UUID 0x1200) returned no record. This is inconclusive: it does not prove the headset has no vendor/product identity.
- The expanded L2CAP service enumeration returned five SDP service records:
  - 0x110B: Audio Sink (A2DP Sink).
  - 0x110E: Advanced Audio / AVRCP Controller role.
  - 0x110C: AVRCP Target.
  - 0x111E: Hands-Free.
  - 0000079A-D102-11E1-9B23-00025B00A5A5: vendor-specific oppointeraction.
- No standard Device ID attributes 0x0201, 0x0202, 0x0203, 0x0205 were found in these returned service records. The remote Device ID SDP service remains absent from the observed result.
- Device Manager / PowerShell enumeration showed six devnodes in one ContainerId {FB1FD640-FDAD-5D08-83ED-59D48F60EA5A}: the physical OPPO device node plus the five profile service nodes. Earlier prose referring to seven nodes was a counting error.
- The screenshot with Device Manager properties open for Advanced Audio displayed compatible IDs containing UUID 0x110E; that is not the A2DP Audio Sink node. The relevant A2DP node is UUID 0x110B, shown in PowerShell as Служба приемника аудио.
- For the actual A2DP node (UUID 0x110B), Windows reports:
  - INF: bth.inf
  - Provider: Microsoft
  - Driver description: Audio Sink Service
  - Driver version: 10.0.20348.5756
  - Matching ID: BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}_GENERIC
  - Hardware ID: BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}_LOCALMFG&0002
  - Compatible IDs: generic A2DP service UUID and its _GENERIC form.
  - Parent: BTH\\MS_BTHBRB\\6&10f06c5d&3&1
  - Instance ID includes remote MAC suffix 840F2A13E3E2, but Hardware ID and Compatible IDs do not.
- The other A2DP-profile nodes likewise use _LOCALMFG&0002; this is local-radio manufacturer data and is shared across peers on this radio, not an OPPO-specific selector.

## Driver-selection implications and next safe design gate

- Windows INF Models entries match device Hardware IDs and Compatible IDs; they do not match an arbitrary per-instance MAC suffix. Instance IDs uniquely distinguish devnodes, but they are a separate identifier family from the IDs used for INF package matching. See Microsoft's Device Identification Strings and INF Models documentation.
- Therefore adding the generic A2DP Compatible ID or _LOCALMFG&0002 to the current function-driver INF would make the package eligible for every matching A2DP devnode on the Intel radio, not just OPPO. This is prohibited for production.
- The current fork's INF still names JBL-specific remote VID/PID IDs and has a Windows 10.0.22621+ target decoration. It does not currently match OPPO and does not yet target Server 2022 build 20348.
- The current driver's DetectRole identifies only the Bluetooth service UUID from the Hardware ID. It does not perform an OPPO MAC-address check at EvtDeviceAdd. L2capQueryAddresses retrieves the remote address later, after the function driver has already been selected and its device object created. Consequently that later address-filtered L2CAP setup is not a safe substitute for PnP driver selection.
- Microsoft documents the SetupAPI workflow for selecting a driver for a specific device instance using SetupDiOpenDeviceInfo, building the compatible-driver list, selecting a particular driver node, and installing it with DiInstallDevice (the older InstallSelectedDriver API is deprecated). This is a possible manual per-devnode test mechanism, not yet a production-safe deployment design: a staged INF with generic A2DP IDs may still be considered for other devices during later PnP matching. Driver ranking and re-enumeration behavior must be tested in a disposable VM before drawing a safety conclusion.
- Next work must stay in source/VM validation. Do not widen the INF on the production host; do not install the unsigned artifact; do not enable test-signing or change Secure Boot on the production host.
- A viable design must demonstrate both: (1) only the exact OPPO A2DP devnode is selected for the custom function driver; and (2) other A2DP devices continue to select their existing inbox driver after reboot, radio restart, and device re-enumeration. If this cannot be shown, investigate an alternative architecture (for example, a per-instance filter or a user-mode Bluetooth transport plus a separately scoped virtual audio endpoint) instead of using a broad function-driver match.

References:
- https://learn.microsoft.com/en-us/windows-hardware/drivers/install/device-identification-strings
- https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-models-section
- https://learn.microsoft.com/en-us/windows-hardware/drivers/install/installselecteddriver

## Updated evidence status (2026-11-19)

- [x] SDP L2CAP service enumeration executed on the actual OPPO headset.
- [x] Confirmed A2DP Sink service UUID 0x110B and other profile UUIDs.
- [x] Confirmed no Device ID attributes in returned SDP records.
- [x] Confirmed actual A2DP devnode currently binds to inbox bth.inf through the generic A2DP compatible ID.
- [x] Confirmed the MAC address is present in the A2DP Instance ID but not in Hardware IDs / Compatible IDs.
- [ ] Design and test a safe per-instance selection/driver-binding strategy in a disposable Server 2022 VM.
- [ ] Verify whether the Server 2022 runtime supports every ACX/BthPort DDI used.
- [ ] SBC-only playback test in isolated VM.
- [ ] Production installation package with signed driver and documented rollback.
