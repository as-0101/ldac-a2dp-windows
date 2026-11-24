# Windows 10 / Server 2022 UUP image audit

Updated: 2026-11-24

## Why this path changed

The first Microsoft Update Catalog pass completed successfully in GitHub Actions CI #463 (run ID 45311922753), but it exposed a payload-format issue: the A2DP-related `.sys` entries extracted from cumulative-update CABs are PSF forward-delta payloads, not complete PE images. They do not begin with the `MZ` signature and cannot be used for PE import/export analysis as-is.

Observed examples:

- Windows 10 KB5036979: `f\\btha2dp.sys`, 11,840 bytes; component/INF version 10.0.19041.4355.
- Windows 10 KB5126657: `f\\btha2dp.sys`, 15,766 bytes; component/INF version 10.0.19041.7802.
- Windows 10 KB5126657: `f\\btampm.sys`, 7,952 bytes; component/INF version 10.0.19041.7725.

The catalog extractor expands MSU/CAB containers but does not reconstruct PSF forward deltas. Therefore its extracted `.sys` payloads are evidence of package membership/version, not usable PE binaries.

## Server package result

The Server 2022 KB5126655 package audit found no A2DP-specific INF/SYS or BtaMPM manifest references. It did find the Server Bluetooth core packages, including:

- `Microsoft-OneCore-Bluetooth-Package`
- `Microsoft-OneCore-Connectivity-Bluetooth-Package`
- Bluetooth WinRT/input/user-experience packages

This is package-level evidence that the Server 2022 cumulative update contains Bluetooth core components but not the Windows client A2DP profile package. It does not prove that no third-party A2DP implementation can run on Server.

Official update references:

