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
- The host has `Acx01000.sys`, but file presence alone does not prove that every ACX DDI used by this project is available at runtime.

## Source-project findings

- Upstream project: https://github.com/yariktop133/ldac-a2dp-windows
- License: Apache-2.0 (verify all notices remain with redistributed source).
- The project contains a KMDF driver using BthPort BRBs for L2CAP, an AVDTP/A2DP source implementation, an ACX render endpoint, and a user-mode encoder service.
- Existing driver INF currently contains hardware IDs for JBL Live 780NC only:
  - A2DP: `BTHENUM\\{0000110b-0000-1000-8000-00805f9b34fb}_VID&000102b0_PID&0000`
  - AVRCP and AVRCP target IDs for the same JBL identity.
- Therefore the current INF does not match the OPPO node observed on the Server 2022 host. Do not install the unmodified package expecting it to bind to OPPO.
- Upstream README documents actual operation with JBL Live 780NC on Windows 11, not Server 2022. Its test procedure uses test signing and Secure Boot changes on a test machine. That is not approval to apply those settings to the production host.
- The upstream GitHub Actions run inspected during this porting review successfully built the KMDF driver, protocol/service tests and settings utility. This verifies the upstream CI build, not OPPO compatibility or Server 2022 runtime operation.

## Porting work plan

1. **Compatibility audit**
   - Check every ACX DDI used by `driver/LdacA2dp/audio.c` against the ACX runtime available on Server 2022 build 20348.
   - Check the KMDF/BthPort DDI usage and minimum runtime versions.
   - Establish whether the existing ACX 1.1 endpoint can run on build 20348. If not, choose a supported PortCls/SYSVAD-style render endpoint or another documented fallback; do not guess based only on the presence of Acx01000.sys.
2. **OPPO device matching**
   - Capture the complete Hardware IDs, Compatible IDs, instance ID, SDP service records and remote address from a test system.
   - Design an install strategy that targets the selected OPPO devnode only. If a shared compatible ID is unavoidable, enforce a strict remote-address/device identity check before the driver opens channels; verify unrelated A2DP devices remain on their original driver.
   - Do not assume the `LOCALMFG&0002` suffix uniquely identifies OPPO.
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

## Current status

- [x] User-created fork confirmed: `as-0101/ldac-a2dp-windows`.
- [x] Dedicated adaptation branch created: `server-2022-oppo`.
- [x] Initial source/INF review completed.
- [ ] ACX/KMDF/BthPort compatibility audit for build 20348.
- [ ] OPPO SDP and device identity capture.
- [ ] Safe OPPO-specific driver installation strategy.
- [ ] SBC-only playback in isolated test VM.
- [ ] Verified install/rollback package for the target host.

## Important distinction

A successful CI build is not a working driver on Server 2022. The finish line is verified stereo playback through OPPO Enco Buds2 on the target OS, with a safe rollback path.
