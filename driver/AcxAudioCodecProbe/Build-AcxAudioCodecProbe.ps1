$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runRoot = Join-Path $env:RUNNER_TEMP 'acx10-sample-bind-probe'
$buildRoot = Join-Path $runRoot 'build'
$packageRoot = Join-Path $runRoot 'package'
$reportRoot = Join-Path $runRoot 'report'
New-Item -ItemType Directory -Path $buildRoot,$packageRoot,$reportRoot -Force | Out-Null

$wdkPackage = Join-Path $repoRoot 'driver\packages\Microsoft.Windows.WDK.x64.10.0.26100.6584'
if (-not (Test-Path -LiteralPath $wdkPackage)) {
    throw "Pinned WDK NuGet package missing: $wdkPackage"
}

$wdkBinRoot = Join-Path $wdkPackage 'c\bin\10.0.26100.0'
$wdkBinX64 = Join-Path $wdkBinRoot 'x64'
$wdkBinX86 = Join-Path $wdkBinRoot 'x86'
$stampInf = Join-Path $wdkBinX64 'stampinf.exe'
if (-not (Test-Path -LiteralPath $stampInf)) {
    throw "Pinned StampInf.exe missing from WDK NuGet package: $stampInf"
}
# WDK targets invoke StampInf by name. Make the exact NuGet tools discoverable.
$env:Path = "$wdkBinX64;$wdkBinX86;$env:Path"

$vswhere = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) { throw 'vswhere.exe not found.' }
$vsPath = & $vswhere -latest -products '*' -requires Microsoft.Component.MSBuild -property installationPath
if (-not $vsPath) { throw 'Visual Studio MSBuild installation not found.' }
$msbuild = Join-Path $vsPath 'MSBuild\Current\Bin\amd64\MSBuild.exe'
if (-not (Test-Path -LiteralPath $msbuild)) { throw "64-bit MSBuild.exe is required for WDK tool discovery; missing: $msbuild" }
$msbuildVersion = (Get-Item -LiteralPath $msbuild).VersionInfo.FileVersion
if ($msbuildVersion -notmatch '^17\.') { throw "WDK 10.0.26100.6584 requires VS2022/MSBuild 17.x; found $msbuildVersion" }
$stampInfVersion = (Get-Item -LiteralPath $stampInf).VersionInfo.FileVersion
$stampInfHash = (Get-FileHash -LiteralPath $stampInf -Algorithm SHA256).Hash
$preflight = [ordered]@{
    MSBuildPath = $msbuild
    MSBuildVersion = $msbuildVersion
    StampInfPath = $stampInf
    StampInfVersion = $stampInfVersion
    StampInfSHA256 = $stampInfHash
    WdkNuGetPackage = $wdkPackage
    WdkNuGetVersion = '10.0.26100.6584'
    WdkBuildVersion = '10.0.26100.0'
    SDKVersion = '10.0.26100.0'
    AcxVersion = '1.0'
    KmdfVersion = '1.31'
    BuildOS = [Environment]::OSVersion.VersionString
    RunnerName = $env:RUNNER_NAME
}
$preflightPath = Join-Path $reportRoot 'build-preflight.json'
$preflight | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $preflightPath -Encoding utf8
Write-Host "PROBE_BUILD_PREFLIGHT=$preflightPath"

$project = Join-Path $PSScriptRoot 'AcxAudioCodecProbe.vcxproj'
$consoleLog = Join-Path $buildRoot 'msbuild-console.log'
$msbuildOutput = & $msbuild $project '/t:Rebuild' '/m' '/nr:false' '/p:Configuration=Release' '/p:Platform=x64' '/v:normal' 2>&1
$msbuildExit = $LASTEXITCODE
$msbuildOutput | Out-File -LiteralPath $consoleLog -Encoding utf8
if ($msbuildExit -ne 0) {
    Get-Content -LiteralPath $consoleLog -Tail 240 | Write-Host
    throw "MSBuild failed with exit code $msbuildExit. See $consoleLog"
}

$buildText = Get-Content -LiteralPath $consoleLog -Raw
if ($buildText -notmatch '(?i)stampinf\.exe') { throw 'WDK build log did not record the StampInf tool invocation.' }
if ($buildText -notmatch '(?im)^\s*WdkVersion:\s*10\.0\.26100\.0\s*$' -or
    $buildText -notmatch '(?im)^\s*WdkAssemblyVersion:\s*10\.0\.26100\.6584\s*$') {
    Get-Content -LiteralPath $consoleLog -Tail 240 | Write-Host
    throw 'WDK build targets did not report exact WDK 10.0.26100.6584 assembly and 10.0.26100.0 build version.'
}
$toolchainMatch = [regex]::Match(
    $buildText,
    '(?m)PROBE_TOOLCHAIN\|WDK_NUGET_DIR=(?<nuget>[^|]+)\|DDK_INC_PATH=(?<inc>[^|]+)\|DDK_LIB_PATH=(?<lib>[^|]+)\|SDK=(?<sdk>[^|]+)\|ACX=(?<acx>[^|]+)\|KMDF=(?<kmdf>[^|]+)\|TARGET=(?<target>[^|]+)\|PLATFORM=(?<platform>[^\r\n]+)')
