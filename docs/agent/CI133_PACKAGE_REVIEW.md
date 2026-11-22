# CI #133 package and binary review

**Review date:** 2026-11-22  
**Scope:** Static inspection of CI #126 and CI #133 artifacts, INF/setup logic, ACX API surface, and Microsoft documentation. No physical-server changes.

## 1. Artifact structure and identity

The downloaded GitHub Actions artifact `ldac-a2dp-oppo-server2022-test` (artifact ID `14763242251`) is an outer ZIP containing one inner ZIP, `ldac-a2dp-oppo-server2022-test.zip`. The inner package contains 11 files:

- `LdacA2dp.sys` — 60,928 bytes.
- `LdacA2dp.inf` — 5,030 bytes.
- `LdacA2dp.cat` — 3,254 bytes.
- `ldac-a2dp-test.cer` — 836 bytes.
- `oppo-driver-tool.exe` — 326,656 bytes.
- `README_OPPO_TEST_RU.txt`, `prepare-oppo-host.cmd`, `install-oppo.cmd`, `upgrade-oppo.cmd`, `rollback-oppo.cmd`, `status-oppo.cmd`.

The package SYS is byte-identical to the SYS in the CI #133 unsigned artifact.

| File | SHA-256 |
|---|---|
| CI #133 package `LdacA2dp.sys` | `435905e1553cb06d089f1477d1cff57c15bbeb84ef3141ca1b3b500a73898f3e` |
| CI #133 package `LdacA2dp.inf` | `5fe047ff4ab7a157b01043f6c4de2ba9c805042c9ee678447404f69da7bbdd19` |
| CI #133 package `LdacA2dp.cat` | `f0202a0eef8f5add021ca01e0d34851ef00def1e2be8aa8ea7c32b3a158ee738` |
| CI #133 package `oppo-driver-tool.exe` | `11070baa1950f34e133f5e653b348b17c0a1ccf8e82388ee05f4228cc41ef733` |
| CI #133 package `ldac-a2dp-test.cer` | `f647651a9f4a24b0e91fbe748227eada79ed62f314f665a1a49635e4676021c1` |

INF DriverVer: `11/22/2026,0.2.326.1634`. PE format: x64 native kernel driver.

## 2. Binary-level confirmation of ACX 1.0

Downloaded both unsigned artifacts and inspected their PDBs:

| Build | PDB size | Unique ACX `*TableIndex` symbols |
|---|---:|---:|
| CI #126 (ACX 1.1 baseline) | 1,019,904 B | 221 |
| CI #133 (ACX 1.0 experiment) | 1,011,712 B | 210 |

Microsoft's ACX version overview enumerates exactly 11 DDIs added in ACX 1.1:
- `AcxCircuitGetElementsCount`
- `AcxCircuitGetPinsCount`
- `AcxCircuitGetSymbolicLinkName`
- `AcxCircuitGetNotificationId`
- `AcxFactoryCircuitGetSymbolicLinkName`
- `AcxDataFormatListRemoveDataFormats`
- `AcxPinRemoveModeDataFormatList`
- `AcxStreamGetElementsCount`
- `AcxStreamGetNotificationId`
- `AcxTargetCircuitGetSymbolicLinkName`
- `AcxTargetPinFlushModeDataFormatListCache`

All 11 names occur in CI #126 PDB and none occur in CI #133 PDB. This is consistent with CI #133 linking against the ACX 1.0 stub/API table, not merely changing the runtime version-check string.

The current driver source uses 36 distinct ACX calls. All 36 corresponding `*TableIndex` entries are present in the CI #133 PDB. The source contains no use of the 11 ACX 1.1-only DDIs listed above.

**Conclusion:** strong binary evidence that the CI #133 binary was built against the ACX 1.0 API surface. The project sets `ACX_VERSION_MINOR=0`, the WDK NuGet props import WDK 10.0.26100.6584, the include/link paths are derived from that macro, and the build/link succeeded. The PDB comparison independently corroborates the intended 1.0 selection.

## 3. Important Microsoft support caveat

Microsoft's [ACX Version Overview](https://learn.microsoft.com/windows-hardware/drivers/audio/acx-version-overview) says:
- ACX 1.1 is the current version and recommended for new driver development; its initial public release is documented for Windows 10 version 2004.
- ACX 1.0 is described as a pre-release version used in early development/testing on Windows 10 version 1903, and is not recommended for new driver development.

The user's physical Server 2022 host is directly documented as exposing ACX `CLASS_MODULE Version v1.0`. Therefore ACX 1.0 is a pragmatic compatibility experiment for this specific host, not a Microsoft-recommended production target. Successful CI compile/link does not establish that this pre-release runtime/API combination is supported or stable on Server 2022.

Microsoft's [AcxDriverIsVersionAvailable documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/acxdriver/nf-acxdriver-acxdriverisversionavailable) explicitly shows the version 1.0 initialization/check and says minimum ACX version 1.0. This supports the correctness of the API used by the experiment, but does not turn ACX 1.0 into a generally supported production target.

## 4. ACX sample comparison

