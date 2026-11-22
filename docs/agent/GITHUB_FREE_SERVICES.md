# GitHub Free services — LDAC project

**Status date:** 2026-11-22  
**Working branch:** `infra/github-free-tooling`  
**Review:** Draft PR #5 — https://github.com/as-0101/ldac-a2dp-windows/pull/5

## Objective

Use GitHub's no-cost capabilities as a reproducible research and CI environment for the Windows Server 2022 LDAC/A2DP driver. Do not depend on paid runners, paid security add-ons, or changes to the physical test host.

## Implemented in this branch

| Capability | Configuration | Purpose | State |
|---|---|---|---|
| Dependabot version updates | `.github/dependabot.yml` | Weekly checks for GitHub Actions and NuGet packages in `driver/` | Added; awaiting GitHub evaluation |
| CodeQL | `.github/workflows/codeql.yml` | Analyze C++, C#, and GitHub Actions code | Added; first CI run in progress |
| Review boundary | Draft PR #5 | Keep infrastructure changes isolated from driver and source-of-truth docs | Active |

## Repository observations

- Repository is public.
- GitHub Actions workflows already build native core, the settings utility, and the KMDF driver on Windows-hosted runners.
- The existing workflow restores WDK/SDK 10.0.26100.6584 through NuGet.
- GitHub Issues API returned HTTP 410: Issues are disabled for this repository. Do not treat Issues as available until repository settings are changed.
- The repository's source-of-truth documentation remains on `docs/project-source-reorg`. This branch is an isolated proposal and does not replace it.

## Candidate free capabilities

| Capability | LDAC use | Current disposition |
|---|---|---|
| GitHub Actions | Windows builds, tests, disposable runtime probes, artifact manifests | Core infrastructure; keep workflows narrow and avoid unnecessary matrix duplication |
| Actions artifacts | Preserve logs, PDBs, package hashes, probe reports | Use short retention for transient diagnostics; publish only sanitized, non-sensitive outputs |
| Dependabot | Keep Actions and NuGet dependencies current | Configured in this branch |
| CodeQL | Static analysis of C++, C#, workflow code | Configured in this branch; confirm first run and repository security settings |
| Releases | Immutable milestones for verified source/package manifests | Use only after a reproducible milestone; never publish private signing keys or physical-host credentials |
| GitHub Pages | Public research dashboard with evidence links and test status | Candidate; requires enabling Pages in repository settings |
| Projects | Cross-experiment backlog and status board | Candidate; currently use documentation until feature availability/settings are confirmed |
| Discussions | Long-form technical discussion | Low priority; Issues are currently disabled |
| Codespaces | Occasional cloud editing | Low priority; not a substitute for Windows Server 2022 runtime testing |
| Packages | Package distribution | Not needed yet; Actions artifacts and Releases are sufficient for current volume |

## Safety and governance

1. Never run experimental driver packages on the physical Server 2022 host without separate explicit user authorization and reviewed rollback steps.
2. Never upload PFX files, private keys, tokens, user data, full memory dumps, or unredacted device identifiers.
3. Treat CI build success, driver load, PnP binding, ACX endpoint creation, codec negotiation, and real audio streaming as separate evidence stages.
4. Use ephemeral hosted runners for runtime experiments; verify test-signing preflight and clean up synthetic devices/certificates even after failures.
5. Set explicit least-privilege workflow permissions. Use `contents: read` by default; grant `security-events: write` only to CodeQL analysis.
6. Pin third-party Actions to reviewed immutable commit SHAs for production workflows where practical; Dependabot can propose updates.
7. Keep experiment artifacts short-lived unless they are indexed and needed as durable evidence. Record SHA-256 for retained binaries.
8. Keep this infrastructure proposal in its own branch until checks pass and the PR is reviewed.

## Next verification steps

- [ ] Confirm CodeQL matrix jobs complete and produce analysis results.
- [ ] Confirm existing build workflow remains green on the infrastructure branch.
- [ ] Confirm Dependabot accepts both ecosystems and opens update PRs when updates are available.
- [ ] Inspect repository settings for Dependency Graph, Dependabot alerts, and security update availability.
- [ ] Decide whether to enable Issues and Projects for experiment tracking.
- [ ] Enable Pages only after a sanitized dashboard exists.
- [ ] Define artifact retention tiers: transient CI logs, investigation evidence, and release-grade outputs.
- [ ] Merge only after review; do not auto-merge this draft.

## Evidence links

- Draft PR: https://github.com/as-0101/ldac-a2dp-windows/pull/5
- CodeQL workflow: https://github.com/as-0101/ldac-a2dp-windows/actions/workflows/codeql.yml
- Existing build workflow: https://github.com/as-0101/ldac-a2dp-windows/actions/workflows/build.yml
