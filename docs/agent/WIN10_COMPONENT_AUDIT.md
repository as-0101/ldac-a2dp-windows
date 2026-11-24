# Windows 10 Bluetooth A2DP component audit

**Updated:** 2026-11-24 05:20 Europe/Kyiv  
**Scope:** Windows 10 22H2 A2DP source package → Windows Server 2022 build 20348.5761.  
**Execution status:** static research only. No build, CI run, driver installation, device restart, or physical-host mutation was performed.

## Executive result

1. The captured Windows 10 inbox A2DP path is a **kernel-mode WDM/KS profile-driver package**, not a standalone user-mode LDAC codec DLL.
2. The Microsoft Windows 10 Classic Audio codec list is SBC and aptX Classic. It does not list LDAC or AAC. The OPPO Enco Buds2 ETE41 supports AAC/SBC, so **SBC is the only common codec** for the first milestone. These earbuds cannot negotiate LDAC; LDAC testing needs a different sink that advertises LDAC.
3. The 2026-11-23 23:49 Win10 package archive already contains the common A2DP INF, source/sink INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys. Do not rerun the collector or ask for the same archive.
4. The absence of a package-local .cat is not evidence that the inbox package is unsigned: the captured system-supplied INFs have no CatalogFile directive, and Microsoft documents that system-supplied INFs are validated using system catalogs. The source catalog identity and component-store ownership still need to be recovered for cross-SKU staging.
5. The recorded Server 2022 inventory already has the generic audio dependencies (ks.inf, wdmaudio.inf and the referenced MSSysFx DLLs), while the A2DP profile package is absent from that archived comparison. This is consistent with Server's documented lack of in-box Bluetooth support, but does not prove that the Windows 10 profile binaries are technically incompatible.
6. Alternative A2DP Driver is the only located off-the-shelf Windows product that explicitly adds LDAC to the inbox Bluetooth stack. It is proprietary, hardware-licensed, its EULA restricts reverse engineering/modification/transfer, and its published support matrix is Windows 10/11—not Server 2022. It is **not** a legal binary-transplant candidate without vendor authorization.
7. The existing as-0101 repository is a fork of yariktop133/ldac-a2dp-windows, a separate open-source replacement-driver project. It is not a Windows 10 codec DLL package. Its ACX/WDK path remains parked.

## 1. Existing source artifacts — already present

| Artifact | Library file ID | Size | Use |
| --- | --- | ---: | --- |
| Win10-A2DP-Package-20261123-234936.zip | file_00000000144c8210a8e309fe18b9e8c4 | 454,831 bytes | Current Win10 package capture; supersedes the earlier partial comparison |
| Win10-A2DP-DriverStore-20261123-234936.zip | file_00000000b3888210bd459ae2490c25d9 | 135,772 bytes | DriverStore package copy |
| a2dp_pe_imports_report(2).txt | file_0000000033e482109479f740ed5a8030 | 8,098 bytes | PE imports for a separate System32 BthA2dp copy |
| a2dp_pe_imports_report(3).txt | file_000000008d708210bada16b6cb44c429 | 8,098 bytes | Duplicate/cross-check report for the System32 copy |
| a2dp_pe_imports_report.txt | file_00000000f33882109a6b1f79c3aaf72d | 1,315,472 bytes | Broader PE import report |
| 00-33.txt | file_000000004d5882109961f477df8a1c48 | 29,125 bytes | INF inspection output |
| 00-34.txt | file_000000004c208210bec65c68b97e9b69 | 5,564 bytes | INF dependency/section inspection output |
| Export-Win10-A2DP-Package.ps1 | file_00000000ae6c82108239f67bdde421be | 5,108 bytes | Existing read-only exporter; its output already exists |

The archive MANIFEST identifies AS-KRM-WIN10, build 19045, capture time 2026-11-23 23:49. The archive contains 31 entries and no .cat files. Its raw ZIP bytes are retained in Project Sources/Library; the current analysis workspace exposes the extracted text reports but not a raw-byte materialization path for those Project files. No re-upload of the existing archive is required.

## 2. Exact INF and driver graph

### A2DP source role — the direction needed for earbuds

