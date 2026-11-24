# Windows 10 / Server 2022 UUP image audit

Updated: 2026-11-24

## Why this path changed

The first Microsoft Update Catalog pass completed successfully in GitHub Actions CI #463 (run ID 45311922753), but it exposed a payload-format issue: the A2DP-related `.sys` entries extracted from cumulative-update CABs are PSF forward-delta payloads, not complete PE images. They do not begin with the `MZ` signature and cannot be used for PE import/export analysis as-is.

Observed examples:

- Windows 10 KB5036979: `f\\btha2dp.sys`, 11,840 bytes; component/INF version 10.0.19041.4355.
- Windows 10 KB5126657: `f\\btha2dp.sys`, 15,766 bytes; component/INF version 10.0.19041.7802.
- Windows 10 KB5126657: `f\\btampm.sys`, 7,952 bytes; component/INF version 10.0.19041.7725.

The catalog extractor expands MSU/CAB containers but does not reconstruct PSF forward deltas. Therefore its extracted `.sys` payloads are evidence of package membership/version, not usable PE binaries.

## Server package result

The Server 2022 KB5126655 package audit found no A2DP-specific INF/SYS or BtaMPM manifest references. It did find the Server Bluetooth core packages, including:

- `Microsoft-OneCore-Bluetooth-Package`
- `Microsoft-OneCore-Connectivity-Bluetooth-Package`
- Bluetooth WinRT/input/user-experience packages

This is package-level evidence that the Server 2022 cumulative update contains Bluetooth core components but not the Windows client A2DP profile package. It does not prove that no third-party A2DP implementation can run on Server.

Official update references:

- [Windows Server 2022 KB5126655](https://support.microsoft.com/help/5126655) — build 20348.5761, 2026-10-13.
- [Windows 10 KB5058481](https://support.microsoft.com/help/5058481) — build 19045.5917, 2025-05-28.

## Winbindex symbol-server collision

The Winbindex index supplied the expected hashes for the previously captured Windows 10 files, but the public symbol-server download did not reproduce those hashes. The returned files shared PE timestamp and size with the indexed target but had different version resources:

| Target identity from captured archive | Symbol-server result | Result |
|---|---|---|
| BthA2dp.sys 10.0.19041.4355, 282,624 bytes | 10.0.19041.6392, 282,624 bytes; timestamp 0xC4B85628 | SHA mismatch |
| BthA2dp.sys 10.0.19041.1, 279,040 bytes | 10.0.19041.1030, 279,040 bytes; timestamp 0xC4B85628 | SHA mismatch |
| BtaMPM.sys 10.0.19041.5848, 43,008 bytes | 10.0.19041.7660, 43,008 bytes; timestamp 0x5A670CFE | SHA mismatch |

Conclusion: timestamp + SizeOfImage is not a unique identity for these files. Do not use those downloaded files as the exact 4355/5848 binaries. Their PE reports are not accepted as evidence for the captured target versions.

## Preferred exact-image source

Use full UUP images rather than implementing a new PSF decoder at this stage:

- Windows 10 22H2 build 19045.5917 x64, UUP ID `598d27dc-ad81-41aa-8c83-42b88e60c823`, edition Professional.
- Windows Server 2022 build 20348.5761 x64, UUP ID `008aacce-b0b7-4aeb-a3b2-43286434832c`, edition ServerDatacenter.

The UUP dump service is independent of Microsoft; its download package obtains the payloads from Microsoft's update infrastructure. The build numbers are cross-checked against the Microsoft KB pages above. The image audit must still verify the mounted image version and the exact file hashes before any binary is accepted.

Existing PSF tooling was compared before writing a custom extractor:

- PSFExtractor v3.07 is MIT-licensed and can extract PSF content, but its inspected PA30 path calls ApplyDeltaB with a null source; it does not reconstruct the forward-delta entries needed here.
- 0xZ0F/Windows-Patch-Diff-Helpers handles forward deltas through msdelta.dll and RTM base files, but the repository has no declared license. It is not being vendored.
- Full UUP images avoid both the base-file reconstruction dependency and copying code with unclear licensing.

## Experimental implementation

Isolated branch: `experiment/win10-a2dp-uup-image-audit-20261124`

- `tools/research/extract_uup_image_a2dp.ps1`
- `.github/workflows/uup-image-audit.yml`

The workflow downloads the two exact UUP images on a disposable GitHub-hosted Windows Server 2022 runner, mounts the images read-only, extracts only metadata for relevant driver/audio files, captures INF/CBS/WinSxS references, and compares Windows 10 PE imports against Server 2022 exports. It uploads JSON/text metadata only; no ISO or Microsoft binary payload is retained.

GitHub Actions run 45317582562 (workflow run number 3) is in progress. Runs 45317386782 and 45317399103 stopped during UUP bootstrap because the packaged `get_aria2.ps1` child shell did not expose `Get-FileHash`. Commit `e9900fc894772997526995feeaecfff4a9ec5ff0` adds a narrow SHA-256 fallback to that helper and prioritizes Windows PowerShell 5.1; run 45317582562 is the verification attempt.

## Acceptance criteria

1. Win10 image version is exactly 19045.5917; Server image version is exactly 20348.5761.
2. BthA2dp DriverStore copy matches captured SHA-256 `5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3`.
3. BthA2dp System32 copy matches captured SHA-256 `0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737`.
4. BtaMPM copy matches captured SHA-256 `DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD`.
5. PE imports, delay imports, exports, API-set references, file versions, and Server export resolution are recorded for the exact matching files.
6. INF, CBS/WinSxS ownership, service/registry registrations, and catalog membership are recorded separately; absence of a package-local CAT is not treated as proof of unsigned status.
7. Static compatibility is not treated as proof of driver load or audio. Runtime sequence remains service start → device enumeration → driver load → A2DP endpoint → SBC negotiation → actual stereo audio.

No ACX bind-probe is authorized by this result. No physical host action is authorized.
