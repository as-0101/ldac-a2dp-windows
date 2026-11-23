# Windows 10 Bluetooth A2DP pipeline and Server 2022 adaptation

**Snapshot:** 2026-11-23 22:36 Europe/Kyiv  
**Scope:** A2DP stereo source only. HFP/microphone is out of scope.

## Executive conclusion

The minimal first-milestone route is to recover and test the **complete signed Windows 10 Microsoft A2DP source package** on a disposable Windows Server 2022 VM. The current Windows 10 capture contains the profile binding INF and `BthA2dp.sys`, but not the common INF and catalog. Do not stage or copy the partial package.

There is **no Microsoft inbox LDAC codec in Windows 10**. Microsoft's documented Windows 10 A2DP codec set is SBC and classic aptX; AAC is listed for Windows 11, not Windows 10, and LDAC is not listed. OPPO Enco Buds2 (ETE41) advertises AAC/SBC only. Therefore the only common codec for the first milestone is **SBC**. Enco Buds2 cannot validate LDAC negotiation or LDAC audio; that later milestone needs a separate LDAC-capable receiver.

## 1. Windows 10 reference facts

Reference machine: `AS-KRM-WIN10`, Windows 10 x64, build 19045.

| Item | Captured value | Status |
|---|---|---|
| A2DP service UUID | `0000110B-0000-1000-8000-00805F9B34FB` | Present |
| Profile binding INF | `microsoft_bluetooth_a2dp_src.inf` | Present; thin source/profile binding |
| Source INF version | `10.0.19041.1` | Recorded |
| Kernel profile driver | `BthA2dp.sys` | Present |
| `BthA2dp.sys` version | `10.0.19041.4355` | Recorded |
| `BthA2dp.sys` size | `282,624` bytes | Recorded |
| `BthA2dp.sys` SHA-256 | `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3` | Recorded |
| Common INF | `microsoft_bluetooth_a2dp.inf` | **Missing from current capture** |
| Package catalog (.cat) | Matching catalog | **Missing from current capture** |
| Complete Include/Needs chain | Source INF delegates to common INF; prior capture notes KS/WDMAudio/BtaMpm references | Incomplete |

The source INF is not a self-contained package. Its `Include` / `Needs` relationship delegates installation to `microsoft_bluetooth_a2dp.inf`. The missing common INF and catalog are a hard stop for package installation. Exact common INF sections, service registrations, catalog membership, and package file list must be recovered first.

The Win10 collector's Kernel-Drivers inventory reports demand-start kernel drivers as Stopped/Manual at snapshot time. This does not negate the signed PnP A2DP devnode record; do not claim `BthA2dp` was Running from that CSV.

## 2. Microsoft Bluetooth stack: component responsibilities

Microsoft documents a PnP-loaded Bluetooth profile-driver model. Profile drivers are selected through device IDs and INF matching and communicate with `BthPort.sys` through WDM requests / Bluetooth Request Blocks. This is not a user-mode codec-DLL plug-in model.

| Layer | Known components / registrations | Responsibility | Still to prove |
|---|---|---|---|
| Radio / transport | Vendor radio miniport; `BthUSB.sys` or vendor USB transport; `BthMini.sys` | Hardware-specific HCI transport | Exact Win10-to-Server binary compatibility |
| Core Bluetooth stack | `BthPort.sys`, `BthEnum.sys`, `BthLEEnum.sys`, `BthServ` service | HCI/L2CAP core and enumeration | Exact package dependencies for this A2DP source |
| A2DP profile enumeration | BTHENUM Audio Sink UUID `0x110B` | Creates the remote A2DP service devnode | Server currently binds this through a generic placeholder |
| A2DP source profile | `BthA2dp.sys`, service registration from `microsoft_bluetooth_a2dp_src.inf` | Microsoft A2DP profile / transport | Exact internal codec implementation and PE imports |
| Common A2DP/audio registration | `microsoft_bluetooth_a2dp.inf`; captured references include `ks.inf`, `wdmaudio.inf`, `BtaMpm.inf` | Shared installation sections and audio-class registration | Common INF missing; exact sections/service order unverified |
| Kernel audio / KS | `ks.sys`, `portcls.sys`, `wdmaud.drv`, observed `BtaMpm.sys` candidate | Kernel Streaming / audio miniport path | Exact A2DP package membership and dependency edges |
| Windows audio endpoint | `AudioEndpointBuilder`, `AudioSrv`, `audioeng.dll`, `MMDevAPI.dll` | Exposes render endpoint and routes PCM | Server endpoint creation not tested |
| AVRCP control | `BthAvctpSvc`, `Microsoft.Bluetooth.AvrcpTransport.sys`, related AVCTP components | Play/pause/metadata/remote control | Not required for basic A2DP stereo |
| HFP / microphone | `BthHfEnum.sys`, `BthHfAud.sys`, gateway services | Hands-free profile and microphone | Explicitly out of scope |

The existing collectors target the core Bluetooth/audio binaries above, including `BthPort.sys`, `BthEnum.sys`, `BTHUSB.sys`, `BthA2dp.sys`, `BtaMpm.sys`, `ks.sys`, `portcls.sys`, `wdmaud.drv`, `AudioEndpointBuilder.dll`, `AudioSrv.dll`, `audioeng.dll`, and `MMDevAPI.dll`. This is an inventory target list, not a final dependency graph. The common INF, CAT, PE imports, and runtime load trace are required to establish exact edges.

### Load sequence