The remote OPPO device advertises the A2DP Sink service (UUID 0x110B). The captured source INF matches the corresponding BTHENUM service node:

~~~text
BTHENUM\{0000110B-0000-1000-8000-00805F9B34FB}
    -> microsoft_bluetooth_a2dp_src.inf
        -> microsoft_bluetooth_a2dp.inf (common install)
~~~

The sink INF is for the reverse direction (the Windows host acting as an A2DP sink for a remote source); it is not required for playback to earbuds.

### Common INF closure

The captured microsoft_bluetooth_a2dp.inf is Class=MEDIA, DriverVer 10.0.19041.4355, x64-only (NTamd64). Its Include/Needs closure is:

~~~text
Include = ks.inf, wdmaudio.inf, BtaMpm.inf
Needs   = KS.Registration,
          WDMAUDIO.Registration,
          BtaMPM.CopyFilesOnly,
          mssysfx.CopyFilesAndRegister
~~~

It copies BthA2dp.sys, registers the BthA2dp kernel service as demand-start (StartType=3, ServiceBinary=%12%\\BthA2dp.sys), and registers KSCATEGORY_AUDIO source/sink interfaces plus endpoint properties.

The separate btampm.inf is Class=SYSTEM, DriverVer 10.0.19041.5848, x64-only. Its BtaMPM.CopyFilesOnly section copies BtaMPM.sys to System32\\drivers. The INF explicitly exists to satisfy external Include/Needs references; it is not a separate PnP device-install section.

### Audio and COM/ APO boundary

- ks.inf and wdmaudio.inf provide the Kernel Streaming/WDM audio registration.
- mssysfx.CopyFilesAndRegister copies/registers WMALFXGFXDSP.dll and SysFxUI.dll.
- The MSFX/FX property registrations are Windows audio-effect/APO registrations. Microsoft describes APOs as user-mode COM objects that process audio effects. They are not A2DP codec providers and are not LDAC encoders.
- No LDAC CLSID, codec-provider interface, or user-mode LDAC DLL was identified in the captured Microsoft A2DP INFs or PE reports.
- The A2DP profile is selected by PnP/INF matching. The profile driver communicates with the Bluetooth port stack through the documented driver/IRP path; BthPort is not expected to appear as a normal PE import from BthA2dp.sys.
- The audio endpoint is exposed through the KS audio interface and consumed by the Windows audio endpoint/audio-engine path. This is distinct from the Bluetooth transport and distinct from the codec implementation.

## 3. Binary inventory and provenance

| File/copy | Version | Size | SHA-256 | PE / imports | Status |
| --- | --- | ---: | --- | --- | --- |
| DriverStore BthA2dp.sys | 10.0.19041.4355 | 282,624 | 5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3 | PE32+ x64, native kernel; direct imports reported from ntoskrnl.exe only; no delay-import directory in E-119 | Package copy; export table not captured |
| System32 BthA2dp.sys | 10.0.19041.1 (secondary public corroboration; exact hash match not proven) | 279,040 | 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737 | PE32+ x64; 8 import descriptors / 144 imported functions | Different, older binary; do not merge with DriverStore report |
| BtaMPM.sys | 10.0.19041.5848 | 43,008 | DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD | PE32+ x64; imports ntoskrnl.exe, cng.sys and WppRecorder.sys; no delay-import directory in E-120 | Multi-profile management dependency, not codec |

Secondary public Windows 10 driver inventories list a 279,040-byte BthA2dp.sys as version 10.0.19041.1, dated 2019-12-06/07. This matches the System32 copy's size, but those sources do not publish the 0442... SHA-256; therefore the hash-to-version mapping remains provisional. A separate Windows 10 DriverStore inventory corroborates btampm.inf 10.0.19041.5848, microsoft_bluetooth_a2dp.inf 10.0.19041.4355 and the source/sink INFs 10.0.19041.1.

The System32 BthA2dp copy imports from:
- ntoskrnl.exe — 70 functions
- HAL.dll — 1
- ks.sys — 40
- btampm.sys — 10
- WppRecorder.sys — 4
- SleepStudyHelper.sys — 8
- WDFLDR.SYS — 4
- ksecdd.sys — 7

