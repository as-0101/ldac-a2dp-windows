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
& 'C:\LDAC-Test\ACX10-Universal\oppo-driver-tool.exe' status 2>&1 | Tee-Object -FilePath "$env:USERPROFILE\Desktop\ldac-acx10-precheck.txt"
```

Expected historical state (must be rechecked): OPPO instance ending 840F2A13E3E2, service LdacA2dp, manufacturer LDAC A2DP Project, current oem75.inf / 0.2.325.1600 / Code 37. The package's upgrade tool independently revalidates OS build, exact MAC, single-A2DP condition, current service/manufacturer, candidate version and driver rank. Stop if the fresh state differs.

## Preparation — only after explicit user authorization

The package is test-signed with a CI-generated certificate. Do not mix its certificate with the CI #143 package or another CI run.

One-line PowerShell command to run the package's preparation script elevated:

```powershell
Start-Process -FilePath 'C:\LDAC-Test\ACX10-Universal\prepare-oppo-host.cmd' -Verb RunAs -Wait
```

This script makes system changes: imports ldac-a2dp-test.cer into LocalMachine Root and TrustedPublisher, enables the IHVDRIVER debug-print filter (0xF), and sets BCD testsigning on. It requires a restart. It is not a read-only precheck. Do not run without explicit approval. Do not disable Secure Boot or bypass Code Integrity if any gate fails.

After restart, start DebugView (Capture Kernel) or WinDbg kernel debug before restarting the OPPO devnode, so the first DriverEntry messages are captured.

## Upgrade — only after preparation and explicit authorization

One-line PowerShell command:

```powershell
Start-Process -FilePath 'C:\LDAC-Test\ACX10-Universal\upgrade-oppo.cmd' -Verb RunAs -Wait
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
Start-Process -FilePath 'C:\LDAC-Test\ACX10-Universal\rollback-oppo.cmd' -Verb RunAs -Wait
```

Important: rollback-oppo.cmd selects the inbox bth.inf driver for the exact OPPO A2DP devnode. It does **not** restore the previous CI #126 LdacA2dp package. Restart after rollback.

The preparation script does not automatically undo test signing or remove the certificate. After confirming the inbox driver is active, remove the certificate and disable test signing with this one-line command:

```powershell
$t=(Get-PfxCertificate -FilePath 'C:\LDAC-Test\ACX10-Universal\ldac-a2dp-test.cer').Thumbprint; certutil -delstore Root $t; certutil -delstore TrustedPublisher $t; bcdedit /set testsigning off
```

Restart again after disabling test signing. Preserve the package and logs until the test is fully closed.

## Safety boundary

- The agent has not run any command on the physical server.
- Do not execute preparation, upgrade, restart or rollback without explicit user authorization.
- If the pre-check reports multiple A2DP devnodes, a different current driver/service, or an unsupported build, stop. Never bypass the tool's safety gates.
- The first physical test must use CI #133 / Universal / ACX 1.0 to isolate ACX version as the only intended variable.