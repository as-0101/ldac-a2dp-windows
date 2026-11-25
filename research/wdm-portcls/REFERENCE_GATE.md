# SysVAD PortCls WDM control — pinned evidence
Checked 2026-11-25. Reference: Microsoft/Windows-driver-samples commit d49bb7d72f3651952b2b6e4ad28d14fe2247eb69. Source under Microsoft Public License (MS-PL), retain notices.
## Static observations
- TabletAudioSample.vcxproj: WindowsKernelModeDriver10.0, TargetVersion=Windows10, KMDF driver, PortCls/WaveRT audio. Not an installed endpoint on Server.
- ComponentizedAudioSample.inx: Include=ks.inf,wdmaudio.inf; Needs=KS.Registration,WDMAUDIO.Registration; HFP speaker KSCATEGORY_RENDER and HFP microphone KSCATEGORY_CAPTURE. Dedicated miniport pairs in EndpointsCommon/bthhfpminipairs.h.
- BthhfpDevice.cpp includes bthhfpddi.h and IOCTL_BTHHFP_*, guarded SYSVAD_BTH_BYPASS. Existing sideband provider required: NOT a stand-alone HFP AG or Bluetooth SCO transport.
- A2dpHpDevice.cpp guarded SYSVAD_A2DP_SIDEBAND; not a standalone A2DP SBC/AVDTP Source. The shown TabletAudioSample project defines SYSVAD_BTH_BYPASS, not A2DP sideband.
- Sample README discusses test-signing for installation; forbidden for physical Server without separate authorization. No production changes.
## Gates
1. Static pinned-source audit: unit tested locally, four synthetic cases, not a test of actual source until CI reads pinned upstream.
2. Isolated Windows runner x64 build with existing WDK NuGet 26100.6584, capture logs, SHA, INF and source-gate output; do not upload binaries.
3. If build passes, inspect PE imports and Server 20348 provider closure; signing remains a separate gate. No real render/capture or call proof.
4. Independently implement Classic HFP AG and A2DP Source transport; sample sideband depends on provider absent in Server snapshots.
HFP #45612001590 failed at donor PowerShell positive-control probe, not at HFP binary installation. Fixed HFP gate lives separately on experiment/native-donor-inf-20261124.
Acceptance: UNTESTED.
