## Latest continuation — 2026-11-22

- Exact failure stage: `VersionBindClass` for class `Acx`, status `0xC000000D`; ACX class-version mismatch remains the leading explanation, not a proven final root cause.
- KMDF 1.31 / runtime 1.33 is supported; Universal is supported on Server 2022; Bluetooth setup class is correct for BTHENUM.
- Hosted runner LiveKD CI #6/#7 were cancelled and produced no valid class-module query; CI #8 failed before dump creation because LiveKD could not find kd.exe. Current workflow correction commit 02dcde601f08e1e52ac9cf073dbf99b6e0e0a8a3 is unverified.
- Physical server remains unchanged: UBR 5761, ACX file 10.0.20348.3451, testsigning Yes, `oem75.inf` 0.2.325.1600, Code 37.
- **Do not run the earlier `Launch-WinDbg-Kernel.bat` as-is:** it uses `-kl` and does not configure BCD local debugging. No BCD or driver changes are authorized.

Read [ACX_RUNTIME_LIVEKD_PROBE.md](docs/agent/ACX_RUNTIME_LIVEKD_PROBE.md) for the current probe history.
# LDAC project — agent bootstrap

> Read this file first. Target context-recovery time: 2–3 minutes. Project scope: Windows Server 2022 Bluetooth A2DP / LDAC for OPPO Enco Buds2 only.

## Required reading order