- [Windows Server 2022 KB5126655](https://support.microsoft.com/help/5126655) — build 20348.5761, 2026-10-13.
- [Windows 10 KB5058481](https://support.microsoft.com/help/5058481) — build 19045.5917, 2025-05-28.

## Winbindex symbol-server collision

The Winbindex index supplied the expected hashes for the previously captured Windows 10 files, but the public symbol-server download did not reproduce those hashes. The returned files shared PE timestamp and size with the indexed target but had different version resources:

| Target identity from captured archive | Symbol-server result | Result |
|---|---|---|
| BthA2dp.sys 10.0.19041.4355, 282,624 bytes | 10.0.19041.6392, 282,624 bytes; timestamp 0xC4B85628 | SHA mismatch |
| BthA2dp.sys 10.0.19041.1, 279,040 bytes | 10.0.19041.1030, 279,040 bytes; timestamp 0xC4B85628 | SHA mismatch |
| BtaMPM.sys 10.0.19041.5848, 43,008 bytes | 10.0.19041.7660, 43,008 bytes; timestamp 0x5A670CFE | SHA mismatch |

Conclusion: timestamp + SizeOfImage is not a unique identity for these files. Do not use those downloaded files as the exact 4355/5848 binaries. Their PE reports are not accepted as evidence for the captured target versions.

## Preferred exact-image source

Use full UUP images rather than implementing a new PSF decoder at this stage:

- Windows 10 22H2 build 19045.5917 x64, UUP ID `598d27dc-ad81-41aa-8c83-42b88e60c823`, edition Professional.
- Windows Server 2022 build 20348.5761 x64, UUP ID `008aacce-b0b7-4aeb-a3b2-43286434832c`, edition ServerDatacenter.

The UUP dump service is independent of Microsoft; its download package obtains the payloads from Microsoft's update infrastructure. The build numbers are cross-checked against the Microsoft KB pages above. The image audit must still verify the mounted image version and the exact file hashes before any binary is accepted.

Existing PSF tooling was compared before writing a custom extractor:

- PSFExtractor v3.07 is MIT-licensed and can extract PSF content, but its inspected PA30 path calls ApplyDeltaB with a null source; it does not reconstruct the forward-delta entries needed here.
- 0xZ0F/Windows-Patch-Diff-Helpers handles forward deltas through msdelta.dll and RTM base files, but the repository has no declared license. It is not being vendored.
- Full UUP images avoid both the base-file reconstruction dependency and copying code with unclear licensing.

## Experimental implementation

Isolated branch: `experiment/win10-a2dp-uup-image-audit-20261124`

- `tools/research/extract_uup_image_a2dp.ps1`
- `.github/workflows/uup-image-audit.yml`

The workflow downloads the two exact UUP images on a disposable GitHub-hosted Windows Server 2022 runner, mounts the images read-only, extracts only metadata for relevant driver/audio files, captures INF/CBS/WinSxS references, and compares Windows 10 PE imports against Server 2022 exports. It uploads JSON/text metadata only; no ISO or Microsoft binary payload is retained.

GitHub Actions run 45317582562 (workflow run number 3) is in progress. Runs 45317386782 and 45317399103 stopped during UUP bootstrap because the packaged `get_aria2.ps1` child shell did not expose `Get-FileHash`. Commit `e9900fc894772997526995feeaecfff4a9ec5ff0` adds a narrow SHA-256 fallback to that helper and prioritizes Windows PowerShell 5.1; run 45317582562 is the verification attempt.

## Acceptance criteria

1. Win10 image version is exactly 19045.5917; Server image version is exactly 20348.5761.
2. BthA2dp DriverStore copy matches captured SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`.
3. BthA2dp System32 copy matches captured SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`.
4. BtaMPM copy matches captured SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`.
5. PE imports, delay imports, exports, API-set references, file versions, and Server export resolution are recorded for the exact matching files.
6. INF, CBS/WinSxS ownership, service/registry registrations, and catalog membership are recorded separately; absence of a package-local CAT is not treated as proof of unsigned status.
7. Static compatibility is not treated as proof of driver load or audio. Runtime sequence remains service start → device enumeration → driver load → A2DP endpoint → SBC negotiation → actual stereo audio.

No ACX bind-probe is authorized by this result. No physical host action is authorized.

## 2026-11-24 05:20 — CI #463 results and UUP audit gaps

### CI #463 (run 45311922753, success)

- KB5036979 carries A2DP component/INF version 10.0.19041.4355, but extracted `f/btha2dp.sys` is an 11,840-byte PSF forward-delta payload, not a PE.
- KB5126657 carries A2DP 10.0.19041.7802 and BtaMPM 10.0.19041.7725; extracted SYS entries are also PSF forward deltas.
- Server 2022 KB5126655 contains Bluetooth core packages but no A2DP source/common INF, BthA2dp.sys, BtaMPM.sys or matching A2DP/BtaMPM CBS manifest references.
- Winbindex symbol-server downloads failed exact identity 0/3. Do not use their PE reports as exact 19041.4355/5848 evidence.

### Static candidate comparison — provisional

The 19041.6392 BthA2dp candidate has 149 imports across 8 descriptors. The 19041.7660 BtaMPM candidate exports all 10 functions imported by BthA2dp from BtaMPM and its 42 imports resolve against the available later Server 20348.5866 exports. 129/149 BthA2dp imports matched the available Server reference set plus companion BtaMPM; 20 imports from HAL/SleepStudyHelper/WDFLDR/ksecdd remain untested because those Server references were not collected. These are not exact captured binaries or the target Server build.

### UUP script limitations to close in the next isolated experiment commit

1. Add HAL.dll, SleepStudyHelper.sys, WDFLDR.SYS and ksecdd.sys to target and Server reference lists.
2. Resolve BthA2dp's btampm.sys imports against companion Win10 BtaMPM exports; resolve BtaMPM imports against Server exports.
3. Add offline SYSTEM/SOFTWARE hive extraction for Services, ControlSet, BTHENUM/class registrations and MMDevices; current script reads INF/CBS/WinSxS metadata only.
4. Search system CatRoot catalogs and verify actual membership; current Get-CatalogSummary scans package-local CAT files only.
5. Preserve the distinction between package-local CAT, system catalog membership, embedded Authenticode and CBS component ownership.
6. If Win10 19045.5917 does not reproduce captured hashes, add a separate 19045.4355 UUP image candidate for captured BthA2dp 10.0.19041.4355.

UUP run #3 (45317582562, commit `e9900fc894772997526995feeaecfff4a9ec5ff0`) remains in progress. No driver installation or physical-host access occurs in this workflow.

### Exact captured build candidate

The captured A2DP common INF/BthA2dp package version is 10.0.19041.4355. UUP Dump lists an x64 Windows 10 22H2 build 19045.4355 candidate (ID `446f2934-e38b-4801-a529-fcf40231a02a`): [UUP Dump build](https://uupdump.net/selectlang.php?id=446f2934-e38b-4801-a529-fcf40231a02a). Its actual mounted image contents have not yet been validated. If the current 19045.5917 image does not contain the captured BthA2dp SHA, add this as a separate exact-version image target; do not replace the current run while it is in progress.

E-119 reports the exact captured DriverStore BthA2dp 19041.4355 has only ntoskrnl direct imports. The separate System32 copy and later 19041.6392 symbol-server candidate have 8 import descriptors, so imports are version-dependent and must be compared per exact hash.

### Exact BtaMPM import check

The captured BtaMPM 10.0.19041.5848 report has 42 imports (37 ntoskrnl, 1 cng/SystemPrng, 4 WppRecorder). The names match the later 19041.7660 candidate and all are exported by the available Server 20348.5866 reference files. Re-run this check against the exact Server 20348.5761 image after UUP extraction; do not treat the later runner build as the target.

## 2026-11-24 06:16 — run #3 failure and corrected reruns

### Run #3 — harness failure, not a binary result

[Run 45317582562](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562), commit `e9900fc894772997526995feeaecfff4a9ec5ff0`, job `138188044012`, failed at line 370 while reading `$selected.Version`. PowerShell reported that the property did not exist on the `Get-WindowsImage` object. The failure occurred before `Mount-WindowsImage`; the run produced no PE/INF/CBS/CAT report and no artifact. This is a script assumption failure only.

### Corrective revisions

- Commit [144d42105a26d5aa21f159ae068b17a047f724a9](https://github.com/as-0101/ldac-a2dp-windows/commit/144d42105a26d5aa21f159ae068b17a047f724a9) removes the DISM object-property dependency. After mounting the selected WIM index read-only, it copies the offline SOFTWARE hive to the temporary work directory, loads that copy, and verifies CurrentBuild.UBR plus EditionID. It records ProductName, InstallationType and BuildLabEx. It also adds HAL.dll, SleepStudyHelper.sys, WDFLDR.SYS and ksecdd.sys to the target/reference set.
- Commit [e947970356884ead996bcc7347fa0e5554aa770b](https://github.com/as-0101/ldac-a2dp-windows/commit/e947970356884ead996bcc7347fa0e5554aa770b) adds the Win10 image's DriverStore-preferred BtaMPM.sys to the export reference directory before auditing Win10 binaries. This allows BthA2dp → BtaMPM imports to resolve against the matching Win10 companion; BtaMPM's own imports are still compared against Server exports.

### Verification runs

- [Run #4 / 45325486392](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325486392) uses the offline-hive identity fix and expanded kernel reference set.
- [Run #5 / 45325586394](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325586394) uses the latest companion-BtaMPM fix.
- Both were in progress at this update. Do not treat either as successful until the image identity fields and output artifact are checked.

### Next evidence gate

1. Confirm exact image identities: Win10 19045.5917 / Professional and Server 20348.5761 / ServerDatacenter.
2. Compare each extracted file's SHA-256 to the captured archive; never merge the DriverStore and System32 BthA2dp copies.
3. Inspect direct/delay imports, exports, API-set references and full Server 20348.5761 resolution, including the Win10 BtaMPM companion.
4. Add offline SYSTEM/SOFTWARE service/class/MMDevices registrations and system CatRoot membership; package-local CAT scanning is not sufficient.
5. Only then consider staging the unmodified package in a disposable Server 2022 VM. No physical-host changes.


## 2026-11-24 07:13 — runs #4/#5 parser failure; #6 regression fix

- UUP audit #4 [45325486392](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325486392), job `138213952436`, and #5 [45325586394](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325586394), job `138214282805`, both verified the offline Server image identity as Windows Server 2022 Datacenter 20348.5761 / ServerDatacenter. They then failed on a parser bug: a named delay-import entry in `AudioEndpointBuilder.dll` had `hint=None`, causing `int(None)`. The Win10 image was not reached and no PE/INF/CBS/CAT artifact was produced.
- This is a tooling failure, not evidence of a missing import, unsupported API, or binary incompatibility.
- Experiment commit [6778022](https://github.com/as-0101/ldac-a2dp-windows/commit/6778022b4453857e53acf8a18afe54bb7e46f5f5) preserves missing hints as null and adds three unit tests. CI #6 [45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839), job `138235648697`, passed the regression-test step. The full offline UUP audit was still running at this update.
- Exact target PE hashes/import closure, Win10 image identity, offline registry/CBS/CAT membership and disposable-VM staging remain unverified. No physical host access or modification occurred.


## 2026-11-24 07:18 — A2DP CBS ownership and exact package-version mapping

CI #463's metadata artifact (workflow artifact ID `14883494285`, ZIP SHA-256 `2cd35a38abcdcde42fb0e175dfa042715aae8bb7e6eb2adf9c40c475886c9d38`) contains MUM search evidence for the A2DP package owner:

- KB5036979 MUM `Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.4355.mum` declares `microsoft_bluetooth_a2dp.inf` as `Product-onecore__dual_microsoft_bluetooth_a2dp.inf`, version 10.0.19041.4355, type `dualModeDriver`. The same MUM declares `btampm.inf`, `microsoft_bluetooth_a2dp_snk.inf` and `microsoft_bluetooth_a2dp_src.inf` as driver entries.
- KB5126657 MUM `Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.7807.mum` declares A2DP common assembly 10.0.19041.7802 and BtaMPM assembly 10.0.19041.7725; source/sink assembly identities remain 10.0.19041.1.
- Server KB5126655 scan has no matching A2DP/BtaMPM MUM/manifest hits.

This is direct evidence that Windows 10's A2DP profile package is CBS-owned by the client desktop required package. It does not prove that PnPUtil/SetupAPI cannot stage the complete signed dualModeDriver package independently on Server. Do not inject the whole Client-Desktop-Required package. The next check is exact WIM DriverStore/CAT membership, INF target decorations and OS applicability. The 74-byte/71-byte INF files in expanded update payloads are PSF delta artifacts/placeholders, not complete INF files.

UUP audit #4/#5 parser failure and #6 regression fix are documented above. CI #6 still needs its final metadata artifact and both image identities before any PE/CAT compatibility result is accepted.


## 2026-11-24 07:20 — CBS ownership and directional package minimization

CI #463 metadata artifact `microsoft-catalog-a2dp-audit.zip` (artifact ID `14883494285`, SHA-256 `2cd35a38abcdcde42fb0e175dfa042715aae8bb7e6eb2adf9c40c475886c9d38`) shows:

- KB5036979 MUM `Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.4355.mum` declares `microsoft_bluetooth_a2dp.inf` as `Product-onecore__dual_microsoft_bluetooth_a2dp.inf`, version 10.0.19041.4355, type `dualModeDriver`; it also declares `btampm.inf`, `microsoft_bluetooth_a2dp_snk.inf` and `microsoft_bluetooth_a2dp_src.inf`.
- KB5126657 MUM declares A2DP common 10.0.19041.7802 and BtaMPM 10.0.19041.7725. The Server KB5126655 scan has no matching A2DP/BtaMPM MUM/manifest hits.
- For PC → OPPO playback, only `microsoft_bluetooth_a2dp_src.inf` is required: it matches the remote A2DP Sink UUID 0x110B. The separate `microsoft_bluetooth_a2dp_snk.inf` is the reverse direction (Windows as A2DP sink) and is excluded from this milestone. The source INF chains to the common INF and its BtaMPM/KS/WDMAUDIO/MSSysFx dependencies.

This is CBS ownership and static INF direction evidence, not proof of standalone staging. Do not inject the entire Client-Desktop-Required package. Next: verify exact DriverStore/CAT membership, INF target decorations and OS applicability, then stage only the source/common dependency closure in a disposable Server 2022 VM. UUP audit #6 is still required for exact PE and offline registry/CAT data.


## 2026-11-24 08:39 — UUP audit #6: exact package binary and Server import closure

### Run and artifact

UUP audit #6 [45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839) completed successfully on experiment commit 6778022b4453857e53acf8a18afe54bb7e46f5f5. Artifact [14895876155](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839/artifacts/14895876155) is uup-image-a2dp-audit-metadata.zip, 328,218 bytes, SHA-256 c1792bd8e5bcdf2a583c3738eeb22bdf27a64ba6ad2701ad70aa8f879d045209.

Exact offline image identities:
- Win10 Pro x64 19045.5917, UUP ID 598d27dc-ad81-41aa-8c83-42b88e60c823.
- Server 2022 Datacenter Desktop Experience x64 20348.5761, UUP ID 008aacce-b0b7-4aeb-a3b2-43286434832c, EditionID ServerDatacenter, InstallationType Server.

### Binary result

The DriverStore BthA2dp binary is the exact archived file: version 10.0.19041.4355, 282,624 bytes, SHA-256 5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3. It is AMD64 PE32+, WDM_DRIVER, with 149 imports in eight descriptors, no delay imports, no API-set imports and no exports. All 149 imported symbols resolve against Server 20348.5761 export tables plus the exact Win10 BtaMPM companion.

Exact BtaMPM 10.0.19041.5848 (43,008 bytes, SHA-256 DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD) has 42 imports and 14 exports; all 42 imports resolve against Server 20348.5761. The DriverStore BthA2dp imports 10 BtaMPM exports.

The separate System32 BthA2dp copy is older 10.0.19041.1, 279,040 bytes, SHA-256 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737, 144 imports. Do not conflate it with the DriverStore package binary.

### INF/service correction

microsoft_bluetooth_a2dp_src.inf 10.0.19041.1 (SHA B97D1DD53BB6FD040CE5C2527015A09416C29FCBD6B528802D595CBDEEAD4A6A) matches remote A2DP Sink UUID 0x110B. It chains to common INF 10.0.19041.4355 (SHA 4F3B988B658E1E7F8B97E645C1C92BE0BA270D4DB76832DAB871516EEDCBCF0C). Common INF needs Server-available KS/WDMAUDIO/MSSysFx sections and BtaMPM.CopyFilesOnly, then copies BthA2dp.sys and installs demand-start BthA2dp.

btampm.inf 10.0.19041.5848 (SHA C657A6B32AC8CCFDEEF3C12630686B87C973DD114BEE73AEC288D86B989961EF) only copies BtaMPM.sys to %12%; it has no AddService. BtaMPM is not a separate service.

The exact Server INF set already contains KS.Registration, WDMAUDIO.Registration, and mssysfx.CopyFilesAndRegister. Server bth.inf still maps 0x110B to generic service with _GENERIC; the Win10 source INF matches the base UUID. This is the minimal binding gap to test.

### Limits

UUP #6 did not verify offline system catalog membership; Get-CatalogSummary only searched package-local DriverStore CAT files, and the INF has no CatalogFile directive. Get-AuthenticodeSignature returning NotSigned for SYS only means no embedded signature. No PnP staging, driver load, endpoint, SBC negotiation or audio test occurred.

The previous E-119 statement that the exact DriverStore BthA2dp had only ntoskrnl imports is superseded by E-169; the exact file has eight import descriptors and 149 imports.

### Next audit

UUP audit #7 [45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564), isolated experiment branch experiment/win10-a2dp-catalog-registry-audit-20261124, adds offline catalog membership and read-only SYSTEM-hive service registration inventory. No package installation or driver load is performed.



## 2026-11-24 08:50 — correction to the generic BTHENUM mapping comparison

Both images contain the generic mapping for UUID 0x110B:
- Win10 bth.inf 10.0.19041.5848, SHA 8635AE12E1C0AF71E95AD0DA65FA6CEEAB2AA0866D213620F49AA0A634CE976D.
- Server bth.inf 10.0.20348.5756, SHA 38302B73607B829CBD94D60D25320924B8727BF55CAD940052444FC22D475459.

Both map the base UUID to BthGenericService with the _GENERIC hardware ID and a null associated-service install. The Win10/Server difference is the additional Win10 dedicated A2DP source/common INFs plus BtaMPM, absent from Server. Do not copy or patch bth.inf. The source INF includes PreConfigureDriver=*; SetupAPI selection/rank remains an explicit disposable-VM test.


## UUP catalog/registry audit recovery — 2026-11-24

### CI #7 failure

[Run 45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564), commit `5bdbc75d904beb8c5f84787cc592ae9134df40c6`, reached the exact Server 20348.5761 image and failed at `Get-OfflineServiceSummary`: StrictMode raised because a registry object lacked the optional `ServiceDll` property. The artifact 14896789955 (144,045 bytes, SHA-256 `dca3859cab81728950b037d93b43f170e2fc730412adda369340d67839152380`) contains 20 Server PE JSON reports only. No catalog membership, offline service registrations, or Win10 image result were produced. This is an audit-script defect, not a Windows driver failure.

### Recovery changes

- `Get-OptionalPropertyValue` now checks `PSObject.Properties` before reading optional registry values and has a small self-test for missing/present properties.
- Per-image results are checkpointed after each target; a failure for one image is recorded and does not suppress the other image's audit.
- Offline SYSTEM hive paths use single Windows separators.
- SignTool discovery safely checks `Get-Command` and falls back to the Windows Kits x64 path.
- Workflow now parses the PowerShell script and confirms x64 SignTool availability before downloading multi-gigabyte UUP images.

### Recovery runs

| Run | Commit | Current state at documentation cut |
|---|---|---|
| [#8 / 45346767600](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45346767600) | `f451e4ce` | In progress; first safe-property recovery, before path correction |
| [#9 / 45346822337](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45346822337) | `fd9fd19c` | In progress; path correction |
| [#10 / 45347437488](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45347437488) | `f0605f14` | In progress; SignTool discovery correction |
| [#11 / 45347639357](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45347639357) | `ff8c4a3b` | Preflight passed; offline UUP/catalog/service audit in progress |

### Important catalog-policy correction

The Win10 `microsoft_bluetooth_a2dp_src.inf`, `microsoft_bluetooth_a2dp.inf`, and `btampm.inf` have no `CatalogFile` directive. Microsoft explicitly states that system-supplied INFs omit this directive because Windows validates them against all system-supplied catalogs. Therefore the absence of a local CAT or CatalogFile line is expected for an inbox package; the next audit must locate the exact matching OS catalog and verify membership. Do not add a CatalogFile line or modify the INF.

The common INF also maps `BthA2dp.sys` to `SignatureAttributes.DRM`, but the captured DRM subsection is empty. Microsoft documents DRMLevel 1200/1300 and conditional HCK application; the exact applied signature attributes remain unverified.

