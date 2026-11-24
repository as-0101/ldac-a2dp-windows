# Build registry

Status vocabulary: `BUILT`, `STATICALLY_VERIFIED`, `VM_TESTED`, `HARDWARE_TESTED`, `REJECTED`, `SUPERSEDED`, `UNKNOWN`. A CI workflow's green result is not a runtime test.

| Build / run | Branch and commit | DriverVer / ACX / target | Artifact identity | Evidence and outcome | Status |
|---|---|---|---|---|---|
| UUP catalog/registry audit #7 / 45342686564 | `experiment/win10-a2dp-catalog-registry-audit-20261124`, `5bdbc75d904beb8c5f84787cc592ae9134df40c6` | Win10 19045.5917 vs Server 20348.5761; offline only | Artifact 14896789955; 144,045 bytes; SHA-256 `dca3859cab81728950b037d93b43f170e2fc730412adda369340d67839152380` | Failed in audit script at optional ServiceDll property access; partial artifact contains 20 Server PE reports only. No catalog/registry conclusion. | REJECTED — TOOLING FAILURE |
| UUP catalog/registry audit #8 / 45346767600 | `experiment/win10-a2dp-catalog-registry-audit-20261124`, `f451e4cee683a1922aacdfb0505d3f8a97ece8a8` | Win10 19045.5917 vs Server 20348.5761; offline only | Pending | Safe optional-property reader added; this attempt preceded path-separator correction. | UNKNOWN |
| UUP catalog/registry audit #9 / 45346822337 | `experiment/win10-a2dp-catalog-registry-audit-20261124`, `fd9fd19cf261b97c0c509127035639c2a69e8386` | Win10 19045.5917 vs Server 20348.5761; offline only | Pending | Corrected offline SYSTEM/registry path separators; in progress at documentation cut. | UNKNOWN |
| UUP catalog/registry audit #10 / 45347437488 | `experiment/win10-a2dp-catalog-registry-audit-20261124`, `f0605f14aff2f8ff937c169c3796216b26058aac` | Win10 19045.5917 vs Server 20348.5761; offline only | Pending | Hardened SignTool discovery and ProgramFilesX86 fallback; in progress at documentation cut. | UNKNOWN |
| UUP catalog/registry audit #11 / 45347639357 | `experiment/win10-a2dp-catalog-registry-audit-20261124`, `ff8c4a3b6a8467d940b239571670ae29da5ca1a3` | Win10 19045.5917 vs Server 20348.5761; offline only | Pending | PowerShell parser + x64 SignTool preflight passed; offline extraction/catalog/service audit in progress. | UNKNOWN |
| Successful baseline run #129 / 44922058650 | `fix/server2022-acx-wdk-26100`, `4571873b505c52a93db4c785fe3d083eabf8499e` | 0.2.325.1600; ACX 1.1; WDK/SDK 10.0.26100.6584 | Historical artifact labels CI-126 are misleading; actual successful run is #129. See E-042 and CI133_PACKAGE_REVIEW. | Successful build; physical device later showed matching version and Code 37 / 0xC000000D. | BUILT |
| CI #133 / 45044497961 | `experiment/acx10-server2022-bind`, `593e8f407ec18e72a332edbec323a4ddbbd27774` | 0.2.326.1634; ACX 1.0; Universal | Test ZIP digest `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad`; SYS `435905e1553cb06d089f1477d1cff57c15bbeb84ef3141ca1b3b500a73898f3e`; INF `5fe047ff4ab7a157b01043f6c4de2ba9c805042c9ee678447404f69da7bbdd19`; CAT `f0202a0eef8f5add021ca01e0d34851ef00def1e2be8aa8ea7c32b3a158ee738`; EXE `11070baa1950f34e133f5e653b348b17c0a1ccf8e82388ee05f4228cc41ef733`. | Package/PDB inspected; PDB shows 210 ACX table entries vs 221 in #129; no physical runtime test. | STATICALLY_VERIFIED |
| CI #143 / 45050062916 | `experiment/acx10-windowsdriver-platform`, `6656e2d1fcda8d731f6795bd2e7a2950d5ba8309` | ACX 1.0; Windows Driver target (A/B against Universal) | See CI run; exact artifact hashes not captured in current compact source. | Three build jobs passed; no physical/hosted bind result. | BUILT |
| Hosted ACX 1.0 attempt #248 / 45060225420 | `experiment/acx10-hosted-load`, `3d1d5d7e179da3379013b10f9863066200c459b6` | 0.2.326.1922; ACX 1.0; Universal | Test package artifact 14768714620, digest `b1ac0c4bd52bc965e549de18c584655331e7c7d58cdc9a02acb35e17528f175c`; unsigned artifact 14769077870, digest `a021fbdd49e803e88f1e7860859d9299ab5112394b39e2204107e72d6400fbc8`; report artifact 14769048266, digest `e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb`. Report SYS SHA-256 `FF97EED8409A7FF9DADB8D9C7C7FB309E789F9A3225847793B39B7D97D8FB9A8`; INF `0111FD38ED61DCA2D3D9691CB6BC70675AD588A9B6B2778113B2CFBDBFFC4B6C`; CAT `F40C19BF69B43DFE91C49CBA67ED7DA18BF4147B6F065C7BC132B97969C22D94`. | Hosted Server 2022 disposable runner; Acx01000 explicitly RUNNING; PnP selected oem13.inf and attempted start; Code 37 / ProblemStatus 0xC000000D. No DriverEntry. Artifact metadata says DriverVer .1922; older PROJECT_STATE line says .1920 — .1922 is supported by preflight.json and SetupAPI. | REJECTED (runtime candidate behavior) |
| ACX stub metadata #255 / 45060819535 | `experiment/acx10-hosted-load`, `085705abb4bf8e52dd5bcb5bccb532352fbb132e` | WDK NuGet 10.0.26100.6584 | Artifact 14769755224, digest `8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce`. | Direct stub descriptor parsing: ACX 1.0 = 210 functions/62 structures; ACX 1.1 = 221/62; candidate CI #246 SYS descriptor = 1.0 / 210 / 62. | STATICALLY_VERIFIED |
| ACX stub-inspection workflow #1 / 45060793775 | `research/acx-stub-metadata`, `4137f3fc2af65a1c1ba9c5683410f9f24e93a554` | WDK 10.0.26100.6584 | No artifact uploaded. | Failed because workflow assumed WDK package contained an `Include` folder; actual NuGet layout differs. Not a driver failure. | REJECTED (harness) |

