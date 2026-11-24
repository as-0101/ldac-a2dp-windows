# Artifact index

This index records durable locations and provenance. Exact hashes are only recorded when measured or supplied by a primary artifact/report. Do not treat a mention as proof that bytes are available.

## User-provided project context files

| File | Project/Conversation file ID | Library ID | Size / SHA-256 | Purpose / status |
|---|---|---|---|---|
| `LDAC_Project_Status_2026-11-22.txt` (current Project Source upload) | `file_000000009e588210b1ac60a958976a9b` | Search found older durable copy `libfile_7829d917520081919e39fbc4c2a1eefc` (`file_000000001ff48210a40943e964b9a35a`) | 7,154 bytes; SHA-256 `c85258bf9d64e2ce85cf00c70e7d88645bcfaa53d004265aab0cda578cebc85f` | Initial status snapshot; superseded by later dated GitHub/Notion updates. Current Source upload and Library copy appear same name/content; verify exact bytes before claiming duplicate identity. |
| `LDAC_Project_Reorganization_Instructions.md` | `file_000000003eb0821095a1edc72cc0d70e` | `libfile_cff6d57284248191805a6557030367ff` | 32,897 bytes; SHA-256 `a633dc1eeab5ac3929bba9006e73a7b4795592d93316fce0a4b0a6d77d701004` | User's reorganization specification; preserved in Project Sources and Library. |
| `A2DP_Server2022_Environment_20261119_180132.txt` | `file_000000006424821088aec377a93ea3a3` | `libfile_3d99bcfe8d6881919b670cfdfe924eea` | 28,300 bytes; hash not measured in this pass | Read-only environment snapshot from 2026-11-19; historical, not current host state. |
| `CODEX_TASK.md` | Not found in audited repo tree or Files search | — | — | NOT_FOUND / NOT_PERSISTED in accessible sources; do not reconstruct. |

## CI/build artifacts

| Artifact | Exact identity | Durable location / status |
|---|---|---|
| CI #133 test package | GitHub artifact 14763242251; outer ZIP SHA-256 `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad` | Library `libfile_60473151996c8191afd738dd16568422`; Project file `file_00000000930c82108b163ba2ebce2681` |
| CI #133 unsigned driver + PDB | GitHub artifact 14763157658; archive SHA-256 `1302c21c3278af9134b5959577a6daa629d0649fd1405148012e074e8147db9` | Library `libfile_964eaac2a28081919289a0387170570d`; Project file `file_000000009bc48210b592ba4406f4af98` |
| CI #248 hosted load report | GitHub artifact 14769048266; ZIP SHA-256 `e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb` | Downloaded to this conversation as `file_00000000ccc882109376b8d31becb174`; Library persistence pending. |
| CI #248 test package | GitHub artifact 14768714620; ZIP digest `b1ac0c4bd52bc965e549de18c584655331e7c7d58cdc9a02acb35e17528f175c` | Temporary GitHub artifact, expires 2026-11-29 unless saved elsewhere. |
| CI #248 unsigned driver | GitHub artifact 14769077870; ZIP digest `a021fbdd49e803e88f1e7860859d9299ab5112394b39e2204107e72d6400fbc8` | Temporary GitHub artifact, expires 2026-11-29 unless saved elsewhere. |
| CI #255 ACX stub metadata | GitHub artifact 14769755224; ZIP digest `8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce` | Temporary GitHub artifact; inspect/preserve before expiry. Contains actual WDK stub libraries and manifest. |
| Hosted LiveKD run #15 | GitHub artifact 14768915976; archive digest in PROJECT_STATE | Temporary artifact; contains direct hosted Server 2022 ACX class v1.0 result. |

## Important technical source records