That report is explicitly for C:\\A2DP-Research\\Win10\\Windows\\System32\\drivers\\BthA2dp.sys. It is not the 282,624-byte DriverStore copy. The package copy's E-119 import report and the System32 copy's 8-descriptor report must remain separate until the exact source paths, VERSIONINFO and catalog membership are reconciled. The package copy's much smaller direct import closure (ntoskrnl only) is a promising compatibility lead, but does not rule out dynamic dependencies or INF/KS/MSSysFx requirements.

The System32 BthA2dp copy imports BtaMpm functions such as GetRemoteDeviceProfileVersionAndAttribute, UpdatePlayStatus, Register/Unregister, UpdateSuspendStatus, RegisterPnp/UnregisterPnp and UpdateConnectionStatus. These are profile/control-management operations, not codec encode/decode entry points.

### What is still not proven at PE level

- Export tables for BthA2dp.sys and BtaMPM.sys have not been captured.
- The package-copy import report is static; it does not prove whether a component is loaded dynamically through another mechanism.
- The System32 copy's delay-import directory and full PE header OS-version fields have not been reconciled with the package copy.
- No API-set imports were reported for the package-copy kernel drivers; a complete Dependencies/PEInspector pass is still pending.
- The exact Microsoft system catalog that covers the source INF/SYS files has not been identified from the original image.
- Import resolution against the exact Server 2022 20348.5761 kernel and dependency exports has not been performed.

## 4. Windows Server 2022 comparison — archived evidence only

The recorded Server 2022 build 20348.5761 comparison found:
- ks.inf and wdmaudio.inf present.
- WMALFXGFXDSP.dll and SysFxUI.dll present at version 10.0.20348.5756.
- The Microsoft A2DP source/common INF package and BthA2dp/BtaMPM components absent from the captured Server inventory.
- Generic BTHENUM handling in bth.inf is not the same as the A2DP profile-driver binding.

Microsoft's support matrix says Windows 10 SKUs have in-box Bluetooth support and Windows Server SKUs do not. That is product-support policy, not proof that a Windows 10 A2DP binary cannot load on Server 2022.

The last recorded physical-host PnP state is the custom LDAC A2DP Project driver, not the Microsoft or Realtek package: the present BTHENUM A2DP Sink node (UUID 0x110B, LOCALMFG&0002 identifying the local Intel Bluetooth radio—not the remote OPPO earbuds) is bound to oem75.inf, provider LDAC A2DP Project, service LdacA2dp, section LdacA2dp_Device.NT, DriverVer 0.2.325.1600. The node is present and enumerated, but driver start fails with Code 37 / ProblemStatus 0xC000000D. This is a failure of the project's custom driver start path; it is not a test of the Windows 10 Microsoft BthA2dp package. The record is historical, not a fresh live check from this run. No physical-host command was run.

The archived Server environment report also records bthserv, Audiosrv and AudioEndpointBuilder running; BTAGService and BthAvctpSvc are not installed. BTAGService is the HFP/audio-gateway path (out of scope); BthAvctpSvc is the AVCTP/AVRCP control path and is not evidence that the core A2DP audio stream is unavailable. Core bthport.sys, bthusb.sys, bthenum.sys and bthmini.sys files are present; btha2dp.sys is not found in System32\\drivers. ibtusb.sys is also not found at that path, although multiple ibtusb.inf packages are in DriverStore, so the active radio miniport is not established by this report.

A DriverStore folder rtka2dp.inf_amd64_0fd0faf5e73b2466 is present, but the A2DP_INF_Investigation report has an empty A2DP INF FILES section and does not capture its INF bytes/version. Microsoft defines LOCALMFG as the manufacturer of the local Bluetooth radio. Bluetooth SIG company ID 0x0002 is Intel; 0x005D is Realtek. Public Realtek catalogs identify the legacy rtka2dp.inf package with BTHENUM IDs ending LOCALMFG&005D, so it targets Realtek local radios and does not match this host's Intel LOCALMFG&0002. The current OPPO A2DP service node is bound to the custom oem75.inf package, not rtka2dp.inf. Treat the Realtek folder as an unverified leftover/reference package, not as the current driver or an LDAC candidate.

## 5. Codec reality and existing LDAC candidates

