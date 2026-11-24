# LDAC A2DP — project entry

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
- BlueCaster v3.0.4 is a possible separate user-mode LDAC transport, but it requires WinUSB on a USB adapter, does not list Server 2022 support, and carries BTstack's personal/non-commercial license. It is not a drop-in codec DLL.


## Read in this order

1. [LDAC_Project_Source_START_HERE.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/LDAC_Project_Source_START_HERE.md)
2. [WIN10_COMPONENT_AUDIT.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_COMPONENT_AUDIT.md)
3. [WIN10_A2DP_PIPELINE.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_A2DP_PIPELINE.md)
4. [NEXT_ACTIONS.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/NEXT_ACTIONS.md)
5. PROJECT_STATE.md, EVIDENCE.md, DECISIONS_AND_EXPERIMENTS.md, BUILD_REGISTRY.md, TEST_MATRIX.md and ARTIFACT_INDEX.md.

## Safety

Physical Server 2022 is read-only during this investigation. No driver install, device restart, BCD/security/test-signing or certificate changes, OS update/rollback, or execution of prepare/upgrade/install/rollback scripts is authorized. HFP/microphone remains out of scope. Notion journal remains append-only.
