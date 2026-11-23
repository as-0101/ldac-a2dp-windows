# START HERE

The canonical Project Source entry point is [LDAC_Project_Source_START_HERE.md](LDAC_Project_Source_START_HERE.md).

**Current direction (2026-11-23 23:40):** stop ACX/WDK bind-probe work. Recover and audit the complete signed Windows 10 Microsoft A2DP source package, then test SBC stereo in a disposable Server 2022 VM. The targeted exporter is read-only but does not collect the full DLL/COM/PE dependency closure. Windows 10 has no inbox LDAC codec; Enco Buds2 is SBC/AAC-only. Alternative A2DP and BlueCaster are third-party fallback architectures, not Microsoft codec DLLs. See [the pipeline map](docs/agent/WIN10_A2DP_PIPELINE.md).

The detailed status, evidence, tests, artifacts, and decisions are maintained in the canonical Project Source file and the linked registries. Historical ACX experiments remain recorded but are not the current next step.
