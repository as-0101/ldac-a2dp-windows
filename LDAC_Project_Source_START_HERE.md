# LDAC / A2DP on Windows Server 2022 — Project Source START HERE

**Updated:** 2026-11-23 23:40 Europe/Kyiv  
**Canonical docs branch:** [docs/project-source-reorg](https://github.com/as-0101/ldac-a2dp-windows/tree/docs/project-source-reorg)

## Mission and scope

Reuse existing Windows 10 Bluetooth A2DP components with the smallest possible adaptation to Windows Server 2022 build 20348. The first milestone is stable SBC stereo. Only after that, prove LDAC negotiation and real LDAC audio. HFP/microphone is out of scope.

**Do not develop a new Bluetooth/ACX driver as the default path. Do not spend more cycles on ACX/WDK bind probes unless the existing Windows 10 package path is proven to be blocked by that layer.**

## Current technical conclusion

1. Microsoft's Windows 10 built-in A2DP stack supports SBC and classic aptX; it does not provide LDAC or AAC. No Microsoft inbox LDAC codec DLL/provider has been identified.
2. OPPO Enco Buds2 model ETE41 officially supports AAC/SBC only. For this headset, the common codec with Windows 10 is **SBC**. It cannot validate LDAC.
3. The Windows 10 reference capture contains `microsoft_bluetooth_a2dp_src.inf` version `10.0.19041.1` and `BthA2dp.sys` version `10.0.19041.4355`, size `282,624`, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`.
4. The captured source INF delegates to `microsoft_bluetooth_a2dp.inf`, but that common INF and the package catalog are missing from the current archive. The package is incomplete and must not be installed or copied piecemeal.
5. The latest recorded Server 2022 evidence (2026-11-23 20:41 Kyiv) shows the A2DP service UUID `0x110B` enumerating through a generic `bth.inf` placeholder, not through `BthA2dp`. The last recorded custom target node was `oem75.inf`, version `0.2.325.1600`, Code 37 / `0xC000000D`. This is a historical read-only snapshot, not a live host check.
6. The current repository's LDAC encoder is AOSP `third_party/libldac`, built as static code and called by `service/encoder.cpp`. It is not a Windows 10 LDAC DLL. The repository's `LdacA2dp.sys` is a separate custom AVDTP/L2CAP + ACX 1.1 driver, not a codec plug-in for Microsoft `BthA2dp.sys`; that path is parked.
7. Microsoft documents no in-box Bluetooth support for Windows Server SKUs. Any package adaptation is research-only until proven in a disposable Server 2022 VM.
8. Microsoft's published A2DP model is a PnP-selected WDM profile driver communicating with BthPort; no user-mode codec-provider DLL hook is documented. A standalone LDAC DLL is not a drop-in extension for `BthA2dp.sys`.
9. Alternative A2DP 1.8.3 is a third-party kernel driver supported on Windows 10 22H2 / Windows 11, not Server 2022. BlueCaster 3.0.4 is an open-source user-mode BTstack/WinUSB alternative for Windows 10 22H2/11 that takes over a USB adapter. Both are fallback architectures, not Microsoft inbox DLLs.

## Immediate next action

Run the existing **read-only** `Export-Win10-A2DP-Package.ps1` on the Windows 10 reference machine. It is already in Library at:

`/Bluetooth на Windows Sever 2022/Export-Win10-A2DP-Package.ps1`

Run it from an elevated PowerShell window in the folder containing the script:

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Export-Win10-A2DP-Package.ps1"`

It does not install drivers or change system configuration. Its output must include the common INF `microsoft_bluetooth_a2dp.inf`, the matching catalog, and the complete package folder(s). If the common INF is still absent, do not install anything; extend the read-only search to WinSxS. Existing archives and scripts are already in Library; do not re-upload those.

## Test gates

Keep these gates separate and never infer a later success from an earlier one:

1. Service start
2. A2DP BTHENUM device enumeration
3. Microsoft A2DP profile driver load / PnP problem code 0
4. A2DP render endpoint creation
5. SBC AVDTP negotiation
6. Actual SBC RTP stream and audible stereo
7. LDAC vendor-specific AVDTP negotiation
8. Actual LDAC media frames and decoded/audio proof

The OPPO Enco Buds2 can pass only the SBC portion. Use a separate LDAC-capable sink for gates 7–8.

## Read next

1. [Windows 10 A2DP pipeline map](docs/agent/WIN10_A2DP_PIPELINE.md)
2. [NEXT_ACTIONS](docs/agent/NEXT_ACTIONS.md)
3. [PROJECT_STATE](docs/agent/PROJECT_STATE.md)
4. [EVIDENCE](docs/agent/EVIDENCE.md)
5. [BUILD_REGISTRY](research/BUILD_REGISTRY.md)
6. [TEST_MATRIX](research/TEST_MATRIX.md)
7. [ARTIFACT_INDEX](research/ARTIFACT_INDEX.md)
8. [DECISIONS_AND_EXPERIMENTS](docs/agent/DECISIONS_AND_EXPERIMENTS.md)

## Safety

- Physical Server 2022: read-only evidence collection only. No driver installation, device restart, BCD/security/test-signing changes, certificate changes, OS update/rollback, or installer/upgrade/rollback script execution.
- No changes to the physical host during this run.
- All future code experiments must use a separate experimental branch. Documentation changes belong only on `docs/project-source-reorg`.
- CI #248 and CI #255 are closed historical ACX results. Do not repeat them.

### Collector audit — 2026-11-23 23:40 Europe/Kyiv

The existing `Export-Win10-A2DP-Package.ps1` was read from Library (file ID `file_00000000ae6c82108239f67bdde421be`, Library ID `libfile_c5e086cd16e0819183aa8607e6c40e94`, 5,108 bytes, 95 lines). It is read-only: it searches `DriverStore\\FileRepository` and `%windir%\\INF` for the listed A2DP/AVRCP/HFP INF names, copies matching DriverStore package directories, copies `BthA2dp.sys`, records direct INF `Include/Needs`, file versions, hashes and Authenticode status, and creates a ZIP.

**Limits:** it does not search WinSxS; recursively fetch every INF named by `Include`; enumerate the complete codec/transport/provider DLL set or COM registrations; parse PE machine/imports/delay-imports/exports; or prove each SYS is a member of the copied CAT. It is a targeted package-recovery tool, not the full component-closure audit. If the common INF or CAT is absent, extend the read-only search to WinSxS before any staging.

The broader read-only `Collect-Win10-Bluetooth-A2DP.ps1` (Library file ID `file_00000000f4b08210aad8e3d4dd2e07eb`, 14,623 bytes) has `-IncludeDriverPackages` and captures wider PnP/service/registry/system-driver context. `Collect-Bluetooth-A2DP-Compare.ps1` (file ID `file_00000000187482108c2566e9f9e8147f`, 7,815 bytes) is the Win10/Server comparison collector. Neither replaces offline PE and catalog-membership analysis.