| CI #15 sample bind probe / 45082965356 | `experiment/acx10-sample-bind-probe-v2`, `488ae8104eec960370c0887e07136a3e9e3846b5` | 11/22/2026,23.24.24.909; ACX 1.0; KMDF 1.31; Windows Driver; MEDIA / ROOT\AudioCodec | Build artifact 14778450384, ZIP SHA-256 `8e701ee7f69f1d9c855f5b2c3d4c06de39628dfb7e955ecb12877fc9f811e449`; runtime artifact 14778137925, ZIP SHA-256 `aa63c8dfbce7b9b319d9117e1be7b8db1565ff85a0d56c08e57c9de98710e59b`; SYS `BAB3C54C0EAB186CC8C9D89B07BCA871112454175C0C45F8D199DA57927114B6`; INF `CC2A09F6D2F8590DA5395CB366FE62C83164D48EF8B227E3B0004447E0112DC7`; CAT (runtime signed) `9A120CCB4D5B8781EED86D50C096A5A95CC59140954A5A1E9830F0875A42ABD8`; PDB `4FDC48C1C86C33DC6939A8130E8CD594016E80EA64DB3ADADE846D083B03CCB7`. | Build and runtime harness jobs passed; PnP selected oem13.inf but returned Code 37 / 0xC000000D before DriverEntry. Cleanup succeeded. | REJECTED (runtime bind behavior) |

