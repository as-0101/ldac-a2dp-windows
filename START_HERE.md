> **LDAC encoder provenance — 2026-11-24**
>
> The existing project already contains the AOSP Sony LDAC encoder from upstream commit eeee1a3f (imported in repository commit 95bb92866b0d77de20ee94694eb4be2979635947). CMake builds ldacBT_enc and ldacBT_abr as STATIC libraries; service/encoder.cpp calls ldacBT_get_handle, ldacBT_init_handle_encode, ldacBT_encode and ldac_ABR_Proc, then frames output with the project's AVDTP code. There is no prebuilt Windows LDAC DLL in this repository. The vendored METADATA does not declare a semantic version, so do not label it 2.0.2 without separate provenance.
>
> The external libldacdec commit c90094b is fetched by tools/ldacverify only to decode/verify test output; it is not part of the product. Historical hardware proof exists on a separate Windows 11 25H2 VM with Realtek USB Bluetooth 5.4 passthrough and JBL Live 780NC: LDAC 96 kHz / MTU 679 / 150 ms was negotiated, audio was heard, and the recorded run delivered 2,972 packets with zero drops (2026-10-22). This proves the existing codec/custom AVDTP path on that test stand, **not** on Server 2022. Keep the immediate Server milestone on the Microsoft Win10 A2DP SBC package path.
>
> **INF comparison correction — 2026-11-24 08:50 Europe/Kyiv**
>
> The generic BthGenericService mapping for A2DP UUID 0x110B exists in both Win10 and Server bth.inf. It is not the OS delta. Win10 bth.inf 10.0.19041.5848 (SHA-256 8635AE12E1C0AF71E95AD0DA65FA6CEEAB2AA0866D213620F49AA0A634CE976D) and Server bth.inf 10.0.20348.5756 (SHA-256 38302B73607B829CBD94D60D25320924B8727BF55CAD940052444FC22D475459) both map UUID 0x110B to BthGenericService with the _GENERIC suffix and null associated-service install.
>
> The actual Win10 addition is the separate microsoft_bluetooth_a2dp_src.inf (base UUID 0x110B) plus common A2DP INF and BtaMPM dependency. Those dedicated A2DP INF files are absent from the Server image. The minimal experiment must add/test that package only; do not replace or patch bth.inf. Source INF has PreConfigureDriver=*; its SetupAPI selection/rank effect must be checked in the disposable VM.
>
> **ACTIVE OVERRIDE — 2026-11-24 08:39 Europe/Kyiv**
>
> UUP audit #6 completed successfully: [run 45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839), artifact ID 14895876155, SHA-256 c1792bd8e5bcdf2a583c3738eeb22bdf27a64ba6ad2701ad70aa8f879d045209.
> - Exact Win10 19045.5917 x64 image reproduced the archived DriverStore BthA2dp.sys hash: version 10.0.19041.4355, 282,624 bytes, SHA-256 5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3. AMD64/PE32+, WDM driver, 149 imports in 8 descriptors, no delay/API-set imports or exports. All 149 imported names/ordinals are present in the exact Server 20348.5761 export-reference set plus exact Win10 BtaMPM.
> - Exact BtaMPM.sys 10.0.19041.5848, 43,008 bytes, SHA-256 DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD: AMD64, 42 imports, 14 exports, no delay/API-set imports. All 42 imports resolve against Server exports; BthA2dp consumes 10 of its exports.
> - Separate 279,040-byte System32 BthA2dp.sys is version 10.0.19041.1, SHA-256 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737, with 144 imports. Do not confuse it with the DriverStore package binary.
> - Correction: earlier E-119 wording that exact DriverStore BthA2dp imports only ntoskrnl.exe is superseded by E-169. Full UUP PE audit shows eight import descriptors and 149 imports.
> - BtaMpm.inf uses BtaMPM.CopyFilesOnly; it does not install a separate BtaMPM service. BtaMPM.sys is a copied companion module imported by BthA2dp.sys. Common A2DP INF installs demand-start BthA2dp.
> - Static import closure is a strong compatibility result, not runtime proof. Catalog membership, INF applicability/staging, service start, PnP enumeration, driver load, endpoint, SBC negotiation and audio remain unverified.
> - UUP audit #7 / [run 45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564) checks offline catalog membership and SYSTEM-hive service registrations. No package install or driver load.
> - Keep exact Win10 A2DP source/common package over Server Bluetooth core. No new Bluetooth/ACX driver; CI #248/#255 remain closed. server-2022-oppo unchanged. Physical Server 2022 not accessed or modified.
>
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
