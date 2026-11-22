# UBR 5870 runtime snapshot and ACX 1.0 hosted-load preflight

**Date:** 2026-11-22 21:02 Kyiv

## Hosted Server 2022 runtime snapshot

[LiveKD metadata run #12](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45057605446), commit b8256dd009bc8b289e17f64abd4300686380ae50, completed successfully.

- OS: Windows Server 2022 Datacenter, version 10.0.20348, UBR 5870.
- Latest listed hotfix: KB5070761, installed 2026-11-19.
- Acx01000.sys: 10.0.20348.5866, 675840 bytes, SHA-256 D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0.
- Wdf01000.sys: 1.33.20348.1, 910856 bytes, SHA-256 32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B.
- BCD testsigning: Yes.
- [LiveKD run #10](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45057090987) measured ACX CLASS_MODULE v1.0 / WDF 1.31 / Wdf01000 runtime 1.33 on this same hosted image.

The physical host is Server 2022 build 20348 / UBR 5761 with Acx01000.sys 10.0.20348.3451 and CLASS_MODULE v1.0 / WDF 1.31 / runtime 1.33. The hosted image is more recently serviced and has a newer ACX binary file version, but its class version is still 1.0. This strongly weakens the idea that the physical host simply needs a cumulative update to obtain ACX 1.1. Do not recommend OS update as the fix on current evidence.

Run #12 artifact 14768231770, SHA-256 d6de1cc8be0ad9e981c843c9e239095f6c918e5e7bdd8350b8b89db3c1133117, Files Library ID libfile_4897fef219b48191a9372a287b40ae44.

## CI #133 package preflight

A separate branch [experiment/acx10-hosted-load](https://github.com/as-0101/ldac-a2dp-windows/tree/experiment/acx10-hosted-load) was created from the ACX 1.0 candidate commit. Preflight [run #1 / 45058127024](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45058127024) completed successfully.

- Downloaded CI #133 artifact 14763242251; archive SHA-256 f3414c19042e51488c9a5a9b00e133eb5a1af26b16ed75b3b1bb96fb34ade1ad.
- Package files verified: LdacA2dp.inf, LdacA2dp.sys, LdacA2dp.cat, ldac-a2dp-test.cer, and the diagnostic scripts/tool.
- DriverVer: 0.2.326.1634.
- INF SHA-256: 5FE047FF4AB7A157B01043F6C4DE2BA9C805042C9EE678447404F69DA7BBDD19.
- SYS SHA-256: 435905E1553CB06D089F1477D1CFF57C15BBEB84EF3141CA1B3B500A73898F3E.
- CAT SHA-256: F0202A0EEF8F5ADD021CA01E0D34851EF00DEF1E2BE8AA8EA7C32B3A158EE738.
- Test certificate thumbprint: 4A4E17BFC74DBE7220CA0606763FB81BA85A947B.
- Hosted runner BCD testsigning: Yes.
- DevGen available: C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devgen.exe.

Preflight artifact 14768550673, SHA-256 a72ae4ea11530e3f4d96f34265c07158cd90d2ccf7ab51fa4984261a2d83abcd, Files Library ID libfile_8111dbd5c2208191b128accd907c5cfc.

## Hosted ACX 1.0 driver-load experiment

Build workflow run #230 / ID 45058265287 on commit 86a1d46aa7c4bc3561e96ded77442b03b34789f0 adds a test job that:
1. Imports the test certificate on the disposable hosted runner only.
2. Creates a temporary SWD software device with the physical BTHENUM A2DP hardware/compatible IDs using DevGen.
3. Installs the ACX 1.0 INF with pnputil.
4. Captures PnP state and Kernel-PnP events.
5. Captures a LiveKD dump and queries !wdfldr acx01000 to see whether LdacA2dp binds as an ACX client.

The job does not run prepare-oppo-host.cmd, does not change BCD, and does not touch the physical server. Run #230 was in progress when this report was written; no load-test result is claimed yet.