## Provenance rules

- Never conflate workflow run number with run ID.
- Never conflate branch head with artifact provenance.
- PDB correspondence requires GUID/Age or an explicit binary/PDB matching tool result; matching filename/version is insufficient.
- CI artifact digests are for the downloaded artifact ZIP, not the inner SYS/INF/CAT.
- Keep every run as its own row; append rather than merging results.

| 10 | 39c8844798485d97f06f40ab3c90f5ab00491733 | WDK 10.0.26100.6584 / SDK 10.0.26100.0 / KMDF 1.31 / ACX 1.0 | x64, hosted Server 2022 | PASS | Artifact 14774844743; SHA-256 d79c6bf6ed04de54c3c073edfd8e91fcfbe9d98ac8537aef951f2d03dfd21dc7 | Probe SYS built; runtime preflight later stopped at incorrect SignTool /kp verification. |
| 11 | 98800f0a88717cc93ef491fb5dff622b6fc4ff25 | WDK 10.0.26100.6584 / SDK 10.0.26100.0 / KMDF 1.31 / ACX 1.0 | x64, hosted Server 2022 | PASS | Artifact 14775454304; SHA-256 7a40925a5b291fcef290a2a47e8f8036410b5f623562cdb3228d34652ee6033e | Build manifest pins ACX stub and WDF link-library hashes; ACX stub hash matches CI #255 exactly. |
| 12 | b74f7247017b4dcbe55b141604a5ae0073b4c0fd | Same pinned toolchain | x64, hosted Server 2022 | NOT BUILT | No probe artifact | PowerShell parser validation caught a script-construction regression before build/runtime. |
| 13 | 35e700a3ecb74548b858f0479a1e15e31a2d110f | WDK 10.0.26100.6584 / SDK 10.0.26100.0 / KMDF 1.31 / ACX 1.0 | x64, hosted Server 2022 | BUILD PASS; RUNTIME FAIL — Code 37 / 0xC000000D before DriverEntry | Build artifact 14776416132, ZIP SHA-256 35e2aba65e565b59beacbf1562294a7e75079a62c2f7a6bfd72b4c769467b600; runtime artifact 14776347679, ZIP SHA-256 b3a26a3565b214355a64a48153074a725bd1320e0e09a78b9308d8a83bd330c4 | Official AudioCodec-derived ACX 1.0 client; root MEDIA INF selected; no DriverEntry. Probe SYS SHA-256 70BA9899BF1B54989E7C6C3F6C0DEDAE2ADFCEF16D7AE6A9803192E7C86EDAA6. |

| 14 | 04518a83900a7e7aa093fe56a7669f91349d7588 | WDK 10.0.26100.6584 / SDK 10.0.26100.0 / KMDF 1.31 / ACX 1.0 | x64, hosted Server 2022 | BUILD PASS; RUNTIME FAIL — same Code 37 / 0xC000000D before DriverEntry | Build artifact 14778135563, ZIP SHA-256 2a266fa558e24745e2a991189da119101641112d18079935c68a0c61e872af86; runtime artifact 14777212842, ZIP SHA-256 a141b772ff978f995a648c6fb68c4e8e1bd46d98cef314786da7e835cab0b312 | Global DbgPrintOn was set after boot; Wdf01000 DriverEntry had already read the setting, so empty !dbgprint is inconclusive. SYS SHA-256 AE960C99DE0DA995621113118DDB2CC13FFACBF5F6BBC217C29CB5E4CF6E91D4. |
| 15 | 488ae8104eec960370c0887e07136a3e9e3846b5 | WDK 10.0.26100.6584 / SDK 10.0.26100.0 / KMDF 1.31 / ACX 1.0 | x64, hosted Server 2022 | BUILD PASS; RUNTIME FAIL — Code 37 / 0xC000000D before DriverEntry | Workflow run 45082965356; build artifact 14778450384 / ZIP SHA-256 8e701ee7f69f1d9c855f5b2c3d4c06de39628dfb7e955ecb12877fc9f811e449; runtime artifact 14778137925 / ZIP SHA-256 aa63c8dfbce7b9b319d9117e1be7b8db1565ff85a0d56c08e57c9de98710e59b | WDF VerboseOn=1 / LogPages=16; ACX runtime IFR visible in raw preinstall log; probe IFR unavailable because driver never loaded; native LiveKD dump still had a missing page. Cleanup succeeded. |