### Microsoft inbox stack

Microsoft's Windows 10 Classic Audio documentation lists SBC and aptX Classic. It does not list LDAC or AAC. Therefore the Windows 10 inbox A2DP package is a valid SBC/aptX transport/profile candidate, but not a source of an LDAC encoder DLL.

For an A2DP source, the host needs an encoder; the remote earbuds perform decoding. A separate host-side LDAC decoder is not required for the transmit path.

### OPPO Enco Buds2

OPPO's official specification lists AAC and SBC. It does not list LDAC. Use these earbuds for the SBC milestone; do not use them to validate LDAC negotiation or LDAC audio.

### Alternative A2DP Driver

BluetoothGoodies' Alternative A2DP Driver publicly advertises LDAC and other codecs, with version 1.8.3 dated 2026-06-22 and a published support matrix of Windows 10 22H2 / Windows 11 21H2–25H2. The project record separately notes a 1.8.3.1 driver on another Windows 11 laptop.

The vendor EULA states that the license is hardware-bound/non-transferable and restricts reverse engineering, decompilation, disassembly, modification and transfer, except where applicable law overrides. Its Additional Terms list AOSP as an OSS component, but do not identify the bundled files; that OSS exception does not grant rights to the proprietary AltA2DP driver. The project already has its own AOSP libldac source. Do not extract, patch, transplant or reverse-engineer the proprietary driver. It is not a supported Server 2022 package. A black-box, as-is test would require an appropriate license and explicit vendor confirmation of Server support.

### Existing open-source repository

The as-0101/ldac-a2dp-windows repository is a fork of yariktop133/ldac-a2dp-windows and is one upstream commit behind. The upstream project is a complete replacement A2DP source implementation (driver/protocol/encoder service), not a pre-existing Windows 10 codec DLL. The current code path remains frozen; no ACX/WDK work is authorized as the next step.

## 6. Next actions — ordered, minimal

1. Obtain the original Windows 10 22H2 and Server 2022 install.wim/install.esd metadata (or the corresponding mounted image/component stores). No ISO/WIM/ESD/CAB/MSU media was found in the current Library inventory.
2. From those images, identify the exact CBS package/component identities, MUMs, manifests, system catalogs, architecture and applicability for microsoft_bluetooth_a2dp_src.inf, microsoft_bluetooth_a2dp.inf and btampm.inf. Determine whether the same component is present but disabled/omitted in Server 2022, or is client-only.
3. Reconcile the two BthA2dp.sys copies by full path, file version, SHA-256 and catalog membership. Re-run the PE audit against the exact DriverStore package copy and BtaMPM.sys.
4. Use the existing Dependencies tool for direct/forwarded/delay-load imports, exports and API-set resolution; use PEInspector or pefile as a second static cross-check. Dependencies does not detect arbitrary runtime LoadLibrary calls, so static analysis is not the whole runtime story.
5. Compare every imported function against exports from the exact Server 2022 20348.5761 ntoskrnl, HAL, KS, CNG, WPP, WDF and security components.
6. Only if the original package and dependencies are compatible, test the unmodified inbox package in a disposable Server 2022 VM. Do not touch the physical server.
7. Keep runtime gates separate: service start → BTHENUM device enumeration → profile-driver load → A2DP render endpoint → SBC negotiation → actual stereo audio. LDAC negotiation and actual LDAC audio require a different LDAC-capable sink.

## 7. Safety and scope

- No physical server install, device restart, BCD/security/test-signing change, certificate change, OS update/rollback or driver rollback.
- No execution of prepare-oppo-host.cmd, upgrade-oppo.cmd, install-oppo.cmd or rollback-oppo.cmd.
- No HFP/microphone work.
- No new ACX bind-probe. CI #248 and #255 remain closed evidence, not a reason to repeat ACX experiments.
- No code changes in this audit. Documentation only on docs/project-source-reorg; Notion journal append-only.
- No runtime test was performed, and no successful A2DP endpoint/audio/LDAC claim is made.

## Sources

