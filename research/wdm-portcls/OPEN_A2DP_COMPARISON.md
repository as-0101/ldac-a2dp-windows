# WDM / A2DP source comparison — verified 2026-11-25

## Microsoft reference
Pinned Windows-driver-samples SHA d49bb7d72f3651952b2b6e4ad28d14fe2247eb69, license MS-PL. SysVAD INF Include=ks.inf,wdmaudio.inf and Needs=KS.Registration,WDMAUDIO.Registration; HFP render and HFP capture KS interfaces separately enumerated. However, SysVAD BthhfpDevice calls IOCTL_BTHHFP_* through bthhfpddi.h and needs an existing Bluetooth HFP sideband provider; it does NOT supply a complete HFP Audio Gateway. A2dpHpDevice uses A2DP sideband, not standalone AVDTP Source.

Our source scan: CI 45653348638: 6/6 Python regression tests and 9/9 original-source controls passed on Windows 2022 hosted runner, WDK 26100 NuGet restored, native build stopped TRK0005 missing stampinf.exe. New tool-path probe CI 45653894037, commit 75cf4ea15367e165b291164fec169002e4011326; investigate outcome before claiming build. No endpoint installed.

## Existing open-source implementation: RafiMota/open-a2dp
Public https://github.com/RafiMota/open-a2dp pinned commit 167ebc0e2c89fec570eec535fefdade72bd9e416 (2026-10-14); own source MIT, SysVAD derivatives MS-PL, aptX encoder GPL caveat. This is a distinct, more advanced implementation of Windows Classic A2DP Source: driver/oa2dp/l2cap.c uses IOCTL_INTERNAL_BTH_SUBMIT_BRB and KMDF BthPort profile; INF matches headset A2DP Sink 0x110B; driver/oa2dpaudio uses a real PortCls WaveRT stereo render miniport and KS Include/Needs; service includes SBC codec.

Independent GitHub CI https://github.com/RafiMota/open-a2dp/actions/runs/38632901913 job 116088730438: on Windows-2022 hosted runner both oa2dp.sys and oa2dpaudio.sys compiled successfully and Inf2Cat generated both unsigned catalogs. README old claim that drivers have never been built is stale relative to CI log and BUILDING.md. No signed installation, headset stream or audio endpoint test confirmed. Upstream itself admits 340ms stale ring possible latency, no jack detection, and untested friendly-name handling. Upstream explicitly relies on Windows native HFP for mic, which fails our Server goal because HFP provider missing. Do NOT run its test installation on physical Server: it requires disabling Secure Boot / enabling testsigning.

Next discriminators: static PE import/provider closure against saved Server 20348.5870, compare signed INF applicability, adapt SBC-only path under proper license, independently design RFCOMM HFP AG + SCO and capture WaveRT endpoint. No assumption that A2DP build proves headset playback or mic duplex.

## HFP donor
CI https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45612001590 failed due PowerShell path-string integer indexing. Source fix commit a3e0551deae076f0c8b60a6ed39e4f9f17ccb32c. Run 45652810986 attempt 1 and 2 both fail upstream UUP HTTP 504 at extract_uup_image_a2dp.ps1:88 BEFORE mounted donor/HFP positive control. This is an external acquisition failure, NOT a driver fail. Avoid unchanged acquisition retry until source or cache changes. Acceptance UNTESTED.

## Source evidence
https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45653348638
https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45653894037
https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45652810986
https://github.com/RafiMota/open-a2dp/actions/runs/38632901913
