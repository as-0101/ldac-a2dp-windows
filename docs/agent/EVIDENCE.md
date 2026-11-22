# Evidence register

Status labels: CONFIRMED = direct evidence; SUPPORTED = converging evidence, not conclusive; HYPOTHESIS = unproven; REFUTED = contradicted by a relevant test; UNTESTED = not checked; BLOCKED = needs external action.

| ID | Claim / observation | Status | Source |
|---|---|---|---|
| E-001 | LDAC driver fails before its `DriverEntry` body; ACX class binding returns `0xC000000D`. | CONFIRMED | Notion journal, 21–22 Nov entries; DebugView `AS-KRM-WS.log` and `AS-KRM-WS(1).log`; Kernel-PnP ETW `LDAC-Trace.xml`. |
| E-002 | Kernel-PnP Event 227 records `STATUS_INVALID_PARAMETER` for the driver-init failure. | CONFIRMED | Notion journal; Library artifact `LDAC-Trace.xml`, file ID `file_00000000c3b08210ba662454ece33a1c`. |
| E-003 | Physical server's ACX class module reports version 1.0; its WDF client version is 1.31. | CONFIRMED | WinDbg `!wdfldr Acx01000.sys` output transcribed in Notion handoff. Distinguish CLASS_MODULE Version from WDF Version. |
| E-004 | CI #126 build requested ACX 1.1 and used WDK/SDK 10.0.26100.6584. | CONFIRMED | GitHub CI #126 and branch project files; [run #126](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/44922058650). |
| E-005 | ACX 1.0 versus 1.1 mismatch explains the pre-DriverEntry binding error. | SUPPORTED | E-001 + E-003 + E-004; final proof requires physical-host test of ACX 1.0 build. |
| E-006 | ACX 1.0 experiment compiles successfully. | CONFIRMED | [CI run #133](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45044497961), head SHA `593e8f407ec18e72a332edbec323a4ddbbd27774`; all three jobs success. |
| E-007 | CI #133 package artifact was generated. | CONFIRMED | Artifact 14763242251, digest `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad`; artifact 14763157658, digest `1302c21c3278af9134b5959577a6daa629d0649fd1405148012e074e8147db9c`. |
| E-008 | CI #133 job ran on Windows Server 2022 build 20348; driver build and signability check passed with zero warnings/errors. | CONFIRMED | KMDF driver job 137276017983, logs; run #133. |
| E-009 | CI #133 resolves the ACX include and stub library specifically to 1.0. | SUPPORTED | Project file sets `ACX_VERSION_MINOR=0` and computes include/link paths from the macro; exact expanded path not printed in captured job log. Verify if needed. |
| E-010 | Driver passes ACX class binding on physical Server 2022. | UNTESTED | No ACX 1.0 package has been installed/tested on the physical server. |
| E-011 | KMDF 1.31 versus WDF runtime 1.33 is the cause. | UNTESTED / LOW PRIORITY | No direct evidence; separate from ACX class module version. |
| E-012 | ACX unload caused LDAC class-bind failure. | UNTESTED | ETW event order alone is not causal evidence. |
| E-013 | `DriverTargetPlatform=Universal` is the cause. | LOW PRIORITY / NOT SUPPORTED | Kept unchanged in experiment; Microsoft sample precedent noted in Notion handoff. |
| E-014 | Physical device was last recorded on `oem75.inf`, version 0.2.325.1600, Code 37. | CONFIRMED (last recorded state) | User-side status after CI #126, documented in Notion. State may have changed since; re-query before any action. |

## Artifact locations

Persistent source archive: Notion Files Library folder `/Bluetooth LDAC Research/Artifacts/`, Directory ID `6b0318b95f648191802d868fc1be5e96`. The handoff page contains exact Library IDs for CI #126 ZIPs and diagnostic logs.

Current run #133 GitHub artifact URLs:
- [Test package 14763242251](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14763242251/zip)
- [Unsigned driver 14763157658](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14763157658/zip)
- [SDP probe 14762557767](https://api.github.com/repos/as-0101/ldac-a2dp-windows/actions/artifacts/14762557767/zip)

All run #133 artifacts expire 2026-11-29. Their digests are in PROJECT_STATE.md.
