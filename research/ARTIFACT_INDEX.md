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
