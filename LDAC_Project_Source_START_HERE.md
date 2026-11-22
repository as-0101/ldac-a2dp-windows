# LDAC project — START HERE

**Last reconciled:** 2026-11-23 (Kyiv).
**Latest project-source commit:** `7e5d332bbaf155b329cc041b97130b4471d83f39` (CI #13/#14 results, WDF diagnostics decision, CI #15 plan). **Documentation branch:** `docs/project-source-reorg`.  
**Mission:** achieve stable Bluetooth A2DP stereo playback on physical Windows Server 2022 Datacenter with OPPO Enco Buds2. First milestone: SBC stereo; only then LDAC negotiation and verified LDAC audio. HFP/microphone is out of scope.

## Current result — do not misread it

- The physical host has not been modified during this investigation. Last directly recorded state: Server 2022 build 20348 / UBR 5761; OPPO A2DP node on `oem75.inf`, driver 0.2.325.1600, Code 37, ProblemStatus `0xC000000D`. Recheck read-only before any future action.
- ACX class module v1.0 is directly reported by WinDbg on the physical host and by hosted Server 2022 LiveKD run #15 (artifact/report in the research records). WDF client 1.31 and WDF runtime 1.33 are separate version fields.
- CI #133 (ACX 1.0 / Universal) built and its package/PDB were statically inspected. It was **not** a successful runtime test.
- **Important negative result:** hosted Server 2022 run #248 / [45060225420](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45060225420), commit `3d1d5d7e179da3379013b10f9863066200c459b6`, explicitly started `Acx01000` and verified RUNNING before installing an ACX 1.0 driver. PnP selected `oem13.inf` (DriverVer 0.2.326.1922) and attempted start, but still returned Code 37 / `0xC000000D`; no DriverEntry evidence. Therefore ACX 1.1-vs-1.0 mismatch alone is insufficient.
- CI #255 / [45060819535](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45060819535), commit `085705abb4bf8e52dd5bcb5bccb532352fbb132e`, succeeded in inspecting the actual WDK 26100.6584 ACX stub libraries. The ACX 1.0 linked descriptor is 1.0 / 210 functions / 62 structures; ACX 1.1 is 1.1 / 221 / 62. The CI #246 candidate SYS descriptor was parsed as 1.0 / 210 / 62. This rules out an accidental ACX 1.1 descriptor in that candidate, not all possible bind metadata problems.
- **CI #13 / [45078613003](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45078613003), commit 35e700a3ecb74548b858f0479a1e15e31a2d110f:** the official AudioCodec-derived ACX 1.0 probe built with WDK 10.0.26100.6584 / KMDF 1.31 and its root-enumerated MEDIA INF was selected by hosted Server 2022 PnP. Runtime still ended Code 37 / 0xC000000D before DriverEntry. This is not LDAC-specific and is not explained by the original LDAC INF topology.
- The sample SYS and LDAC candidate SYS both carry ACX 1.0 descriptor 210 functions / 62 structures. The sample's DriverEntry order is WdfDriverCreate then AcxDriverInitialize, but no DriverEntry path is reached.
- **CI #14 / [45081844225](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45081844225), commit 04518a83900a7e7aa093fe56a7669f91349d7588:** same Code 37 / 0xC000000D pre-DriverEntry result. The post-boot global DbgPrintOn registry write was too late: Wdf01000.sys reads WdfLdrDbgPrintOn in its DriverEntry at system startup. Empty !dbgprint is an instrumentation limitation, not evidence that the loader emitted no messages.
- Compatibility caveat: Microsoft lists ACX 1.0 as pre-release for Windows 10 1903 / KMDF 1.29; Server 2022 is not listed in that ACX 1.0 table. The tested tuple is not documented as supported; this is not yet a proven cause.
- **CI #15 / [45082965356](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45082965356), commit 488ae8104eec960370c0887e07136a3e9e3846b5:** in progress with per-driver WDF VerboseOn/LogPages, WDF IFR dumps and LiveKD native dumps.
- Current root cause: **UNRESOLVED**. ACX class bind / WDK stub vs Server 2022 runtime remains the focus; do not repeat the claim that merely switching to ACX 1.0 fixes it.

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
