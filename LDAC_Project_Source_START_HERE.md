# LDAC Project Source — START HERE

**Last verified:** 2026-11-24 01:42 Europe/Kyiv  
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

## Immediate next actions

1. Obtain original Windows 10 22H2 and Server 2022 install.wim/install.esd metadata or mounted component stores. No ISO/WIM/ESD/CAB/MSU media was found in the current Library inventory.
2. Resolve CBS package/component identities, MUMs, manifests, system catalogs, architecture and applicability for the A2DP source/common and btampm packages.
3. Reconcile the DriverStore and System32 BthA2dp.sys copies and complete PE exports/delay-import/API-set analysis.
4. Compare imported symbols with exact Server 2022 build 20348.5761 exports.
5. Only then test the unmodified inbox package in a disposable Server 2022 VM, using separate gates: service start → enumeration → driver load → endpoint → SBC negotiation → actual audio.
6. LDAC tests must use a different LDAC-capable receiver.

## Physical-host safety

Last recorded PnP state: the OPPO BTHENUM 0x110B node was present and bound to the project's own oem75.inf (provider LDAC A2DP Project, service LdacA2dp, DriverVer 0.2.325.1600); Code 37 / ProblemStatus 0xC000000D occurred at custom driver start. This is not a test of the Microsoft Win10 BthA2dp package and is not a fresh read-only check from this run. No physical-host command or mutation was performed.

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
