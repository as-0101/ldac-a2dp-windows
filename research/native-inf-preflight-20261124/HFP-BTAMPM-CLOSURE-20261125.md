# Manual automation kick — HFP PE cross-artifact closure and SysVAD CI 2026-11-25

## Execution mode and boundaries
The Bluetooth automation `6b05e602ca7481918bd4a164f6e2407f` accepted an explicit `run_now` and supplied an **inline_run in Chat**. Its hourly schedule remains unchanged. This proves manual execution in this thread, **not** automatic scheduled-run effectiveness. No Codex/Work, paid resource, physical Server changes, security relaxation or Microsoft binaries published.

## Verified SysVAD gate (modified CI reference only)
- Windows-driver-samples pinned source `d49bb7d72f3651952b2b6e4ad28d14fe2247eb69` (MS-PL); comparison baseline original source is unmodified. The disposable runner's `ComponentizedAudioSample.inx` was modified locally to add `MsApoFxProxy.Registration` to `SYSVAD_SA.NT` Needs as demanded by previous InfVerif ERROR(2663). Commit: [62ce875](https://github.com/as-0101/ldac-a2dp-windows/commit/62ce875add00727f5cb3440b29c47f426f11a3a5).
- [CI run 45659496556](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45659496556) **completed/success**. `EndpointsCommon` and `TabletAudioSample.sys` compile/link exit codes 0. Separately run x64 InfVerif returns **0 on all three generated INF files** (ComponentizedApoSample, ComponentizedAudioSample, ComponentizedAudioSampleExtension).
- `TabletAudioSample.sys`: 238080 bytes; SHA256 `D809365452A72E864BB66E564ABB5CAC5F21BCCEF130BFE41E8A6547E7524D06`. INF patched source SHA256 `4A0D85BC27C0CCD6E1D3594285AD502CBD488496A40C4A9D79D0D709592A837A`.
- Metadata artifact [15044209116](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45659496556/artifacts/15044209116), downloaded and verified ZIP SHA256 `2dc0a0aa8f16fcb5773e46dcea55374ebb14c55babe9d221c77f22fc3aed203f`, persistent Library `/LDAC Project/Artifacts/WDM-20261125/sysvad-ci-45659496556-metadata.zip`.
- **Caution:** MSBuild built-in x86 verification/ApiValidator tasks were disabled in this *compile-only* free runner; independent InfVerif passed but neither API validator nor signed catalog/kernel installation/loaded endpoint/duplex were proved. Do not claim package deployment.

## NEW HFP import → package BtaMPM export closure
- Read the original partial HFP donor artifact [15023735500](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45612001590/artifacts/15023735500), run 45612001590 (failed **later** in metadata harness, but 3 PE JSONs were preserved). ZIP SHA256 `d105dea586066c10e3f162a0bb1fb4dae5280dbe5041b6bac3527ad7043f610d`.
- Cross-checked against prior stored `/LDAC Project/Artifacts/A2DP-donor-results-20261125.zip` (nested CI-6-dependency-first.zip) ZIP SHA256 `e750de7636098d71b73cc64542059547c0854cbdbf39547b0b6c4c2fc280c60d`.
- Exact package BtaMPM.sys (SHA256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`) exports 14 names, with no forwarders for the seven HFP references.
- Both `BthHfEnum.sys` variants independently import **seven named BtaMPM functions**, **7/7 exported and no missing names or ordinal imports**:
  `BtaMpmBuildIndirectStringFromMessageWithSingleUTF8Arg`, `BtaMpmConnectionRequest`, `BtaMpmGetRemoteDeviceProfileVersionAndAttribute`, `BtaMpmRegister`, `BtaMpmSuspendRequest`, `BtaMpmUnregister`, `BtaMpmUpdateConnectionStatus`.
- DriverStore `BthHfEnum.sys`: 149504 bytes, SHA256 `1e9a3ca8f834c12a2c866e6f65ab5cf1116b641298578e0b753718790287538c`, 76 total imported names (includes seven BtaMPM). System32 `BthHfEnum.sys`: 144896 bytes, SHA256 `91c72c54142a0d4e5a5f33268850ceb8315aa30c2f0b74a9ffa962887abac797`, 70 imported names (also seven BtaMPM). These are different builds; do not conflate.
- `BthHfAud.sys`: 65536 bytes, SHA256 `4e4d7e1f1a6dfcdb35e2ce1c1cb99b1e23e4aef7023aa5889f44ce50dd38af9d`, 83 imported names distributed ntoskrnl(43), HAL(1), ks(35), WppRecorder(4). **No installed/running HFP Audio Gateway or capture endpoint is proved.**
- Reproducible analyzer `tools/research/hfp_btampm_closure.py` and tests `tools/research/test_hfp_btampm_closure.py`: **4/4 tests pass with both source ZIPs**, including negative missing-name and forwarded-export controls. Reproducible artifact `research/native-inf-preflight-20261124/hfp-btampm-closure-20261125.json`. Archives also preserved in Library.

## Next discriminators
1. Inspect exact Server 20348 export set for **HFP-specific BthHfAud and BthHfEnum imports**, not just BtaMPM name closure. Static compatibility is necessary, not sufficient. Never repeat unchanged original INF 0xE000022F staging.
2. Determine supported kernel signer and INF/catalog path, then isolated Server 2022 runtime test without relaxing security; do not use physical host until authorized.
3. Independently implement HFP Audio Gateway RFCOMM/SCO and microphone capture (existing OpenA2DP is render-only), and prove same-headset render/capture identity + real messenger duplex. **UNTESTED**.
