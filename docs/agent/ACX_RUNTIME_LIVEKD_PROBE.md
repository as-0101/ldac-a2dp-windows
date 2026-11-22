# ACX runtime LiveKD probe — 2026-11-22

## Purpose

Inspect a more-serviced Windows Server 2022 environment without changing the physical OPPO server, and determine whether its registered ACX class version differs from the physical host. The physical host's previous `!wdfldr` output recorded ACX class module Version 1.0; its current ACX file version is 10.0.20348.3451.

## Baselines

| Environment | OS / WDF | ACX file | Notes |
|---|---|---|---|
| Physical host | Server 2022 build 20348, UBR 5761; WDF runtime 1.33 | `Acx01000.sys` 10.0.20348.3451 | `oem75.inf` 0.2.325.1600, Code 37, one A2DP devnode; testsigning Yes. No changes performed. |
| GitHub `windows-2022` runner | Server 2022 build 20348; WDF 1.33.20348.1 | `Acx01000.sys` 10.0.20348.5866 | ACX service stopped by default. File version does not prove class version. |

The ACX service was manually started only on the disposable GitHub runner; `sc.exe start Acx01000` succeeded. This was not run on the user's physical server.

## Probe branch and CI history

Branch: [research/acx-runtime-livekd](https://github.com/as-0101/ldac-a2dp-windows/tree/research/acx-runtime-livekd). This branch contains only a diagnostic workflow; no driver source or production branch was changed.

| Probe | Commit | Run | Result |
|---|---|---|---|
| Initial WinDbg install attempt | `d48ebbc942cd284a4707c986cb98aa4fa0ab309a` | [45053790417](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45053790417) | Failed: `winget` is unavailable on the hosted Server 2022 image. |
| WinDbg MSIX attempt | `90b5ef9ed1c97fd508c6956c868843e98a48527e` | [45053899867](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45053899867) | Failed: extracted WinDbg package did not contain `kdX64.exe`. |
| WinDbg MSIX retry | `f2499f3a765db58e6755122fc9566bb0d427e661` | [45053922954](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45053922954) | Same missing-console-debugger issue. |
| SDK Debugging Tools + LiveKD | `6c0204588207d80a4a921d156379772ab05e0808` | [45054071166](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054071166) | SDK Debugging Tools 10.0.26100.6584 installed; ACX service start succeeded; LiveKD initially could not find `kd.exe` on PATH. Report artifact 14767070902 preserved in Files Library. |
| LiveKD native dump + KD | `40d40d4b0300b708388c25f83e3fb2bc00c7b19e` | [45054287408](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054287408) | **Capture succeeded.** LiveKD `-ml -o` produced a native kernel dump and KD opened it. `!wdfkd.wdfldr` could not resolve `wdfldr!WdfLdrGlobals` / required private WDF symbols from the public symbol set, so no `CLASS_MODULE` version was returned. Report artifact 14766509597 preserved in Files Library. |
| Direct LiveKD `-k` path | `e13cd43d66d13e7c341f7c81a64f1677a3aabfe4` | [45054673989](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054673989) | Cancelled. Job log shows KD command-line usage; no valid WDF/ACX class query. Artifact 14767527142. |
| LiveKD with preconfigured symbol path | `d30bc2cdccc5bcea16059505ef444393701dac0a` | [45054866734](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054866734) | Cancelled. Job log shows KD command-line usage; no valid WDF/ACX class query. Artifact 14767775337. |
| LiveKD dump + KD command-file flow | `02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3` | [45056585788](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45056585788) | **Success:** native dump captured; KD opened it and loaded Acx01000 symbols. `!wdfldr` showed WDF runtime 1.33 and an unnamed client 1.31 at the Acx01000 image base. Exact CLASS_MODULE query still missing. Artifact 14768155168. |

Files Library copies:
- `/Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run4-report.zip` — Library ID `libfile_1c51ba296db8819195bef7905d6b0bb2`.
- `/Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run5-report.zip` — Library ID `libfile_f6b3dc250e70819180b85bfe0f78d3df`.

## Interpretation

1. A native LiveKD `-ml` dump can be captured on Server 2022 and opened with KD without enabling BCD local kernel debugging.
2. The WDF extension could not enumerate class modules because the hosted runner's public symbols did not expose `wdfldr!WdfLdrGlobals` and related private type information. This is a symbol-availability limitation, not evidence that ACX 1.0 or 1.1 is present.
3. The runner's newer `Acx01000.sys` file version (5866 versus host 3451) does not establish a different ACX class version. Do not infer class version from file version.
4. The previous physical-host `!wdfldr` output remains the direct evidence for that host's ACX class module Version 1.0.

## Debugger safety

The earlier `Launch-WinDbg-Kernel.bat` launches WinDbg with `-kl` only. Local kernel debugging requires BCD `debug on`, local `dbgsettings`, and a reboot; the BAT does not configure these. Do not run it on the physical host as-is or enable BCD debugging without separate authorization. Prefer LiveKD `-ml` native live-dump mode if a fresh host snapshot is needed.

## Latest CI audit — 2026-11-22 20:37 Kyiv

- [Run #8 / 45056354003](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45056354003) failed. LiveKD reported `Error finding kd.exe`; the expected dump was not created. Artifact 14767208063, SHA-256 `b9cf8c3a224d0c370305ae1270de369b3bfd6c885d038488a5ede475115427ea`.
- Run #6 artifact 14767527142, SHA-256 `f793ea378ba1e57df6a1f7102a1f21e8bc3acce76e9d6646d9551bd69967af1c`, Files Library ID `libfile_3fcc773af2ec8191899040f1ab2f0021` (duplicate-safe path ends in run6-report(1)).
- Run #7 artifact 14767775337, SHA-256 `bb8764e5cb2d789981bd36cda3053f4ec91f83f29359f8fe27e738d238b3a5a1`, Files Library ID `libfile_70550aca71088191b2940b0f11fb92ab`.
- Run #8 artifact 14767208063 is preserved in Files Library, ID `libfile_5fe724c427a08191a924c877c0c16ba2`.
- Workflow-only fix committed on `research/acx-runtime-livekd`: [02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3](https://github.com/as-0101/ldac-a2dp-windows/commit/02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3). It adds the KD directory to PATH and uses a command file (`-cf`) for KD inspection. Verified by successful run #9; it does not yet resolve the ACX class version.

## Next action

- If a new CI run can be triggered for commit `02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3`, verify whether LiveKD creates the dump and whether KD reaches `!wdfkd.wdfldr`. Do not treat the workflow correction as proven before a successful run.
- Hosted runner ACX class-module version remains unknown. The only direct ACX 1.0 evidence is the physical host's earlier `!wdfldr` output; do not infer from file version.
- Keep CI #133 / #143 packages and PRs unmerged; do not run host prepare/upgrade/rollback.


## Microsoft ACX class-binding query — 2026-11-22 20:44 Kyiv

Run #9 proves that the LiveKD dump + separate KD command-file flow works. The WDF listing shows Wdf01000.sys runtime v1.33 and an unnamed WDF client v1.31 at the exact Acx01000.sys image base. The image and PDB load, but this does not reveal ACX CLASS_MODULE version.

The official [Microsoft !acxkd documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd) shows the exact command for ACX binding:

    !wdfldr acx01000

Its example output contains both CLIENT_MODULE and CLASS_MODULE, including the ACX Version field. The prior !wdfkd.wdfldr Acx01000.sys invocation is not equivalent and returned “Unable to find the specified WDF driver”.

A follow-up workflow commit [218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383](https://github.com/as-0101/ldac-a2dp-windows/commit/218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383) adds !wdfldr acx01000 to the command file. Verified by [run #10 / 45057090987](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45057090987): the exact query returned CLASS_MODULE Version v1.0.

Run #9 report artifact 14768155168, SHA-256 bb29ddd8613eb94d350c6ad08818369d8c169ebd962ec6796f28939955687d8c, Files Library ID libfile_574b6bc225f08191acf43df2c939095c, path /Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run9-report.zip.

## Next action

- Inspect the CI run triggered by commit 218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383 and capture the output of !wdfldr acx01000.
- If the hosted runner reports CLASS_MODULE Version v1.1, record the host/runner difference but do not attribute it to a particular cumulative update without a controlled image comparison.
- If it reports v1.0, the host and runner are aligned; continue investigating other binding inputs.
- Keep physical Server 2022 unchanged. CI #133 / Universal / ACX 1.0 remains a separate gated test.


## Run #10 class-version result — 2026-11-22 20:48 Kyiv

[Run #10](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45057090987), commit 218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383, succeeded. The documented !wdfldr acx01000 query returned:
- CLIENT_MODULE Acx01000.sys, WDF Version v1.31, bound to Wdf01000.sys runtime v1.33.
- CLASS_MODULE Acx01000.sys, WDF Version v1.31, Version v1.0.
- Service path HKLM\SYSTEM\ControlSet001\Services\Acx01000; class module client list empty because no ACX client driver was loaded on the hosted runner.

This is the same ACX CLASS_MODULE v1.0 / WDF 1.31 / runtime 1.33 combination previously observed on the physical host. The ACX 1.1 client versus ACX 1.0 class mismatch is now STRONGLY SUPPORTED as the leading explanation for the pre-DriverEntry STATUS_INVALID_PARAMETER, though other binding metadata mismatches are not excluded.

Run #10 artifact 14768205866, SHA-256 aed85ff189ca817191383edb38945f69c27e50a86832ea8819c2e3b42674ade7, Files Library ID libfile_4ab21e3426e0819190b2fa201822980c, path /Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run10-report.zip. Full analysis: [2026-11-22-LIVEKD-RUN10-ACX-VERSION.md](2026-11-22-LIVEKD-RUN10-ACX-VERSION.md).

## Next action

The hosted class-version uncertainty is resolved: Server 2022 runner reports ACX class v1.0, matching the physical host. Next step is the read-only pre-check for the CI #133 / Universal / ACX 1.0 package. No driver installation, prepare, certificate import, upgrade, device restart, rollback, BCD change or OS update without separate explicit authorization.


## Auxiliary runner metadata probe — 2026-11-22 20:53 Kyiv

An optional follow-up intended to print the hosted runner's OS/UBR, ACX/WDF file hashes and BCD test-signing flags failed before creating a job:
- Run #11 / ID 45057551731 on commit 3ee4c71aba04b3dd9e74f64bc24066695f12eeca failed because three PowerShell lines were not indented inside the YAML run block.
- Corrected in workflow-only commit [b8256dd009bc8b289e17f64abd4300686380ae50](https://github.com/as-0101/ldac-a2dp-windows/commit/b8256dd009bc8b289e17f64abd4300686380ae50). No follow-up CI run has yet been observed; the optional OS/UBR/BCD snapshot remains unverified.
- This does not affect the successful run #10 result: hosted Server 2022 ACX CLASS_MODULE v1.0 / WDF 1.31 / runtime 1.33, matching the physical host.

The optional metadata probe is secondary. The next project blocker is the read-only status pre-check for the CI #133 / Universal / ACX 1.0 package. No physical host change is needed for this workflow.
