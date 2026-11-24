> **ACTIVE PROJECT OVERRIDE — 2026-11-24 05:20 Europe/Kyiv**
>
> Priority is the smallest Windows 10 A2DP package adaptation for Server 2022, starting with SBC stereo. Do not create a new Bluetooth/ACX driver and do not resume ACX bind-probe work; CI #248/#255 are closed.
> - Existing Win10 source/common/sink INF, DriverStore and System32 artifacts are already in Project Sources/Library. Do not re-export or ask the user to resend them.
> - CI #463 (run 45311922753) succeeded. Catalog packages contain PSF forward-delta SYS payloads; Winbindex returned 0/3 exact SHA identities. Metadata-only artifacts are stored in `/LDAC Project/Incoming`.
> - Library contains `pe_imports_a2dp_fixed.py`. Reports (2)/(3) are byte-identical and describe the 279,040-byte System32 copy, not the 282,624-byte DriverStore copy. The old 1.3 MB report remains invalid.
> - A nearby Win10 symbol-server candidate has a promising but incomplete static import match against a later Server 20348.5866 runtime. It is not the exact captured binary and does not establish compatibility with target 20348.5761.
> - UUP audit run #3 (45317582562) is in progress against Win10 19045.5917 and Server 20348.5761. See `WIN10_UUP_IMAGE_AUDIT.md` for gaps.
> - `server-2022-oppo` remains unchanged. No driver install or runtime test was performed on the physical host.
>
> The Library Project Source START_HERE snapshot is historical; use this repository copy and the canonical docs below.

# LDAC Project Source — START HERE

**Last verified:** 2026-11-24 02:19 Europe/Kyiv  
**Code branch:** server-2022-oppo  
**Documentation branch:** docs/project-source-reorg

## Goal and order

1. First milestone: stable A2DP stereo using SBC on Windows Server 2022 with OPPO Enco Buds2.
2. Only after the SBC path is proven, investigate LDAC negotiation and real LDAC audio with a sink that actually supports LDAC.
3. HFP/microphone is out of scope.

## Current verified direction

- Stop ACX/WDK bind-probe work. CI #248 and #255 are closed historical evidence; they are not the next step.
- The 2026-11-23 23:49 Win10 package archive already exists. It contains the source/common/sink A2DP INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys. Do not rerun the exporter or request the same archive.
- The common INF is Class=MEDIA, DriverVer 10.0.19041.4355; it includes ks.inf, wdmaudio.inf and BtaMpm.inf, and registers BthA2dp as a demand-start kernel service plus KSCATEGORY_AUDIO interfaces.
- btampm.inf is Class=SYSTEM, DriverVer 10.0.19041.5848; its CopyFilesOnly section supplies BtaMPM.sys.
- The recorded Server 2022 inventory has ks.inf, wdmaudio.inf, WMALFXGFXDSP.dll and SysFxUI.dll, but not the A2DP profile package. This is archived evidence, not a fresh physical-host query.
- The package has no local .cat file, but the system-supplied INFs have no CatalogFile directive. Microsoft documents that system-supplied INFs are validated against system catalogs. The source catalog identity and CBS/component ownership are still needed before cross-SKU staging.
- Two BthA2dp.sys copies have different sizes and hashes. Their PE import reports must not be merged; see WIN10_COMPONENT_AUDIT.md.
- Microsoft Windows 10 inbox A2DP does not provide LDAC. OPPO Enco Buds2 ETE41 supports AAC/SBC only, so SBC is the only common codec. LDAC needs a different sink.
- Alternative A2DP Driver advertises LDAC but its EULA restricts reverse engineering/modification/transfer and its published support matrix does not include Server 2022. Do not transplant it.
- The repository is a fork of yariktop133/ldac-a2dp-windows, a separate replacement-driver project. The custom driver code path remains frozen.
## Strategy correction — 2026-11-24 02:19 Europe/Kyiv

