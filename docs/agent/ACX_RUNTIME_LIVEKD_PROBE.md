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
| Direct LiveKD `-k` path | `e13cd43d66d13e7c341f7c81a64f1677a3aabfe4` | [45054673989](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054673989) | In progress at this snapshot. |
| LiveKD with preconfigured symbol path | `d30bc2cdccc5bcea16059505ef444393701dac0a` | [45054866734](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45054866734) | In progress at this snapshot. |

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

## Next action

- Inspect CI #6 and #7. If the WDF loader symbols remain unavailable, stop the hosted-runner class-version probe rather than inferring from the file version.
- If a fresh physical-host snapshot is needed, prepare a LiveKD-based BAT that captures a dump and runs `!wdfkd.wdfldr Acx01000.sys` using the user's existing debugger/symbol environment. No BCD changes, driver installation, device restart, or OS update.
- Keep CI #133 / #143 packages and PRs unmerged; do not run host prepare/upgrade/rollback.
