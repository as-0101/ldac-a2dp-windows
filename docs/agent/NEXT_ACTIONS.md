# Active executable queue — 2026-11-25
## P0-WDM: independent audio control (new priority)
1. On research/wdm-profile-reengineering, inspect Microsoft's SysVAD PortCls sample and existing repository build tooling. Identify exact WDK 20348-compatible render/capture topology and dependencies. Pin sample revision, record license and source. Build an unmodified control on an available free isolated Windows runner, without changing trust policy. Inspect logs, PE imports and INF closure. A build is not a loaded endpoint. If signed installation is unavailable, record signing as a runtime gate and continue static and transport checks.
2. Compare documented Bluetooth BRB L2CAP and SCO interfaces with Server headers/import inventory. Design independent transport adapter with A2DP Source and HFP AG state machines; reuse only license-compatible existing code. Test protocol logic independently of hardware; save actual test output. No fabricated endpoint claims.
3. HFP: check fixed donor CI fd55005a rather than rerun original failed job. Use connector jobs/logs/artifacts; if listing unavailable record exact limitation and advance WDM.
4. In every run make an actual tool call first, perform a concrete test or analysis, persist evidence and next task. A report without work is not a successful cycle. Never invent a blocker.

## Prior queue (still applicable)
# Active queue — 2026-11-25
Canonical scope: [START_HERE](../../START_HERE.md). Historical queue: [archive](../../archive/2026-11-25/docs/agent/NEXT_ACTIONS.md).
## P0 HFP donor dependency evidence
1. Read latest experiment/native-donor-inf-20261124 head and HFP workflow runs; verify whether fd55005a has run. Old run 45586559618 is a harness failure, not a product failure. Test ordered-dictionary filter with positive, absent and empty inputs. Obtain hfp-donor.json and PE metadata; compare exact INF Include/Needs, service registrations, import names/ordinals/forwarders and Server provider inventory. Keep raw donor files private. Record limitations.
2. In parallel, inspect tools/stand/headset-endpoints.ps1 for container/ancestry and render/capture correlation. Endpoint identity does not prove a call.
## P0 A2DP package applicability
3. Investigate documented signed Server-applicable package/servicing path or independently supported driver implementation preserving Server transport and trust. Original Win10 CAT membership and static closure are established; unchanged PnPUtil retries and dependency-first staging already failed. No blind CBS import or edited inbox INF with original CAT.
4. Only with materially changed supported conditions, run disposable staging test; check native return, DriverStore delta and SetupAPI. If staged, test PnP binding/service start/driver load separately. UBR 5870 differs from physical 5761.
## P1 Runtime and acceptance
5. A2DP render endpoint, SBC negotiation and real stereo; HFP render+capture endpoints for same paired device; duplex messenger call, reconnect, stereo recovery, Windows 10 control and portability. Real radio/headset and remote participant necessary. Physical host requires explicit authorization.
## Parked
ACX/LDAC optional paths remain historical until new discriminating evidence. No unchanged reruns of CI #5/#6, no repeat inventory without new target or coverage. Do not mark untested ABI/runtime as refuted.
## Loop
For each run: refresh evidence → test hypothesis → inspect actual output → fix measurement → repeat where useful → independent hypothesis → update current checkpoint and evidence. Report only verified outcomes. 