if (-not $toolchainMatch.Success) { throw 'Build log did not contain the evaluated PROBE_TOOLCHAIN provenance marker.' }

$toolchain = [pscustomobject]@{
    WdkNuGetDir = $toolchainMatch.Groups['nuget'].Value.Trim()
    DdkIncludePath = $toolchainMatch.Groups['inc'].Value.Trim()
    DdkLibraryPath = $toolchainMatch.Groups['lib'].Value.Trim()
    WindowsTargetPlatformVersion = $toolchainMatch.Groups['sdk'].Value.Trim()
    AcxVersion = $toolchainMatch.Groups['acx'].Value.Trim()
    KmdfVersion = $toolchainMatch.Groups['kmdf'].Value.Trim()
    DriverTargetPlatform = $toolchainMatch.Groups['target'].Value.Trim()
    Platform = $toolchainMatch.Groups['platform'].Value.Trim()
}
if ($toolchain.WdkNuGetDir -notmatch 'driver\\packages' -or
    [string]::IsNullOrWhiteSpace($toolchain.DdkIncludePath) -or
    [string]::IsNullOrWhiteSpace($toolchain.DdkLibraryPath) -or
    $toolchain.DdkIncludePath -notmatch '10\.0\.26100\.0' -or
    $toolchain.DdkLibraryPath -notmatch '10\.0\.26100\.0' -or
    $toolchain.WindowsTargetPlatformVersion -ne '10.0.26100.0' -or
    $toolchain.AcxVersion -ne '1.0' -or
    $toolchain.KmdfVersion -ne '1.31' -or
    $toolchain.DriverTargetPlatform -ne 'Windows Driver' -or
    $toolchain.Platform -ne 'x64') {
    throw "Evaluated WDK/SDK/ACX/KMDF properties do not match the experiment contract: $($toolchain | ConvertTo-Json -Compress)"
}

$repoBuildRoot = Join-Path $repoRoot 'build\AcxAudioCodecProbe'
if (-not (Test-Path -LiteralPath $repoBuildRoot)) { throw "Build output directory missing: $repoBuildRoot" }

$sys = Get-ChildItem -LiteralPath $repoBuildRoot -Filter 'AcxAudioCodecProbe.sys' -File -Recurse |
    Where-Object { $_.FullName -notmatch '\\obj\\' } | Select-Object -First 1
$infCandidates = Get-ChildItem -LiteralPath $repoBuildRoot -Filter 'AcxAudioCodecProbe.inf' -File -Recurse
$infFile = $infCandidates | Where-Object { $_.FullName -notmatch '\\obj\\' } | Select-Object -First 1
if (-not $infFile) { $infFile = $infCandidates | Select-Object -First 1 }
$pdbFile = Get-ChildItem -LiteralPath $repoBuildRoot -Filter 'AcxAudioCodecProbe.pdb' -File -Recurse |
    Select-Object -First 1
if (-not $sys -or -not $infFile -or -not $pdbFile) {
    throw "Expected SYS, INF and PDB outputs. SYS=$([bool]$sys), INF=$([bool]$infFile), PDB=$([bool]$pdbFile)"
}

$catFile = Get-ChildItem -LiteralPath $repoBuildRoot -Filter 'AcxAudioCodecProbe.cat' -File -Recurse |
    Where-Object { $_.FullName -notmatch '\\obj\\' } | Select-Object -First 1

$packageFiles = @(
    @{ Source = $sys.FullName; Name = 'AcxAudioCodecProbe.sys' },
    @{ Source = $infFile.FullName; Name = 'AcxAudioCodecProbe.inf' },
    @{ Source = $pdbFile.FullName; Name = 'AcxAudioCodecProbe.pdb' }
)
foreach ($file in $packageFiles) {
    Copy-Item -LiteralPath $file.Source -Destination (Join-Path $packageRoot $file.Name) -Force
}

