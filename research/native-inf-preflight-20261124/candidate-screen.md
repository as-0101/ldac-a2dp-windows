# Profile package screening for Server 20348 amd64

The [native preflight](README.md) records an Intel local manufacturer identifier of 0002 and a remote Audio Sink UUID of 110B. The following checks use published vendor metadata. No installer was run.

| Candidate | Positive match | Reason to exclude from current VM test |
| --- | --- | --- |
| [CSR Bluetooth Stereo Audio 5.0.14.0, Update Catalog ID 8b93bd2b-6b0f-4360-bc53-65fe1cbe8c18](https://www.catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=8b93bd2b-6b0f-4360-bc53-65fe1cbe8c18) | AMD64 and Audio Sink UUID 110B | Listed model restricts the local manufacturer to 000A. Published products are Windows 7, 8 and 8.1. The previous preflight screened a different, x86 CSR entry. |
| [Bluetooth Goodies Alternative A2DP Driver](https://www.bluetoothgoodies.com/a2dp/faq/) | Vendor supplies a replacement A2DP driver for x64 Windows clients | Vendor requires Windows 10/11 inbox Bluetooth stack and an audio device already recognized by the OS as A2DP. Server 2022 support and creation of the missing profile from the captured generic Bluetooth node are unsubstantiated. |

CI [stage-smoke #5, step 7](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45393451133/job/138442895066) already failed during staging. Its recorded failure does not call for an identical rerun. These two additional exclusions do not establish absence of all compatible packages. A remaining independent path is inventorying CBS package identities and parent/applicability metadata across available Server 20348 packages, including optional components, beyond the existing capability display-name query. Preserve the distinction between the Server target build and each source image examined.
