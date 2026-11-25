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