$catPath = Join-Path $packageRoot 'AcxAudioCodecProbe.cat'
$inf2catPath = 'WDK build output catalog'
$inf2catVersion = $null
$inf2catExit = 0
if ($catFile) {
    Copy-Item -LiteralPath $catFile.FullName -Destination $catPath -Force
} else {
    $inf2catPathCandidate = Join-Path $wdkBinX86 'Inf2Cat.exe'
    if (-not (Test-Path -LiteralPath $inf2catPathCandidate)) {
        throw "Pinned Inf2Cat.exe missing from WDK NuGet package: $inf2catPathCandidate"
    }
    $inf2cat = Get-Item -LiteralPath $inf2catPathCandidate
    $inf2catPath = $inf2cat.FullName
    $inf2catVersion = $inf2cat.VersionInfo.FileVersion
    $inf2catLog = Join-Path $buildRoot 'inf2cat-server2022.log'
    $inf2catOutput = & $inf2cat.FullName "/driver:$packageRoot" /os:Server2022_X64 2>&1
    $inf2catExit = $LASTEXITCODE
    $inf2catOutput | Out-File -LiteralPath $inf2catLog -Encoding utf8
    if ($inf2catExit -ne 0) { throw "Inf2Cat Server2022_X64 failed with exit code $inf2catExit." }
}
if (-not (Test-Path -LiteralPath $catPath)) { throw 'No catalog was produced by the WDK build or Inf2Cat fallback.' }

$packageInf = Join-Path $packageRoot 'AcxAudioCodecProbe.inf'
$infText = Get-Content -LiteralPath $packageInf -Raw
foreach ($required in @(
    '(?im)^Class\s*=\s*MEDIA\s*$',
    '(?i)ROOT\\AudioCodec',
    '(?im)^KmdfLibraryVersion\s*=\s*1\.31\s*$'
)) {
    if ($infText -notmatch $required) { throw "Built INF failed sample-topology preflight: $required" }
}

