# HFP INF/CAT and signature gate — Windows Server 2022

Date: 2026-11-25. **Only metadata tests, no driver package staging/loading.**

## Confirmed CI
- Branch `research/hfp-inf-cat-gate-20261125`; commit [`d736e25`](https://github.com/as-0101/ldac-a2dp-windows/commit/d736e25eaaf7cf1b17f4aef996291caf59f31939).
- Free hosted runner CI [45663727116](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45663727116): **SUCCESS**, Server 2022 Datacenter build **20348.5870**; **13/13** HFP INF parser controls passed. No Windows client donor binaries were downloaded or published.
- CI metadata artifact ID `15046132226`, ZIP SHA256 `3982d95b576707b9b8a8e5dbb0956d14ebb344acc89c28b9b0c0857bcb0c2ec7` (downloaded and independently hashed). Artifact expires 2026-12-02; permanent backup in `LDAC Project/Artifacts/HFP-INF-CAT-20261125/`.
- **HFP INF missing** in `C:\Windows\INF` and **HFP DriverStore package absent**. `BTHHFENUM` root absent. `BthHfEnum`, `BthHfAud`, `BthHFSrv`, `BTAGService`, `BtaMPM`, `BthA2dp` service keys absent. `BthHfAud.sys`, `BthHfEnum.sys`, `BtaMPM.sys` absent from `System32\drivers`.
- Positive control: Server `BthPort.sys` SHA256 `CD9249B879ECDA828501F3016B1885862E70F15F9F22614EBB94A17721BD836E` is Microsoft signed (`Get-AuthenticodeSignature`: Valid), **SignTool /kp /v /a exit code 0**, 0 errors. This verifies the *tool and inbox transport*, **not foreign Win10 HFP CAT applicability**.
- `bth.inf` contains generic Hands-Free service mapping UUID 0x111E; that generic mapping is not the missing HFP AG+audio provider.
- WDK `Inf2Cat.exe` absent from the unmodified hosted runner installation; its documented target identifier for Server 2022 x64 is `ServerFE_X64`. No complete original HFP INF/CAT is present to run it against.

## Donor evidence limitation
The archived Win10 donor artifact from [CI 45612001590](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45612001590) contains only 3 PE JSON reports and `manifest.json`, **not** original INF, SYS, CAT. The code fix for HFP scanner was later blocked by UUP HTTP 504 before extraction. It is incorrect to infer signer, CAT SHA, catalog membership, decorated INF applicability or service closure for `microsoft_bluetooth_hfp.inf` from PE import data alone. The earlier 229/229 export-name closure remains static ABI evidence only.

## Driver signing policy: critical gate
Microsoft [Driver Signing Options](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/driver-signing-offerings) states Windows Server 2016+ does not accept dashboard attestation signed device/filter drivers, and normal modern Server loading requires HLK-passed dashboard signing. Thus the independent OpenA2DP/HFP route must plan for Microsoft Server-appropriate HLK signing, **not** assume that self-signing or desktop attestation solves deployment. Do not change Secure Boot, kernel integrity policy or test mode on the physical host. Legacy exceptions are not the target strategy.

## Next executable discriminators
1. Acquire the **complete original unmodified Windows 10 HFP package** (INF/CAT and referenced SYS) from an authorized local Win10 donor or independent Microsoft source. We prepared a read-only Windows 10 collector `tools/stand/collect_win10_hfp_inf_cat_evidence.ps1` which outputs JSON metadata only. This collector itself is **not yet run against a Win10 donor**.
2. In a disposable Server 2022 runner, first check real CAT signature and **each exact file** with `SignTool verify /kp /v /c`, original INF with InfVerif, package signability with `Inf2Cat /nocat /os:ServerFE_X64` if full referenced source files available. Compare signature trust and PnP package/catalog completeness. Do not mistake `Inf2Cat`'s unsigned signability check for a signed-trust result.
3. Only after a Server-accepted signed package exists, consider isolated staging, PnP binding, service start, media capture endpoint and actual radio/duplex tests. No test-signing, no physical server modifications, no paid CI.

**Acceptance: UNTESTED. Real HFP driver load: NOT ATTEMPTED. Current missing blocker: authentic complete Windows 10 HFP INF/CAT and Server-eligible signing path.**