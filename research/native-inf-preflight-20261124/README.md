# A2DP source on Server 2022 — native preflight, 24 November 2026

**Outcome.** On hosted Server Datacenter 20348.5870, SetupAPI can read the target audio registration sections. System INF lookup returns file-not-found for each of the three Bluetooth profile dependencies. Existing stage-smoke #5 stopped while importing the source INF. The tested route has no successful DriverStore import, profile-driver start, audio endpoint or SBC playback. The physical machine was not contacted.

## VM_TEST — experiments on separate, disposable standard windows-2022 runners

| Run | Commit | Observation |
| --- | --- | --- |
| [1](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45482378430) | 144c783388078bf31c674509de7cf08387f5d5d3 | Positive control ks.inf failed with 0xE0000201. PowerShell passed the optional class through a string parameter. No availability conclusion from this run. |
| [2](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45482659386) | 8e9a35eaca9cfce7cc46d1b4ba3bbff3443585b3 | With IntPtr.Zero, both inbox controls opened. KS.Registration had 1 line, WDMAUDIO.Registration and MSSYSFX.CopyFilesAndRegister had 2 each. A2DP source, common and btampm INF names returned error 2. Of 316 reported capabilities, zero names contained Bluetooth or A2DP. |
| [3](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45482793915) | 6ca2cd69140cce37d6c0b76b14e48d4fc063e789 | SetupVerifyInfFileW returned the same Server catalog for the published wdmaudio.inf and its byte-identical temporary copy. Appending bytes changed the result to 0x57. Missing-file control returned 2. |
| [4](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45482932167) | d8d5d3b6ba0cce2dbd6a17c75b11be5c8e42044a | Repeated with one case change inside a comment, same 26,966-byte length. The changed copy still opened and returned 2 registration lines. Verification failed with 0x57. Both unchanged controls verified under the Server Desktop Shared Drivers Merged Package catalog 20348.5866. |

In runs 2–4 a synthetic primary INF referenced a sibling in the same temporary folder. Simply opening the primary yielded no sibling section. Explicit append by basename failed with error 2 in the runner working directory. Explicit append with the full path succeeded (1 section line). This measures the open/append API; a caller can explicitly resolve a file without publishing a driver package. The earlier real PnPUtil run is the evidence for staging behavior.

## STATIC_ANALYSIS — original captures and signed component ownership

* At capture time on physical Server 20348.5761 the OPPO 110B node under the Intel radio was Bluetooth / CM_PROB_NONE. On Win10 19045.6456 the matching remote identifier was MEDIA / OPPO Enco Buds2 Stereo / CM_PROB_NONE. The Server SetupAPI history records service deletion, oem75.inf unpublication (line 52223), and unregistration (52229) on 23 November. The older Code 37 was a real historical observation. The capture CSV does not report the currently bound INF or MMDevice endpoint state. No inference of current playback.
* Each of the two original CI #5 attempts logged the missing common INF before import validation. Both file queues show only the source INF being copied. The fatal signature result was 0xE000022F. Resolving either condition alone has no demonstrated staging outcome.
* Parsed the CTL member table in the captured .6456 catalog. All 24 Windows lookup rows match its catalog hash and its member keys (12 distinct SHA-1/SHA-256 identifiers, 6 basenames). All four A2DP/MPM INFs and the neutral .6456 MUM match by SHA-256. The MUM names 13 drivers, including the four mapped in results.json. Source and sink have component version .1, common .4355 and MPM .5848. The sink is listed for ownership, outside the source installation closure. SYS membership is cross-checked using the captured Windows catalog hashes, not the flat PE file hashes. Catalogs from .6456 and CI #5 (.5917) have different SHA-256 values.
* Local controls: an extra byte on the source INF changes its digest to a non-member; one flipped bit in the CTL makes OpenSSL signature integrity verification fail. The original passes. The OpenSSL test skips certificate chain policy. The first local parser stopped at the content wrapper, so it returned zero keys. Corrected the traversal and repeated against the complete CTL and captured Windows lookup data. Test outputs are in results.json and native-runs.txt.

## Decision and outstanding evidence

No supported Server 2022 package for the Intel-attached 110B profile was identified. Microsoft's Server support statement allows IHV drivers; Intel's published wireless Bluetooth package lists Windows client operating systems. An Update Catalog entry for the USB radio alone does not identify a MEDIA profile package. A CSR candidate in the catalog specifies x86 and LOCALMFG&000A; the captured radio is USB VID_8087/PID_0032 with LOCALMFG&0002. A capability-name search is narrower than a complete servicing-package inventory.

A candidate that can advance the driver path needs explicit applicability to Server 2022 amd64, an applicable profile model or supported component identity, the corresponding signature, and a way to resolve all referenced profile INFs. Validate any concrete candidate first on a disposable VM. The direct Win10 inbox-PnPUtil experiment remains blocked. Do not repeat catalog registration, import the desktop client MUM, or treat the successful Server control as verification of donor files.

## Reproduction

Run `python3 recheck.py "/path/to/LDAC Project/Incoming"` with Python 3 and OpenSSL. The script reads the four original ZIPs listed with SHA-256 in results.json. The workflow source is available at the [final experiment commit](https://github.com/as-0101/ldac-a2dp-windows/blob/d8d5d3b6ba0cce2dbd6a17c75b11be5c8e42044a/.github/workflows/native-inf-preflight.yml). No hardware identifiers unique to the physical device are reproduced here.

- [Microsoft — Server Bluetooth support](https://learn.microsoft.com/en-us/windows-hardware/drivers/bluetooth/general-bluetooth-support-in-windows)
- [Microsoft — system-supplied catalogs and INF Version](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-version-section)
- [Microsoft — SetupVerifyInfFileW](https://learn.microsoft.com/en-us/windows/win32/api/setupapi/nf-setupapi-setupverifyinffilew)
- [Intel — wireless Bluetooth package](https://www.intel.com/content/www/us/en/download/18649/intel-wireless-bluetooth-for-windows-10-and-windows-11.html)
- [Update Catalog — CSR profile hardware and architecture](https://www.catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=3d9d67bb-62ca-4cb7-bb82-89afc8acba23)
