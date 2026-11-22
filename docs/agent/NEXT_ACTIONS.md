# Next actions — exact continuation

**Current blocker:** no physical-host test of the successful ACX 1.0 package has been performed. Do not touch the user's server without explicit authorization.

1. Preserve run #133 artifacts before their expiry (2026-11-29): test package artifact 14763242251 and unsigned driver artifact 14763157658. Record SHA-256 digests from PROJECT_STATE.md.
2. Inspect the downloaded test package and unsigned driver package contents: confirm INF DriverVer, SYS binary, package identity and that the driver was built from the ACX 1.0 experiment. The build job log shows INF stamp 0.2.326.1634.
3. Verify the effective ACX 1.0 include and link inputs from build diagnostics or package metadata. Current project file sets ACX_VERSION_MINOR=0 and constructs both paths from this macro; captured CI log does not echo the expanded paths.
4. Prepare a controlled physical-host test plan with a precise rollback to the previously active package. Do not execute it until the user explicitly authorizes the server-side test.
5. If authorized, capture Kernel Debug Output / WinDbg before restarting only the OPPO devnode. Primary success signal: `LdacA2dp: DriverEntry started`; primary failure signal: the same ACX class-bind status.
6. Interpret only the first actual failing stage. If DriverEntry is reached, the next layer is `WdfDriverCreate`, then `AcxDriverInitialize`, then ACX device/circuit initialization. Do not jump directly to Bluetooth protocol debugging.
7. Update this state, evidence register, experiment record and Notion journal with exact observed data. Keep the journal append-only.

## No user action required now

The next work can continue from CI artifact inspection and source comparison. Ask the user only if a physical-server test becomes necessary.


## New work after package review

1. **Do not install yet.** The CI #133 package is verified as a genuine ACX 1.0 build, but ACX 1.0 is documented by Microsoft as pre-release/not recommended for new driver development.
2. The target host's last recorded build is 20348.2849 (2024-11); newer cumulative build 20348.5873 exists (2026-11-13). Investigate separately whether a fully serviced Server 2022 image has a different `Acx01000.sys` version or ACX `CLASS_MODULE Version`. Current KB summaries do not prove a runtime change.
3. If an updated image/VM is available, capture `(Get-Item "$env:windir\\System32\\drivers\\Acx01000.sys").VersionInfo | Format-List FileVersion,ProductVersion` and WinDbg `!wdfldr Acx01000.sys`. Compare against the existing host's exact values. Do not combine OS update and LDAC driver installation in one experiment.
4. If the updated image still reports ACX class 1.0, proceed to prepare the isolated physical test/rollback plan for CI #133, requiring explicit user authorization before any server change.
5. If it reports ACX 1.1, revisit the ACX 1.1 branch first; do not install the 1.0 experiment merely because it compiled.
6. Review the stale `docs/stage5-audio-options.md` statement that INF class is MEDIA against current `LdacA2dp.inx` (Bluetooth class); preserve the current class until a discriminating test justifies change.

## Updated continuation — 2026-11-22

1. CI #143 / run 45050062916 completed successfully. All 3 jobs passed; the Windows Driver variant generated a test package and unsigned driver. Compare the two variants only if a package-level difference becomes relevant; neither build proves physical class binding.
2. Keep PR #3 draft and never merge it automatically. The A/B build only checks target-platform build/package effects, not runtime class binding.
3. Preserve CI #133 and #143 artifacts with their artifact IDs and SHA-256 digests before the 2026-11-29 expiry.
4. The strongest next discriminator remains a controlled physical-server load of the ACX 1.0 package, with a verified rollback package and Kernel Debug Output capture. Do not install or restart any device until the user explicitly authorizes the test.
5. On physical test, success is the first LdacA2dp DriverEntry debug message and absence of FxStubBindClasses class Acx 0xC000000D. If DriverEntry is reached, move to WdfDriverCreate, AcxDriverInitialize, ACX device/circuit creation, then A2DP/SBC.
6. If the ACX 1.0 test fails before DriverEntry, obtain the Server 2022 ACX PDB/bind metadata and measure the actual class function count; do not reuse the Windows 10 19045 counts.

## Physical test runbook

Read [PHYSICAL_TEST_RUNBOOK.md](PHYSICAL_TEST_RUNBOOK.md) before any user-side action. First request only the read-only status output after the CI #133 package is extracted to C:\\LDAC-Test\\ACX10-Universal. Do not ask the user to run prepare/upgrade until explicit authorization. The package's rollback returns to inbox bth.inf, not CI #126.