- [Microsoft — Bluetooth Classic audio](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-classic-audio)
- [Microsoft — Using the Bluetooth driver stack](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack)
- [Microsoft — Bluetooth support in previous Windows versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions)
- [Microsoft — INF Version section and system-supplied catalogs](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-version-section)
- [Microsoft — Audio Processing Object architecture](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/audio-processing-object-architecture)
- [Microsoft — Bluetooth device PnP IDs and LOCALMFG](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/installing-a-bluetooth-device)
- [Bluetooth SIG — Assigned company identifiers](https://www.bluetooth.com/wp-content/uploads/Files/Specification/HTML/Assigned_Numbers/out/en/index-en.html)
- [OPPO — Enco Buds2 specifications](https://www.oppo.com/uk/accessories/enco-buds2/specs/)
- [BluetoothGoodies — Alternative A2DP Driver version history](https://www.bluetoothgoodies.com/a2dp/version-history/)
- [BluetoothGoodies — Alternative A2DP Driver EULA](https://www.bluetoothgoodies.com/a2dp/eula/)
- [Dependencies — open-source PE dependency analysis](https://github.com/lucasg/Dependencies)
- [Upstream LDAC A2DP Windows project](https://github.com/yariktop133/ldac-a2dp-windows)


## 8. Strategy correction — codec ownership and ready alternatives (2026-11-24 02:19)

### 8.1 Windows 10 has no inbox LDAC binary to transplant

Microsoft's [Classic Audio codec table](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-classic-audio) lists SBC and aptX Classic for Windows 10; AAC is Windows 11-only and LDAC is not listed. The captured package therefore remains a candidate for the SBC milestone, not a source of an LDAC DLL.

Microsoft's [Bluetooth stack documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/using-the-bluetooth-driver-stack) describes a PnP-loaded profile driver selected through INF matching and communicating with `BthPort.sys` through WDM IRPs and BRBs. The captured source/common INF installs `BthA2dp.sys`; `BtaMPM.sys` is profile/multiprofile management. The `mssysfx` APO registration path is for audio effects and is not an LDAC codec provider.

A public PDB symbol index for the older `BthA2dp.sys` 10.0.17763.168 build exposes internal `A2dpSbcCodec` and `AptXCodec` classes and AVDTP code, with no `Ldac` string in 997 named symbols. This is useful architecture corroboration only; it is not the PDB for the captured 10.0.19041.4355 DriverStore binary and must not be used as an exact symbol map for that file.

### 8.2 Existing LDAC source in this repository

The `server-2022-oppo` branch already vendors AOSP `external/libldac` at upstream commit `eeee1a3f` (import recorded in [commit 95bb928](https://github.com/as-0101/ldac-a2dp-windows/commit/95bb92866b0d77de20ee94694eb4be2979635947)). CMake builds `ldacBT_enc` and `ldacBT_abr` as static libraries; `service/encoder.cpp` calls the AOSP APIs. This is an existing encoder source, not a Windows 10 DLL, not a Microsoft A2DP provider and not a transport by itself.

The vendored NOTICE states that certification is required to use LDAC in products. Sony's [AOSP page](https://www.sony.net/Products/LDAC/aosp/) provides a corporate licensing inquiry. Keep a local technical proof separate from any product-distribution/certification decision.

### 8.3 PE parser correction

The legacy `pe_imports_a2dp.py` has a parser defect and its 1.3 MB report is invalid. Library contains `pe_imports_a2dp_fixed.py` (file ID `file_000000006ac88210b1f6b3d695278455`), which advances IMAGE_IMPORT_DESCRIPTOR by 20 bytes. Reports (2)/(3) are byte-identical and describe the separate 279,040-byte System32 copy, not the 282,624-byte DriverStore package copy. The fixed script reports direct imports only; use the repository `tools/research/audit_pe_binary.py` for exports, delay imports, VERSIONINFO and API-set data on exact UUP-extracted binaries.

### 8.4 Existing user-mode LDAC alternative: BlueCaster

[BlueCaster v3.0.4](https://github.com/SeiyaFunaokaJP/BlueCaster/releases/tag/v3.0.4), published 2026-11-23, advertises LDAC 330/660/990 kbps and implements A2DP using BTstack+WinUSB in user mode. It bypasses the Windows Bluetooth stack and requires a USB Bluetooth adapter assigned to WinUSB. Its published requirements are Windows 10 22H2 or Windows 11; Server 2022 is not listed. Its README states that distributed programs include BTstack under a personal/non-commercial license unless separately licensed. This is a possible later disposable-VM alternative, not a plug-in DLL and not an approved physical-host action.

### 8.5 Corrected decision and next gate

1. Do not search for a Microsoft inbox LDAC DLL or attempt to register MSSysFx/APO DLLs as codecs.
2. Keep the captured Win10 Microsoft package as the minimal SBC candidate.
3. Re-run the exact DriverStore `BthA2dp.sys` and `BtaMPM.sys` static audit with a retained parser, then resolve imports against the exact Server 20348.5761 exports.
4. Continue official WIM/CBS/system-catalog provenance work. No cross-SKU staging before package ownership and applicability are known.
5. Test only in a disposable Server 2022 VM and report service, enumeration, driver load, endpoint, SBC negotiation and actual audio as separate gates.
6. For LDAC, use a different sink. Evaluate BlueCaster only after SBC and after Server/WinUSB/licensing constraints are resolved.

No build, CI, install, runtime test, physical-host query or physical-host mutation was performed in this update.


### 8.6 Microsoft public symbol-index hash cross-check

Winbindex's x64 hash-only pages independently list all three exact hashes already recorded from the Win10 archive/inventory:

- DriverStore `BthA2dp.sys`, 282,624 bytes, version 10.0.19041.4355, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`: [hash page 5f](https://winbindex.m417z.com/hashes/5f.html).
- Separate System32 `BthA2dp.sys`, 279,040 bytes, SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`: [hash page 04](https://winbindex.m417z.com/hashes/04.html).
- `BtaMPM.sys`, 43,008 bytes, version 10.0.19041.5848, SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`: [hash page da](https://winbindex.m417z.com/hashes/da.html).

Winbindex's [README](https://github.com/m417z/winbindex) says its full download links target Microsoft's public symbol server (msdl.microsoft.com). The simplified pages establish hash presence only; they do not expose file version, PE timestamp/virtual size, OS/update identity or catalog membership. The full metadata/download URL is still needed before a reproducible public-symbol retrieval can replace the inaccessible Project Source archive bytes.


### 8.7 Server 2022 Bluetooth support-scope nuance

Do not overread the phrase "no in-box Bluetooth". Microsoft's [previous-Windows support page](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions) explicitly says all Windows Server SKUs lack in-box Bluetooth wireless technology support, while third-party IHV Bluetooth drivers may be available. The same page lists A2DP 1.3.2 and AVDTP 1.3 as Windows 10 in-box profiles; it does not list Server profiles.

Separately, Microsoft's [Bluetooth component guidelines](https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/bluetooth) list QD ID 130847 for Windows Server 2022 as a **Host Subsystem** qualification (the same QD ID is listed for Windows 10 22H2). This is not evidence that the Server SKU ships the Bluetooth host stack or A2DP profile in-box, so it does not contradict the previous-Windows support page.

For this project, keep the Server layers separate:
1. Vendor radio/transport driver and any third-party host stack installed on the machine.
2. Microsoft Bluetooth core/host-subsystem interfaces (`BthPort`, HCI/L2CAP/SDP/BRBs) that a profile driver may communicate with.
3. The A2DP profile package (`BthA2dp.sys` plus its INF/management/audio registrations), which is the specific missing in-box feature being investigated.

A radio enumerating or a host-subsystem qualification existing does not prove that an A2DP render endpoint or SBC codec is installed. Use the archived read-only host inventory for context; do not mutate the physical Server.


## 2026-11-24 package audit update

CI #463 confirms that the A2DP component payloads in KB5036979 and KB5126657 are PSF forward-delta files, not complete PE binaries. The extracted payload sizes (11,840 / 15,766 bytes for BthA2dp and 7,952 bytes for BtaMPM) fail the PE DOS-header check. The INF/component versions are still useful package-membership evidence.

The Server 2022 KB5126655 scan found core Bluetooth packages but no A2DP INF/SYS or BtaMPM references. This makes the client A2DP profile package the concrete component gap to investigate; it does not justify a new driver or ACX experiment.

Winbindex symbol-server downloads are rejected as exact targets because all three hashes differed from the captured archive and the returned file versions were 19041.6392 / 19041.1030 / 19041.7660 rather than 19041.4355 / 19041.1 / 19041.5848. See WIN10_UUP_IMAGE_AUDIT.md.


## 2026-11-24 package audit update

CI #463 confirms that the A2DP component payloads in KB5036979 and KB5126657 are PSF forward-delta files, not complete PE binaries. The extracted payload sizes (11,840 / 15,766 bytes for BthA2dp and 7,952 bytes for BtaMPM) fail the PE DOS-header check. The INF/component versions are still useful package-membership evidence.

The Server 2022 KB5126655 scan found core Bluetooth packages but no A2DP INF/SYS or BtaMPM references. This makes the client A2DP profile package the concrete component gap to investigate; it does not justify a new driver or ACX experiment.

Winbindex symbol-server downloads are rejected as exact targets because all three hashes differed from the captured archive and the returned file versions were 19041.6392 / 19041.1030 / 19041.7660 rather than 19041.4355 / 19041.1 / 19041.5848. See WIN10_UUP_IMAGE_AUDIT.md.

## 2026-11-24 05:20 — corrected parser and static compatibility lead

### Parser correction

Library contains `pe_imports_a2dp_fixed.py` (file ID `file_000000006ac88210b1f6b3d695278455`). It advances IMAGE_IMPORT_DESCRIPTOR by 20 bytes. Reports (2)/(3) are byte-identical and analyze the 279,040-byte System32 BthA2dp copy (SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`), not the 282,624-byte DriverStore copy. The fixed script parses direct imports only. The repo `tools/research/audit_pe_binary.py` parses headers, VERSIONINFO, direct/delay imports, exports, API-set names and optional import-to-export comparison.

### Candidate import closure from CI #463 — not exact target binaries

| File | Candidate version | Candidate SHA-256 | Captured SHA-256 |
|---|---|---|---|
| DriverStore BthA2dp.sys | 10.0.19041.6392 | `3d026ae46f46c2323e9e70b194f1fb5eb32974c42c4fd1f9a24e44214dafd4ec` | `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3` |
| BtaMPM.sys | 10.0.19041.7660 | `7e9c0cfcf073d501fe4cbdf632fc9f3a22c088abaccc73f9735a603a4c9951dd` | `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD` |

Candidate BthA2dp imports 75 symbols from ntoskrnl, 40 from ks, 10 from BtaMPM, 4 from WppRecorder, 1 from HAL, 8 from SleepStudyHelper, 4 from WDFLDR and 7 from ksecdd. Companion BtaMPM exports all 10 required symbols; its 42 imports (37 ntoskrnl, 1 cng, 4 WppRecorder) resolve against available later Server 20348.5866 exports.

129/149 BthA2dp imports resolve against that later Server reference set plus companion BtaMPM. The remaining 20 are untested because HAL.dll, SleepStudyHelper.sys, WDFLDR.SYS and ksecdd.sys were omitted from the Server reference directory. They are not known missing. Server 20348.5866 is later than target 20348.5761, and the Win10 candidates do not match the captured versions. This is not a compatibility pass.

### INF/package-level transplant hypothesis

The common INF is Class=MEDIA, DriverVer 10.0.19041.4355:
- `Include = ks.inf, wdmaudio.inf, BtaMpm.inf`
- `Needs = KS.Registration, WDMAUDIO.Registration, BtaMPM.CopyFilesOnly, mssysfx.CopyFilesAndRegister`
- `AddService = BthA2dp`: `ServiceType=1`, `StartType=3`, `ServiceBinary=%12%\BthA2dp.sys`
- `AddInterface=KSCATEGORY_AUDIO` for A2DP source and sink interfaces.

The archived Server comparison already contains ks.inf, wdmaudio.inf, WMALFXGFXDSP.dll and SysFxUI.dll. The likely missing profile-specific closure is the A2DP source/common INF plus BthA2dp.sys and BtaMPM/INF. This remains a package-level hypothesis pending exact UUP, registry and catalog checks.

### Existing LDAC implementations checked

BlueCaster is user-mode BTstack+WinUSB, takes over a USB radio and has no Server 2022 support claim; its BTstack license is personal/non-commercial. OpenA2DP is pre-alpha; its kernel drivers have not been built with WDK or run against a headset. The project's AOSP libldac remains a static encoder library in the existing service, not a Windows 10 A2DP provider DLL.

### Version-specific import surface — important correction

The exact captured DriverStore BthA2dp 10.0.19041.4355 (282,624 bytes, SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`) is reported by E-119/GNU objdump to import directly from `ntoskrnl.exe` only. Do not confuse it with the separate 279,040-byte System32 copy (8 descriptors / 144 imports) or the non-exact 19041.6392 symbol-server candidate (8 descriptors / 149 imports). Import closure changes across versions; the exact package binary still needs revalidation with the retained full parser.

The exact captured BtaMPM 10.0.19041.5848 (43,008 bytes, SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`) is the 3-descriptor / 42-import file shown in reports (2)/(3). Its direct imports are ntoskrnl.exe (37), cng.sys (1) and WppRecorder.sys (4). The 19041.7660 symbol-server candidate has the same import DLL set/count but a different hash; its export table is not proof of the exact 19041.5848 export table. Exact BtaMPM exports must be obtained from the matching UUP image.

### Official LDAC implementation boundary

Sony's own support article (E-158) states that Windows and macOS do not provide system-level LDAC support, independent of the Bluetooth controller. Therefore the search for a Microsoft/Sony inbox LDAC provider DLL in Windows 10 has a negative result. The Windows 10 inbox A2DP package is still useful for SBC/aptX; LDAC requires a third-party A2DP implementation or an alternate user-mode Bluetooth transport. Do not confuse a codec library such as AOSP `libldac` with a Windows A2DP provider.

### Exact BtaMPM import closure cross-check

The exact captured BtaMPM 10.0.19041.5848 report (SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`) lists 42 imports: 37 ntoskrnl, 1 cng (`SystemPrng`) and 4 WppRecorder. The exact import-name set matches the later 19041.7660 symbol-server candidate; all 42 names are present in the available Server 20348.5866 export reference. Exact Server 20348.5761 export confirmation and the exact 19041.5848 BtaMPM export table remain pending.

## UUP audit harness correction — 2026-11-24 06:16

The first exact-image attempt (run #3 / 45317582562) failed before mounting the image because the selected DISM image object did not expose a `Version` property. This does not change the component map or establish any binary incompatibility.

The corrected experiment now verifies image identity from a copied offline SOFTWARE hive (CurrentBuild.UBR and EditionID), adds the previously omitted HAL/SleepStudyHelper/WDFLDR/ksecdd references, and in its latest revision includes the Win10 BtaMPM.sys companion when resolving BthA2dp imports. Runs #4 / 45325486392 and #5 / 45325586394 were still in progress at the last check. Exact PE, catalog and registry conclusions remain pending.

## Server 2022 A2DP profile-binding gap — 2026-11-24

The archived INF comparison now isolates a smaller package-level delta than the previous broad stack hypothesis:

- Server 20348 `bth.inf` maps BTHENUM Audio Sink UUID 0x110B to `BthGenericService` with a `_GENERIC` hardware-ID suffix. The generic service section installs a null associated service and sets `GenericDriverInstalled`; it does not create the dedicated BthA2dp service.
- Win10 `microsoft_bluetooth_a2dp_src.inf` matches the base remote A2DP Sink UUID 0x110B and chains through `microsoft_bluetooth_a2dp.inf` to `Common_BthA2dp_Install`.
- The common INF copies BthA2dp.sys, installs the demand-start BthA2dp kernel service and registers KSCATEGORY_AUDIO source/sink interfaces, while reusing KS/WDMAUDIO/BtaMPM/MSSysFx registrations.

This makes the Win10 source/common INF plus its exact binaries the first minimal adaptation candidate. It does **not** yet prove that the binary loads on Server 20348.5761 or that the package is signed/applicable. Exact PE exports/imports, CAT/CBS ownership, rank and disposable-VM staging are still required. Preserve Server's existing BthPort/BthEnum/radio core; no new Bluetooth driver is justified by this evidence.