The official Microsoft [AudioCodec ACX sample](https://github.com/microsoft/Windows-driver-samples/tree/main/audio/Acx/Samples/AudioCodec) provides a useful structural reference:
- It calls `AcxDeviceInitInitialize` before `WdfDeviceCreate`.
- It calls `AcxDeviceInitialize` after creating the WDF device.
- It adds ACX circuits in `EvtDevicePrepareHardware` and removes them in `EvtDeviceReleaseHardware`.
- Its INF registers `KSCATEGORY_AUDIO`, `KSCATEGORY_RENDER`, and `KSCATEGORY_REALTIME` interfaces and the standard audio endpoint proxy properties.

The LDAC driver follows this broad lifecycle, with one important project-specific difference: its ACX circuit is attached to the Bluetooth A2DP BTHENUM function device, and the stream's PCM is exchanged with a user-mode encoder service.

Microsoft documents that AudioEndpointBuilder monitors `KSCATEGORY_AUDIO` arrivals to discover endpoints: [Audio Endpoint Builder Algorithm](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/audio-endpoint-builder-algorithm). The package INF registers this category, so the endpoint-discovery mechanism is grounded in the standard audio model.

## 5. INF class and Bluetooth matching

The current INF declares `Class=Bluetooth` and the Bluetooth class GUID. This is consistent with Microsoft's [Installing a Bluetooth Device](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/installing-a-bluetooth-device) documentation, which says Bluetooth devices are members of the Bluetooth setup class and Bluetooth profile drivers are installed through the Bluetooth class installer.

The old `docs/stage5-audio-options.md` describes the endpoint INF as class `MEDIA`; that statement does not match the current `LdacA2dp.inx`. The official AudioCodec sample is class MEDIA because it installs a root-enumerated audio device; it is not by itself proof that a Bluetooth profile driver's INF must use MEDIA. Do not change the current Bluetooth class without a targeted test.

The INF comment says it binds by a full hardware ID, but the Server 2022 model section actually lists `BTHENUM\\{0000110b-...}_GENERIC`. The exact OPPO instance is restricted separately by:
1. SetupAPI tool's target-MAC selection (`840F2A13E3E2`);
2. single-present-A2DP-devnode safety gate;
3. driver's runtime instance-ID/MAC guard.

The installer also compares driver rank with inbox `bth.inf`; the candidate is refused if its rank could outrank inbox for other A2DP devices. In the upgrade path, it checks current service/manufacturer, candidate version greater than installed, and candidate rank lower priority than inbox. These controls are meaningful, but they do not replace a physical-host rollback plan.

## 6. Package preparation side effects and documentation defect

`prepare-oppo-host.cmd`:
- checks Windows build 20348;
- imports the test certificate into LocalMachine Root and TrustedPublisher;
- sets the IHVDRIVER Debug Print Filter registry value;
- runs `bcdedit /set testsigning on`;
- requires a restart.

This is a material boot/security configuration change. The script does not itself establish that Secure Boot permits test signing. The README correctly says not to bypass Secure Boot/Code Integrity and says the complete package and rollback script must be kept locally. Never run preparation automatically.

The README contains the “DIAGNOSTIC UPGRADE…” section twice. This is a documentation duplication, not a driver defect.

## 7. OS servicing is now a separate investigation axis

The last recorded physical host build is **20348.2849**, corresponding to Microsoft's November 12, 2024 update KB5046616. As of the research date, Microsoft lists Windows Server 2022 build **20348.5873** (November 13, 2026 OOB cumulative update KB5136487) as newer.

Sources:
- [KB5046616 — build 20348.2849](https://support.microsoft.com/en-us/servicing/os/windows-server/2024/11/november-12-2024-kb5046616-os-build-20348-2849)
- [KB5131090 — build 20348.5870](https://support.microsoft.com/en-us/servicing/os/windows-server/2026/11/kb5131090-windows-server-2022-security-update)
- [KB5136487 — build 20348.5873](https://support.microsoft.com/en-us/servicing/os/windows-server/2026/11/kb5136487-windows-server-2022-update)

The public KB summaries do not establish whether these later cumulative updates change `Acx01000.sys` or its registered ACX class version. Therefore OS servicing is a **separate untested variable**, not a proven fix. Before the physical ACX 1.0 test, obtain the current file version of `C:\\Windows\\System32\\drivers\\Acx01000.sys` and current `!wdfldr` output. If considering OS servicing, verify the ACX runtime version on a separate updated image/VM first; do not combine an OS upgrade and driver-version change in one experiment.

## 8. Current interpretation

1. The original ACX 1.1 vs runtime 1.0 mismatch hypothesis is now strongly supported by physical-host WinDbg evidence, CI #126/#133 source settings, and PDB API-table comparison.
2. CI #133 package identity and binary have been inspected; it is a real ACX 1.0 build, not a mislabeled archive.
3. The next discriminating experiment remains physical class binding, but the old OS build introduces a possible prior question: would a newer Server 2022 servicing level expose a different ACX class version?
4. No driver installation, BCD change, certificate import, device restart, or OS update was performed during this review.
