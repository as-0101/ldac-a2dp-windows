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
- [ ] Enable/dispatch GitHub Actions workflow and obtain a real CI build result.
- [ ] SBC-only playback in isolated test VM.
- [ ] Verified install/rollback package for the target host.

## Important distinction

A successful CI build is not a working driver on Server 2022. The finish line is verified stereo playback through OPPO Enco Buds2 on the target OS, with a safe rollback path. The current broad-ID route is not safe for production because it could replace the audio driver for other Bluetooth headsets on the same Intel radio. The new SDP identity diagnostic is source-complete but has not yet been compiled or run on hardware.