- **There is no Microsoft inbox Windows 10 LDAC DLL/provider to transplant.** Microsoft's Classic Audio table lists Windows 10 A2DP codecs as SBC and aptX Classic; AAC is not supported on Windows 10 and LDAC is not listed.
- The documented Microsoft model is a PnP-loaded kernel profile driver selected through INF and communicating with `BthPort.sys` over WDM IRPs / Bluetooth Request Blocks. The captured source/common INF installs `BthA2dp.sys`; `BtaMPM.sys` is profile/multiprofile management, not an LDAC codec. The `mssysfx` APO path is audio effects, not codec provisioning.
- Public symbols for the older `BthA2dp.sys` 10.0.17763.168 show internal `A2dpSbcCodec` and `AptXCodec` classes and AVDTP code, with no `Ldac` symbol among 997 named symbols. This is secondary architecture evidence for that older build, not a symbol map for the captured 10.0.19041.4355 binary.
- The code branch already vendors AOSP `external/libldac` at upstream commit `eeee1a3f`; CMake builds `ldacBT_enc` and `ldacBT_abr` as static libraries, and `service/encoder.cpp` calls them. This is not a Windows 10 DLL or a plug-in for Microsoft's `BthA2dp.sys`.
- OPPO Enco Buds2 ETE41 advertises AAC/SBC only. Use it for SBC; it cannot validate LDAC negotiation or LDAC audio.
- The legacy `pe_imports_a2dp.py` has a parser defect: its IMAGE_IMPORT_DESCRIPTOR loop never advances by 20 bytes. The 1.3 MB `a2dp_pe_imports_report.txt` repeats the first descriptor and is invalid for import-count/dependency conclusions. Reports (2)/(3) have no retained corrected parser source; re-run the exact binaries with Dependencies/PEInspector and retain the parser.
- Winbindex's x64 hash-only index now confirms the exact SHA-256 values for the 282,624-byte DriverStore BthA2dp.sys, the separate 279,040-byte System32 copy, and BtaMPM.sys. This confirms hash presence in the Microsoft public-symbol index, but does not supply PE timestamp/virtual size, OS/update mapping or catalog membership; see E-143–E-145.
- BlueCaster v3.0.4 is an existing user-mode A2DP implementation advertising LDAC, but it bypasses the Windows Bluetooth stack, takes a USB Bluetooth adapter over through WinUSB, lists Windows 10 22H2/Windows 11 rather than Server 2022, and bundles BTstack with a personal/non-commercial license. It is a later disposable-VM candidate, not the current Microsoft SBC path.
- The AOSP source is Apache-2.0 in the repository, but its NOTICE says LDAC product use requires certification; Sony's AOSP page provides a licensing inquiry. Treat distribution/certification as a release gate, separate from a local technical proof.

No source code, driver package, physical host, device, service, BCD, security setting, certificate, or OS image was changed in this research pass.


## Immediate next actions

1. Stop searching for a Microsoft Windows 10 LDAC DLL: the documented inbox codec set has no LDAC, and the captured INF/PE path is a kernel A2DP profile package, not a codec-DLL plug-in.
2. Re-run a retained, reproducible PE audit on the exact 282,624-byte DriverStore `BthA2dp.sys` and `BtaMPM.sys`: version/resource data, architecture, complete direct/forwarded/delay imports, exports, API sets, dynamic-load clues, signature/catalog identity and SHA-256. Keep the separate 279,040-byte System32 copy distinct. Do not use the legacy 1.3 MB report.
3. Continue sourcing official Windows 10 22H2 and Server 2022 20348.5761 image/component metadata independently. Resolve CBS package identities, MUM/manifests, system catalogs, architecture and applicability for the source/common A2DP and btampm packages. Do not ask for the already captured ZIP.
4. Compare the exact package import closure with exports from the exact Server 2022 20348.5761 kernel, HAL, KS, CNG, WPP, WDF and security components. A smaller import table alone is not proof of compatibility.
5. Only if package ownership, catalog and static compatibility pass, stage the unmodified Microsoft package in a disposable Server 2022 VM. Report each gate separately: service start → BTHENUM enumeration → profile-driver load → A2DP render endpoint → SBC negotiation → actual stereo audio.
6. After SBC is proven, evaluate LDAC with a separate LDAC-capable sink. BlueCaster v3.0.4 may be assessed only in a disposable VM with a USB adapter/WinUSB; Server 2022 support is unverified and BTstack's license must be respected. OPPO ETE41 is not an LDAC test sink.
7. Keep ACX/WDK bind-probe parked. HFP/microphone remains out of scope.


## Physical-host safety

Last recorded PnP state: the OPPO BTHENUM 0x110B node was present on the local Intel radio (LOCALMFG&0002; Microsoft defines LOCALMFG as the local radio manufacturer) and bound to the project's own oem75.inf (provider LDAC A2DP Project, service LdacA2dp, DriverVer 0.2.325.1600); Code 37 / ProblemStatus 0xC000000D occurred at custom driver start. This is not a test of the Microsoft Win10 BthA2dp package and is not a fresh read-only check from this run. No physical-host command or mutation was performed.

Do not run prepare-oppo-host.cmd, upgrade-oppo.cmd, install-oppo.cmd or rollback-oppo.cmd. No driver install/restart, BCD/security/test-signing or certificate changes, or OS update/rollback. Notion journal is append-only.

## Canonical documents

- [Windows 10 component audit](docs/agent/WIN10_COMPONENT_AUDIT.md)
- [A2DP pipeline map](docs/agent/WIN10_A2DP_PIPELINE.md)
- [Next actions](docs/agent/NEXT_ACTIONS.md)
- [Project state](docs/agent/PROJECT_STATE.md)
- [Evidence register](docs/agent/EVIDENCE.md)
- [Decisions and experiments](docs/agent/DECISIONS_AND_EXPERIMENTS.md)
- [Build registry](research/BUILD_REGISTRY.md)
- [Test matrix](research/TEST_MATRIX.md)
- [Artifact index](research/ARTIFACT_INDEX.md)
