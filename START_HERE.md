## Product scope — vendor-independent A2DP Source

User clarified 2026-11-24: the deliverable is restoration of standard Bluetooth Classic A2DP Source playback on Windows Server 2022 using the existing Windows Bluetooth transport, not an OPPO- or Intel-specific driver. OPPO Enco Buds2 and Intel are reference hardware only. The design must not require vendor-specific controller IDs or headset model IDs in profile binding; use the standard remote Audio Sink service UUID (0x110B) where appropriate. Controller vendors can supply transport drivers and optional proprietary extensions, so compatibility is conditional on a working Windows-compatible Bluetooth Classic transport and remote A2DP Sink support. Preserve Server inbox Bluetooth core and audio core. Initial success: stable SBC stereo endpoint and audible playback on reference hardware. Generalization: separately validate other available controller/headset combinations (ideally Intel and Realtek with distinct A2DP headsets); do not claim universal hardware compatibility before testing. LDAC and HFP remain separate later milestones. This clarification does not change the active WDM research path, authorize physical-host modifications, or prove runtime support.

## 2026-11-25 — HFP inventory completed

The exact Windows 10 profile family microsoft_bluetooth_hfp.inf, its BthHfAud runtime and candidate HFP service definitions were absent from the inspected hosted Server 20348.5870 inventory. The generic 0x111E mapping and core service controls were present. Windows 10 SetupAPI identifies the original HFP audio child, INF and SYS. [Evidence](/research/native-inf-preflight-20261124/hfp-inventory.md).

## 2026-11-25 — HFP microphone added to scope

A2DP Source remains the stereo SBC milestone. HFP Audio Gateway is a separate milestone for mono playback and microphone capture. In the saved Server 20348.5761 PnP CSV, the headset Hands-Free UUID 0x111E appears under BTHENUM with class Bluetooth and CM_PROB_NONE. In the Win10 19045.6456 comparison, the 0x111E node has class System and there is a MEDIA BTHHFENUM child named OPPO Enco Buds2 Hands-Free AG Audio. The Server capture has no BTHHFENUM row. These PnP snapshots do not contain evidence of a capture endpoint or a successful audio recording. Next evidence to collect on a disposable runner: presence of HFP profile INF and associated services and, on a suitable Windows VM with a radio, proof of a capture endpoint and audio samples. Physical-host authorization is unchanged.

[Microsoft Bluetooth Classic audio](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/bluetooth-classic-audio)

## 2026-11-25 — CI #6 completed; direct import names resolved

All three original donor INFs failed staging with 0xE000022F, including the standalone MPM attempt. On hosted Server 20348.5870, explicit append exposed all eight tested sections and the donor SYS pair resolved 149 and 42 direct imports respectively in a static check. No runtime binding or audio result. [Report](/research/native-inf-preflight-20261124/donor-results.md).

## 2026-11-25 — Dependency-first staging CI started

[Run 45511693396](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45511693396) on experiment/win10-a2dp-stage-smoke-20261124, commit df8eb05e896312277938c01fda37a51418c374d7. The hosted Server preflight and PowerShell syntax checks passed. Step 7 prepares the donor WIM and verifies original Microsoft CAT membership before separate PnPUtil calls in common INF, MPM INF, source INF order. Each call records its exit code, matching newly staged entries and appended SetupAPI log. The disposable runner does not install devices, change signature policy or register a catalog in this experiment. Check the run's step 7 log and stage-test.json before assigning any staging result. CI #5's equivalent image preparation and staging step took about 27 minutes.

## 2026-11-25 — Bluetooth deployment and additional component media checked

The installed deployment's ten direct dependencies and all 33 selected neutral non-language CAB tables in official Server 2022 optional media had no named A2DP/BtaMPM payload. The App Compatibility CAB does carry basic Bluetooth service/API files. See [deployment audit](research/native-inf-preflight-20261124/deployment-audit.md) and [optional media audit](research/native-inf-preflight-20261124/optional-media-audit.md). Next experimental discriminator: capture unchanged common/MPM INF staging outcomes separately before the source INF, with signature policy preserved on a disposable runner.