## CI #16 and #17 continuation — 2026-11-23

| Build / run | Branch and commit | DriverVer / toolchain | Artifact identity | Evidence and outcome | Status |
|---|---|---|---|---|---|
| CI #16 / 45084678951 | `experiment/acx10-sample-bind-probe-v2`, `9da48c3ecd5921f8cab47888325b156dc9a536f3` | `11/22/2026,23.43.43.890`; WDK NuGet 10.0.26100.6584; SDK 10.0.26100.0; VS2022 MSBuild 17.14.60.43110; KMDF 1.31; ACX 1.0; x64 / Windows Driver | Build artifact 14779061024, 126,939 bytes, SHA-256 `d332fc338cbd8c4aa41f56338bb68104059b2956558067362d69b495a0ba8e72`; runtime artifact 14779107472, 162,186 bytes, SHA-256 `7d53835ecaababca7451c19e0ce79bab7186f9e59568fcc3a3b047efa3e95214`; SYS `F7BAE855C1B184ABCF0BFCBC258EF11740700788BC08270A3C22041E76860E37`; INF `25C1E5AAEF51FB417E6E0ED2113C33841A08D4DDC05DABF60AA7AFB1BF41CD39`; PDB `7B2FEDE81388EDA93FD930B2B88A47FDFB72BC8686A7C47D7967A449D7863855`. | Build, InfVerif and Server2022 Inf2Cat passed. Hosted Server2022 20348.5870 selected oem13.inf then Code 37 / 0xC000000D before DriverEntry. ACX CLASS_MODULE v1.0 and WDF client 1.31 / runtime 1.33 present. Full preinstall mirror 17,174,368,256 bytes, zero missing pages. Runtime PDB: WDF_CLASS_BIND_INFO 0x50, WDF_CLASS_BIND_INFO2 0x78; ACX descriptor 0x78. Exact internal bind rejection remains unknown. | REJECTED (runtime bind behavior); STATICALLY_VERIFIED |
| CI #17 / 45158705058 | `experiment/acx10-wdk20348-control`, `79460f03492a54444473589dd142da864a703a73` | Intended EWDK/WDK 10.0.20348.1 + VS2019; ACX 1.0 / KMDF 1.31; x64 / Windows Driver. No DriverVer until build completes. | No artifact available at 2026-11-23 12:53 Kyiv. | PowerShell parser and project XML gates passed. Build job 137638217372 remains in step 4 (official EWDK ISO download, ACX 1.0 stub inspection and build). Hosted runtime job has not started. | PENDING — BUILD_ONLY |

CI #16 Library copies were independently re-materialized and matched against the downloaded GitHub artifact ZIP bytes. The earlier PROJECT_STATE build ZIP digest `d332fc56...` was a transcription error; the correct digest is the one in the table above. CI #17 is a toolchain-bundle comparison (WDK and compiler generation both change), not a pure WDK-only A/B test. WDK 20348.1 is unsupported and research-only; the experiment uses the official EWDK distribution, not the legacy SDK/WDK MSI installers.


## 2026-11-23 strategy reset — no new build
- No driver or service build was run in this cycle.
- No source code was changed.
- No CI run ID was created.
- No physical-host action or runtime installation was performed.
- Next build/test work is deferred until the complete Windows 10 A2DP source/common INF package and catalog are captured and audited.
- CI #248 and CI #255 remain closed historical ACX evidence. No ACX bind-probe is the next step.

