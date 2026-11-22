# Physical Server 2022 test runbook — ACX 1.0

**Status:** PREPARED, NOT AUTHORIZED / NOT EXECUTED. No server changes have been made.

## Candidate selection

Use **CI #133 / ACX 1.0 / Universal** for the first physical test, not CI #143. CI #133 changes only ACX from 1.1 to 1.0 while preserving the original Universal target. CI #143 additionally changes DriverTargetPlatform and would confound the first runtime test.

- Package artifact: 14763242251.
- SHA-256: f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad.
- Persistent file: /Bluetooth LDAC Research/Artifacts/CI-133-ACX10-Universal-test.zip.
- Files Library ID: libfile_fac18af78e50819181cc6ed246a9bb4a.
- DriverVer: 0.2.326.1634.
- Extract the complete ZIP to C:\\LDAC-Test\\ACX10-Universal. Keep the ZIP separately for integrity/rollback reference.

## Pre-check — read-only

Run this one-line PowerShell command after extracting the package. It does not install or change anything; it reports the exact OPPO A2DP devnode and driver state and saves a copy on the Desktop:

```powershell
& 'C:\\LDAC-Test\\ACX10-Universal\\oppo-driver-tool.exe' status 2>&1 | Tee-Object -FilePath "$env:USERPROFILE\\Desktop\\ldac-acx10-precheck.txt"
```

Expected historical state (must be rechecked): OPPO instance ending 840F2A13E3E2, service LdacA2dp, manufacturer LDAC A2DP Project, current oem75.inf / 0.2.325.1600 / Code 37. The package's upgrade tool independently revalidates OS build, exact MAC, single-A2DP condition, current service/manufacturer, candidate version and driver rank. Stop if the fresh state differs.

## Preparation — only after explicit user authorization

The package is test-signed with a CI-generated certificate. Do not mix its certificate with the CI #143 package or another CI run.

One-line PowerShell command to run the package's preparation script elevated:

```powershell
Start-Process -FilePath 'C:\\LDAC-Test\\ACX10-Universal\\prepare-oppo-host.cmd' -Verb RunAs -Wait
```

This script makes system changes in sequence: imports ldac-a2dp-test.cer into LocalMachine Root and TrustedPublisher, enables the IHVDRIVER debug-print filter (0xF), and sets BCD testsigning on. It requires a restart. It is not transactional: if a later step fails, earlier certificate/registry changes may remain. On any nonzero exit, stop and inspect the certificate stores, IHVDRIVER value and BCD state before attempting cleanup or retry. Do not assume the host was left unchanged.

The CI #133 certificate identity, verified from the package:
- Subject: CN=LDAC A2DP OPPO Physical Server 2022 Test Only
- SHA-1 thumbprint: 4A4E17BFC74DBE7220CA0606763FB81BA85A947B
- Validity: 2026-11-22 through 2028-11-22.

Do not run without explicit approval. Do not disable Secure Boot or bypass Code Integrity if any gate fails.

After restart, start DebugView (Capture Kernel) or WinDbg kernel debug before restarting the OPPO devnode, so the first DriverEntry messages are captured.

## Upgrade — only after preparation and explicit authorization

One-line PowerShell command:

```powershell
Start-Process -FilePath 'C:\\LDAC-Test\\ACX10-Universal\\upgrade-oppo.cmd' -Verb RunAs -Wait
```

The elevated tool prompts for the exact confirmation token: I_ACCEPT_LDAC_DIAGNOSTIC_UPGRADE. It checks Windows Server 2022 build 20348, exact OPPO MAC, only one present A2DP devnode, current service LdacA2dp and manufacturer LDAC A2DP Project, candidate driver newer than the installed version, and candidate rank lower priority than inbox bth.inf for other sinks. It stages the INF and calls DiInstallDevice for the exact OPPO devnode only. It does not blanket-update all Bluetooth devices. It may require a restart.

Do not use install-oppo.cmd: it is intentionally for an inbox bth.inf device and is not the correct path when the current driver is already LdacA2dp.

## Success / failure criteria

Primary success: kernel debug shows LdacA2dp: DriverEntry started and the prior FxStubBindClasses / class Acx / 0xC000000D failure is absent.

If DriverEntry starts, stop and capture the log before proceeding. Next investigate WdfDriverCreate, AcxDriverInitialize, ACX device/circuit creation, then A2DP/SBC. Do not conflate a successful class bind with working audio.

If the same pre-DriverEntry bind error remains, save the complete kernel log and exact device status. Do not repeat install attempts.

## Rollback

One-line PowerShell command:

```powershell
Start-Process -FilePath 'C:\\LDAC-Test\\ACX10-Universal\\rollback-oppo.cmd' -Verb RunAs -Wait
```

Important: rollback-oppo.cmd selects the inbox bth.inf driver for the exact OPPO A2DP devnode. It does **not** restore the previous CI #126 LdacA2dp package (historically oem75.inf / 0.2.325.1600). This is a fallback to the inbox Bluetooth Audio Sink Service, not a bit-for-bit restoration of the pre-test driver state. Confirm the resulting active INF, service and device status after restart. If restoring the old LDAC package is required, that needs a separately preserved and verified CI #126 package and a separately planned recovery procedure; do not assume rollback-oppo.cmd does this.

The preparation script does not automatically undo test signing or remove the certificate. After confirming the inbox driver is active, remove only the CI #133 certificate by its verified thumbprint and disable test signing with this one-line command:

```powershell
certutil -delstore Root 4A4E17BFC74DBE7220CA0606763FB81BA85A947B; certutil -delstore TrustedPublisher 4A4E17BFC74DBE7220CA0606763FB81BA85A947B; bcdedit /set testsigning off
```

The thumbprint is from the CI #133 package certificate. Do not use Get-PfxCertificate on the .cer file: that cmdlet is documented for PFX files, while this package contains a public .cer certificate. Verify both store-removal results and the BCD value, then restart again. Preserve the package and logs until the test is fully closed.

## Package review notes

- The nested README_OPPO_TEST_RU.txt contains a duplicated “DIAGNOSTIC UPGRADE…” section. This is a documentation defect, not a runtime defect.
- The README's older INSTALLATION section describes an inbox-driver install path; for the current physical host already bound to LDAC, follow only the guarded upgrade procedure above.
- Static package review confirmed the CI #133 test ZIP SHA-256 and INF DriverVer. No package script has been executed on the physical host.

## Kernel debugger capture safety — important correction

The earlier `Launch-WinDbg-Kernel.bat` starts WinDbg with `-kl` only. It does **not** enable local kernel debugging. Microsoft requires BCD `debug on`, local `dbgsettings`, and a reboot for `-kl`. These are system/BCD changes; do not enable them on the physical Server 2022 host without separate explicit authorization.

Preferred non-BCD route under validation: Sysinternals LiveKD `-ml` native live-dump mode. CI #5 proved that it can capture a Server 2022 live dump and run KD against it. The WDF `!wdfkd.wdfldr` extension still needs WDF loader symbols that were not available from the hosted runner's public symbol set. If using LiveKD on the physical host, preserve the output log and do not install or update any driver.

## Safety boundary

- The agent has not run any command on the physical server.
- Do not execute preparation, upgrade, restart or rollback without explicit user authorization.
- If the pre-check reports multiple A2DP devnodes, a different current driver/service, or an unsupported build, stop. Never bypass the tool's safety gates.
- The first physical test must use CI #133 / Universal / ACX 1.0 to isolate ACX version as the only intended variable.
