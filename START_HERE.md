# Bluetooth Classic on Windows Server 2022 — START HERE
Revision: 2026-11-25 | Repository: as-0101/ldac-a2dp-windows | Canonical branch: docs/project-source-reorg

## Mission and acceptance
Adapt the Windows 10 Bluetooth Classic headset stack to Server 2022 while preserving Server Bluetooth transport and audio core. OPPO Enco Buds2 + Intel are the reference pair. A2DP Source/SBC to headset Sink 0x110B is the first milestone; HFP Audio Gateway to Hands-Free 0x111E is equally mandatory. LDAC is optional, not an OPPO acceptance criterion.
After one pairing, show selectable render and capture endpoints of the same physical headset. Confirm their association using device ancestry/container and Bluetooth identity, then prove simultaneous two-way speech in a real messenger call, repeat after reconnect, compare with Windows 10, prove stereo before and recovery after the call. Repeat with another compatible Classic headset and another controller. Distinct logical endpoints are allowed. No hardware call evidence means acceptance UNTESTED.

## Read only these first
1. [Live START_HERE](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/START_HERE.md) — freshest evidence and gate.
2. [Active tasks](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/NEXT_ACTIONS.md).
3. [Decision graph](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/KNOWLEDGE_GRAPH.md).
4. Relevant evidence only: [A2DP](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/research/native-inf-preflight-20261124/donor-results.md), [HFP](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/research/native-inf-preflight-20261124/hfp-inventory.md), [artifact index](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/research/ARTIFACT_INDEX.md).
Historical documents are not instructions. [Archived navigation](https://github.com/as-0101/ldac-a2dp-windows/tree/docs/project-source-reorg/archive/2026-11-25). GitHub is the technical source of truth, Notion is navigation/decision history, Library /LDAC Project retains evidence. Do not reload all history.

## Baseline at this revision
- Physical snapshot 20348.5761; disposable hosted Server 20348.5870; Windows 10 donor 19045.5917; comparison capture 19045.6456. Do not equate these builds.
- A2DP: exact donor imports resolve by name (149/149 BthA2dp; 42/42 BtaMPM). Static INF closure 28 sections, no unresolved explicit references in combined model. Original CAT verifies five donor files. CI #5 and #6 still reject staging; no package added. No runtime result.
- HFP: generic 0x111E exists; inspected Server lacks named HFP profile INF/runtime/service keys, saved Server capture lacks BTHHFENUM child seen in Win10. Capture endpoint and duplex are UNTESTED.
- HFP donor CI [45586559618](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45586559618) failed in metadata harness; artifact [15010587976](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45586559618/artifacts/15010587976) listed as unexpired, 9863 bytes. Fix committed [fd55005a](https://github.com/as-0101/ldac-a2dp-windows/commit/fd55005a9134e38066c2a0feb75058164e83182c) on experiment/native-donor-inf-20261124; repeat outcome not verified. Check latest branch and real job log before repeating.
- ACX Code 37 route PARKED; ACX 1.0 alone did not fix tested candidate. Do not reopen without discriminating new evidence.

## Execution rules
Work in Chat using available connectors and free resources. Read branch head, actual CI logs and artifact metadata; don't equate empty PR-filtered workflow search with no runs. Use alternative branch/head_sha lookup where available. Fix harness defects, retest; if blocked or CI pending, pursue independent tests. Do not end on a minor negative result, one commit, plan, or CI launch. Finish on verified meaningful gate, actual execution limit, or exhausted safe independent work. Report exact blocker and what was not done.
Preserve original Microsoft signatures; no security weakening, no physical Server change without separate authorization and rollback review. No Microsoft binary publication, paid runner, or whole unrelated client CBS import. Use disposable tests and metadata-only reports. Record SHA, run/job/artifact IDs, OS/UBR, controls, result and next discriminator. PowerShell commands one line. No claims of background execution outside automation.
