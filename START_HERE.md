# LDAC project — START HERE

**Last reconciled:** 2026-11-23 (Kyiv).
**Latest technical experiment commit:** `9da48c3ecd5921f8cab47888325b156dc9a536f3` (CI #16 full-mirror/WDF class-bind diagnostics). **Documentation branch:** `docs/project-source-reorg` (follow the branch head for the current source map).  
**Mission:** achieve stable Bluetooth A2DP stereo playback on physical Windows Server 2022 Datacenter with OPPO Enco Buds2. First milestone: SBC stereo; only then LDAC negotiation and verified LDAC audio. HFP/microphone is out of scope.

## Current result — do not misread it

- The physical host has not been modified. Last directly recorded state remains Server 2022 build 20348 / UBR 5761; OPPO A2DP node on `oem75.inf`, driver 0.2.325.1600, Code 37 / `0xC000000D`. Any future host check must be read-only.
- CI #248 / [run 45060225420](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45060225420) proved that starting `Acx01000` and selecting ACX 1.0 alone does not fix the LDAC candidate: PnP still returned Code 37 / `0xC000000D` before DriverEntry.
- CI #255 / [run 45060819535](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45060819535) parsed the WDK 10.0.26100.6584 ACX stubs: ACX 1.0 = version 1.0 / 210 functions / 62 structures; ACX 1.1 = 1.1 / 221 / 62. The ACX 1.0 stub hash is `9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74`.
- CI #13 / [run 45078613003](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45078613003) first reproduced the same failure with a minimal Microsoft AudioCodec-derived ACX 1.0 client and a root-enumerated MEDIA INF.
- **CI #15 / [run 45082965356](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45082965356), commit `488ae8104eec960370c0887e07136a3e9e3846b5`:** build and hosted runtime jobs completed successfully as a test harness, but the driver bind did not. On hosted Server 2022 build 20348 / UBR 5870, PnP selected `oem13.inf` for `ROOT\DEVGEN\ACX_SAMPLE_BIND_PROBE_CI`, then returned Code 37 / `0xC000000D`; no DriverEntry marker. The probe SYS SHA-256 is `BAB3C54C0EAB186CC8C9D89B07BCA871112454175C0C45F8D199DA57927114B6`.
- CI #15 used WDK NuGet 10.0.26100.6584, SDK 10.0.26100.0, VS2022 MSBuild 17.14.60.43110, KMDF 1.31, ACX 1.0, x64, `DriverTargetPlatform=Windows Driver`; INF `Class=MEDIA`, hardware ID `ROOT\AudioCodec`, `KmdfLibraryVersion=1.31`. `DriverVer=11/22/2026,23.24.24.909`.
- The CI #15 runtime files match the earlier hosted baseline: `Acx01000.sys` 10.0.20348.5866, SHA-256 `D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0`; `Wdf01000.sys` 1.33.20348.1, SHA-256 `32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B`. CI #10 directly showed ACX `CLASS_MODULE` v1.0, WDF client 1.31 and WDF runtime 1.33; CI #15's dump could not re-display the class-module record because a page was missing.
- CI #15's preinstall dump contains WDF IFR records for the running `Acx01000` runtime. The probe's own WDF IFR is unavailable because its driver never successfully loaded. The report's structured `WdfIfrLines` field only extracted postinstall output and missed the preinstall records; the raw preinstall log was inspected, and CI #16 fixes this extraction.
- The WDK ACX 1.0 stub object contains a 0x78-byte (120-byte) class-bind descriptor, version 1.0, 210 functions; the associated stub metadata reports 62 structures. The ACX 1.1 stub has 221 functions / 62 structures. The runtime class's actual function/structure counts are still unknown.
- WDF source commit `b6191d9543441329154da32f7ab9bdd97228dd3c` shows `FxGetNextClassBindInfo` validates descriptor size against `WDF_CLASS_BIND_INFO` / `WDF_CLASS_BIND_INFO2`; its `WdfVersionBindClass` comment says that call loads/references the class extension and links the client. Existing physical debug evidence records `WdfVersionBindClass` returning `0xC000000D`. This places the known failure at the class-bind call, not in LDAC topology or the probe's DriverEntry body; the exact runtime validation that rejects the descriptor remains unknown.
- Official ACX documentation lists ACX 1.0 as pre-release for Windows 10 1903 / KMDF 1.29 and does not list Server 2022; ACX 1.1 is the public version initially released for Windows 10 2004 / KMDF 1.31. WDK 26100.6584 is the Microsoft-recommended VS2022 path and the WDK supports building for Windows Server 2016 and later, but that does not establish ACX 1.0 runtime support on Server 2022.
- **CI #16 / [run 45084678951](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45084678951), commit `9da48c3ecd5921f8cab47888325b156dc9a536f3`:** in progress. It uses a full LiveKD mirror (`-m0x3FFF`) for the preinstall snapshot, queries WDF class-bind types in the runtime PDB, preserves preinstall and postinstall IFR separately, and scans the WDK include tree for class-bind declarations.
- Root cause remains **UNRESOLVED**. Do not repeat the already disproven claim that changing only ACX 1.1 to 1.0 fixes the failure. All runtime experiments remain on disposable hosted runners.

## Read in this order — do not read the whole history

1. This page.
2. [NEXT_ACTIONS](docs/agent/NEXT_ACTIONS.md).
3. [PROJECT_STATE](docs/agent/PROJECT_STATE.md) — use the latest dated continuation at the end.
4. [EVIDENCE](docs/agent/EVIDENCE.md) for the claim being investigated.
5. Only the relevant test/build record: [BUILD_REGISTRY](research/BUILD_REGISTRY.md), [TEST_MATRIX](research/TEST_MATRIX.md), [ARTIFACT_INDEX](research/ARTIFACT_INDEX.md).
6. Before any possible host action, read [HARDWARE_SAFETY](research/HARDWARE_SAFETY.md) and [PHYSICAL_TEST_RUNBOOK](docs/agent/PHYSICAL_TEST_RUNBOOK.md).
7. Use [DECISIONS_AND_EXPERIMENTS](docs/agent/DECISIONS_AND_EXPERIMENTS.md) to avoid repeating ruled-out work. Notion journal is historical/append-only; search it selectively.

## Source of truth and navigation

- [GitHub repository](https://github.com/as-0101/ldac-a2dp-windows)
- [Documentation branch](https://github.com/as-0101/ldac-a2dp-windows/tree/docs/project-source-reorg)
- [Full agent bootstrap](AGENT_BOOTSTRAP.md)
- [Project state](docs/agent/PROJECT_STATE.md) · [Evidence](docs/agent/EVIDENCE.md) · [Next actions](docs/agent/NEXT_ACTIONS.md)
- [Build registry](research/BUILD_REGISTRY.md) · [Test matrix](research/TEST_MATRIX.md) · [Hardware safety](research/HARDWARE_SAFETY.md) · [Artifact index](research/ARTIFACT_INDEX.md)
- [Notion START HERE](https://app.notion.com/p/420769fff63681fe89efc8bb2c918ddc) (historical page; see its reorganization notice)
- [Notion handoff/artifact index](https://app.notion.com/p/420769fff636812ab023c0fb67c66a5a)
- [Notion investigation journal](https://app.notion.com/p/41f769fff636810fbd50c285bc3d33f6)
- [CI #133 package/PDB analysis](https://app.notion.com/p/420769fff636810eb51ddcb4e05310fc)

## Next technical action

Inspect CI #15's WDF IFR output from the native LiveKD dump. If it identifies FxStubBindClasses / VersionBindClass / InitTypes, compare the WDK 26100 ACX 1.0 stub against the hosted Server 2022 Acx01000 class module. If it does not expose the stage, use a live KD or ETW capture, then consider an older-WDK ACX 1.0 control build. Do not rewrite the INF topology and do not change the physical server.

## Evidence discipline

Use `CONFIRMED`, `SUPPORTED`, `HYPOTHESIS`, `REFUTED`, `UNTESTED`, `BLOCKED`. For hardware-related claims always label the environment: `BUILD_ONLY`, `STATIC_ANALYSIS`, `VM_TEST`, or `PHYSICAL_HARDWARE_TEST`.

Build success ≠ driver load. Driver load ≠ PnP binding. PnP binding ≠ ACX circuit/endpoint. Endpoint ≠ codec negotiation. Codec selection ≠ actual audio stream.

## Every incoming user file — mandatory workflow

For every file: preserve original bytes/name; compute SHA-256 and size; add/retain it in Project Sources when supported; save a durable Library copy in the project folder; list exact file IDs, Library IDs, path, hash, date and purpose in `research/ARTIFACT_INDEX.md); link it to the relevant build/test/research note. For ZIP/CAB preserve the original and record the internal file listing separately. Derivatives must name their source ID and transformation. If persistence fails, mark `NOT_PERSISTED` and tell the user. Never infer persistence from a chat attachment or a filename. Before asking for re-upload, search Project Sources, Library, Artifact Index, GitHub and Notion.

## Safety boundary

No physical-server driver installation, device restart, BCD change, test-signing change, certificate import/removal, Secure Boot/Code Integrity change, OS update, or rollback without a separate explicit user authorization and a reviewed rollback plan. Never run `prepare-oppo-host.cmd`, `upgrade-oppo.cmd`, `install-oppo.cmd`, or `rollback-oppo.cmd` automatically. Keep HID working. Do not modify driver/INF/SYS/CAT as part of documentation work.

## File/repository rules

- Commit documentation only to `docs/project-source-reorg` until reviewed; never mix research docs with driver source changes.
- One logical documentation commit per coherent set; record exact commit SHA in this page and Notion journal.
- Update BUILD_REGISTRY after build changes; TEST_MATRIX and DECISIONS_AND_EXPERIMENTS after tests; ARTIFACT_INDEX after every new artifact; PROJECT_STATE, NEXT_ACTIONS and START_HERE after material changes.
- Do not overwrite originals, erase historical records, commit credentials/private keys or large binaries.
- `CODEX_TASK.md` was not found in the audited GitHub tree or searched Project Sources/Library; treat as unavailable until located, do not reconstruct it from guesswork.


## Active experiment — ACX 1.0 sample-derived bind probe (2026-11-23)

Current experiment: [ACX10_SAMPLE_BIND_PROBE](research/ACX10_SAMPLE_BIND_PROBE.md). Separate code branch: `experiment/acx10-sample-bind-probe-v2`, head `488ae8104eec960370c0887e07136a3e9e3846b5`. CI #13 and #14 both built and reached hosted Server 2022 PnP; both ended Code 37 / 0xC000000D before DriverEntry. CI #14's global DbgPrintOn write was applied after Wdf01000 had loaded and did not enable loader output. CI #15 is running with per-driver WDF VerboseOn=1 / LogPages=16, `!wdfkd.wdflogdump`, and LiveKD native `-ml` capture.

CI #13 and #14 build/runtime artifacts are preserved under /LDAC Project/Incoming/ and indexed in research/ARTIFACT_INDEX.md. Physical server remains untouched.
