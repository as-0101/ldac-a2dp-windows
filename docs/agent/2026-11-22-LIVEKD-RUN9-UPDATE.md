# LiveKD run #9 — 2026-11-22 20:44 Kyiv

## Result

[GitHub Actions ACX runtime LiveKD probe run #9](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45056585788) completed successfully on commit 02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3. The companion general build workflow run #198 also passed.

The corrected workflow:
1. Added the installed Windows SDK Debugging Tools directory to PATH so LiveKD could locate kd.exe.
2. Captured a native kernel live dump with LiveKD -ml -o.
3. Opened the saved dump directly with KD.
4. Used a command file (-cf) to avoid fragile multi-token command-line quoting.

The log confirms:
- LiveKD wrote server2022-live.dmp.
- KD opened the dump.
- Acx01000.sys and its public PDB loaded successfully.
- lmvm Acx01000 resolved the image base 0xfffff803b1cf0000 and image size 0xA5000.
- The unqualified !wdfldr command showed Wdf01000.sys runtime v1.33 with 43 associated clients. Its first client row had an unresolved image name but WDF client version v1.31 and image base/size exactly matching Acx01000.sys. This is consistent with ACX being a WDF 1.31 client on WDF runtime 1.33 on the hosted runner.
- The subsequent !wdfkd.wdfldr Acx01000.sys query returned “Unable to find the specified WDF driver”. This does not mean ACX failed to load; the command is not the documented query for ACX class binding.

## Exact class-binding query from Microsoft

Microsoft's official [!acxkd documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-acxkd) shows the exact command:

    !wdfldr acx01000

The documented output includes:
- CLIENT_MODULE: ACX WDF client version 1.31, bound to Wdf01000.sys runtime 1.33.
- CLASS_MODULE: ACX class-module Version v1.1 (in Microsoft's example).

The hosted run #9 command file did not include this exact query. The unqualified !wdfldr listing and !wdfkd.wdfldr query are not substitutes.

## Artifact

- GitHub artifact: 14768155168
- SHA-256: bb29ddd8613eb94d350c6ad08818369d8c169ebd962ec6796f28939955687d8c
- Files Library: /Bluetooth LDAC Research/Artifacts/ACX-runtime-LiveKD-run9-report.zip
- Library ID: libfile_574b6bc225f08191acf43df2c939095c

## Follow-up workflow commit

Commit [218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383](https://github.com/as-0101/ldac-a2dp-windows/commit/218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383) on research/acx-runtime-livekd adds the exact command !wdfldr acx01000 to the KD command file, while retaining the other queries for comparison.

No CI run had yet been observed for this commit at the time of this report. The change is unverified and modifies only the research workflow, not driver source or the physical host.

## Interpretation

- CONFIRMED: corrected LiveKD dump capture and separate KD inspection work on the disposable hosted Server 2022 runner.
- CONFIRMED: the hosted runner has Wdf01000 runtime v1.33 and an Acx01000.sys image represented in the WDF client list as version 1.31.
- UNKNOWN: hosted runner ACX CLASS_MODULE version. It must be queried with !wdfldr acx01000.
- Do not infer class version from Acx01000.sys file version or the unqualified WDF client list.
- The physical host's previously captured CLASS_MODULE Version v1.0 remains the only direct class-version result for the target.

## Exact continuation

1. Inspect the workflow run triggered by commit 218b457e9df2bf7ccf58e4d4ad18e40c2bb8d383.
2. If the log shows CLASS_MODULE Version v1.1, record that the hosted image differs from the physical host. This alone does not prove that a cumulative update caused the difference.
3. If it shows Version v1.0, the runner and physical host are aligned; investigate other causes without assuming ACX version mismatch is sufficient.
4. No physical server action is required for this probe. The CI #133 / Universal / ACX 1.0 physical test remains a separate, gated experiment requiring a read-only package pre-check and explicit authorization.
