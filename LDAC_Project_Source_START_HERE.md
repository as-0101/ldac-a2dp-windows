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
- The legacy `pe_imports_a2dp.py` has a parser defect and its 1.3 MB report is invalid. Library contains `pe_imports_a2dp_fixed.py` (file ID `file_000000006ac88210b1f6b3d695278455`), which advances IMAGE_IMPORT_DESCRIPTOR by 20 bytes. Reports (2)/(3) are byte-identical and describe the separate 279,040-byte System32 copy, not the 282,624-byte DriverStore package copy. The fixed script reports direct imports only; use the repository `tools/research/audit_pe_binary.py` for exports, delay imports, VERSIONINFO and API-set data on exact UUP-extracted binaries.
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
- [UUP image audit](docs/agent/WIN10_UUP_IMAGE_AUDIT.md)
- [Next actions](docs/agent/NEXT_ACTIONS.md)
- [Project state](docs/agent/PROJECT_STATE.md)
- [Evidence register](docs/agent/EVIDENCE.md)
- [Decisions and experiments](docs/agent/DECISIONS_AND_EXPERIMENTS.md)
- [Build registry](research/BUILD_REGISTRY.md)
- [Test matrix](research/TEST_MATRIX.md)
- [Artifact index](research/ARTIFACT_INDEX.md)

## Latest verified state — 2026-11-24 (CI #11)

- CI #11 (45347639357) completed offline extraction for Win10 19045.5917 and Server 20348.5761 and uploaded metadata artifact uup-image-a2dp-audit-metadata (artifact 14901033654, SHA-256 277ed892887f10383e34bb9f3c3690a0ebdf290d32cb9f4899d6016e78fbadff, 331,349 bytes).
- SignTool verified all five Win10 A2DP package files against one Win10 servicing catalog: Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.5917.cat, SHA-256 78772FA12959C072D687283F08D08367B8A8EF1A2F07D7B72F20BCAFD12483BF.
- The Win10 CBS MUM identifies microsoft_bluetooth_a2dp.inf 10.0.19041.4355, microsoft_bluetooth_a2dp_src.inf 10.0.19041.1, and btampm.inf 10.0.19041.5848 as dualModeDriver components owned by Client-Desktop-Required-Package 10.0.19041.5917.
- Server 20348.5761 has BthPort/BthEnum/BTHUSB and audio services, but no BthA2dp service registration or BtaMPM component registration. BtaMPM is not a service in either image.
- Critical open question: CI #11 checked the package against Win10 catalogs only. It did not check whether the same Win10 files are members of Server 2022's system catalog set. Do not infer cross-SKU package acceptance from the Win10 result.
- A focused follow-up exists on experiment/win10-a2dp-cross-sku-catalog-audit-20261124 (script commit 05555dc8fac8b2f551826b71cba40084defe9a46, workflow commit 08663c4ca7d1536b96c554fd5e484382262b1250). It checks the exact Win10 files against Server catalogs and uses Server Bluetooth core files as positive controls.

Next gate: finish cross-SKU catalog verification, then test original-package staging on a disposable Server 2022 VM. No physical-host changes; no ACX bind-probe.

## Cross-SKU audit implementation update — 2026-11-24

The isolated cross-SKU audit script was extended to record the matched CAT's embedded Authenticode signer/status in addition to SignTool membership and catalog SHA-256. Latest script commit: 11f0c4776b3d1ed6c79f5dca75634dda40c19ba9. The follow-up CI result has not yet been verified.

## Latest verified state — cross-SKU catalog audit (2026-11-24)

CI #12 [45354874225](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45354874225) completed successfully. Exact images: Windows 10 19045.5917 x64 and Windows Server 2022 20348.5761 x64.

The exact five-file Win10 A2DP package (BthA2dp.sys, BtaMPM.sys, common INF, source INF, btampm.inf) is a member of one Win10 servicing CAT (SHA-256 78772FA12959C072D687283F08D08367B8A8EF1A2F07D7B72F20BCAFD12483BF). The same exact file hashes have no match in the 8,325 Server image catalogs. Server positive controls passed 4/4 against the Server OneCore Bluetooth catalog (SHA-256 B0A59B9C3B6E528487BB273332015C8CC3A65A5E60F33BF8AA263E41F6D59AA6). Therefore the Win10 CAT is not pre-registered in the Server image's system catalog set; this does not prove that its Microsoft signature chain cannot be validated or that the catalog cannot be registered.

The next experiment is limited to a disposable GitHub-hosted Server 2022 runner: verify the original CAT and its members with SignTool, try PnPUtil staging without /install, then (only if required) add the original CAT to the system component/driver catalog database and retry. No certificate store change, device binding, service start, driver load or physical-host access. Current run #3: [45371687882](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882).

CI #12 metadata and its readable summary are saved under /LDAC Project/Incoming in Library. The Server-side CAT signer subject was not captured by the artifact (catalogSignature is null); do not claim it was independently recorded.

