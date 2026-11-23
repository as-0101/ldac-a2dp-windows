# Server 2022 export compatibility inventory — 2026-11-23

## Status

- Classification: **CONFIRMED** for static export-name resolution on the tested hosted OS image.
- Environment: **CI / Windows Server 2022 Datacenter x64**, build 20348, version 10.0.20348; kernel and system component files reported as 10.0.20348.5866 (some inbox components 20348.1 / 20348.2849).
- Workflow run: https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45283079589
- Artifact: `server2022-export-inventory` (run artifact ID 14870687672).
- This is a hosted runner, not the user's physical Server 2022 machine. User host snapshot previously recorded build 20348 / UBR 5761; this run's kernel files are UBR 5866. Export-name results must not be represented as a byte-for-byte host inventory.

## Imported symbol comparison

Source PE import report: `a2dp_pe_imports_report(2).txt`.

| Importing binary | Imported module | Imports | Missing names in tested Server 2022 exports |
|---|---:|---:|---:|
| BthA2dp.sys | ntoskrnl.exe | 70 | 0 |
| BthA2dp.sys | HAL.dll | 1 | 0 |
| BthA2dp.sys | ks.sys | 40 | 0 |
| BthA2dp.sys | WppRecorder.sys | 4 | 0 |
| BthA2dp.sys | SleepStudyHelper.sys | 8 | 0 |
| BthA2dp.sys | WDFLDR.SYS | 4 | 0 |
| BthA2dp.sys | ksecdd.sys | 7 | 0 |
| BtaMPM.sys | ntoskrnl.exe | 37 | 0 |
| BtaMPM.sys | cng.sys | 1 | 0 |
| BtaMPM.sys | WppRecorder.sys | 4 | 0 |

**Result:** all 176 imported function names across the two supplied PE reports are present in the corresponding exports collected from the hosted Server 2022 image. The BthA2dp import of `btampm.sys` is not part of the inbox OS export set; it is a package-supplied dependency and must be evaluated against the package's BtaMPM.sys.

## BtaMPM package export verification

The package copy `BtaMPM.sys` from `Win10-A2DP-Package-20261123-234936.zip` has:
- Size: 43,008 bytes
- SHA256: `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`
- 14 named exports.
- All 10 functions imported by the supplied BthA2dp.sys PE report are exported by this package BtaMPM.sys.

This confirms static symbol-name closure for the dependency pair in the inspected files. It does **not** prove that BtaMPM initializes successfully, that the package installs, or that A2DP binds at runtime.

## Important binary provenance discrepancy

The supplied PE report analyzes BthA2dp.sys with:
- Size: 279,040 bytes
- SHA256: `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`

The archived Win10 A2DP package contains BthA2dp.sys in both DriverStore and SystemDrivers with:
- Size: 282,624 bytes
- SHA256: `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`

These are different binaries. Do not transfer import/export findings from one binary to the other without analyzing the exact package binary. The BtaMPM hashes match exactly.

## Missing inbox modules

The tested Server 2022 runner did not contain inbox `BthA2dp.sys` or `BtaMPM.sys`. This is expected for the tested baseline inventory; the Win10 package supplies both driver binaries. The package INF/copy behavior and runtime dependency loading still need separate verification.

## Next steps

1. Run the same read-only export inventory against the user's exact physical host build/UBR, or obtain a matching Server 2022 image at UBR 5761. No system modifications are needed.
2. Run the PE import parser against the exact 282,624-byte package BthA2dp.sys and compare its imports with the same export set.
3. Verify INF dependency/copy order and package catalog/signature completeness.
4. Only after static closure is complete, continue isolated VM/CI installation and PnP binding diagnostics. No physical host installation without explicit approval and rollback plan.

## Interpretation guardrails

Static import resolution is only one prerequisite. It does not prove driver load, PnP binding, KS filter registration, audio endpoint creation, A2DP negotiation, codec selection, or actual audio streaming.
