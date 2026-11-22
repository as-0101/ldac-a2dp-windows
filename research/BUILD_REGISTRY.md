# Build registry

Status vocabulary: `BUILT`, `STATICALLY_VERIFIED`, `VM_TESTED`, `HARDWARE_TESTED`, `REJECTED`, `SUPERSEDED`, `UNKNOWN`. A CI workflow's green result is not a runtime test.

| Build / run | Branch and commit | DriverVer / ACX / target | Artifact identity | Evidence and outcome | Status |
|---|---|---|---|---|---|
| Successful baseline run #129 / 44922058650 | `fix/server2022-acx-wdk-26100`, `4571873b505c52a93db4c785fe3d083eabf8499e` | 0.2.325.1600; ACX 1.1; WDK/SDK 10.0.26100.6584 | Historical artifact labels CI-126 are misleading; actual successful run is #129. See E-042 and CI133_PACKAGE_REVIEW. | Successful build; physical device later showed matching version and Code 37 / 0xC000000D. | BUILT |
| CI #133 / 45044497961 | `experiment/acx10-server2022-bind`, `593e8f407ec18e72a332edbec323a4ddbbd27774` | 0.2.326.1634; ACX 1.0; Universal | Test ZIP digest `f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad`; SYS `435905e1553cb06d089f1477d1cff57c15bbeb84ef3141ca1b3b500a73898f3e`; INF `5fe047ff4ab7a157b01043f6c4de2ba9c805042c9ee678447404f69da7bbdd19`; CAT `f0202a0eef8f5add021ca01e0d34851ef00def1e2be8aa8ea7c32b3a158ee738`; EXE `11070baa1950f34e133f5e653b348b17c0a1ccf8e82388ee05f4228cc41ef733`. | Package/PDB inspected; PDB shows 210 ACX table entries vs 221 in #129; no physical runtime test. | STATICALLY_VERIFIED |
| CI #143 / 45050062916 | `experiment/acx10-windowsdriver-platform`, `6656e2d1fcda8d731f6795bd2e7a2950d5ba8309` | ACX 1.0; Windows Driver target (A/B against Universal) | See CI run; exact artifact hashes not captured in current compact source. | Three build jobs passed; no physical/hosted bind result. | BUILT |
| Hosted ACX 1.0 attempt #248 / 45060225420 | `experiment/acx10-hosted-load`, `3d1d5d7e179da3379013b10f9863066200c459b6` | 0.2.326.1922; ACX 1.0; Universal | Test package artifact 14768714620, digest `b1ac0c4bd52bc965e549de18c584655331e7c7d58cdc9a02acb35e17528f175c`; unsigned artifact 14769077870, digest `a021fbdd49e803e88f1e7860859d9299ab5112394b39e2204107e72d6400fbc8`; report artifact 14769048266, digest `e2e3f177c85420886b6139ba4ef130d5a6df8beaaeb261c3a9685c7645b2a5bb`. Report SYS SHA-256 `FF97EED8409A7FF9DADB8D9C7C7FB309E789F9A3225847793B39B7D97D8FB9A8`; INF `0111FD38ED61DCA2D3D9691CB6BC70675AD588A9B6B2778113B2CFBDBFFC4B6C`; CAT `F40C19BF69B43DFE91C49CBA67ED7DA18BF4147B6F065C7BC132B97969C22D94`. | Hosted Server 2022 disposable runner; Acx01000 explicitly RUNNING; PnP selected oem13.inf and attempted start; Code 37 / ProblemStatus 0xC000000D. No DriverEntry. Artifact metadata says DriverVer .1922; older PROJECT_STATE line says .1920 — .1922 is supported by preflight.json and SetupAPI. | REJECTED (runtime candidate behavior) |
| ACX stub metadata #255 / 45060819535 | `experiment/acx10-hosted-load`, `085705abb4bf8e52dd5bcb5bccb532352fbb132e` | WDK NuGet 10.0.26100.6584 | Artifact 14769755224, digest `8d23900221ae823eeb4044f9d7ca8169c7b5491cd512a323e65ed418a27ba5ce`. | Direct stub descriptor parsing: ACX 1.0 = 210 functions/62 structures; ACX 1.1 = 221/62; candidate CI #246 SYS descriptor = 1.0 / 210 / 62. | STATICALLY_VERIFIED |
| ACX stub-inspection workflow #1 / 45060793775 | `research/acx-stub-metadata`, `4137f3fc2af65a1c1ba9c5683410f9f24e93a554` | WDK 10.0.26100.6584 | No artifact uploaded. | Failed because workflow assumed WDK package contained an `Include` folder; actual NuGet layout differs. Not a driver failure. | REJECTED (harness) |

## Provenance rules

- Never conflate workflow run number with run ID.
- Never conflate branch head with artifact provenance.
- PDB correspondence requires GUID/Age or an explicit binary/PDB matching tool result; matching filename/version is insufficient.
- CI artifact digests are for the downloaded artifact ZIP, not the inner SYS/INF/CAT.
- Keep every run as its own row; append rather than merging results.
