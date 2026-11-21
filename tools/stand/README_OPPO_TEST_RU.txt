LDAC A2DP — OPPO ENCO BUDS2 — PHYSICAL SERVER TEST PACKAGE
============================================================

TARGET
------
Physical Windows Server 2022 Datacenter, build 20348.
Bluetooth peer: OPPO Enco Buds2, MAC 84:0F:2A:13:E3:E2.
Initial playback target: SBC stereo. Do not enable HFP/microphone during first test.

IMPORTANT
---------
This is an experimental test-signed kernel driver, not a Microsoft production-signed driver.
It has not yet been proven stable on this physical hardware. A kernel-driver fault can cause
a system crash. Keep rollback-oppo.cmd and this package available locally before proceeding.

SAFETY GATES
------------
- Windows Server 2022 build 20348 only.
- Exact OPPO A2DP devnode MAC 84:0F:2A:13:E3:E2 only.
- Installer refuses if more than one present A2DP devnode is found.
- Installer requires the current driver to be inbox bth.inf.
- Installer compares the test driver rank against inbox bth.inf and refuses if the generic
  match could outrank inbox and affect other headsets.
- Driver runtime checks the target Bluetooth instance/MAC.
- Installation uses DiInstallDevice for the selected devnode, not a blanket PnP update.
- Rollback selects inbox bth.inf / Audio Sink Service for the OPPO A2DP devnode.

PREPARATION
-----------
1. Extract the complete ZIP to a local folder.
2. Run prepare-oppo-host.cmd as Administrator.
3. The script imports ldac-a2dp-test.cer into LocalMachine Root and TrustedPublisher,
   then enables test signing with BCD.
4. Restart the physical server.

DIAGNOSTIC UPGRADE OF AN ALREADY INSTALLED LDAC DRIVER
------------------------------------------------------
If this device already uses an LDAC A2DP Project package (for example oem73.inf),
do NOT run install-oppo.cmd: that command intentionally accepts only the inbox bth.inf.
Use upgrade-oppo.cmd instead. It verifies the exact OPPO MAC, current service and
manufacturer, single-A2DP-device condition, that the candidate is newer than the
installed driver, and that its rank remains below inbox bth.inf. If any check fails,
the upgrade is refused. Import this package's test certificate and ensure test signing
is enabled before proceeding; restart after preparation. After the upgrade, restart
again and capture DbgPrintEx with DebugView (Capture Kernel) or WinDbg.

DIAGNOSTIC UPGRADE OF AN ALREADY INSTALLED LDAC DRIVER
------------------------------------------------------
If this device already uses an LDAC A2DP Project package (for example oem73.inf),
do NOT run install-oppo.cmd: that command intentionally accepts only the inbox bth.inf.
Use upgrade-oppo.cmd instead. It verifies the exact OPPO MAC, current service and
manufacturer, single-A2DP-device condition, that the candidate is newer than the
installed driver, and that its rank remains below inbox bth.inf. If any check fails,
the upgrade is refused. Import this package's test certificate and ensure test signing
is enabled before proceeding; restart after preparation. After the upgrade, restart
again and capture DbgPrintEx with DebugView (Capture Kernel) or WinDbg.

INSTALLATION
------------
1. Confirm OPPO Enco Buds2 is paired and connected.
2. Run status-oppo.cmd first; confirm the exact MAC and current INF bth.inf.
3. Run install-oppo.cmd as Administrator.
4. At the confirmation prompt type exactly: I_ACCEPT_LIVE_DRIVER_TEST
5. If the installer refuses because multiple A2DP devnodes exist, STOP. Do not bypass
   the single-device gate; identify the extra A2DP devnode first.
6. Restart if requested. Check Device Manager and Sound > Playback devices.
7. Begin with SBC playback only. Test low volume first.

ROLLBACK
--------
Run rollback-oppo.cmd as Administrator. It selects the inbox bth.inf driver for the same
OPPO A2DP devnode. Restart the server.
After confirming rollback, disable test signing:
    bcdedit /set testsigning off
Restart again. Remove the test certificate from LocalMachine Root and TrustedPublisher
only after the test driver has been rolled back.

LIMITATIONS
-----------
A successful build and successful driver installation do not guarantee ACX/BT runtime
compatibility on Server 2022. Verify endpoint creation, playback, disconnect/reconnect,
and system stability before considering the driver usable.
