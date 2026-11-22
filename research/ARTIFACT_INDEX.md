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