$toolRoots = @(
    $wdkPackage,
    (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Windows Kits\10')
) | Where-Object { Test-Path -LiteralPath $_ }
$infVerifCandidates = foreach ($root in $toolRoots) {
    Get-ChildItem -LiteralPath $root -Filter 'InfVerif.exe' -File -Recurse -ErrorAction SilentlyContinue
}
$infVerif = $infVerifCandidates | Where-Object { $_.FullName -like '*\10.0.26100.0\x86\InfVerif.exe' } | Select-Object -First 1
if (-not $infVerif) { $infVerif = $infVerifCandidates | Where-Object { $_.FullName -like '*\x86\InfVerif.exe' } | Select-Object -First 1 }
if (-not $infVerif) { $infVerif = $infVerifCandidates | Select-Object -First 1 }
if (-not $infVerif) { throw 'InfVerif.exe not found in pinned WDK package or installed Windows Kits.' }

$infVerifLog = Join-Path $buildRoot 'infverif-windows-driver.log'
$infVerifOutput = & $infVerif.FullName /w $packageInf 2>&1
$infVerifExit = $LASTEXITCODE
$infVerifOutput | Out-File -LiteralPath $infVerifLog -Encoding utf8
if ($infVerifExit -ne 0) { throw "InfVerif /w failed with exit code $infVerifExit. See $infVerifLog" }

$hashes = [ordered]@{}
foreach ($name in @('AcxAudioCodecProbe.sys','AcxAudioCodecProbe.inf','AcxAudioCodecProbe.cat','AcxAudioCodecProbe.pdb')) {
    $path = Join-Path $packageRoot $name
    $hashes[$name] = [pscustomobject]@{
        Length = (Get-Item -LiteralPath $path).Length
        SHA256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
}

$acxStubPath = Join-Path $toolchain.DdkLibraryPath 'acx\km\1.0\acxstub.lib'
$acxHeaderPath = Join-Path $toolchain.DdkIncludePath 'acx\km\1.0\acx.h'
$wdfLibRoot = Join-Path $wdkPackage 'c\lib\wdf\kmdf\x64\1.31'
$wdfDriverEntryLibPath = Join-Path $wdfLibRoot 'WdfDriverEntry.lib'
$wdfLdrLibPath = Join-Path $wdfLibRoot 'WdfLdr.lib'
foreach ($requiredPath in @($acxStubPath,$acxHeaderPath,$wdfDriverEntryLibPath,$wdfLdrLibPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) { throw "Required ACX/WDF build input missing: $requiredPath" }
}
$acxStubItem = Get-Item -LiteralPath $acxStubPath
$acxStubHash = (Get-FileHash -LiteralPath $acxStubPath -Algorithm SHA256).Hash
if ($acxStubItem.Length -ne 1362352 -or $acxStubHash -ne '9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74') {
    throw "ACX 1.0 stub differs from CI #255 WDK 10.0.26100.6584 baseline: length=$($acxStubItem.Length), SHA256=$acxStubHash"
}
$acxHeaderHash = (Get-FileHash -LiteralPath $acxHeaderPath -Algorithm SHA256).Hash
$wdfDriverEntryHash = (Get-FileHash -LiteralPath $wdfDriverEntryLibPath -Algorithm SHA256).Hash
$wdfLdrHash = (Get-FileHash -LiteralPath $wdfLdrLibPath -Algorithm SHA256).Hash

$wdfHeaderScanPath = Join-Path $reportRoot 'wdf-class-bind-header-scan.txt'
$headerRoots = @(
    (Join-Path $toolchain.DdkIncludePath 'wdf'),
    (Join-Path $toolchain.DdkIncludePath 'acx')
) | Where-Object { Test-Path -LiteralPath $_ }
$headerFiles = foreach ($root in $headerRoots) {
    Get-ChildItem -LiteralPath $root -Filter '*.h' -File -Recurse -ErrorAction SilentlyContinue
}
$headerMatches = @($headerFiles | Select-String -Pattern 'WDF_CLASS_BIND_INFO2?|WDF_CLASS_EXTENSION_DESCRIPTOR|WDF_CLASS_LIBRARY_INFO|WDF_CLASS_VERSION' -Context 2,8 -ErrorAction SilentlyContinue)
if ($headerMatches.Count -gt 0) {
    $headerReport = foreach ($match in $headerMatches) {
        @(
            "FILE=$($match.Path)"
            "LINE=$($match.LineNumber)"
            $match.Context.PreContext
            $match.Line
            $match.Context.PostContext
            ''
        )
    }
    $headerReport | Set-Content -LiteralPath $wdfHeaderScanPath -Encoding utf8
} else {
    'NO_PUBLIC_WDK_HEADER_MATCH_FOR_WDF_CLASS_BIND_TYPES' | Set-Content -LiteralPath $wdfHeaderScanPath -Encoding utf8
}
$wdfHeaderScan = [ordered]@{
    SearchRoots = @($headerRoots)
    HeaderFileCount = @($headerFiles).Count
    MatchCount = $headerMatches.Count
    Report = 'wdf-class-bind-header-scan.txt'
}
$driverVer = [regex]::Match($infText, '(?im)^\s*DriverVer\s*=\s*(.+)$').Groups[1].Value.Trim()
$manifest = [ordered]@{
    Experiment = 'ACX 1.0 Microsoft AudioCodec sample-derived bind probe'
    SourceSampleCommit = 'd49bb7d72f3651952b2b6e4ad28d14fe2247eb69'
    SourceSampleDriverCppBlob = '452b0d99eaf24451d965bd1b0f3ef140417e6d98'
    SourceSampleProjectBlob = '0cdc9e6154c6340d384c8b07550d6ecf11a2e6d3'
    SourceSampleInfBlob = '0bc5fe2314b32e30e13827e3d421911048d8f579'
    RepositoryCommit = $env:GITHUB_SHA
    RepositoryRef = $env:GITHUB_REF_NAME
    WorkflowRunId = $env:GITHUB_RUN_ID
    WorkflowRunNumber = $env:GITHUB_RUN_NUMBER
    Toolchain = $toolchain
    WdkVersionFromBuildLog = '10.0.26100.0'
    WdkAssemblyVersionFromBuildLog = '10.0.26100.6584'
    DriverVer = $driverVer
    MSBuildPath = $msbuild
    MSBuildVersion = $msbuildVersion
    StampInfPath = $stampInf
    StampInfVersion = $stampInfVersion
    StampInfSHA256 = $stampInfHash
    Inf2CatPath = $inf2catPath
    Inf2CatVersion = $inf2catVersion
    Inf2CatServer2022ExitCode = $inf2catExit
    InfVerifPath = $infVerif.FullName
    InfVerifVersion = $infVerif.VersionInfo.FileVersion
    InfVerifWindowsDriverExitCode = $infVerifExit
    SourceSamplePublicHeaderBlob = 'f1e9da3bd6101a503f620a31fa3d2ec471009161'
    AcxStubLibrary = [ordered]@{
        Path = $acxStubPath
        Length = $acxStubItem.Length
        SHA256 = $acxStubHash
    }
    AcxStubDescriptor = [ordered]@{
        MajorVersion = 1
        MinorVersion = 0
        FunctionCount = 210
        StructureCount = 62
        DescriptorSizeBytes = 120
        SourceArtifact = 'CI #255 artifact 14769755224; exact stub hash asserted above'
    }
    WdfClassBindHeaderScan = $wdfHeaderScan
    AcxHeader = [ordered]@{
        Path = $acxHeaderPath
        SHA256 = $acxHeaderHash
    }
    WdfLibraries = [ordered]@{
        WdfDriverEntryPath = $wdfDriverEntryLibPath
        WdfDriverEntrySHA256 = $wdfDriverEntryHash
        WdfLdrPath = $wdfLdrLibPath
        WdfLdrSHA256 = $wdfLdrHash
    }
    Files = $hashes
}
$manifestPath = Join-Path $reportRoot 'build-manifest.json'
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Host "PROBE_BUILD_MANIFEST=$manifestPath"