1. [Current project state](docs/agent/PROJECT_STATE.md) — authoritative current status and next step.
2. [Physical test runbook](docs/agent/PHYSICAL_TEST_RUNBOOK.md) — safety gates, test sequence and rollback limitations.
3. [CI #133 package review](docs/agent/CI133_PACKAGE_REVIEW.md) — inspected package, PDB comparison and ACX 1.0 evidence.
4. [Evidence register](docs/agent/EVIDENCE.md) — important claims linked to logs, commits, CI and artifacts.
5. [Knowledge graph](docs/agent/KNOWLEDGE_GRAPH.md) — causal chain, hypotheses and dependencies.
6. [Decisions and experiments](docs/agent/DECISIONS_AND_EXPERIMENTS.md) — completed tests, exclusions and rationale.
7. [Next actions](docs/agent/NEXT_ACTIONS.md) — exact continuation sequence.
8. [Microsoft sample comparison](docs/agent/SAMPLE_COMPARISON.md) — official ACX sample and related analysis.

Full human-readable research journal and original evidence index:
- [Notion research journal](https://app.notion.com/p/41f769fff636810fbd50c285bc3d33f6)
- [Notion handoff and artifact index](https://app.notion.com/p/420769fff636812ab023c0fb67c66a5a)

## Current physical-host snapshot — 2026-11-22

Latest user-provided read-only PowerShell output:

- Windows Server 2022 Datacenter, build 20348, UBR 5761.
- `Acx01000.sys` file version: `10.0.20348.3451`. This is a file version, **not** the ACX class-module version.
- BCD `testsigning Yes`; desktop test-mode watermark is expected. Do not enable it again.
- OPPO Enco Buds2 A2DP instance ends with MAC `840F2A13E3E2`; exactly one present A2DP devnode.
- Active package: `oem75.inf`, `0.2.325.1600`, provider `LDAC A2DP Project`.
- Device status: `CM_PROB_FAILED_DRIVER_ENTRY`, Problem Code 37.
- CI #133 package is extracted to `C:\LDAC-Test\ACX10-Universal`; INF version `0.2.326.1634` and SYS SHA-256 were checked against the reference.

Earlier WinDbg `!wdfldr Acx01000.sys` output on this host reported ACX `CLASS_MODULE Version v1.0` and WDF client 1.31. Reconfirm in a genuine kernel-debugger session if possible. The user has launched WinDbg, but the start page titled `KD, Local Connection (Quiet)` did not establish that the kernel is attached. Do not mistake the ACX file version for the class-module version.

## Rules for every agent

- Treat `PROJECT_STATE.md` as the authoritative current snapshot; the Notion journal is append-only historical detail.
- Never upgrade a hypothesis to fact without direct evidence. Use CONFIRMED, SUPPORTED, HYPOTHESIS, REFUTED, UNTESTED, BLOCKED.
- Preserve the distinction between ACX class version (1.0/1.1) and KMDF/WDF version (1.31/1.33).
- A successful CI build is not proof that the driver binds or runs on the physical server.
- Do not infer causality from event ordering alone.
- Do not repeat rejected investigations unless new evidence changes their premise.
- Do not install, remove, stage or restart drivers on the user's physical server without a separate explicit instruction. Do not change BCD, Secure Boot, certificates, services, registry or system settings without an explicit test authorization.
- Do not merge experimental branches or change the production branch as part of documentation work.
- Before editing code, inspect current branch and working tree; preserve user changes.
- Every experiment must state its single changed variable, expected observation, success/failure criteria and rollback.
- Record exact date, commit SHA, workflow run ID, job results, artifact ID, digest and source links.
- Give the user one PowerShell command at a time, on one line, and state whether it is read-only or changes the system.

## Current technical assessment

The leading supported explanation is an ACX class-version mismatch. The previous driver requested ACX 1.1, while the physical host was observed with ACX class module 1.0. Binding failed before the driver's `DriverEntry` body:

`FxStubBindClasses / VersionBindClass class Acx → 0xC000000D (STATUS_INVALID_PARAMETER)`

CI #133 is the isolated ACX 1.0 / Universal candidate. It builds successfully and its package was inspected, but **it has not been installed or runtime-tested on the physical host**. The next technical objective is to obtain a genuine kernel-debugger session and capture:

```text
!wdfldr Acx01000.sys
```

If local kernel debugging is unavailable, investigate a supported remote-kernel-debugging setup. Do not change BCD or reboot the server merely to force a debugger connection without a separate plan and explicit authorization.

## Candidate builds

- **CI #133 — first candidate:** [workflow run](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45044497961), branch `experiment/acx10-server2022-bind`, commit `593e8f407ec18e72a332edbec323a4ddbbd27774`, INF `0.2.326.1634`, ACX 1.0 / Universal. Outer test ZIP SHA-256: `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad`. SYS SHA-256: `435905e1553cb06d089f1477d1cff57c15bbeb84ef3141ca1b3b500a73898f3e`. Durable copy: Files Library `/Bluetooth LDAC Research/Artifacts/CI-133-ACX10-Universal-test.zip`, ID `libfile_fac18af78e50819181cc6ed246a9bb4a`.
- **CI #143 — A/B only:** [workflow run](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45050062916), branch `experiment/acx10-windowsdriver-platform`, commit `6656e2d1fcda8d731f6795bd2e7a2950d5ba8309`. Changes Universal → Windows Driver on top of ACX 1.0. All three jobs passed. It has not been tested on the physical host; draft PR #3 must not be merged.

## Physical-test safety

Before any server-side test, read [PHYSICAL_TEST_RUNBOOK.md](docs/agent/PHYSICAL_TEST_RUNBOOK.md).

- CI #133 is the first candidate because it isolates ACX version while retaining the original Universal target.
- The package preparation script imports a test certificate into LocalMachine Root and TrustedPublisher, enables IHVDRIVER debug output and sets BCD testsigning; it requires a reboot and is not transactional.
- The guarded upgrade tool requires the exact token `I_ACCEPT_LDAC_DIAGNOSTIC_UPGRADE` and checks the exact OPPO devnode and candidate package.
- Do not use `install-oppo.cmd` for the current target; it is intended for an inbox `bth.inf` device.
- `rollback-oppo.cmd` selects inbox `bth.inf`; it does **not** restore the prior WDK 26100 baseline package from successful run #129 / `oem75.inf`. It is a fallback, not an exact restore.
- The CI #133 certificate thumbprint is `4A4E17BFC74DBE7220CA0606763FB81BA85A947B`.
- None of the CI #133 preparation, certificate import, driver upgrade, rollback or reboot steps has been performed on the physical host.

## Current continuation

1. Resolve WinDbg attachment: determine whether the current WinDbg instance is genuinely connected to the local kernel. If not, research a supported debugger transport without changing the host.
2. Capture `!wdfldr Acx01000.sys` and confirm ACX class-module version.
3. Revalidate CI #133 INF version, SYS hash and current device status using read-only commands.
4. Review the complete physical test runbook and record all preconditions.
5. Only after explicit authorization, execute the guarded CI #133 test. First runtime success criterion: the old ACX class-bind `0xC000000D` failure is absent and `LdacA2dp: DriverEntry started` appears. Then test WDF/ACX initialization and A2DP; stable SBC comes before LDAC.

## Confidence discipline

- **CONFIRMED:** directly shown by a source artifact, command output, CI result or reproducible test.
- **SUPPORTED:** multiple independent clues, but no decisive test.
- **HYPOTHESIS:** plausible explanation awaiting a discriminating experiment.
- **REFUTED:** contradicted by a relevant test.
- **UNTESTED:** not yet investigated.
- **BLOCKED:** cannot proceed without user-side access/action.

If any source conflicts with this snapshot, do not silently choose. Compare timestamps and exact commits, record the conflict, then update the snapshot after resolving it. Never claim background work is running unless an actual scheduled automation or tool execution is doing it.


## Latest continuation — 2026-11-22 20:37 Kyiv

Read [the latest run #129 / PnP / LiveKD update](docs/agent/2026-11-22-RUN129-PNP-LIVEKD-UPDATE.md) after this bootstrap. The physical PnP properties now show service LdacA2dp, oem75.inf, DriverVer 0.2.325.1600, Code 37 and ProblemStatus 0xC000000D. The successful WDK 26100.6584 ACX 1.1 build is GitHub Actions run #129 (ID 44922058650); actual run #126 (ID 44922013678) failed. Do not reuse the old CI #126 label for run #129 artifacts.

The leading ACX 1.1-versus-1.0 class-version hypothesis remains supported, not proven. CI #6/#7 were cancelled, CI #8 failed in the LiveKD harness, and the latest workflow fix commit has no verified CI result. Next action is the read-only status pre-check for CI #133 / ACX 1.0 after extraction; no server-changing action is authorized.
