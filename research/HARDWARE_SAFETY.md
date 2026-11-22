# Physical hardware safety rules

**Default policy: read-only on the physical Windows Server 2022 host.** Investigation, compilation, static inspection and disposable hosted/VM tests are preferred.

## Prohibited without separate explicit authorization

- Installing/upgrading/removing/replacing any driver; restarting the OPPO node, Bluetooth radio, or parent bus.
- Running `prepare-oppo-host.cmd`, `upgrade-oppo.cmd`, `install-oppo.cmd`, or `rollback-oppo.cmd`.
- Changing BCD, enabling/disabling test signing, changing debug settings, importing/removing certificates, or changing IHVDRIVER debug registry filters.
- Disabling Secure Boot or Code Integrity; replacing Windows Bluetooth binaries; updating Windows; changing Intel Bluetooth driver/parent bus.
- Rebooting the host for an experiment.

## Required before any authorized physical experiment

1. Read-only snapshot: OS edition/build/UBR; Secure Boot and Code Integrity; BCD; installed certificates; Bluetooth radio and driver; all present OPPO A2DP devnodes; current INF/provider/version/service/rank; audio endpoints; current driver-store packages.
2. Preserve exact candidate and rollback package bytes, names, hashes, signatures, INF versions, and provenance.
3. Write a step-by-step test plan with one variable, expected result, stop conditions, and a rollback plan that restores the actual prior state.
4. Confirm rollback limitations. `rollback-oppo.cmd` selects inbox `bth.inf`; it does not restore prior WDK 26100 LDAC package `oem75.inf` / 0.2.325.1600.
5. Obtain explicit user authorization for the specific planned system changes.
6. Capture diagnostics before/after; verify Bluetooth HID keyboard/mouse still function.

## Known hazardous script

`prepare-oppo-host.cmd` imports the test certificate into LocalMachine Root and TrustedPublisher, changes IHVDRIVER Debug Print Filter, enables BCD testsigning, and requires reboot. It is not a read-only preflight and must not be run blindly. Test signing is already recorded as Yes on the physical host; never enable it again without new evidence and authorization.

## Safe research environment

- Prefer disposable GitHub-hosted Windows Server 2022 runners or a recoverable VM snapshot.
- Keep OS servicing and driver installation as separate experiments.
- Do not infer physical support from CI compile, PnP simulation, or synthetic SWD device results.
- Preserve HID operation; do not change the Intel Bluetooth parent stack without a reproducible causal test.

## Command presentation

When asking the user to run PowerShell, provide one single-line command at a time and label it READ-ONLY or SYSTEM-CHANGING. Never bundle multiple destructive operations into one line.
