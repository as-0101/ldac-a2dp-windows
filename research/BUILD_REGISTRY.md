# Build registry

Status vocabulary: `BUILT`, `STATICALLY_VERIFIED`, `VM_TESTED`, `HARDWARE_TESTED`, `REJECTED`, `SUPERSEDED`, `UNKNOWN`. A CI workflow's green result is not a runtime test.

| Build / run | Branch and commit | DriverVer / ACX / target | Artifact identity | Evidence and outcome | Status |
|---|---|---|---|---|---|
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