## 2026-11-24 — Server package inventory and detached INF staging control

On disposable Server 20348.5870, PnPUtil /add-driver on a byte-identical detached wdmaudio.inf (zero CatalogFile directives) returned exit 0, published name wdmaudio.inf, already present; no new OEM package. This confirms recognition of a preinstalled package, not first-time import of a donor package. [Native control and inventory](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45486457745). No A2DP/BTAMPm filename matches among 24,246 local component manifests and 3,005 local servicing package MUMs. [First content scan](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45486691734) failed its transport-token control. [Corrected XML scan](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45486918270) parsed all 3,005 MUMs, found Bluetooth package identities in eight and detected two synthetic profile markers. No MUM contained microsoft_bluetooth_a2dp, btha2dp or btampm. The Bluetooth package refers to Microsoft-OneCore-Bluetooth-Deployment. This is a literal search in installed package XML; it neither traverses deployment manifests nor covers optional media. It does not establish absence in all Server packages.

The [DDInstall documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-ddinstall-section) describes Include/Needs providers as system-supplied. CopyINF concerns staging other packages; colocation of an external provider does not make it system-supplied. The Win10 files are already in evidence. No user collection is needed. No donor install, driver load or SFC outcome from these controls. Follow deployment manifests and independently sourced Server optional media before repeating a packaging experiment.

## 2026-11-24 — Native Server preflight completed

Hosted Server 20348.5870 opened KS and WDMAudio provider sections. All three donor profile INF names returned error 2. A detached, unchanged Server wdmaudio.inf verified under its Server catalog; a parseable one-byte comment change failed verification. CI #5 still has zero staged packages. The later physical capture on 20348.5761 shows OPPO 110B in class Bluetooth with CM_PROB_NONE following historical oem75.inf removal; earlier Code 37 is historical. SBC playback remains unverified. [Native INF preflight and signed-catalog evidence](/research/native-inf-preflight-20261124/README.md).

## ACTIVE STATUS — CI #5 reviewed; transitive INF closure confirmed (2026-11-24)

- CI #5 [45393451133](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45393451133) completed, not running. Original CAT and both SYS (/kp) and three INF (/pa) verified; original CAT registration succeeded. PnPUtil staging failed both before and after registration with 0xE000022F (NO_CATALOG_FOR_OEM_INF), zero staged packages. SetupAPI logs independently report unresolved common INF dependency, despite files being colocated in the input folder. This is a package-staging blocker, not a driver load or ABI failure. Runner 20348.5870 had pre-existing Test Signing mode; no security settings were changed. Cleanup used incompatible catdb /r /u flags; do not repeat.
- New independent read-only analysis using the user's physical Server 20348.5761 and Win10 captures: recursively traverse explicit Needs, CopyFiles, AddReg, AddService and AddInterface starting at the three BthA2dpSrc sections. Result: 28 visited sections, zero unresolved references in a combined source+target static model. All 12 reached Server inbox ks.inf/wdmaudio.inf sections match the Win10 bodies after stripping comments and outer whitespace. All four referenced Server inbox copy payloads (drmk.sys, portcls.sys, SysFxUI.dll, WMALFXGFXDSP.dll) are present in the captured Server DriverStore inventory. The two required source payloads are BthA2dp.sys and BtaMPM.sys. This does not demonstrate native SetupAPI Include resolution.
- Important correction to the older SignatureAttributes note: the actual captured common A2DP INF declares DRMLevel=1300 in SignatureAttributes.DRM, not an empty section. A successful general kernel signature verification does not alone establish DRM attribute satisfaction in a newly signed package. See https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-signatureattributes-section. The INF also contains inbox-specific MSEP/MSFX endpoint/effect properties; a third-party package design must respect Microsoft guidance (https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects).
- Reproducible audit script: Library /LDAC Project/Artifacts/audit_a2dp_inf_closure.py, libfile_e75504a3818c8191bce4a3a4d98ff6c4, SHA256 1ca7488a5e272d49af5357956fe60fd5f16e2454b955a412d7695a38bf3dcb19. JSON result: /LDAC Project/Artifacts/A2DP-INF-closure-20261124.json, libfile_f372ab3311ec8191aac60bbab2d74b88, SHA256 e54ab9762fd2e303db5f11b30d0914a7542ca6b849f98099a49dde337c79398c. Four checks passed locally: real archive closure, removed Needs section, removed payload inventory row, and transitive missing AddReg section. The parser is deliberately scoped to explicit sections in captured INFs, not a general Windows INF parser.
- Next: investigate a supported signed package/servicing route which resolves both package catalog and Include/Needs dependencies. Prefer native read-only SetupAPI preflight and isolated Windows tests; do not repeat unchanged CAT registration or force third-party staging. Preserve original Microsoft signatures and do not import unrelated whole client CBS package. Do not change physical host or security settings. ACX remains parked per project priority. No new hardware/runtime evidence or CI experiment in this static audit.