## 2026-11-23 23:40 — package-path research pass

- No driver or service build was run.
- No CI run ID or build artifact was created.
- No source code or driver package was changed.
- The pass was limited to read-only source inspection and official documentation review.
- CI #248 and #255 remain closed historical ACX evidence; no ACX bind-probe is scheduled next.


## 2026-11-24 01:42 — Win10 A2DP component audit (research only)

- Code branch: no changes to server-2022-oppo or experiment branches.
- Documentation branch: docs/project-source-reorg.
- Build/CI: no build performed; no CI run ID created.
- Artifacts: no new binary or package artifact created. Existing Win10 package archive and PE/INF text reports were indexed in ARTIFACT_INDEX.md.
- Runtime: no service/device/driver/endpoint/audio test performed.
- Physical host: no live query or mutation performed. No driver install, device restart, BCD/security/test-signing, certificate or OS changes.
- Decision: next gate is Win10/Server WIM component ownership and exact PE import/export compatibility. CI #248 and #255 remain closed; no ACX bind-probe.


## 2026-11-24 02:19 — codec/component research only

- No code, driver, service or package build was run.
- No CI workflow was started; no CI run ID or build artifact was created.
- No binary was downloaded, installed or modified.
- Only documentation on `docs/project-source-reorg` was updated.
- No runtime stage was tested; no fresh physical-host query or mutation occurred.
- The next build/runtime gate remains blocked on exact package catalog/CBS ownership and PE/API compatibility. CI #248/#255 remain closed historical ACX evidence.


## 2026-11-24 package and image audit runs

- CI #463 — success: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45311922753, branch experiment/win10-a2dp-symbol-audit-20261124, commit 4459e152886cec3c2d4a2f0458a5467469c7b3dc. Artifacts: win10-a2dp-symbol-audit-metadata.zip (14882708862) and microsoft-catalog-a2dp-audit.zip (14883494285). Package discovery succeeded; PSF payloads were not reconstructed; Winbindex exact hash identity was 0/3.
- UUP image audit #3 — in progress: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562, branch experiment/win10-a2dp-uup-image-audit-20261124, commit e9900fc894772997526995feeaecfff4a9ec5ff0. Targets: Win10 19045.5917 and Server 20348.5761.
- UUP audit attempts 1 and 2 (runs 45317386782 and 45317399103) failed during downloader bootstrap because the child helper did not expose Get-FileHash; the current attempt adds a local SHA-256 fallback and prioritizes Windows PowerShell 5.1.


## 2026-11-24 package and image audit runs

- CI #463 — success: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45311922753, branch experiment/win10-a2dp-symbol-audit-20261124, commit 4459e152886cec3c2d4a2f0458a5467469c7b3dc. Artifacts: win10-a2dp-symbol-audit-metadata.zip (14882708862) and microsoft-catalog-a2dp-audit.zip (14883494285). Package discovery succeeded; PSF payloads were not reconstructed; Winbindex exact hash identity was 0/3.
- UUP image audit #3 — in progress: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562, branch experiment/win10-a2dp-uup-image-audit-20261124, commit e9900fc894772997526995feeaecfff4a9ec5ff0. Targets: Win10 19045.5917 and Server 20348.5761.
- UUP audit attempts 1 and 2 (runs 45317386782 and 45317399103) failed during downloader bootstrap because the child helper did not expose Get-FileHash; the current attempt adds a local SHA-256 fallback and prioritizes Windows PowerShell 5.1.

## 2026-11-24 05:20 — Win10 package audit runs

