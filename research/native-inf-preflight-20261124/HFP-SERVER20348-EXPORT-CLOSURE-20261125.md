# HFP donor -> Server 2022 export-name closure (manual automation re-run)

**Status: CONFIRMED static name-only closure, 229/229, no missing imports.**
**Scope:** Saved Win10 donor HFP PE JSON metadata vs saved hosted Windows Server 2022 Datacenter x64 **20348.5866** export tables; package-supplied BtaMPM.sys from the original Win10 A2DP metadata ZIP. This analysis did not install, sign, load or execute any driver. The owner's physical Server snapshot was **20348.5761**, not this hosted baseline. A real duplex voice call is still **UNTESTED**.

## Result: 229 imported function names, 0 unresolved

| PE input (pinned SHA256 prefix) | ntoskrnl.exe | HAL.dll | ks.sys | WppRecorder.sys | BtaMPM.sys | SleepStudyHelper.sys | ksecdd.sys | WDFLDR.sys | Total | Missing |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `BthHfAud.sys` `4e4d7e1f1a6d` | 43 | 1 | 35 | 4 | - | - | - | - | 83 | 0 |
| `BthHfEnum.sys` DriverStore `1e9a3ca8f834` | 45 | 1 | - | 4 | 7 | 8 | 7 | 4 | 76 | 0 |
| `BthHfEnum.sys` System32 `91c72c54142a` | 39 | 1 | - | 4 | 7 | 8 | 7 | 4 | 70 | 0 |
| **Sum** | 127 | 3 | 35 | 12 | 14 | 16 | 14 | 8 | **229** | **0** |

- All module names case-normalized. All imports had **names**, none were ordinal-only. The parser checks that each Server `dumpbin /exports` table matches the declared `number of names`; it skips `[NONAME]` entries rather than interpreting them as names. It checks forwarded exports separately: all 3 `HAL.dll!KeQueryPerformanceCounter` references forward to a valid `ntoskrnl.exe!KeQueryPerformanceCounter` export in the saved Server inventory.
- BtaMPM is **not inbox** on Server. The 7 referenced names from each BthHfEnum variant are all exported by the pinned **package** BtaMPM.sys SHA256 `da5cbbdce6ac511ef8400e121df6b6eaca7d05c0f40a01f7353ce9f220eb3dcd`. This reproduces and extends the earlier 7/7 HFP-to-BtaMPM result.
- BthHfEnum DriverStore and System32 PE hashes differ; they were audited separately, not mixed. Both resolved 100% for the modules in evidence.

## Reproducible evidence

- Server CI [45283079589](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45283079589), export inventory artifact **14870687672**, ZIP SHA256 `5d52b990b9c8850696f452dc9c6cae8a1860014b1a8028348ee6a664865f2f53` (module-status and 8 dumpbin text tables). Source is hosted Server 20348 / kernel 20348.5866.
- HFP donor CI [45612001590](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45612001590), artifact **15023735500**, ZIP SHA256 `d105dea586066c10e3f162a0bb1fb4dae5280dbe5041b6bac3527ad7043f610d` (the CI itself failed later, yet PE metadata files are present).
- Prior A2DP donor artifact stored at `/LDAC Project/Artifacts/A2DP-donor-results-20261125.zip`, ZIP SHA256 `e750de7636098d71b73cc64542059547c0854cbdbf39547b0b6c4c2fc280c60d`; nested `CI-6-dependency-first.zip` contains the BtaMPM PE export inventory.
- Analyzer: `tools/research/hfp_server_export_audit.py`, tests: `tools/research/test_hfp_server_export_audit.py`, machine report: `research/native-inf-preflight-20261124/hfp_server_exports_20261125.json`. **11/11 unit tests passed** including missing-name, missing-module, missing forwarder target, ordinal-only import, truncated PE import table, duplicate and incomplete dumpbin tables. Real-data integration result: 3 PE files, 229 imports, unresolved 0.
- Analyzer and metadata-only JSON/Markdown are included in GitHub and persistent `/LDAC Project/Artifacts/WDM-20261125/`. No Microsoft binaries are republished.

## New finding and limitations

The HFP transport/KS binaries do not currently exhibit an **unresolved static symbol-name requirement** against the tested Server 20348.5866 export inventory and the supplied BtaMPM.sys. That removes one potential blocker but **does not establish** Microsoft CAT/INF applicability, PnP service binding, runtime initialization, Bluetooth RFCOMM+SCO call transport, PortCls render/capture endpoint creation, application device selection, or real simultaneous OPPO microphone/speaker audio. Current Server lacks installed HFP profile provider/service in prior inventory. A genuine Server-relevant signature and package integration path remains unsolved.

## Next discriminators

1. Audit HFP original `microsoft_bluetooth_hfp.inf` (Include/Needs/service/CopyFiles/catalog membership) from already saved Win10 donor image or metadata. Do not repeat unchanged UUP HTTP 504 download and don't claim imported metadata contains the full INF unless verified.
2. Compare exported functions and WDM/runtime prerequisites with 20348.5761 target or reproducible matching Server image; hosted 20348.5866 is not byte-identical.
3. Independently investigate profile AG (RFCOMM AT control, SCO/eSCO, microphone capture) and legal signed deployment path; only after explicit authorization conduct real OPPO endpoint/duplex acceptance. No security weakening, no physical host change, no paid CI.