1. The Bluetooth bus enumerates the remote `0x110B` service as a BTHENUM devnode.
2. PnP matches the devnode to the profile INF. On the Windows 10 reference this is `microsoft_bluetooth_a2dp_src.inf`; the Server 2022 snapshot currently shows a generic `bth.inf` placeholder.
3. PnP installs/starts the profile driver service (`BthA2dp`) on demand. The profile driver communicates with `BthPort.sys`; it is not a DLL loaded by `bthserv`.
4. The profile driver's audio/KS registrations allow AudioEndpointBuilder to expose a render endpoint. The Windows audio engine then supplies PCM.
5. A2DP codec negotiation occurs in the Bluetooth profile path. Public Microsoft documentation does not identify a supported third-party codec-provider DLL interface. Do not assume an LDAC DLL can be injected into `BthA2dp.sys`.

## 3. Microsoft codecs versus third-party LDAC

### Microsoft inbox stack

- Windows 10: SBC and classic aptX.
- Windows 10: AAC is not listed as supported by the built-in stack.
- Windows 11: AAC is listed; LDAC is not listed as a built-in codec.
- No Microsoft inbox LDAC encoder DLL/provider has been identified.

### OPPO Enco Buds2

OPPO's official specification for model ETE41 lists Bluetooth codecs `AAC/SBC`. It does not list LDAC. With Windows 10's built-in A2DP stack, SBC is the common codec. A successful SBC stream is a valid first milestone, not evidence of LDAC support.

### Existing LDAC implementations found in project evidence

| Implementation | Actual component type | Function | Suitability |
|---|---|---|---|
| Repository `third_party/libldac` | AOSP source library, built as static code | Encoder API called by `service/encoder.cpp` / `ldacsvc` | Reusable encoder source, but not a Windows 10 DLL or a plug-in for `BthA2dp.sys` |
| Repository `LdacA2dp.sys` | Custom KMDF / ACX 1.1 profile driver plus user-mode service | Own AVDTP/L2CAP path | Parked; separate driver architecture, not minimal DLL adaptation |
| Alternative A2DP Driver 1.8.3.1 (Luculent) | Third-party kernel driver: `AltA2DP.sys`, INF `oem96.inf`, MEDIA class | Known from a separate Windows 11 laptop/JBL reference; negotiated LDAC | Commercial/closed-source driver, not a DLL, not present in AS-KRM-WIN10 capture; Server support unproven |
| BlueCaster | User-mode WASAPI encoder + BTstack A2DP/AVDTP/L2CAP + WinUSB adapter | Supports LDAC and SBC without Windows' built-in A2DP profile | Best ready fallback if Microsoft package path fails; published OS matrix is Windows 10 22H2 / Windows 11, not Server 2022; takes ownership of selected adapter |
| OpenA2DP | Pre-alpha custom A2DP driver project | Experimental driver-based stack | Not a ready binary; do not switch to it now |

The repository's `third_party/libldac` derives from Android Open Source Project `external/libldac`. The repository NOTICE says LDAC certification requirements are separate from the source-code license. Do not equate an Apache-licensed source tree with permission to ship a certified LDAC product.

## 4. Windows Server 2022 comparison

Windows Server 2022 build 20348 / UBR 5761 is not an officially supported in-box Bluetooth client SKU according to Microsoft's Bluetooth support matrix. Third-party IHV drivers may provide hardware support, but that does not imply the A2DP profile package is present.

The latest recorded Server evidence is the 2026-11-23 20:41 Kyiv archive, not a live query. It records:

- Core Bluetooth components and the Intel radio stack are present.
- OPPO A2DP service UUID `0x110B` is enumerated, but the node is handled by generic `bth.inf` / `BthGenericService`, not the Microsoft `BthA2dp` profile package.
- No `BthA2dp.sys` / Microsoft A2DP source package was found in the Server inventory.
- The last recorded custom target node used `oem75.inf`, driver `0.2.325.1600`, Code 37 / `0xC000000D`.

Do not claim this is the current live state; the physical server was not queried during this run. No installation, device restart, BCD/security change, certificate change, or OS change was performed.

## 5. Minimal adaptation path

1. **Recover the complete Windows 10 package.** Use the existing read-only `Export-Win10-A2DP-Package.ps1` from Library. It searches DriverStore and Windows INF locations for source/common A2DP INFs and copies package directories, catalogs, `BthA2dp.sys`, hashes, signatures, and Include/Needs metadata.
2. **Audit before staging.** Verify source/common INF versions, `DriverVer`, `NTamd64` decorations, `Include` / `Needs`, service/interface registrations, package folder contents, CAT signature, and catalog membership of each SYS. Parse each PE for machine type, version resource, imports, delay imports, exports, API-set references, and OS assumptions. Compare each dependency with the Server 2022 counterpart.
3. **Do not edit the Microsoft package yet.** Editing an INF changes catalog-covered content and invalidates the original package signature. First test the original signed package in a disposable Server 2022 VM. Do not copy only `BthA2dp.sys` or invent registry registrations.
4. **Test in order:** service start → BTHENUM enumeration → profile driver load / PnP problem code 0 → A2DP render endpoint → SBC AVDTP negotiation → actual RTP media stream and audible stereo.
5. **Only after SBC passes**, test LDAC using an LDAC-capable sink. Enco Buds2 cannot be used for that stage. Require observed LDAC vendor-specific AVDTP configuration and real LDAC media frames; endpoint presence alone is not proof.
6. If the original package is blocked by an OS decoration or dependency, identify the exact blocker and propose one minimal change. Any INF/catalog/signing experiment belongs only in a disposable VM and a separate experimental branch.

## 6. Explicitly parked work

- No new Bluetooth stack or A2DP/ACX driver from scratch.
- No ACX AudioCodec bind-probe as the next step.
- CI #248 and CI #255 are closed historical evidence; do not repeat them.
- No code changes on `docs/project-source-reorg`; documentation only.
- No physical Server 2022 driver install, device restart, BCD/test-signing/security change, certificate change, OS update/rollback, or installer/rollback script execution.
