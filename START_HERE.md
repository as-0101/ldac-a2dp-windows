# LDAC project — START HERE

**Last reconciled:** 2026-11-23 evening (Kyiv).
**Latest technical experiment commit:** `79460f03492a54444473589dd142da864a703a73` (CI #17 WDK 20348.1 control; completed, ACX 1.0 stub not found, runtime skipped). **Documentation branch:** `docs/project-source-reorg` (follow the branch head for the current source map).  
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
- The WDK ACX 1.0 stub object contains a 0x78-byte (120-byte) class-bind descriptor, version 1.0, 210 functions / 62 structures. CI #16 resolved Server 2022 `WDF_CLASS_BIND_INFO2` in the Wdf01000 public PDB as the same 0x78-byte size with matching field offsets. This weakens a simple descriptor-size mismatch hypothesis but does not prove pointer/value/ACX-specific semantic compatibility; runtime ACX function/structure counts remain unknown.
- WDF source commit `b6191d9543441329154da32f7ab9bdd97228dd3c` shows `FxGetNextClassBindInfo` validates descriptor size against `WDF_CLASS_BIND_INFO` / `WDF_CLASS_BIND_INFO2`; its `WdfVersionBindClass` comment says that call loads/references the class extension and links the client. Existing physical debug evidence records `WdfVersionBindClass` returning `0xC000000D`. This places the known failure at the class-bind call, not in LDAC topology or the probe's DriverEntry body; the exact runtime validation that rejects the descriptor remains unknown.
- The pinned Microsoft AudioCodec sample defaults to ACX 1.1 / KMDF 1.31 and VS2019 16.0.31409.214; its INF targets 19041+, which includes Server 2022 build 20348. The probe deliberately forces ACX 1.0 to match the observed Server 2022 class module. Official ACX docs label 1.0 pre-release (Windows 10 1903 / KMDF 1.29) and 1.1 the public version initially released for Windows 10 2004 / KMDF 1.31; Server 2022 is not explicitly listed in the ACX table. Microsoft's KMDF 1.31 row lists Windows 10 2004 and later; it does not explicitly name Server 2022. CI #10 and #16 directly observed a KMDF 1.31 client bound to the 1.33 runtime on Server 2022.
- **CI #16 / [run 45084678951](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45084678951), commit `9da48c3ecd5921f8cab47888325b156dc9a536f3`:** completed successfully as a test harness, but the sample-derived ACX 1.0 driver still failed PnP Code 37 / `0xC000000D` before DriverEntry. The candidate INF was selected. The full LiveKD mirror captured 17,174,368,256 bytes with zero missing pages; WDF IFR showed no precise bind failure. Build/runtime artifact hashes and the WDF PDB layout comparison are in [ACX10_SAMPLE_BIND_PROBE](research/ACX10_SAMPLE_BIND_PROBE.md).
- Root cause remains **UNRESOLVED**. Do not repeat the already disproven claim that changing only ACX 1.1 to 1.0 fixes the failure. All runtime experiments remain on disposable hosted runners.

- **Headset identity confirmed by user photo:** the phone's connected-device page names the physical headset OPPO Enco Buds2. OPPO's official specs map Enco Buds2 to earbuds ETE41 / case ETE42 and list AAC/SBC only, not LDAC. The photos do not show a printed ETE code, but no further model-code check is needed for project scoping. Evidence E-027/E-028 in [EVIDENCE](docs/agent/EVIDENCE.md).
- **CI #17 complete:** [run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058) inspected the official EWDK 20348.1 ISO and found no ACX 1.0 stub; no probe build or runtime test occurred. The green job is an inspection success, not a driver-bind success.
- **Alternative architecture:** BlueCaster 3.0.0 (formerly A2DP Windows Bridge) uses a dedicated WinUSB Bluetooth adapter and user-mode A2DP stack, bypassing ACX. Its published support is Windows 10 22H2/Windows 11, not Server 2022; Server 2022 is untested. It does not add LDAC support to a headset that lacks LDAC.

- **New Windows 10 reference evidence (2026-11-23):** the working OPPO Enco Buds2 path uses Microsoft classic A2DP profile driver `BthA2dp.sys` / service `BthA2dp`, installed via `microsoft_bluetooth_a2dp_src.inf`; Stereo and Hands-Free endpoints are healthy. Microsoft documents classic A2DP as a WDM profile driver communicating with BthPort; ACX is used in the documented LE Audio VSAP architecture. Server SKUs lack in-box Bluetooth support. See latest entries in [EVIDENCE](docs/agent/EVIDENCE.md), [PROJECT_STATE](docs/agent/PROJECT_STATE.md), and [NEXT_ACTIONS](docs/agent/NEXT_ACTIONS.md). Do not copy individual DLL/SYS files or import Win10 registry exports.

## Critical architecture correction — 2026-11-23

The working Windows 10 reference uses the classic Microsoft A2DP WDM profile driver: `BthA2dp.sys` / service `BthA2dp`, INF `microsoft_bluetooth_a2dp_src.inf`, BTHENUM service GUID 0x110B, MEDIA class, KS/WDMAudio registration (`ks.inf`, `wdmaudio.inf`, `BtaMpm.inf`). Microsoft documents classic A2DP profile drivers communicating with BthPort through WDM/IRPs; ACX is not the documented classic A2DP foundation. Stop assuming the ACX-only branch is the path to Windows 10-style A2DP. See latest [EVIDENCE](docs/agent/EVIDENCE.md) entries E-037–E-043 and [NEXT_ACTIONS](docs/agent/NEXT_ACTIONS.md).

The latest re-uploaded Win10 ZIP is byte-identical to the earlier archive (SHA-256 `3bebbee156019cfa6e1c031e8158c8d1e230fd6f64dd57f3a3bc5aae991254cd`); it is not a new corrected-collector run and contains no Server inventory or copied A2DP INF/DriverStore package.

## Latest finding — Windows 10 A2DP package dependency (2026-11-23 20:49 Kyiv)

The new reference archive confirms the Win10 A2DP profile devnode is bound to `microsoft_bluetooth_a2dp_src.inf` and `BthA2dp.sys` (10.0.19041.4355). Crucially, the source INF delegates installation to `microsoft_bluetooth_a2dp.inf` via Include/Needs. The latter common INF and its catalog/package were **not** captured yet. Do not treat the source INF alone as an installable package. The Server 2022 inventory has generic BTHENUM Audio Sink Service via `bth.inf`, but no A2DP MEDIA profile devnode, A2DP INF, BthA2dp.sys or BthA2dp service. Core Bluetooth and Windows Audio components are present. See E-044–E-048 in [EVIDENCE](docs/agent/EVIDENCE.md).

The Win10 collector's Kernel-Drivers.csv reports demand-start kernel drivers as Stopped/Manual at snapshot time. This does not negate the signed PnP A2DP devnode record; do not claim BthA2dp was Running from that CSV.

**Next:** run the targeted read-only `Export-Win10-A2DP-Package.ps1` (attached to the current ChatGPT conversation) to capture `microsoft_bluetooth_a2dp.inf`, all Include/Needs dependencies, CAT files, and BthA2dp.sys with hashes/signature metadata. Then verify package OS decorations and Server applicability. Physical Server remains unchanged.

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

Confirm the exact headset model. If it is OPPO Enco Buds2 ETE41, close LDAC milestones for this receiver and focus on stable AAC/SBC playback. If LDAC is still required, use an LDAC-capable headset and evaluate BlueCaster's dedicated-USB-adapter user-mode architecture in an isolated Server 2022 test; its published OS support does not include Server 2022. Do not modify the physical host. CI #17's WDK 20348.1 route is stopped because the EWDK image did not contain the ACX 1.0 stub.

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


## Active experiment — WDK 20348.1 ACX 1.0 control (2026-11-23)

Current findings and full sample requirements: [ACX10_SAMPLE_BIND_PROBE](research/ACX10_SAMPLE_BIND_PROBE.md). CI #16 completed with the same pre-DriverEntry Code 37 / `0xC000000D` result. The WDF public-PDB layout comparison shows the 0x78-byte ACX stub descriptor matches `WDF_CLASS_BIND_INFO2` size and field offsets; exact semantic validation remains unknown.

Current isolated code branch: `experiment/acx10-wdk20348-control`, head `79460f03492a54444473589dd142da864a703a73`. CI #17 / [run 45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058) completed the EWDK 20348.1 inspection; the ACX 1.0 stub was not found and runtime was skipped. This branch is stopped.

CI #16 build/runtime artifacts and the descriptor analysis report are preserved and indexed. Physical server remains untouched.
