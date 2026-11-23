# Package BthA2dp.sys import closure — follow-up

Date: 2026-11-23
Classification: **CONFIRMED** (static PE import/export name comparison only)
Environment: hosted Windows Server 2022 Datacenter x64 build 20348, kernel components 10.0.20348.5866.

## Exact package binary analyzed

Source archive: `Win10-A2DP-Package-20261123-234936.zip`
Entry: `DriverStore/microsoft_bluetooth_a2dp.inf_amd64_b2e16a3e473a4a6a/BthA2dp.sys`
Size: 282,624 bytes
SHA256: `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`

The fixed PE parser (revision 2) was run against this exact binary. Result: 8 imported modules, 149 imported function names.

## Results against hosted Server 2022 exports

| Module | Imported functions | Missing names |
|---|---:|---:|
| ntoskrnl.exe | 75 | 0 |
| HAL.dll | 1 | 0 |
| ks.sys | 40 | 0 |
| WppRecorder.sys | 4 | 0 |
| SleepStudyHelper.sys | 8 | 0 |
| WDFLDR.SYS | 4 | 0 |
| ksecdd.sys | 7 | 0 |
| btampm.sys | 10 | 0 (checked against package BtaMPM.sys exports) |

The package's BtaMPM.sys exact SHA256 is `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`; it exposes 14 named exports, including all 10 names requested by BthA2dp.sys.

## Interpretation

The exact archived Win10 package BthA2dp.sys also has static import-name closure against the tested Server 2022 system export tables and its packaged BtaMPM.sys dependency. This materially strengthens the WDM package compatibility hypothesis compared with analysis of the separate 279,040-byte binary.

It still does not establish runtime compatibility. Remaining blockers include INF applicability/registration behavior, package catalog/signature completeness, service initialization, dependency load order, KS filter registration, and PnP binding. The CI runner's UBR (5866) differs from the user's previously recorded physical host UBR (5761), so exact-host confirmation remains outstanding.

## Next discriminating experiment

Use a disposable Server 2022 VM/runner matching build 20348 to stage the complete signed package and capture:
- SetupAPI.dev.log
- pnputil staging/install result
- service load status and Code 37 / NTSTATUS if any
- Kernel-PnP events
- KS filter/interface enumeration

Do not install on the physical host during this research stage.
