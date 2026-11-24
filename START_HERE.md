> **ACTIVE PROJECT OVERRIDE — 2026-11-24 07:22 Europe/Kyiv**
>
> Primary target remains the Microsoft Win10 A2DP source/common package for SBC stereo on Server 2022. No new Bluetooth/ACX driver; CI #248/#255 remain closed.
> - CI #463 confirms the A2DP source/common/sink and BtaMPM packages are `dualModeDriver` entries owned by `Microsoft-Windows-Client-Desktop-Required-Package`; Server KB5126655 has no corresponding package references. Do not inject the whole client CBS package.
> - For PC → OPPO playback, only `microsoft_bluetooth_a2dp_src.inf` + common INF + BtaMPM/KS/WDMAUDIO/MSSysFx dependencies are in scope. Exclude the reverse-direction sink INF and HFP.
> - UUP audit #4/#5 failed on the parser's `hint=None` edge case; isolated experiment commit [6778022](https://github.com/as-0101/ldac-a2dp-windows/commit/6778022b4453857e53acf8a18afe54bb7e46f5f5) fixed it. CI #6 passed regression tests; full image audit is still in progress.
> - Existing LDAC-capable alternatives were checked from official/public docs: Alternative A2DP Driver 1.8.3 supports Windows 10 22H2 / Windows 11 21H2–25H2, uses the inbox Bluetooth stack and replaces the per-device A2DP driver; Server 2022 is not listed. It supports LDAC/SBC and ABR but is proprietary, hardware-bound licensed, requires admin for driver selection, and its EULA prohibits reverse engineering/disassembly and redistribution. Treat as a black-box later-stage candidate only; no installer/binary was downloaded or installed. BlueCaster is a user-mode BTstack + WinUSB option for Windows 10 22H2/11, requires a dedicated USB adapter (Windows loses that adapter while active), and bundled BTstack is personal/non-commercial unless separately licensed.
> - The fork already statically links AOSP libldac 2.0.2; this is encoder code, not a Microsoft A2DP plug-in. OPPO Enco Buds2 supports SBC/AAC, not LDAC.
> - `server-2022-oppo` remains unchanged; physical Server 2022 was not queried or modified.
>
# LDAC A2DP — project entry

## Current priority — 2026-11-24

The active path is exact Windows 10 / Server 2022 component extraction and static compatibility analysis. Do not return to ACX/WDK bind-probe work.

- CI #463 completed package discovery: Windows 10 A2DP SYS entries in cumulative-update CABs are PSF forward-delta payloads, not full PE files.
- The Server 2022 KB5126655 package contains Bluetooth core packages but no A2DP INF/SYS or BtaMPM references.
- Winbindex symbol-server retrieval is not exact for the captured files: same timestamp/size collisions returned different file versions and SHA-256 values.
- UUP audit #3 failed before image mount because the DISM object lacked a `Version` property. This was a harness failure, not a binary or OS failure. Corrected offline-hive verification is under test in runs #4/#5 (`45325486392`, `45325586394`).
- The key INF delta is now explicit: keep Server BthPort/BthEnum/radio core; evaluate only the existing Win10 A2DP source/common INF + BthA2dp package after exact PE/CAT checks. No INF has been staged or installed.
- No SBC negotiation, A2DP endpoint, or actual audio success is claimed yet. No physical server actions have been taken.

See WIN10_UUP_IMAGE_AUDIT.md for evidence, run IDs, hashes, and acceptance criteria.


## Current priority — 2026-11-24

The active path is exact Windows 10 / Server 2022 component extraction and static compatibility analysis. Do not return to ACX/WDK bind-probe work.

- CI #463 completed package discovery: Windows 10 A2DP SYS entries in cumulative-update CABs are PSF forward-delta payloads, not full PE files.
- The Server 2022 KB5126655 package contains Bluetooth core packages but no A2DP INF/SYS or BtaMPM references.
- Winbindex symbol-server retrieval is not exact for the captured files: same timestamp/size collisions returned different file versions and SHA-256 values.
- UUP audit #3 failed before image mount because the DISM object lacked a `Version` property. This was a harness failure, not a binary or OS failure. Corrected offline-hive verification is under test in runs #4/#5 (`45325486392`, `45325586394`).
- The key INF delta is now explicit: keep Server BthPort/BthEnum/radio core; evaluate only the existing Win10 A2DP source/common INF + BthA2dp package after exact PE/CAT checks. No INF has been staged or installed.
- No SBC negotiation, A2DP endpoint, or actual audio success is claimed yet. No physical server actions have been taken.