## Active status — 2026-11-24 (CI #4 reviewed; CI #5 running)

- Stage-smoke CI #4 [45381650079](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45381650079) ran on disposable Windows Server 2022 Datacenter **20348.5870** (not target UBR 5761). Win10 19045.5917 extraction and PE reports completed, but the stage path stopped before SignTool/PnPUtil because it required the historical CAT filename `Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.5917.cat` and did not find that exact name in the mounted image's catalog roots. This is a catalog-discovery/harness failure, **not** a Server trust rejection and not a driver-compatibility result.
- CI #4 artifact 14918010587: 154,452 bytes, SHA-256 `b3f8f459cf468a44a7191554a95a0b43cec72c7c0c2650a687f1c4fab7dcf274`; saved to Library `/LDAC Project/Incoming/CI-4-stage-smoke-failure.zip` (Library ID `libfile_f37d34e806088191b2e1d8d2a04bc8e3`).
- Corrective experiment commit [de392442](https://github.com/as-0101/ldac-a2dp-windows/commit/de3924424779a44b7d0d66ce2065c7f8dbae6655) on `experiment/win10-a2dp-stage-smoke-20261124`: catalog discovery now includes Hidden/System CAT files, prefers the previously observed exact CAT then CBS owner-package catalogs then a full fallback scan, verifies that one common catalog covers all five pinned package files, records per-root inventory, and skips staging with an explicit blocked report if no common catalog is found. The old CAT name/hash is now a historical reference, not a hard-coded prerequisite.
- CI #5 [45393451133](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45393451133) is running the corrected script. No result yet. It remains limited to original package signature verification and DriverStore staging without `/install`; it cannot prove PnP enumeration, service start, driver load, endpoint, SBC negotiation or audio.
- Primary path remains the unmodified Windows 10 A2DP Source/common + BtaMPM package on disposable Server 2022, first SBC stereo with OPPO Enco Buds2. Existing AOSP LDAC encoder/AVDTP work remains deferred until SBC; OPPO ETE41 is SBC/AAC only.
- Physical Server 2022 is untouched; `server-2022-oppo` remains frozen; ACX bind-probe remains parked.

## ACTIVE REVIEW — stage-smoke #3 tooling failure; #4 diagnostic rerun

- CI #3 [45371687882](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882), job 138367259323, completed with `failure`. Runner: Windows Server 2022 Datacenter build 20348, **UBR 5870**; preflight steps 1–6 passed.
- Win10 19045.5917 mounted read-only; offline image identity verified; exact BtaMPM companion found. The script then failed during offline audit with `The property 'Name' cannot be found on this object.`
- Failure occurred before `Invoke-StagePackageSmokeTest`. The offline catalog-membership subroutine may have begun, but no complete membership report was saved; its result is **UNKNOWN**, not pass or no-match. The explicit stage-smoke SignTool gate, `pnputil /add-driver`, `catdb` operation and DriverStore staging were not reached. No `manifest.json` or `stage-test.json` was generated.
- Cleanup succeeded. Artifact [14910689667](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882/artifacts/14910689667) is 152,010 bytes, SHA-256 `431f94d613a177c2d78735fad72844aab1b9fd04782641e5e39532525ee65c08`; it contains 23 PE JSON reports only. Preserved in Library: `/LDAC Project/Incoming/CI-3-stage-smoke-failure.zip`, ID `libfile_87489e2386f48191a54635114c06391a`.
- The outer catch's direct `$_.InvocationInfo.MyCommand.Name` access could mask the originating error when invocation metadata is incomplete. This is a diagnostic-risk hypothesis, not a proven root cause. Commit [4d5734fb](https://github.com/as-0101/ldac-a2dp-windows/commit/4d5734fb19929dc332dfb572e9824151c470b62b) now captures optional error fields safely and logs each offline audit subroutine.
- CI #4 [45381650079](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45381650079), head `4d5734fb19929dc332dfb572e9824151c470b62b`, is in progress; steps 1–6 passed, step 7 active at last check, no artifact yet.
- UBR 5870 is not target UBR 5761. Even a successful hosted result must be labelled with its exact runner UBR.
- No package staging, device enumeration, service start, driver load, A2DP endpoint, SBC negotiation or audio is proven. Physical Server 2022 untouched; `server-2022-oppo` unchanged; ACX parked.

## ACTIVE NEXT ACTIONS — stage-smoke diagnostic recovery

1. Inspect CI #4 after step 7 completes. Use the new `[AUDIT]` markers and captured error position/stack trace to identify the exact failing subroutine.
2. If offline audit completes, inspect original CAT verification and then the unmodified source INF DriverStore staging result. Use `pnputil /add-driver` without `/install`; any temporary CAT database registration remains disposable-only and must be removed.
3. Record actual runner build/UBR. A 20348.5870 result is not exact 20348.5761 proof.
4. If staging succeeds, next gates remain PnP match/ranking → BthA2dp service start → driver load → KS render endpoint. Real SBC negotiation/audio requires a Bluetooth radio/USB passthrough.
5. Keep the minimal Win10 A2DP Source/common + BtaMPM package; reuse Server KS/WDMAUDIO. Do not replace BthPort/BthEnum/BTHUSB, Server audio core or Server bth.inf.
6. Do not modify `server-2022-oppo`, touch the physical host, or resume ACX bind-probe. CI #248/#255 remain closed.

## ACTIVE OVERRIDE — 2026-11-24 12:10 Europe/Kyiv

**Primary route remains the existing Windows 10 A2DP Source package. Do not return to ACX/WDK bind-probe work.** CI #12 has now completed the cross-SKU catalog check. The next gate is original-CAT verification and DriverStore-only staging on a disposable Windows Server 2022 runner.

- CI #12 [45354874225](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45354874225), commit 08663c4ca7d1536b96c554fd5e484382262b1250, completed successfully. It extracted Win10 19045.5917 and Server 20348.5761 offline images.
- All five exact Win10 A2DP package files verify against the same Win10 servicing CAT: Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.5917.cat, SHA-256 78772FA12959C072D687283F08D08367B8A8EF1A2F07D7B72F20BCAFD12483BF.
- The same five file hashes have **no matching catalog in the Server 20348.5761 offline image**, after scanning all 8,325 catalog files. This is a validated no-membership result, not proof that the CAT itself is untrusted or cannot be registered.
- Server positive controls passed 4/4: BthPort.sys, BthEnum.sys, BTHUSB.sys and bth.inf all verify against Microsoft-OneCore-Bluetooth-Package~...~10.0.20348.5756.cat, SHA-256 B0A59B9C3B6E528487BB273332015C8CC3A65A5E60F33BF8AA263E41F6D59AA6.
- The CI #12 artifact is preserved in Library at /LDAC Project/Incoming/CI-12-cross-sku-a2dp-audit.zip (Library ID libfile_08ac72cb1a688191b6940ec4cb82716e) with a readable summary beside it (Library ID libfile_9d20fd91acdc8191bf556453ba6d746c).
- CAT signer subject/thumbprint was **not** retained in CI #12 metadata (catalogSignature serialized as null). Do not claim a recorded signer identity. File membership and signature-policy verification succeeded on the Win10 source image; verbose target-side SignTool evidence is the next test.
- The dedicated stage-smoke branch is experiment/win10-a2dp-stage-smoke-20261124. It verifies the original CAT on a disposable GitHub-hosted Server 2022 runner, then tries pnputil /add-driver without /install; if needed it registers the CAT with SignTool's system component/driver catalog database and retries. It cleans up the staged package and catalog. It does not bind a device or start a driver.
- Stage-smoke runs #1/#2 failed in the PowerShell parser before UUP extraction due an interpolated $name: string; the parser issue was corrected. Run #3 [45371687882](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45371687882) is the current attempt. These harness failures are not Windows compatibility results.
- No A2DP endpoint, PnP device match, service start, driver load, SBC negotiation or audio stream has been proven. Physical Server 2022 remains untouched; server-2022-oppo is unchanged; ACX bind-probe remains parked.


> **System-supplied A2DP package catalog correction — 2026-11-24**
>
> The Win10 A2DP source/common and BtaMPM INFs have no `CatalogFile` directive. This is expected for system-supplied INFs: Microsoft documents that Windows validates them against all system-supplied catalog files. Do **not** classify these INFs as unsigned and do not add a `CatalogFile` line; verify exact INF/SYS membership against offline OS catalogs. See [INF Version section](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-version-section) and [Catalog files and digital signatures](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/catalog-files).
>
> The common A2DP INF also maps `BthA2dp.sys` to `SignatureAttributes.DRM`, but the captured `[SignatureAttributes.DRM]` section is empty. Microsoft documents DRMLevel values 1200/1300 and says additional signatures depend on HCK package features/tests. Do not infer that a DRM signature was actually applied; record the exact INF text and catalog evidence separately. See [INF SignatureAttributes section](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-signatureattributes-section).
>
> **UUP audit recovery — 2026-11-24**
>
> UUP audit #7 [45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564) failed in the audit script, not in Windows compatibility: StrictMode raised because an offline service registry object did not contain optional `ServiceDll`. Its artifact 14896789955 is partial (20 Server PE JSON reports only; no catalog/service result), SHA-256 `dca3859cab81728950b037d93b43f170e2fc730412adda369340d67839152380`.
>
> The isolated experiment branch now has a safe optional-property reader, per-image checkpoints/continue-on-error, corrected registry path separators, and hardened SignTool discovery. CI #11 [45347639357](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45347639357) passed its PowerShell parser + x64 SignTool preflight; the offline image audit is still running. Runs #8–#10 are redundant recovery attempts and remain separately recorded. No package staging or driver load has been attempted.
>
> The previously verified PE result remains static-only: exact Win10 DriverStore `BthA2dp.sys` 10.0.19041.4355 (SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`) has 149/149 imports resolved against Server 20348.5761 plus exact Win10 BtaMPM; `BtaMPM.sys` 10.0.19041.5848 has 42/42 imports resolved. This is not ABI/runtime/load proof.
>
> Physical Server 2022 was not accessed. `server-2022-oppo` remains unchanged; ACX bind-probe remains parked.
>
> **LDAC encoder provenance — 2026-11-24**
>
> The existing project already contains the AOSP Sony LDAC encoder from upstream commit eeee1a3f (imported in repository commit 95bb92866b0d77de20ee94694eb4be2979635947). CMake builds ldacBT_enc and ldacBT_abr as STATIC libraries; service/encoder.cpp calls ldacBT_get_handle, ldacBT_init_handle_encode, ldacBT_encode and ldac_ABR_Proc, then frames output with the project's AVDTP code. There is no prebuilt Windows LDAC DLL in this repository. The vendored METADATA does not declare a semantic version, so do not label it 2.0.2 without separate provenance.
>
> The external libldacdec commit c90094b is fetched by tools/ldacverify only to decode/verify test output; it is not part of the product. Historical hardware proof exists on a separate Windows 11 25H2 VM with Realtek USB Bluetooth 5.4 passthrough and JBL Live 780NC: LDAC 96 kHz / MTU 679 / 150 ms was negotiated, audio was heard, and the recorded run delivered 2,972 packets with zero drops (2026-10-22). This proves the existing codec/custom AVDTP path on that test stand, **not** on Server 2022. Keep the immediate Server milestone on the Microsoft Win10 A2DP SBC package path.
>
> **INF comparison correction — 2026-11-24 08:50 Europe/Kyiv**
>
> The generic BthGenericService mapping for A2DP UUID 0x110B exists in both Win10 and Server bth.inf. It is not the OS delta. Win10 bth.inf 10.0.19041.5848 (SHA-256 8635AE12E1C0AF71E95AD0DA65FA6CEEAB2AA0866D213620F49AA0A634CE976D) and Server bth.inf 10.0.20348.5756 (SHA-256 38302B73607B829CBD94D60D25320924B8727BF55CAD940052444FC22D475459) both map UUID 0x110B to BthGenericService with the _GENERIC suffix and null associated-service install.
>
> The actual Win10 addition is the separate microsoft_bluetooth_a2dp_src.inf (base UUID 0x110B) plus common A2DP INF and BtaMPM dependency. Those dedicated A2DP INF files are absent from the Server image. The minimal experiment must add/test that package only; do not replace or patch bth.inf. Source INF has PreConfigureDriver=*; its SetupAPI selection/rank effect must be checked in the disposable VM.
>
> **ACTIVE OVERRIDE — 2026-11-24 08:39 Europe/Kyiv**
>
> UUP audit #6 completed successfully: [run 45332165839](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45332165839), artifact ID 14895876155, SHA-256 c1792bd8e5bcdf2a583c3738eeb22bdf27a64ba6ad2701ad70aa8f879d045209.
> - Exact Win10 19045.5917 x64 image reproduced the archived DriverStore BthA2dp.sys hash: version 10.0.19041.4355, 282,624 bytes, SHA-256 5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3. AMD64/PE32+, WDM driver, 149 imports in 8 descriptors, no delay/API-set imports or exports. All 149 imported names/ordinals are present in the exact Server 20348.5761 export-reference set plus exact Win10 BtaMPM.
> - Exact BtaMPM.sys 10.0.19041.5848, 43,008 bytes, SHA-256 DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD: AMD64, 42 imports, 14 exports, no delay/API-set imports. All 42 imports resolve against Server exports; BthA2dp consumes 10 of its exports.
> - Separate 279,040-byte System32 BthA2dp.sys is version 10.0.19041.1, SHA-256 0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737, with 144 imports. Do not confuse it with the DriverStore package binary.
> - Correction: earlier E-119 wording that exact DriverStore BthA2dp imports only ntoskrnl.exe is superseded by E-169. Full UUP PE audit shows eight import descriptors and 149 imports.
> - BtaMpm.inf uses BtaMPM.CopyFilesOnly; it does not install a separate BtaMPM service. BtaMPM.sys is a copied companion module imported by BthA2dp.sys. Common A2DP INF installs demand-start BthA2dp.
> - Static import closure is a strong compatibility result, not runtime proof. Catalog membership, INF applicability/staging, service start, PnP enumeration, driver load, endpoint, SBC negotiation and audio remain unverified.
> - UUP audit #7 / [run 45342686564](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45342686564) checks offline catalog membership and SYSTEM-hive service registrations. No package install or driver load.
> - Keep exact Win10 A2DP source/common package over Server Bluetooth core. No new Bluetooth/ACX driver; CI #248/#255 remain closed. server-2022-oppo unchanged. Physical Server 2022 not accessed or modified.
>
> **ACTIVE PROJECT OVERRIDE — 2026-11-24 07:22 Europe/Kyiv**
>
> Primary target remains the Microsoft Win10 A2DP source/common package for SBC stereo on Server 2022. No new Bluetooth/ACX driver; CI #248/#255 remain closed.
> - CI #463 confirms the A2DP source/common/sink and BtaMPM packages are `dualModeDriver` entries owned by `Microsoft-Windows-Client-Desktop-Required-Package`; Server KB5126655 has no corresponding package references. Do not inject the whole client CBS package.
> - For PC → OPPO playback, only `microsoft_bluetooth_a2dp_src.inf` + common INF + BtaMPM/KS/WDMAUDIO/MSSysFx dependencies are in scope. Exclude the reverse-direction sink INF and HFP.
> - UUP audit #4/#5 failed on the parser's `hint=None` edge case; isolated experiment commit [6778022](https://github.com/as-0101/ldac-a2dp-windows/commit/6778022b4453857e53acf8a18afe54bb7e46f5f5) fixed it. CI #6 passed regression tests; full image audit is still in progress.
> - Existing LDAC-capable alternatives were checked from official/public docs: Alternative A2DP Driver 1.8.3 supports Windows 10 22H2 / Windows 11 21H2–25H2, uses the inbox Bluetooth stack and replaces the per-device A2DP driver; Server 2022 is not listed. It supports LDAC/SBC and ABR but is proprietary, hardware-bound licensed, requires admin for driver selection, and its EULA prohibits reverse engineering/disassembly and redistribution. Treat as a black-box later-stage candidate only; no installer/binary was downloaded or installed. BlueCaster is a user-mode BTstack + WinUSB option for Windows 10 22H2/11, requires a dedicated USB adapter (Windows loses that adapter while active), and bundled BTstack is personal/non-commercial unless separately licensed.
> - The fork already statically links AOSP libldac 2.0.2; this is encoder code, not a Microsoft A2DP plug-in. OPPO Enco Buds2 supports SBC/AAC, not LDAC.
> - `server-2022-oppo` remains unchanged; physical Server 2022 was not queried or modified.
>
# LDAC A2DP — project entry

## Current priority — 2026-11-24

The active path is exact Windows 10 / Server 2022 component extraction and static compatibility analysis. Do not return to ACX/WDK bind-probe work.

- CI #463 completed package discovery: Windows 10 A2DP SYS entries in cumulative-update CABs are PSF forward-delta payloads, not full PE files.
- The Server 2022 KB5126655 package contains Bluetooth core packages but no A2DP INF/SYS or BtaMPM references.
- Winbindex symbol-server retrieval is not exact for the captured files: same timestamp/size collisions returned different file versions and SHA-256 values.
- UUP audit #3 failed before image mount because the DISM object lacked a `Version` property. This was a harness failure, not a binary or OS failure. Corrected offline-hive verification is under test in runs #4/#5 (`45325486392`, `45325586394`).
- The key INF delta is now explicit: keep Server BthPort/BthEnum/radio core; evaluate only the existing Win10 A2DP source/common INF + BthA2dp package after exact PE/CAT checks. No INF has been staged or installed.
- No SBC negotiation, A2DP endpoint, or actual audio success is claimed yet. No physical server actions have been taken.

See WIN10_UUP_IMAGE_AUDIT.md for evidence, run IDs, hashes, and acceptance criteria.


## Current priority — 2026-11-24

The active path is exact Windows 10 / Server 2022 component extraction and static compatibility analysis. Do not return to ACX/WDK bind-probe work.

- CI #463 completed package discovery: Windows 10 A2DP SYS entries in cumulative-update CABs are PSF forward-delta payloads, not full PE files.
- The Server 2022 KB5126655 package contains Bluetooth core packages but no A2DP INF/SYS or BtaMPM references.
- Winbindex symbol-server retrieval is not exact for the captured files: same timestamp/size collisions returned different file versions and SHA-256 values.
- UUP audit #3 failed before image mount because the DISM object lacked a `Version` property. This was a harness failure, not a binary or OS failure. Corrected offline-hive verification is under test in runs #4/#5 (`45325486392`, `45325586394`).
- The key INF delta is now explicit: keep Server BthPort/BthEnum/radio core; evaluate only the existing Win10 A2DP source/common INF + BthA2dp package after exact PE/CAT checks. No INF has been staged or installed.
- No SBC negotiation, A2DP endpoint, or actual audio success is claimed yet. No physical server actions have been taken.

See WIN10_UUP_IMAGE_AUDIT.md for evidence, run IDs, hashes, and acceptance criteria.


**Code branch:** [server-2022-oppo](https://github.com/as-0101/ldac-a2dp-windows/tree/server-2022-oppo)  
**Documentation branch:** [docs/project-source-reorg](https://github.com/as-0101/ldac-a2dp-windows/tree/docs/project-source-reorg)  
**Current direction:** 2026-11-24 02:19 Europe/Kyiv

The next engineering milestone is **SBC stereo on Windows Server 2022**, using the existing Windows 10 inbox A2DP package if its component ownership and kernel dependencies prove compatible. The ACX/WDK bind-probe path is parked.

Important codec boundary:
- Windows 10 inbox A2DP documents SBC and aptX Classic, not LDAC.
- OPPO Enco Buds2 ETE41 documents AAC/SBC only. SBC is the only common codec; these earbuds cannot be the LDAC test sink.
- Alternative A2DP Driver advertises LDAC but is proprietary, hardware-licensed, and not published as Server 2022-supported. Do not transplant or reverse-engineer its binaries.

The 2026-11-23 23:49 Win10 package archive already exists and includes the common/source/sink A2DP INFs, btampm.inf, BthA2dp.sys and BtaMPM.sys. Do not rerun the exporter or ask for the same archive. The latest recorded OPPO A2DP node was enumerated on the local Intel radio (LOCALMFG&0002) but bound to the project's custom oem75.inf / LdacA2dp driver, which failed to start with Code 37; that does not test the Microsoft Win10 package. The remaining package-ownership blocker is the original Windows 10/Server 2022 WIM component metadata.
## Critical component boundary — 2026-11-24 02:19

- Windows 10 inbox A2DP provides SBC and aptX Classic, not LDAC. There is no Microsoft inbox LDAC DLL to transplant.
- `BthA2dp.sys` is the kernel A2DP/AVDTP profile driver; `BtaMPM.sys` is profile management. MSSysFx/APO DLLs are effects, not LDAC codecs.
- The repo already contains AOSP `libldac` at `eeee1a3f`, compiled as static libraries into the custom service; it is not a Windows 10 codec DLL.
- OPPO ETE41 is AAC/SBC only; SBC is the common milestone codec. LDAC requires another sink.
- The legacy PE import report is invalid because its parser never advances to the next 20-byte import descriptor. See E-139.
- Winbindex's x64 hash-only index now confirms the exact SHA-256 values for the 282,624-byte DriverStore BthA2dp.sys, the separate 279,040-byte System32 copy, and BtaMPM.sys. This confirms hash presence in the Microsoft public-symbol index, but does not supply PE timestamp/virtual size, OS/update mapping or catalog membership; see E-143–E-145.
- BlueCaster v3.0.4 is a possible separate user-mode LDAC transport, but it requires WinUSB on a USB adapter, does not list Server 2022 support, and carries BTstack's personal/non-commercial license. It is not a drop-in codec DLL.


## Read in this order

1. [LDAC_Project_Source_START_HERE.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/LDAC_Project_Source_START_HERE.md)
2. [WIN10_COMPONENT_AUDIT.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_COMPONENT_AUDIT.md)
3. [WIN10_A2DP_PIPELINE.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_A2DP_PIPELINE.md)
4. [WIN10_UUP_IMAGE_AUDIT.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/WIN10_UUP_IMAGE_AUDIT.md)
5. [NEXT_ACTIONS.md](https://github.com/as-0101/ldac-a2dp-windows/blob/docs/project-source-reorg/docs/agent/NEXT_ACTIONS.md)
6. PROJECT_STATE.md, EVIDENCE.md, DECISIONS_AND_EXPERIMENTS.md, BUILD_REGISTRY.md, TEST_MATRIX.md and ARTIFACT_INDEX.md.

## Safety

Physical Server 2022 is read-only during this investigation. No driver install, device restart, BCD/security/test-signing or certificate changes, OS update/rollback, or execution of prepare/upgrade/install/rollback scripts is authorized. HFP/microphone remains out of scope. Notion journal remains append-only.