- [Project state](../docs/agent/PROJECT_STATE.md) — authoritative dated evidence and exact hashes.
- [Evidence register](../docs/agent/EVIDENCE.md) — claim-level provenance.
- [Build registry](BUILD_REGISTRY.md) — per-run build identity.
- [Test matrix](TEST_MATRIX.md) — test-stage results.
- [Notion handoff](https://app.notion.com/p/420769fff636812ab023c0fb67c66a5a) — older detailed index; reconcile with this file.
- [Notion journal](https://app.notion.com/p/41f769fff636810fbd50c285bc3d33f6) — append-only history.

## Ingestion protocol for every new user file

1. Preserve original bytes and original filename.
2. Confirm Project Sources availability; do not claim the assistant can attach a file to Sources unless the product surface confirms it.
3. Save a Library copy under `/LDAC Project/Incoming/` when available.
4. Measure SHA-256 and size from original bytes.
5. Add exact file IDs, Library IDs, path, date, hash, purpose, and links to related tests/builds.
6. For archives, preserve the original archive and separately record its full member listing.
7. Record derivatives with source file ID, tool/version, and transformation.
8. If a step fails, mark `NOT_PERSISTED` and report it.
9. Before requesting re-upload, search Project Sources, Library, this index, GitHub and Notion.


## Durable Library copies created during reorganization — 2026-11-22

| File | Library path | Project/Library IDs | Size / SHA-256 |
|---|---|---|---|
| `LDAC_Project_Source_START_HERE.md` | `/LDAC Project/Project Source/LDAC_Project_Source_START_HERE.md` | Project file `file_0000000015d48210a463663038ecbd0d`; Library file `file_0000000082f882109ca4a9f9b180919b`; Library ID `libfile_48b2df44b1ac8191bc854fb0ca710c5c` | 7,289 bytes; SHA-256 `f9d04af187f406057fdff92544b0dcf76b62389c14edd94d6bf1154ba8bce44b` |
| `CI-248-acx10-hosted-load-report.zip` | `/LDAC Project/Incoming/CI-248-acx10-hosted-load-report.zip` | Project file `file_00000000ccc882109376b8d31becb174`; Library file `file_0000000015588210944830d9d3b27af4`; Library ID `libfile_f9a6457e083881918777d501d24e13d7` | 8,617 bytes; SHA-256 `e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb` |
| `CI-255-ACX-stub-metadata.zip` | `/LDAC Project/Incoming/CI-255-ACX-stub-metadata.zip` | Project file `file_0000000032408210a2e5b11e2faa35be`; Library ID `libfile_5c85caa58938819180c99a4fdacbe4ea` | 751,747 bytes; SHA-256 `8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce` |
| `CI-248-ACX10-test-package.zip` | `/LDAC Project/Incoming/CI-248-ACX10-test-package.zip` | Project file `file_0000000088e88210891be91840374d63`; Library ID `libfile_df8cc4ddeaf081918fa485ac709aca9c` | 195,313 bytes; SHA-256 `b1ac0c4bd52bc965e549de18c584655331e7c7d58cdc9a02acb35e17528f175c` |
| `CI-248-ACX10-unsigned-driver.zip` | `/LDAC Project/Incoming/CI-248-ACX10-unsigned-driver.zip` | Project file `file_00000000bff48210b7fb6ebd8b88a4b5`; Library ID `libfile_031e3b04b4ec81918e7bc06c0bb8dcd1` | 339,119 bytes; SHA-256 `a021fbdd49e803e88f1e7860859d9299ab5112394b39e2204107e72d6400fbc8` |

Incoming user instructions file is preserved separately: `LDAC_Project_Reorganization_Instructions.md`, Project file `file_000000003eb0821095a1edc72cc0d70e`, Library ID `libfile_cff6d57284248191805a6557030367ff`, 32,897 bytes, SHA-256 `a633dc1eeab5ac3929bba9006e73a7b4795592d93316fce0a4b0a6d77d701004`.

The CI #248 report and both CI #248 package archives plus CI #255 stub archive are now durably saved in Library; GitHub artifact retention is no longer the only copy. ZIP originals are preserved unchanged.

- **CI #10 ACX 1.0 sample probe build** — GitHub artifact 14774844743; SHA-256 d79c6bf6ed04de54c3c073edfd8e91fcfbe9d98ac8537aef951f2d03dfd21dc7; durable Library copy /LDAC Project/Incoming/CI-10-ACX10-Sample-Probe-Build.zip; Library file ID libfile_fbedf282d84081918ec9cbe9b9ed9094.
- **CI #10 ACX 1.0 sample probe runtime preflight** — artifact 14775099125; SHA-256 cb9bbc178c58cf7fe6681267c86151b34030b72e77fb0730e81b2230f5fd635b; Library copy /LDAC Project/Incoming/CI-10-ACX10-Sample-Probe-Runtime-Preflight.zip; Library file ID libfile_c3566576a8ac8191af380d74f0f17a57.
- **CI #11 ACX 1.0 sample probe build + manifest** — artifact 14775454304; SHA-256 7a40925a5b291fcef290a2a47e8f8036410b5f623562cdb3228d34652ee6033e; durable Library copy /LDAC Project/Incoming/CI-11-ACX10-Sample-Probe-Build.zip; Library file ID libfile_5b4bd62f5af4819191f72c3e2357d7f2.
- **CI #11 ACX 1.0 sample probe runtime preflight** — artifact 14776440518; SHA-256 380638450711410885f785bb75d99feec19020a17ac46ee0cb05ce9e446e9c2d; Library copy /LDAC Project/Incoming/CI-11-ACX10-Sample-Probe-Runtime-Preflight.zip; Library file ID libfile_7d9bb98142b881919332288dc98b1b19.
- Each Library copy was materialized and its SHA-256 matched the original GitHub artifact byte-for-byte.
- CI #12 (run 45078310971) produced no probe artifact because PowerShell parser validation failed before build/runtime. CI #13 (run 45078613003) build artifact/runtime report are pending completion and will be indexed in the next update.


## CI #13/#14 ACX 1.0 sample bind probe artifacts — 2026-11-23

All four GitHub artifacts were copied to Library and SHA-256 rechecked after materialization. Each ZIP remains unchanged.

| Artifact | GitHub run / artifact ID | Repository commit | Library path | File ID | Library ID | Size | SHA-256 |
|---|---|---|---|---|---|---:|---|
| CI #13 build | 45078613003 / 14776416132 | 35e700a3ecb74548b858f0479a1e15e31a2d110f | /LDAC Project/Incoming/CI-13-ACX10-Sample-Bind-Build.zip | file_00000000dc7c82308c042331f2aff619 | libfile_509f5b94f4308191bd673c86d486ebf9 | 122,613 | 35e2aba65e565b59beacbf1562294a7e75079a62c2f7a6bfd72b4c769467b600 |
| CI #13 runtime | 45078613003 / 14776347679 | 35e700a3ecb74548b858f0479a1e15e31a2d110f | /LDAC Project/Incoming/CI-13-ACX10-Sample-Bind-Runtime.zip | file_0000000024c88230a51233edbfa39a92 | libfile_a26ef569e41881919d92c23f68001dd9 | 149,036 | b3a26a3565b214355a64a48153074a725bd1320e0e09a78b9308d8a83bd330c4 |
| CI #14 build | 45081844225 / 14778135563 | 04518a83900a7e7aa093fe56a7669f91349d7588 | /LDAC Project/Incoming/CI-14-ACX10-Sample-Bind-Build.zip | file_0000000016308230b17fad479feda0cb | libfile_c94c662148a48191a58c215aa72e31aa | 123,366 | 2a266fa558e24745e2a991189da119101641112d18079935c68a0c61e872af86 |
| CI #14 runtime | 45081844225 / 14777212842 | 04518a83900a7e7aa093fe56a7669f91349d7588 | /LDAC Project/Incoming/CI-14-ACX10-Sample-Bind-Runtime.zip | file_00000000f4448230ba6ecc149356941e | libfile_74630d0600e08191b2014f0953d7ded8 | 151,169 | a141b772ff978f995a648c6fb68c4e8e1bd46d98cef314786da7e835cab0b312 |

The CI #13 sample SYS hash is 70BA9899BF1B54989E7C6C3F6C0DEDAE2ADFCEF16D7AE6A9803192E7C86EDAA6; CI #14 sample SYS hash is AE960C99DE0DA995621113118DDB2CC13FFACBF5F6BBC217C29CB5E4CF6E91D4. Both contain ACX 1.0 / 210-function / 62-structure descriptor metadata. CI #15 build and runtime artifacts are now durably saved in `/LDAC Project/Incoming/`; exact Library IDs and byte-for-byte verified hashes are recorded below.

## CI #15 sample bind artifacts — 2026-11-23

| Artifact | GitHub run / artifact ID | Repository commit | Library path | File ID | Library ID | Size | SHA-256 |
|---|---|---|---|---|---|---:|---|
| CI #15 build | 45082965356 / 14778450384 | `488ae8104eec960370c0887e07136a3e9e3846b5` | `/LDAC Project/Incoming/CI-15-ACX10-Sample-Bind-Build.zip` | `file_0000000088fc8230b404f1bc3423c8e8` | `libfile_c72211f203f88191a5895df8e19daf32` | 123,115 | `8e701ee7f69f1d9c855f5b2c3d4c06de39628dfb7e955ecb12877fc9f811e449` |
| CI #15 runtime | 45082965356 / 14778137925 | `488ae8104eec960370c0887e07136a3e9e3846b5` | `/LDAC Project/Incoming/CI-15-ACX10-Sample-Bind-Runtime.zip` | `file_0000000070a88230a7da7802d7525cfc` | `libfile_553acf157ff88191b459dfdf42911d8a` | 152,791 | `aa63c8dfbce7b9b319d9117e1be7b8db1565ff85a0d56c08e57c9de98710e59b` |

Both Library copies were materialized and SHA-256 matched the original GitHub artifact bytes. Runtime package inner hashes: SYS `BAB3C54C0EAB186CC8C9D89B07BCA871112454175C0C45F8D199DA57927114B6`; INF `CC2A09F6D2F8590DA5395CB366FE62C83164D48EF8B227E3B0004447E0112DC7`; CAT `9A120CCB4D5B8781EED86D50C096A5A95CC59140954A5A1E9830F0875A42ABD8`; PDB `4FDC48C1C86C33DC6939A8130E8CD594016E80EA64DB3ADADE846D083B03CCB7`. Build and runtime SYS/INF/PDB bytes match; the CAT differs because the runtime package is signed with the ephemeral test certificate.

GitHub artifact retention is 14 days from the run; durable Library copies are retained independently.


## CI #16 sample bind probe and descriptor report — 2026-11-23

The original GitHub artifacts were downloaded again and compared byte-for-byte with their durable Library copies. All three hashes below match. The build ZIP digest previously transcribed in PROJECT_STATE was wrong; this is the verified digest.

| Artifact | GitHub run / artifact ID | Repository commit | Library path | Project file ID | Library ID | Size | SHA-256 |
|---|---|---|---|---|---|---:|---|
| CI #16 build | 45084678951 / 14779061024 | `9da48c3ecd5921f8cab47888325b156dc9a536f3` | `/LDAC Project/Incoming/CI-16-ACX10-Sample-Bind-Build.zip` | `file_00000000bca08211bc1de8bfd1963463` | `libfile_302ac31a94f881919afbd7001981672d` | 126,939 | `d332fc338cbd8c4aa41f56338bb68104059b2956558067362d69b495a0ba8e72` |
| CI #16 runtime | 45084678951 / 14779107472 | `9da48c3ecd5921f8cab47888325b156dc9a536f3` | `/Bluetooth LDAC Research/Artifacts/CI-16-ACX10-Sample-Bind-Runtime.zip` | `file_00000000f95c8210885725aee73f1356` | `libfile_f82f167acb64819197c7a42682180d12` | 162,186 | `7d53835ecaababca7451c19e0ce79bab7186f9e59568fcc3a3b047efa3e95214` |
| CI #16/#255 descriptor compatibility report | Derived from CI #16 runtime artifact 14779107472 and CI #255 stub artifact 14769755224 | `9da48c3ecd5921f8cab47888325b156dc9a536f3` | `/LDAC Project/Incoming/CI-16-255-Descriptor-Compatibility-Analysis.md` | `file_00000000373c8209b70496924c4066c6` | `libfile_7382ad8229608191bf4927498dd58227` | 6,016 | `8523e7f5063c829541adae3fcacad0fe97e6f7eee4c39a914d16d7dce86bac5a` |

Inner build package hashes from `build-manifest.json`: SYS `F7BAE855C1B184ABCF0BFCBC258EF11740700788BC08270A3C22041E76860E37`; INF `25C1E5AAEF51FB417E6E0ED2113C33841A08D4DDC05DABF60AA7AFB1BF41CD39`; PDB `7B2FEDE81388EDA93FD930B2B88A47FDFB72BC8686A7C47D7967A449D7863855`. The full 17,174,368,256-byte LiveKD dump is not included in the runtime ZIP; its hash and zero-missing-page count are preserved in the debugger transcript/capture report.

## CI #17 pending artifact state — 2026-11-23 12:53 Kyiv

Workflow run 45158705058 / commit `79460f03492a54444473589dd142da864a703a73` is still in its build step. No build/runtime artifact exists yet. Add artifact IDs, original ZIP hashes, Library IDs and inner SYS/INF/PDB hashes only after the workflow produces and verifies them.


## CI #17 — EWDK 20348.1 inspection report (2026-11-23)

- Workflow run: [45158705058](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45158705058)
- Branch / commit: `experiment/acx10-wdk20348-control` / `79460f03492a54444473589dd142da864a703a73`
- Artifact ID: `14814207710`
- Name: `acx10-wdk20348-control-build.zip`
- Size: 2,156 bytes
- ZIP SHA-256: `2c8f73e08ce5ba7e24ac6d61198a4b03932f482e9527614eed84b4ecb4c9a3f6`
- Purpose: provenance/report from the official EWDK 20348.1 inspection.
- Result: `EWDK_ACX10_STUB_FOUND=false`; no ACX 1.0 probe SYS was built and the hosted runtime job was skipped. The green workflow status reflects successful inspection/skip logic, not a driver test.
- Retention: GitHub Actions artifact; preserve before expiry if later analysis requires it. No durable Library copy is claimed.


## Windows 10 A2DP source and Server comparison artifacts — 2026-11-23

All paths below are in Library folder `/Bluetooth на Windows Sever 2022/`. File IDs are recorded for exact retrieval; no file was re-uploaded during this run.

| Artifact | File ID | Library ID | Size | Status / use |
|---|---|---|---:|---|
| `Bluetooth-A2DP-Compare-AS-KRM-WIN10-20261123-204910.zip` | `file_00000000d88c8210b1f196dcd824b5de` | `libfile_40e5b2f397548191adf91284ec279e0d` | 3,395,313 bytes | Historical 20:49 partial comparison; superseded by the 23:49 package capture below |
| `Win10-Bluetooth-A2DP-20261123-201418.zip` | `file_000000006994821096915807feeeb159` | `libfile_ff5486df416081919f09274f08e8ea38` | 5,153,885 bytes | Win10 reference collector archive; package folders not included; prior project state records SHA-256 `3bebbee156019cfa6e1c031e8158c8d1e230fd6f64dd57f3a3bc5aae991254cd` |
| `Bluetooth-A2DP-Compare-AS-KRM-WS-20261123-204114.zip` | `file_000000002fc08210b073a5416f7ca6d7` | `libfile_b9bb8bde48908191b78e2d741b8ffa5d` | 3,140,988 bytes | Latest recorded Server 2022 read-only comparison snapshot; not a live host check |
| `Export-Win10-A2DP-Package.ps1` | `file_00000000ae6c82108239f67bdde421be` | `libfile_c5e086cd16e0819183aa8607e6c40e94` | 5,108 bytes | Read-only targeted package exporter; output produced as Win10-A2DP-Package-20261123-234936.zip; do not rerun |
| `Collect-Win10-Bluetooth-A2DP.ps1` | `file_00000000f4b08210aad8e3d4dd2e07eb` | `libfile_92cbe93ca6088191af6e314201155e50` | 14,623 bytes | Existing read-only collector; optional `-IncludeDriverPackages` copies active DriverStore package folders |
| `Collect-Bluetooth-A2DP-Compare.ps1` | `file_00000000187482108c2566e9f9e8147f` | `libfile_d1b948264d648191b4c9041736c4f387` | 7,815 bytes | Existing read-only Win10/Server comparison collector |

### Binary / INF facts currently recorded

| File | Version | Architecture | SHA-256 | Notes |
|---|---|---|---|---|
| `BthA2dp.sys` | `10.0.19041.4355` | PE machine not yet independently parsed | `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3` | 282,624 bytes; Microsoft A2DP profile driver |
| `microsoft_bluetooth_a2dp_src.inf` | `10.0.19041.1` | INF x64 target decoration to be audited | Not recorded | Thin source/profile binding; delegates to common INF |
| `microsoft_bluetooth_a2dp.inf` | Unknown | Unknown | Not available | Missing from current capture |
| Package catalog (.cat) | Unknown | N/A | Not available | Missing from current capture |

Archive SHA-256 is recorded only where explicitly stated in prior project evidence. The 20:49 Win10 comparison archive and 20:41 Server archive are historical snapshots; raw Project Source bytes were not available for local re-hashing in this run.

### Existing LDAC implementation references

- Current project AOSP encoder source: `third_party/libldac`, called from `service/encoder.cpp`; not a Win10 DLL.
- Alternative A2DP 1.8.3.1: documented `AltA2DP.sys` / `oem96.inf` on a separate Win11 laptop; no package binary currently indexed in Library.
- BlueCaster: external user-mode WinUSB/BTstack project; not copied into this repository or Library.

## Collector audit — 2026-11-23 23:40

| Existing file | File ID | Library ID | Size | Audited scope / limitation |
|---|---|---|---:|---|
| `Export-Win10-A2DP-Package.ps1` | `file_00000000ae6c82108239f67bdde421be` | `libfile_c5e086cd16e0819183aa8607e6c40e94` | 5,108 bytes | Read-only targeted A2DP INF/package capture; DriverStore + Windows INF only; no WinSxS, full DLL/COM scan, PE import/export parse, or CAT member verification |
| `Collect-Win10-Bluetooth-A2DP.ps1` | `file_00000000f4b08210aad8e3d4dd2e07eb` | `libfile_92cbe93ca6088191af6e314201155e50` | 14,623 bytes | Existing broad read-only collector; optional `-IncludeDriverPackages`; captures PnP/service/registry and selected system-driver context |
| `Collect-Bluetooth-A2DP-Compare.ps1` | `file_00000000187482108c2566e9f9e8147f` | `libfile_d1b948264d648191b4c9041736c4f387` | 7,815 bytes | Existing Win10/Server comparison collector; does not replace PE/catalog audit |

The 23:49 Win10 package archive supersedes the 20:49 partial comparison: common/source/sink INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys are present. No local .cat is included; the system-supplied INFs have no CatalogFile directive, so identify the OS system catalog through WIM/CBS metadata rather than treating this as an unsigned package.


## Win10 A2DP package capture and PE audit — 2026-11-24 01:42

The 23:49 archive is the current package source. It supersedes the earlier 20:49 comparison archive's “common INF missing” status.

| Artifact | File ID | Size | Status / use |
|---|---|---:|---|
| Win10-A2DP-Package-20261123-234936.zip | file_00000000144c8210a8e309fe18b9e8c4 | 454,831 bytes | Current Win10 19045 package capture; common/source/sink A2DP INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys |
| Win10-A2DP-DriverStore-20261123-234936.zip | file_00000000b3888210bd459ae2490c25d9 | 135,772 bytes | DriverStore package directories |
| a2dp_pe_imports_report(2).txt | file_0000000033e482109479f740ed5a8030 | 8,098 bytes | Static imports for separate System32 BthA2dp copy |
| a2dp_pe_imports_report(3).txt | file_000000008d708210bada16b6cb44c429 | 8,098 bytes | Cross-check report for System32 copy |
| a2dp_pe_imports_report.txt | file_00000000f33882109a6b1f79c3aaf72d | 1,315,472 bytes | Broader PE import report |
| 00-33.txt | file_000000004d5882109961f477df8a1c48 | 29,125 bytes | Captured INF inspection output |
| 00-34.txt | file_000000004c208210bec65c68b97e9b69 | 5,564 bytes | Captured INF section/dependency output |

### Binary identities

| File | Version | Size | SHA-256 | Notes |
|---|---|---:|---|---|
| DriverStore BthA2dp.sys | 10.0.19041.4355 | 282,624 | 5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3 | Package copy; PE32+ x64; E-119 reports direct imports from ntoskrnl.exe only; no delay-import directory |
| System32 BthA2dp.sys | 10.0.19041.1 (secondary public corroboration; hash not matched) | 279,040 | 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737 | Different older copy; 8 import descriptors / 144 functions; do not merge with package-copy report |
| BtaMPM.sys | 10.0.19041.5848 | 43,008 | DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD | Imports ntoskrnl.exe, cng.sys and WppRecorder.sys |
| btampm.inf | 10.0.19041.5848 | — | c657a6b32ac8ccfdeef3c12630686b87c973dd114bee73aec288d86b989961ef | Class=SYSTEM, CopyFilesOnly for BtaMPM.sys |
| microsoft_bluetooth_a2dp.inf | 10.0.19041.4355 | — | 4f3b988b658e1e7f8b97e645c1c92be0ba270d4db76832dab871516eedcbcf0c | Class=MEDIA; Include/Needs closure and BthA2dp service registration captured |
| microsoft_bluetooth_a2dp_src.inf | 10.0.19041.1 | — | Not recorded | Matches remote A2DP Sink UUID 0x110B |
| microsoft_bluetooth_a2dp_snk.inf | Captured | — | Not recorded | Reverse direction; not needed for playback to earbuds |

### Corrections and limitations

- The common INF and BtaMPM files are present in the 23:49 archive. Do not request another Win10 collection for those files.
- The archive contains no package-local .cat, but the system-supplied INFs have no CatalogFile directive. Microsoft documents validation through system catalogs. The exact source catalog and CBS owner remain open.
- The two BthA2dp.sys hashes belong to different copies. The import report for one must not be applied to the other.
- Export tables, full delay-import/API-set data and exact Server 20348 import/export resolution remain incomplete.
- No ISO/WIM/ESD/CAB/MSU media was found in the current Library inventory. Do not ask for the already captured ZIP; the remaining image input is Windows 10 22H2 and Server 2022 WIM/component metadata.
- New detailed map: [WIN10_COMPONENT_AUDIT.md](../docs/agent/WIN10_COMPONENT_AUDIT.md).



## Server 2022 read-only Bluetooth/PnP evidence — 2026-11-24

| Artifact | File ID | What it establishes |
|---|---|---|
| A2DP_Server2022_Environment_20261119_180132.txt | file_000000006424821088aec377a93ea3a3 | Archived Server 20348.5761 services, core Bluetooth driver files, missing btha2dp.sys and DriverStore INF folder inventory |
| A2DP_INF_Investigation.txt | file_0000000004ec8210a7a7c2273d7e5dbe | bth.inf generic service mapping and an empty A2DP INF FILES section; notes the rtka2dp DriverStore folder without exporting its INF bytes |
| ldac-precheck.txt | file_000000007b088210b26633c565ab08df | One present A2DP devnode and current binding oem75.inf |
| 20-36.txt | file_00000000f64082108f18eca5ae6a2fb0 | Detailed latest recorded PnP properties: custom LDAC A2DP Project provider/service, oem75.inf, DriverVer 0.2.325.1600, Code 37 / 0xC000000D |
| 17-45.txt | file_000000005394821082f50d54a99d9133 | Earlier custom-driver package/rank comparison; historical only |
| A2DP_Server2022_NextGate.txt | file_000000006ac48210a535a619c14edeeb | Existing Server-side next-gate summary |

### Interpretation

- The 20-36 record is the latest recorded PnP evidence: the A2DP service node is present/enumerated; the custom LdacA2dp driver fails at start. It is not a test of Microsoft's Win10 BthA2dp package.
- Microsoft defines LOCALMFG as the local Bluetooth radio manufacturer. 0x0002 is Intel; 0x005D is Realtek. The current host's LOCALMFG&0002 therefore identifies the local Intel radio, not the OPPO earbuds.
- The rtka2dp DriverStore folder is not the active oem75 binding; its INF bytes/version were not captured. Public Realtek package IDs use LOCALMFG&005D, so it is not applicable to the current Intel radio.
- Earlier records that show Microsoft A2DP or BTAGService/BthAvctpSvc running are historical snapshots; E-132/E-133 are the later records for this audit.


## 2026-11-24 02:19 — codec and PE-parser provenance

| Artifact / reference | ID / URL | Version / size / SHA-256 | Purpose / status |
|---|---|---|---|
| `pe_imports_a2dp.py` | Project/Library file ID `file_000000002c8c821081ba77ee9d223c6f`; Library ID `libfile_6bda9621e34481918defd5640143d3de` | 3,380 bytes | Legacy parser source. **Invalid for descriptor enumeration**: no 20-byte increment in IMAGE_IMPORT_DESCRIPTOR loop. Retain for audit trail only. |
| `a2dp_pe_imports_report.txt` | Project/Library file ID `file_00000000f33882109a6b1f79c3aaf72d`; Library ID `libfile_d42044fdbba48191ba88ed214588123b` | 1,315,472 bytes | Superseded/invalid repeated-descriptor report. Do not use as an import closure. |
| Public BthA2dp PDB symbol index | https://lise.pnfsoftware.com/winpdb/DFB24CB4F18C0AA1A5BFD99419D85302B75DAAFEB253DD4A5CA22DFF65BA3385-BthA2dp.html | BthA2dp.sys 10.0.17763.168; SHA-256 DFB24CB4F18C0AA1A5BFD99419D85302B75DAAFEB253DD4A5CA22DFF65BA3385 | Secondary evidence of internal SBC/aptX codec classes and AVDTP; not the captured 10.0.19041.4355 binary. |
| AOSP libldac source import | https://github.com/as-0101/ldac-a2dp-windows/commit/95bb92866b0d77de20ee94694eb4be2979635947 | Upstream AOSP external/libldac commit `eeee1a3f` | Existing encoder source, statically linked into the project service; no Windows 10 DLL. Sony certification/licensing needs separate confirmation before product distribution. |
| BlueCaster v3.0.4 x64 portable release | https://github.com/SeiyaFunaokaJP/BlueCaster/releases/tag/v3.0.4 | 16,494,671 bytes; SHA-256 `3C27828065D6A20ABEF3B19B435B71D8F6053768CC0900934E15FD112346A024` | External release asset only; not downloaded or installed. Existing user-mode A2DP/LDAC path using BTstack+WinUSB; requires USB adapter, lists Win10 22H2/Win11, not Server 2022. BTstack personal/non-commercial license applies. |

### Parser provenance correction

The legacy 1.3 MB report is not a trustworthy multi-descriptor import report. Its generating script reuses the same descriptor offset for every loop iteration. The 8,098-byte reports (2)/(3) are separate outputs, but their corrected generating script was not found in the Library. Until those exact binaries are re-run with a retained parser and a second tool, treat the 144-function count as provisional. The GNU objdump E-119 report for the 282,624-byte DriverStore package copy remains a separate record and must not be conflated with the System32 report.


## Microsoft public symbol-index cross-check — 2026-11-24 02:35

| Captured binary | SHA-256 | Winbindex x64 hash-only page | What this proves / does not prove |
|---|---|---|---|
| DriverStore `BthA2dp.sys` (282,624 bytes; inventory version 10.0.19041.4355) | `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3` | https://winbindex.m417z.com/hashes/5f.html | Exact hash is indexed under `btha2dp.sys`; no version/OS/update/CAT metadata on the simplified page. |
| System32 `BthA2dp.sys` (279,040 bytes; separate secondary copy) | `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737` | https://winbindex.m417z.com/hashes/04.html | Exact distinct hash is indexed under `btha2dp.sys`; keep separate from DriverStore copy. |
| `BtaMPM.sys` (43,008 bytes; inventory version 10.0.19041.5848) | `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD` | https://winbindex.m417z.com/hashes/da.html | Exact hash is indexed under `btampm.sys`; no version/OS/update/CAT metadata on the simplified page. |

Winbindex README: https://github.com/m417z/winbindex. It states that full download links are generated for Microsoft's public symbol server (msdl.microsoft.com). The current tool path exposed only the hash-only pages; PE timestamp/virtual size, exact symbol-server URL, version mapping and catalog membership remain unverified. No binary was downloaded.


## Server 2022 support-scope references — 2026-11-24 02:48

| Reference | URL | What it establishes | Limitation |
|---|---|---|---|
| Bluetooth version/profile support in previous Windows versions | https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-support-in-previous-windows-versions | All Windows Server SKUs lack in-box Bluetooth wireless support; third-party IHV drivers may be available. The A2DP/AVDTP profile list is for Windows 10. | Does not say that no third-party Bluetooth stack can run on Server. |
| Bluetooth component guidelines | https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/bluetooth | QD ID 130847 lists Windows Server 2022 as a Bluetooth Host Subsystem qualification. | Host-subsystem qualification is not proof of an in-box A2DP profile or codec. |


## 2026-11-24 new artifacts

- docs/agent/WIN10_UUP_IMAGE_AUDIT.md — PSF delta finding, Winbindex collision evidence, exact UUP image IDs, acceptance criteria.
- Experimental branch experiment/win10-a2dp-uup-image-audit-20261124:
  - tools/research/extract_uup_image_a2dp.ps1 — offline UUP image extraction and PE metadata comparison.
  - .github/workflows/uup-image-audit.yml — disposable Windows Server 2022 CI workflow; metadata-only artifacts.
- CI #463 artifacts are attached to https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45311922753.
- UUP image audit run #3: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562, in progress.


## 2026-11-24 new artifacts

- docs/agent/WIN10_UUP_IMAGE_AUDIT.md — PSF delta finding, Winbindex collision evidence, exact UUP image IDs, acceptance criteria.
- Experimental branch experiment/win10-a2dp-uup-image-audit-20261124:
  - tools/research/extract_uup_image_a2dp.ps1 — offline UUP image extraction and PE metadata comparison.
  - .github/workflows/uup-image-audit.yml — disposable Windows Server 2022 CI workflow; metadata-only artifacts.
- CI #463 artifacts are attached to https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45311922753.
- UUP image audit run #3: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562, in progress.

## 2026-11-24 05:20 — CI #463 and parser artifacts

| Artifact | Location / ID | Size | SHA-256 / identity | Purpose |
|---|---|---:|---|---|
| CI-463-microsoft-catalog-a2dp-audit.zip | Library `/LDAC Project/Incoming`; file ID `file_000000007e6c81f5a6fed066326780e7`; Library ID `libfile_4cce95d91fac8191894670146376ad23`; CI artifact ID `14883494285` | 20,705,628 | `2cd35a38abcdcde42fb0e175dfa042715aae8bb7e6eb2adf9c40c475886c9d38` | Catalog package discovery, PSF delta classification, Server 20348.5866 runtime PE references; metadata only |
| CI-463-win10-a2dp-symbol-audit-metadata.zip | Library `/LDAC Project/Incoming`; file ID `file_00000000cb98821286ae83732b30ae46`; Library ID `libfile_6753685bdd608191ab683fd3427b1b98`; CI artifact ID `14882708862` | 23,803 | `2fd33c77ef3a8a6ad99201c2b66322a00c803c6b8fe4144128c33e0e738f3408` | Winbindex metadata and non-exact PE reports |
| `pe_imports_a2dp_fixed.py` | Library file ID `file_000000006ac88210b1f6b3d695278455` | — | No script SHA-256 captured | Correct 20-byte descriptor stepping; direct imports only |
| `a2dp_pe_imports_report(2).txt` | Library file ID `file_0000000033e482109479f740ed5a8030` | 8,098 | Byte-identical to report (3) | 279,040-byte System32 BthA2dp copy only |
| `a2dp_pe_imports_report(3).txt` | Library file ID `file_000000008d708210bada16b6cb44c429` | 8,098 | Byte-identical to report (2) | Same System32 copy; not DriverStore BthA2dp |
| `tools/research/audit_pe_binary.py` | Experiment branch blob `e6ae095e3b33e96dc19ca90c1f2b595a851ac285` | — | Git blob SHA, not file SHA-256 | Headers, direct/delay imports, exports, VERSIONINFO, API-set names and optional export comparison |
| `tools/research/extract_uup_image_a2dp.ps1` | Experiment branch blob `91effff2d036a63caa0b130578fe3dcd538220ab` | — | Git blob SHA, not file SHA-256 | Offline UUP image extraction |
| `.github/workflows/uup-image-audit.yml` | Experiment branch blob `dede61e2962691d9d4c3f1c0f7924d9265d10fb9` | — | Git blob SHA, not file SHA-256 | Disposable Server 2022 metadata-only audit workflow |

CI #463: [45311922753](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45311922753). UUP audit #3: [45317582562](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45317582562), in progress.

## UUP audit failure and corrected reruns — 2026-11-24

| Artifact / source | Identity | Purpose / status |
|---|---|---|
| UUP audit #3 | Run `45317582562`; commit `e9900fc894772997526995feeaecfff4a9ec5ff0`; job `138188044012` | Failed before image mount because `Get-WindowsImage.Version` was absent. No metadata artifact was uploaded. |
| Offline image identity fix | Commit `144d42105a26d5aa21f159ae068b17a047f724a9`; script blob `2e0bd7e213c7ede02e8d61461e9d442e0e871fad` | Verifies CurrentBuild.UBR and EditionID from a copied offline SOFTWARE hive; adds four omitted kernel dependencies. Git blob SHA is not a file SHA-256. |
| Win10 BtaMPM companion fix | Commit `e947970356884ead996bcc7347fa0e5554aa770b`; script blob `b4eaf2fa5cb4372710fe087b0afb0f46c44276a9` | Adds matching Win10 BtaMPM.sys to the PE export reference set for BthA2dp. Git blob SHA is not a file SHA-256. |
| UUP audit #4 | Run `45325486392`, commit `144d42105a26d5aa21f159ae068b17a047f724a9` | In progress at update; does not include the later companion-copy change. |
| UUP audit #5 | Run `45325586394`, commit `e947970356884ead996bcc7347fa0e5554aa770b` | In progress at update; latest experiment revision. |

The source Win10 package archives remain in Project Sources/Library and were not recollected or re-exported. Run #3 had no artifact; inspect #4/#5 artifacts only after completion. No Microsoft binary payload or image is committed to Git.

## A2DP profile binding evidence — 2026-11-24

| Artifact | Project Library identity | Evidence |
|---|---|---|
| `00-33.txt` | file `file_000000004d5882109961f477df8a1c48`; Library ID `libfile_652152c5c384819180d7047bc6f017d9`; 29,125 bytes | Archived Win10/Server INF comparison: Server `bth.inf` generic 0x110B fallback; Win10 `microsoft_bluetooth_a2dp_src.inf` base-UUID match and Include/Needs chain |
| `00-34.txt` | file `file_000000004c208210bec65c68b97e9b69`; Library ID `libfile_c0db9e79a6d4819187b64773debbc45e`; 5,564 bytes | Archived common INF / KS / WDMAUDIO section comparison: BthA2dp service and KSCATEGORY_AUDIO interface registration |
| E-162 | `docs/agent/EVIDENCE.md` | Static INF evidence only; no package staging, service start, endpoint, SBC negotiation or audio |

These are existing Library artifacts. No new collection or materialization was required.

## LDAC codec/transport source inventory — 2026-11-24

| Artifact | Source identity | Role / status |
|---|---|---|
| `third_party/libldac/inc/ldacBT.h` | repo branch `server-2022-oppo`; blob `f43820cc3444ac624fd87ee45019598c80f965f6` | AOSP/Sony LDAC encoder C API declarations |
| `third_party/libldac/abr/inc/ldacBT_abr.h` | blob `135238ff1b673ab4cceafec670c542fcceef2d63` | LDAC adaptive-bitrate C API declarations |
| `third_party/libldac/src/ldacBT_api.c` | blob `a490a62451cb61c8c2d352b3e16c29ddcbe01691` | `ldacBT_get_version()` returns 2.0.2 |
| `CMakeLists.txt` | blob `1c9f6e01f541c4b8b04837119f2ecf55c55cb67e` | Static `ldacBT_enc` / `ldacBT_abr` linked into `ldacsvc_core` |
| `service/encoder.cpp` | blob `216b2d9d8c30b37030aefd3dcfcf494b0aedfadd` | Calls LDAC encoder and AVDTP media packetizer; no DLL boundary |
| `tools/ldacverify/build-ldacdec.py` | blob `6e673a95d09ceed379cb251294f56be00fbb3565` | Fetches `anonymix007/libldacdec` commit `c90094b15e25aef0e47c6d775fa94aceb36cabbc`; verification-only decoder |
| [Incus Multicodec](https://github.com/incustechsupport/incus-multicodec) | `btmulticodec/ldac.py`, `native/build.cmd` | Builds `ldac.dll` from libldac source; no prebuilt DLL committed; encoder only; Bumble + WinUSB transport |
| [BlueCaster](https://github.com/SeiyaFunaokaJP/BlueCaster) | repository README | BTstack + WinUSB user-mode A2DP source; adapter takeover; Windows 10 22H2/11, Server 2022 not declared |
| [OpenA2DP](https://github.com/RafiMota/open-a2dp) | repository README | Pre-alpha; driver build/runtime not established |
| Upstream parent | [yariktop133/ldac-a2dp-windows](https://github.com/yariktop133/ldac-a2dp-windows) | Current fork parent; Windows 11 / ACX 1.1 / test-signing path, not Server 20348 drop-in |

Git blob identifiers above are not file SHA-256 values. No Incus `ldac.dll` binary was built or hashed in this audit.


## 2026-11-24 07:13 Europe/Kyiv — PE parser correction and UUP rerun

| Artifact | Identity | Purpose / status |
|---|---|---|
| PE parser fix | Experiment commit `6778022b4453857e53acf8a18afe54bb7e46f5f5`; parser Git blob `fb2ec06a56f39e196a3e482c7fe3b8396ef15b0f` | Treat absent delay-import hint as null instead of calling `int(None)`; Git blob SHA is not a file SHA-256 |
| Regression tests | `tests/test_audit_pe_binary.py`; Git blob `941e15984dd1d725326bcc09a703712eca1b3aa0` | Tests named delay-import with missing hint, ordinal import with missing hint, and numeric named-import hint |
| UUP workflow update | `.github/workflows/uup-image-audit.yml`; Git blob `fec810d613874df33a61b4c32bf6699516d95702` | Adds regression-test path trigger and runs unit tests before downloading UUP images |
| UUP audit #4/#5 | Runs `45325486392` / `45325586394` | Both failed in the parser after verifying Server image identity; no output artifact |
| UUP audit #6 | Run `45332165839`; commit `6778022b4453857e53acf8a18afe54bb7e46f5f5`; job `138235648697` | Regression tests passed; image audit still running; no metadata artifact available at this update |

No Microsoft binary payload or UUP image was committed. Existing Win10 source package archives were not recollected.