See WIN10_UUP_IMAGE_AUDIT.md for evidence, run IDs, hashes, and acceptance criteria.


**Code branch:** [server-2022-oppo](https://github.com/as-0101/ldac-a2dp-windows/tree/server-2022-oppo)  
**Documentation branch:** [docs/project-source-reorg](https://github.com/as-0101/ldac-a2dp-windows/tree/docs/project-source-reorg)  
**Current direction:** 2026-11-24 02:19 Europe/Kyiv

The next engineering milestone is **SBC stereo on Windows Server 2022**, using the existing Windows 10 inbox A2DP package if its component ownership and kernel dependencies prove compatible. The ACX/WDK bind-probe path is parked.

Important codec boundary:
- Windows 10 inbox A2DP documents SBC and aptX Classic, not LDAC.
- OPPO Enco Buds2 ETE41 documents AAC/SBC only. SBC is the only common codec; these earbuds cannot be the LDAC test sink.
- Alternative A2DP Driver advertises LDAC but is proprietary, hardware-licensed, and not published as Server 2022-supported. Do not transplant or reverse-engineer its binaries.

The 2026-11-23 23:49 Win10 package archive already exists and includes the common/source/sink A2DP INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys. Do not rerun the exporter or ask for the same archive. The latest recorded OPPO A2DP node was enumerated on the local Intel radio (LOCALMFG&0002) but bound to the project's custom oem75.inf / LdacA2dp driver, which failed to start with Code 37; that does not test the Microsoft Win10 package. The remaining package-ownership blocker is the original Windows 10/Server 2022 WIM component metadata.
## Critical component boundary — 2026-11-24 02:19

- Windows 10 inbox A2DP provides SBC and aptX Classic, not LDAC. There is no Microsoft inbox LDAC DLL to transplant.
- `BthA2dp.sys` is the kernel A2DP/AVDTP profile driver; `BtaMPM.sys` is profile management. MSSysFx/APO DLLs are effects, not LDAC codecs.
- The repo already contains AOSP `libldac` at `eeee1a3f`, compiled as static libraries into the custom service; it is not a Windows 10 codec DLL.
- OPPO ETE41 is AAC/SBC only; SBC is the common milestone codec. LDAC requires another sink.
- The legacy PE import report is invalid because its parser never advances to the next 20-byte import descriptor. See E-139.
- Winbindex's x64 hash-only index now confirms the exact SHA-256 values for the 282,624-byte DriverStore BthA2dp.sys, the separate 279,040-byte System32 copy, and BtaMPM.sys. This confirms hash presence in the Microsoft public-symbol index, but does not supply PE timestamp/virtual size, OS/update mapping or catalog membership; see E-143–E-145.
- BlueCaster v3.0.4 is a possible separate user-mode LDAC transport, but it requires WinUSB on a USB adapter, does not list Server 2022 support, and carries BTstack's personal/non-commercial license. It is not a drop-in codec DLL.


## Read in this order

1. [LDAC_Project_Source_START_HERE.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/LDAC_Project_Source_START_HERE.md)
2. [WIN10_COMPONENT_AUDIT.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_COMPONENT_AUDIT.md)
3. [WIN10_A2DP_PIPELINE.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_A2DP_PIPELINE.md)
4. [WIN10_UUP_IMAGE_AUDIT.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_UUP_IMAGE_AUDIT.md)
5. [NEXT_ACTIONS.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/NEXT_ACTIONS.md)
6. PROJECT_STATE.md, EVIDENCE.md, DECISIONS_AND_EXPERIMENTS.md, BUILD_REGISTRY.md, TEST_MATRIX.md and ARTIFACT_INDEX.md.

## Safety

Physical Server 2022 is read-only during this investigation. No driver install, device restart, BCD/security/test-signing or certificate changes, OS update/rollback, or execution of prepare/upgrade/install/rollback scripts is authorized. HFP/microphone remains out of scope. Notion journal remains append-only.
