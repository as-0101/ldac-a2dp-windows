# LDAC project — agent bootstrap

> Read this file first. Target context-recovery time: 2–3 minutes. Project scope: Windows Server 2022 Bluetooth A2DP / LDAC for OPPO Enco Buds2 only.

## Required reading order

1. [Current project state](docs/agent/PROJECT_STATE.md) — authoritative current status and next step.
2. [Evidence register](docs/agent/EVIDENCE.md) — every important claim linked to logs, commits, CI and artifacts.
3. [Knowledge graph](docs/agent/KNOWLEDGE_GRAPH.md) — causal chain, hypotheses and dependencies.
4. [Decisions and experiments](docs/agent/DECISIONS_AND_EXPERIMENTS.md) — what was tested, excluded and why.
5. [Next actions](docs/agent/NEXT_ACTIONS.md) — exact continuation sequence.

Full human-readable research journal and original evidence index:
- [Notion research journal](https://app.notion.com/p/41f769fff636810fbd50c285bc3d33f6)
- [Notion handoff and artifact index](https://app.notion.com/p/420769fff636812ab023c0fb67c66a5a)

## Rules for every agent

- Treat `PROJECT_STATE.md` as the current snapshot; the Notion journal is append-only historical detail.
- Never upgrade a hypothesis to fact without direct evidence. Use CONFIRMED, SUPPORTED, HYPOTHESIS, REFUTED, UNTESTED, BLOCKED.
- Preserve the distinction between ACX class version (1.0/1.1) and KMDF version (1.31/1.33).
- A successful CI build is not proof that the driver binds or runs on the physical server.
- Do not infer causality from event ordering alone.
- Do not repeat rejected investigations unless new evidence changes their premise.
- Do not install, remove, stage or restart drivers on the user's physical server without a separate explicit instruction. Do not change BCD, Secure Boot, services or system settings.
- Do not merge experimental branches or change the production branch as part of documentation work.
- Before editing code, inspect current branch and working tree; preserve user changes.
- Every experiment must state its single changed variable, expected observation, success/failure criteria and rollback.
- Record exact date, commit SHA, workflow run ID, job results, artifact ID, digest and source links.

## Current continuation in one sentence

The physical Server 2022 host reports ACX class module 1.0, while the previous driver build requested ACX 1.1 and failed in pre-DriverEntry class binding; the isolated ACX 1.0 experiment now builds successfully in CI run #133, and the next unresolved question is whether that package passes class binding on the physical host.

## Confidence discipline

- CONFIRMED: directly shown by a source artifact, command output, CI result or reproducible test.
- SUPPORTED: multiple independent clues, but no decisive test.
- HYPOTHESIS: plausible explanation awaiting a discriminating experiment.
- REFUTED: contradicted by a relevant test.
- UNTESTED: not yet investigated.
- BLOCKED: cannot proceed without user-side access/action.

If any source conflicts with this snapshot, do not silently choose. Record the conflict, compare timestamps and exact commits, then update this file only after resolving it.

## New comparison reference — 2026-11-22

Read [docs/agent/SAMPLE_COMPARISON.md](docs/agent/SAMPLE_COMPARISON.md) for the detailed comparison with Microsoft's official ACX AudioCodec sample, the ACX 1.0 API scan, INF/service analysis, target-platform A/B branch, and ETW unload timeline.

Current A/B branch: [experiment/acx10-windowsdriver-platform](https://github.com/as-0101/ldac-a2dp-windows/tree/experiment/acx10-windowsdriver-platform), draft [PR #3](https://github.com/as-0101/ldac-a2dp-windows/pull/3), CI #143 run 45050062916 completed successfully; all three jobs passed. Artifacts are preserved in the Files Library; see PROJECT_STATE.md.