- **CI #463:** success — [45311922753](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45311922753), branch `experiment/win10-a2dp-symbol-audit-20261124`, commit `4459e152886cec3c2d4a2f0458a5467469c7b3dc`. Catalog package extraction only; no driver installation/runtime test.
- Artifacts: `microsoft-catalog-a2dp-audit.zip` ID `14883494285`; `win10-a2dp-symbol-audit-metadata.zip` ID `14882708862`. Metadata-only copies are stored in Library `/LDAC Project/Incoming`; see ARTIFACT_INDEX.
- **UUP image audit #3:** in progress — [45317582562](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562), branch `experiment/win10-a2dp-uup-image-audit-20261124`, commit `e9900fc894772997526995feeaecfff4a9ec5ff0`. Targets Win10 19045.5917 / Server 20348.5761.
- Code branch `server-2022-oppo` remains `39eea45ab5d93c09836819db75f2a64177fbf09a`.

## 2026-11-24 — UUP audit #3 failure and corrected reruns

| Run | Commit | Result | Notes |
|---|---|---|---|
| [#3 / 45317582562](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562) | `e9900fc894772997526995feeaecfff4a9ec5ff0` | FAILED — harness | `Get-WindowsImage` result had no `Version` property; failure before image mount; no artifact |
| [#4 / 45325486392](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325486392) | `144d42105a26d5aa21f159ae068b17a047f724a9` | IN PROGRESS at update | Offline SOFTWARE-hive identity check; HAL/SleepStudyHelper/WDFLDR/ksecdd references |
| [#5 / 45325586394](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45325586394) | `e947970356884ead996bcc7347fa0e5554aa770b` | IN PROGRESS at update | Latest script; adds matching Win10 BtaMPM companion export reference |

No run in this block has established PE compatibility, CAT membership, driver staging/load, A2DP endpoint, SBC negotiation or audio. Run #3 produced no artifact. Do not report it as a successful image audit.

## 2026-11-24 — static INF binding delta (no build)

The archived comparison transcripts `00-33.txt` and `00-34.txt` reveal the Server generic 0x110B fallback versus the Win10 dedicated A2DP source INF/common install chain (E-162). This was a read-only static review of existing Library artifacts; no build, package stage, CI run, driver installation or runtime test was performed. The UUP image runs #4/#5 remain the separate PE/CBS/catalog audit gate.

## 2026-11-24 — LDAC codec/DLL source audit (no build)

Read-only source audit only. The current fork statically links AOSP libldac 2.0.2 encoder + ABR into `ldacsvc_core`; no DLL was built. Incus Multicodec contains a source build recipe for a separate `ldac.dll` encoder wrapper but no checked-in binary. The decoder build is verification-only. No CI/build/run ID, PE hash, DLL import/export table or runtime test was produced. See E-163.


## 2026-11-24 07:13 — UUP audit harness correction

| Run | Branch / commit | Result | Artifact / evidence |
|---|---|---|---|
| UUP audit #4 / 45325486392 | `experiment/win10-a2dp-uup-image-audit-20261124`, `144d42105a26d5aa21f159ae068b17a047f724a9` | FAILED — parser harness | Server image identity 20348.5761 / ServerDatacenter verified; `int(None)` on AudioEndpointBuilder.dll delay-import hint; no metadata artifact |
| UUP audit #5 / 45325586394 | same branch, `e947970356884ead996bcc7347fa0e5554aa770b` | FAILED — same parser harness | Same Server identity; same TypeError; no metadata artifact |
| UUP audit #6 / 45332165839 | same branch, `6778022b4453857e53acf8a18afe54bb7e46f5f5` | IN PROGRESS at update | Three PE parser regression tests passed; UUP extraction/audit still running; no result accepted yet |

The failures in #4/#5 are not binary or OS compatibility results. Do not use them as evidence against BthA2dp. No driver/runtime build or physical-host test was performed.


## 2026-11-24 07:18 — CBS package ownership evidence (CI #463)

- CI #463 / run 45311922753 / artifact 14883494285 / ZIP SHA-256 `2cd35a38abcdcde42fb0e175dfa042715aae8bb7e6eb2adf9c40c475886c9d38`.
- KB5036979 MUM `Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.4355.mum` declares the A2DP common INF assembly as `dualModeDriver` version 10.0.19041.4355, and also declares BtaMPM plus A2DP source/sink INFs.
- KB5126657 latest MUM declares A2DP common 10.0.19041.7802 and BtaMPM 10.0.19041.7725.
- Server KB5126655 scan has no corresponding A2DP/BtaMPM MUM/manifest hits.
- Status: STATICALLY_VERIFIED — CBS ownership only. Standalone DriverStore staging, exact CAT membership, Server INF applicability and runtime remain untested.


## 2026-11-24 07:22 — third-party LDAC candidate screening

No build or installation was performed. Public documentation screening only:
- Alternative A2DP Driver 1.8.3: officially supports Win10 22H2 / Win11 21H2–25H2, not Server 2022; uses inbox Bluetooth stack and per-device kernel driver; supports LDAC/SBC/ABR; proprietary EULA, hardware-bound license, no redistribution/reverse-engineering.
- BlueCaster: Win10 22H2/Win11; user-mode BTstack + WinUSB; dedicated USB adapter takeover; BTstack personal/non-commercial limitation unless separately licensed.
- No third-party installer or binary was downloaded, staged, installed or patched.


## 2026-11-24 08:39 — exact Win10 A2DP PE audit (UUP audit #6)

- Run [45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839), job 138235648697, experiment commit 6778022b4453857e53acf8a18afe54bb7e46f5f5, conclusion success.
- Artifact 14895876155, 328,218 bytes, SHA-256 c1792bd8e5bcdf2a583c3738eeb22bdf27a64ba6ad2701ad70aa8f879d045209.
- Exact Win10 19045.5917 and Server 20348.5761 image identities verified from offline SOFTWARE hives.
- Exact DriverStore BthA2dp 10.0.19041.4355 hash matched archived capture; all 149 imports resolve against Server 20348.5761 exports plus exact Win10 BtaMPM.
- Exact BtaMPM 10.0.19041.5848 has 42 imports / 14 exports; all 42 imports resolve against Server exports.
- No build, staging or runtime test. Artifact contains metadata/text PE reports only; no Microsoft SYS/DLL/ISO payloads.
- UUP audit #7 [45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564) is in progress for offline catalog membership and SYSTEM service registry inventory. Branch experiment/win10-a2dp-catalog-registry-audit-20261124, commit 5bdbc75d904beb8c5f84787cc592ae9134df40c6.

## CI #11 — offline UUP catalog and service inventory (2026-11-24)

- Workflow run: 45347639357 — https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45347639357.
- Job conclusion: failure after both image records completed and the script printed UUP image audit complete; artifact upload succeeded. Exact cause of the final process exit code 1 remains a tooling issue, not a package compatibility failure.
- Artifact ID: 14901033654; size 331,349 bytes; SHA-256 277ed892887f10383e34bb9f3c3690a0ebdf290d32cb9f4899d6016e78fbadff.
- Result: all five Win10 A2DP package files verified against the same Win10 CBS servicing CAT. Server catalog membership was not checked.
- Follow-up code branch: experiment/win10-a2dp-cross-sku-catalog-audit-20261124; script commit 05555dc8fac8b2f551826b71cba40084defe9a46; workflow commit 08663c4ca7d1536b96c554fd5e484382262b1250.
- No driver build or runtime test was performed.

- Follow-up audit's latest script commit: 11f0c4776b3d1ed6c79f5dca75634dda40c19ba9; matched CAT signer/status is now recorded with Get-AuthenticodeSignature.

## 2026-11-24 — cross-SKU catalog audit and stage-smoke harness

| Run | Branch / commit | Result | Evidence |
|---|---|---|---|
| CI #12 / [45354874225](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45354874225) | experiment/win10-a2dp-cross-sku-catalog-audit-20261124, 08663c4ca7d1536b96c554fd5e484382262b1250 | SUCCESS — Win10 CAT membership 5/5; Server membership 0/5; Server positive controls 4/4 | Artifact 14907426966; ZIP SHA-256 655d93a43fc599c393988cec830e1914639fd1560ff957cea488295077bf7e8a |
| CI #13 / [45355817586](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45355817586) | same branch, 11f0c4776b3d1ed6c79f5dca75634dda40c19ba9 | FAILED — UUP Dump reported WU_REQUEST_FAILED; harness then dereferenced missing data; no compatibility result | No artifact |
| Stage smoke #1 / [45371500131](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371500131) | experiment/win10-a2dp-stage-smoke-20261124, 692cb1a5e4df7de5ca0ebc72e61878c1c62df300 | FAILED — PowerShell parser caught unescaped $name: interpolation before UUP download | Harness-only failure |
| Stage smoke #2 / [45371573832](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371573832) | same branch, 32fe8206781cdf41955348a18bf3671c998e71bb | FAILED — same parser issue; run started before parser fix | Harness-only failure |
| Stage smoke #3 / [45371687882](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882) | same branch, 3305dddcb18f4e407e6b61762a2539a77412ea2d | IN PROGRESS at 2026-11-24 12:10 Kyiv | Parser preflight passed; UUP extraction/stage step running |

Stage-smoke scope: disposable GitHub-hosted Windows Server 2022 runner; explicit CAT verification; PnPUtil DriverStore staging without /install; optional SignTool catdb add/remove; cleanup. It does not bind a device or prove service start, driver load or audio. No physical host or production code branch is touched.



## Stage-smoke run #3 — current execution review (2026-11-24 12:25 Europe/Kyiv)

- Run [45371687882](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882), job 138367259323; branch `experiment/win10-a2dp-stage-smoke-20261124`.
- Script commit `3305dddcb18f4e407e6b61762a2539a77412ea2d`; workflow commit `692cb1a5e4df7de5ca0ebc72e61878c1c62df300`.
- Steps 1–6 passed; step 7 is still in progress. No artifact/result is available yet.
- Runner preflight enforces Server 2022 build 20348 / InstallationType=Server and records UBR, but does not pin UBR 5761. Interpret the eventual result only at the recorded UBR. If different from 5761, a separate exact-UBR disposable VM test is required before making a 20348.5761-specific claim.
- Test scope remains CAT verification and DriverStore staging without `/install`; no device binding or driver load.

## A2DP package stage-smoke experiments — 2026-11-24

| Run | Branch / commit | Target runner | Artifact | Result |
|---|---|---|---|---|
| Stage-smoke #3 / 45371687882 | `experiment/win10-a2dp-stage-smoke-20261124` / `3305dddcb18f4e407e6b61762a2539a77412ea2d` | Server 2022 build 20348.5870 | 14910689667; 152,010 bytes; SHA-256 `431f94d613a177c2d78735fad72844aab1b9fd04782641e5e39532525ee65c08` | Offline audit script failed with missing `Name` property before stage-smoke; no CAT/staging result. **REJECTED — TOOLING FAILURE** |
| Stage-smoke #4 / 45381650079 | `experiment/win10-a2dp-stage-smoke-20261124` / `4d5734fb19929dc332dfb572e9824151c470b62b` | Server 2022 build 20348; exact UBR pending | Pending | Safe exception capture + per-stage trace markers; step 7 active at last check. **IN PROGRESS** |

Run #3 artifact is preserved in Library at `/LDAC Project/Incoming/CI-3-stage-smoke-failure.zip` (Library ID `libfile_87489e2386f48191a54635114c06391a`). The PE JSONs are metadata only; no SYS/DLL/INF/CAT payload is retained.

Neither run proves package staging, PnP binding, service start, driver load, endpoint, SBC negotiation or audio. A hosted result on UBR 5870 must not be labelled as an exact 20348.5761 result.
