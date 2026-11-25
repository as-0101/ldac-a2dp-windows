# Exact donor INF, staging and kernel import results — 25 November 2026

On disposable Windows Server 2022 Datacenter 20348.5870, all five original Win10 package members passed CI catalog checks. The common INF, MPM INF and source INF each failed independent staging with 0xE000022F and zero new matching packages. The source package could not locate the common INF; the common package could not locate BtaMPM.inf. MPM copied both its INF and SYS to temporary locations and reached the same catalog rejection without a missing Include. Reordering the three unchanged donor packages cannot resolve this leaf failure under the tested conditions. No device install or audio test.

The native explicit-append experiment compared three configurations using the exact donor INF hashes. With only the source open, its section had two lines and the seven dependency sections were absent. After appending both donor INF providers by full path and both Server audio INFs, all eight sections were readable. The source section queued zero copies; common and MPM each queued one in separate disposable queues. None was committed. Explicit parser resolution does not publish a package.

The complete installed CSI scan parsed all 24,246 manifests, including 24,054 decoded DCM manifests, with zero XML errors and zero targeted A2DP/MPM markers in attribute values or text. Positive Bluetooth deployment control matched. Optional-media run 45487714110 stopped on a faulty filename control. The separate [successful optional-media inventory](optional-media-audit.md) covered 33 neutral CABs. Scope excludes other media and vendor packages.

## Direct imports

STATIC_ANALYSIS on hosted 20348.5870. All 42 BtaMPM.sys imports resolved. All 149 BthA2dp.sys imports resolved against the Server export tables plus the ten functions supplied by the donor BtaMPM.sys. No delay imports in the two donor reports. Positive and deliberately absent symbol controls passed. This checks names/ordinals and forwarders, not binary calling contracts, dynamic lookups, binding or playback. Target hardware UBR 5761 remains a different build revision. Original stage report SHA-256 8a6742e5185d28539f9ba281faf0618c3b560534e94cbf3e8c64ec109f66d005 (ZIP artifact 14977359334). The continuing engineering question is how to supply a legitimately signed Server-applicable profile package while retaining the Bluetooth and audio core. No new original-file collection is needed.

- [Exact donor INF tests](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45487324546)
- [Installed CSI inventory](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45487527472)
- [Three independent staging attempts](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45511693396)
- [Import resolution and controls](https://github.com/as-0101/ldac-a2dp-windows/actions/runs/45578765026)
