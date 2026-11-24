> **ACTIVE PROJECT OVERRIDE — 2026-11-24 07:13 Europe/Kyiv**
>
> Priority is the smallest Windows 10 A2DP package adaptation for Server 2022, starting with SBC stereo. Do not create a new Bluetooth/ACX driver and do not resume ACX bind-probe work; CI #248/#255 are closed.
> - Existing Win10 source/common/sink INF, DriverStore and System32 artifacts are already in Project Sources/Library. Do not re-export or ask the user to resend them.
> - CI #463 (run 45311922753) succeeded. Catalog packages contain PSF forward-delta SYS payloads; Winbindex returned 0/3 exact SHA identities. Metadata artifacts are already in Library `/LDAC Project/Incoming`.
> - UUP audit #3 (45317582562) failed before image mount because the DISM object lacked `.Version`; no image/component result.
> - UUP audits #4 (45325486392) and #5 (45325586394) both verified the Server image identity as Windows Server 2022 Datacenter 20348.5761 / ServerDatacenter, then failed in the PE parser on `AudioEndpointBuilder.dll`: a named delay-import entry had `hint=None`, and the parser called `int(None)`. This is a tooling failure, not a binary incompatibility. Neither run reached the Win10 image; neither produced a metadata artifact.
> - Isolated experiment commit [6778022](https://github.com/as-0101/ldac-a2dp-windows/commit/6778022b4453857e53acf8a18afe54bb7e46f5f5) makes missing delay-import hints nullable, adds three regression tests, and runs them before the long UUP download. CI #6 / [45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839) has passed the parser regression-test step; the offline image audit is still running. No PE/CAT/registry conclusion is available yet.
> - Exact captured DriverStore BthA2dp 10.0.19041.4355, separate System32 copy and BtaMPM 10.0.19041.5848 remain distinct. Do not transfer import conclusions across versions. Exact 20348.5761 comparison is pending.
> - Server `bth.inf` routes remote A2DP Sink UUID 0x110B to a generic fallback; Win10 source/common INF installs `BthA2dp.sys` and KSCATEGORY_AUDIO interfaces. This is a package-level candidate only; no staging or runtime success is claimed.
> - The fork already statically links AOSP libldac 2.0.2 into `ldacsvc_core`; no Microsoft inbox LDAC provider DLL has been identified. OPPO Enco Buds2 is SBC/AAC only.
> - `server-2022-oppo` remains unchanged. Physical Server 2022 has not been queried or modified in this run.
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
