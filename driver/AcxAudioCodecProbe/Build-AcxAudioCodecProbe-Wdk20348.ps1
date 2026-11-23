param()
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$runRoot = Join-Path $env:RUNNER_TEMP 'acx10-sample-bind-probe'
$reportRoot = Join-Path $runRoot 'report'
$buildRoot = Join-Path $runRoot 'build'
$packageRoot = Join-Path $runRoot 'package'
$inputRoot = Join-Path $runRoot 'inputs'
New-Item -ItemType Directory -Path $reportRoot,$buildRoot,$packageRoot,$inputRoot -Force | Out-Null

$isoUrl = 'https://software-download.microsoft.com/download/sg/EWDK_fe_release_20348_210507-1500.iso'
$isoPath = Join-Path $env:RUNNER_TEMP 'EWDK_fe_release_20348_210507-1500.iso'
$diskImage = $null

function Write-Json([string]$Path,[object]$Value) {
    $Value | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $Path -Encoding utf8
}
function Get-HashInfo([string]$Path) {
    $item = Get-Item -LiteralPath $Path
    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256
    return [ordered]@{ Path = $item.FullName; Length = [long]$item.Length; SHA256 = $hash.Hash }
}
function Set-ProbeOutput([bool]$Built) {
    if ($env:GITHUB_OUTPUT) {
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value ("probe_built=" + $Built.ToString().ToLowerInvariant()) -Encoding utf8
    }
}

try {
    Write-Host 'EWDK_20348_DOWNLOAD_BEGIN'
    $headInfo = $null
    try {
        $head = Invoke-WebRequest -Uri $isoUrl -Method Head -MaximumRedirection 10 -TimeoutSec 90
        $headInfo = [ordered]@{
            StatusCode = [int]$head.StatusCode
            ContentLength = [string]$head.Headers['Content-Length']
            ContentType = [string]$head.Headers['Content-Type']
        }
    } catch {
        $headInfo = [ordered]@{ HeadRequestError = $_.Exception.Message }
    }
    Invoke-WebRequest -Uri $isoUrl -OutFile $isoPath -MaximumRedirection 10 -TimeoutSec 3600
    $isoInfo = Get-HashInfo $isoPath
    Write-Host ("EWDK_ISO_SHA256=" + $isoInfo.SHA256)
    Write-Host ("EWDK_ISO_LENGTH=" + $isoInfo.Length)

    $diskImage = Mount-DiskImage -ImagePath $isoPath -PassThru
    $volumes = @($diskImage | Get-Volume -ErrorAction SilentlyContinue)
    if (-not ($volumes | Where-Object DriveLetter)) {
        $volumes = @(Get-DiskImage -ImagePath $isoPath | Get-Disk | Get-Partition | Get-Volume -ErrorAction SilentlyContinue)
    }
    $volume = $volumes | Where-Object DriveLetter | Select-Object -First 1
    if (-not $volume) { throw 'EWDK ISO mounted but no drive-letter volume was discovered.' }
    $ewdkRoot = "$($volume.DriveLetter):\"

    $launchBuildEnv = Join-Path $ewdkRoot 'LaunchBuildEnv.cmd'
    $setupBuildEnv = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'SetupBuildEnv.cmd' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    $setupVSEnv = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'SetupVSEnv.cmd' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (Test-Path -LiteralPath $launchBuildEnv) {
        Get-Content -LiteralPath $launchBuildEnv -Raw | Set-Content -LiteralPath (Join-Path $reportRoot 'ewdk-launch-build-env.txt') -Encoding utf8
    }
    if ($setupBuildEnv) {
        Get-Content -LiteralPath $setupBuildEnv.FullName -Raw | Set-Content -LiteralPath (Join-Path $reportRoot 'ewdk-setup-build-env.txt') -Encoding utf8
    }

    $acxStubCandidates = @(Get-ChildItem -LiteralPath $ewdkRoot -Filter 'acxstub.lib' -File -Recurse -ErrorAction SilentlyContinue)
    $acxHeaderCandidates = @(Get-ChildItem -LiteralPath $ewdkRoot -Filter 'acx.h' -File -Recurse -ErrorAction SilentlyContinue)
    $acx10Stub = $acxStubCandidates | Where-Object { $_.FullName -match '\\acx\\km\\1\.0\\acxstub\.lib$' } | Select-Object -First 1
    $acx10Header = $acxHeaderCandidates | Where-Object { $_.FullName -match '\\acx\\km\\1\.0\\acx\.h$' } | Select-Object -First 1

    $preflight = [ordered]@{
        Experiment = 'ACX 1.0 AudioCodec-derived probe — WDK 20348.1 / VS2019 control'
        EwdkIsoUrl = $isoUrl
        EwdkIsoHead = $headInfo
        EwdkIso = $isoInfo
        EwdkRoot = $ewdkRoot
        LaunchBuildEnv = $launchBuildEnv
        SetupBuildEnv = if ($setupBuildEnv) { $setupBuildEnv.FullName } else { $null }
        SetupVSEnv = if ($setupVSEnv) { $setupVSEnv.FullName } else { $null }
        AcxStubCandidates = @($acxStubCandidates | ForEach-Object { Get-HashInfo $_.FullName })
        AcxHeaderCandidates = @($acxHeaderCandidates | ForEach-Object { $_.FullName })
        Acx10StubFound = [bool]$acx10Stub
        Acx10HeaderFound = [bool]$acx10Header
        SourceSampleCommit = 'd49bb7d72f3651952b2b6e4ad28d14fe2247eb69'
        SourceSampleSolutionVisualStudioVersion = '16.0.31409.214'
        CurrentWdk26100Acx10StubSha256 = '9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74'
    }
    Write-Json (Join-Path $reportRoot 'build-preflight.json') $preflight

    if (-not $acx10Stub -or -not $acx10Header) {
        $preflight.Status = 'BLOCKED_NO_ACX10_STUB_OR_HEADER_IN_EWDK_20348'
        Write-Json (Join-Path $reportRoot 'build-preflight.json') $preflight
        Set-ProbeOutput $false
        Write-Host 'EWDK_ACX10_STUB_FOUND=false; runtime job must remain skipped.'
        exit 0
    }

    $wdkIncPath = $acx10Header.FullName -replace '\\acx\\km\\1\.0\\acx\.h$',''
    $wdkLibPath = $acx10Stub.FullName -replace '\\acx\\km\\1\.0\\acxstub\.lib$',''
    $versionMatch = [regex]::Match($wdkIncPath, '\\Include\\(?<version>10\.0\.\d+\.\d+)\\km$')
    if (-not $versionMatch.Success) { throw "Cannot derive WDK include version from $wdkIncPath" }
    $wdkKitVersion = $versionMatch.Groups['version'].Value
    $includeVersionDir = Split-Path -Parent $wdkIncPath
    $includeRoot = Split-Path -Parent $includeVersionDir
    $kitsRoot = Split-Path -Parent $includeRoot
    $sdkCandidates = @(Get-ChildItem -LiteralPath $includeRoot -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName 'um\Windows.h')) -and (Test-Path (Join-Path $_.FullName 'shared\Windows.h'))
    })
    $sdkMatch = $sdkCandidates | Where-Object { $_.Name -eq $wdkKitVersion } | Select-Object -First 1
    if (-not $sdkMatch) { $sdkMatch = $sdkCandidates | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1 }
    if (-not $sdkMatch) { throw 'No complete Windows SDK include version was found in the EWDK.' }
    $sdkVersion = $sdkMatch.Name

    $wdfDriverEntry = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'WdfDriverEntry.lib' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\1\.31\\WdfDriverEntry\.lib$' } | Select-Object -First 1
    $wdfLdr = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'WdfLdr.lib' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\1\.31\\WdfLdr\.lib$' } | Select-Object -First 1
    if (-not $wdfDriverEntry -or -not $wdfLdr) { throw 'KMDF 1.31 WdfDriverEntry.lib or WdfLdr.lib is missing from EWDK 20348.1.' }

    $msbuild = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'MSBuild.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\MSBuild\\Current\\Bin\\MSBuild\.exe$' } | Select-Object -First 1
    $cppDefaultProps = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'Microsoft.Cpp.Default.props' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\MSBuild\\Microsoft\\VC\\v160\\Microsoft\.Cpp\.Default\.props$' } | Select-Object -First 1
    $cl = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'cl.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\Hostx64\\x64\\cl\.exe$' } | Select-Object -First 1
    $link = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'link.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\Hostx64\\x64\\link\.exe$' } | Select-Object -First 1
    $libTool = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'lib.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\Hostx64\\x64\\lib\.exe$' } | Select-Object -First 1
    $dumpbin = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'dumpbin.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\Hostx64\\x64\\dumpbin\.exe$' } | Select-Object -First 1
    if (-not $msbuild -or -not $cppDefaultProps -or -not $cl -or -not $link) {
        throw 'EWDK 20348.1 VS2019 MSBuild/VC targets/compiler/linker were not all found.'
    }

    $inf2cat = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'Inf2Cat.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x86\\Inf2Cat\.exe$' } | Select-Object -First 1
    $infverif = Get-ChildItem -LiteralPath $ewdkRoot -Filter 'InfVerif.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x64\\InfVerif\.exe$' -or $_.FullName -match '\\x86\\InfVerif\.exe$' } | Select-Object -First 1
    if (-not $inf2cat -or -not $infverif) { throw 'EWDK 20348.1 Inf2Cat or InfVerif is missing.' }

    Copy-Item -LiteralPath $acx10Stub.FullName -Destination (Join-Path $inputRoot 'acxstub-1.0.lib') -Force
    Copy-Item -LiteralPath $acx10Header.FullName -Destination (Join-Path $inputRoot 'acx-1.0.h') -Force
    Copy-Item -LiteralPath $wdfDriverEntry.FullName -Destination (Join-Path $inputRoot 'WdfDriverEntry-1.31.lib') -Force
    Copy-Item -LiteralPath $wdfLdr.FullName -Destination (Join-Path $inputRoot 'WdfLdr-1.31.lib') -Force

    if ($libTool) {
        $libList = & $libTool.FullName /list $acx10Stub.FullName 2>&1
        $libList | Set-Content -LiteralPath (Join-Path $reportRoot 'acxstub-members.txt') -Encoding utf8
    }
    if ($dumpbin) {
        $dumpOutput = & $dumpbin.FullName /all $acx10Stub.FullName 2>&1
        $dumpOutput | Set-Content -LiteralPath (Join-Path $reportRoot 'acxstub-dumpbin-all.txt') -Encoding utf8
    }

    $setupScript = if ($setupBuildEnv) { $setupBuildEnv.FullName } else { $launchBuildEnv }
    if (-not (Test-Path -LiteralPath $setupScript)) { throw 'EWDK build environment entry point is missing.' }
    $setupVsLine = if ($setupVSEnv) { 'call "' + $setupVSEnv.FullName + '"' } else { 'rem SetupVSEnv.cmd not present; SetupBuildEnv environment is used.' }
    $envReport = Join-Path $reportRoot 'ewdk-environment.txt'
    $whereReport = Join-Path $reportRoot 'ewdk-tools-paths.txt'
    $projectPath = Join-Path $PSScriptRoot 'AcxAudioCodecProbe-Wdk20348.vcxproj'
    $msbuildLog = Join-Path $buildRoot 'msbuild-console.log'
    $msbuildError = Join-Path $buildRoot 'msbuild-stderr.log'
    $batchPath = Join-Path $runRoot 'build-wdk20348.cmd'

    $batch = @"
@echo off
call "$setupScript"
if errorlevel 1 exit /b %errorlevel%
$setupVsLine
if errorlevel 1 exit /b %errorlevel%
set WDKContentRoot=$kitsRoot\
set WindowsSdkDir=$kitsRoot\
set WindowsSDKVersion=$sdkVersion\
set WindowsTargetPlatformVersion=$sdkVersion
set LatestTargetPlatformVersion=$sdkVersion
set DDK_INC_PATH=$wdkIncPath
set DDK_LIB_PATH=$wdkLibPath
set VCTargetsPath=$(Split-Path -Parent $cppDefaultProps.FullName)\
set PATH=$(Split-Path -Parent $msbuild.FullName);$(Split-Path -Parent $cl.FullName);$(Split-Path -Parent $link.FullName);%PATH%
set > "$envReport"
where msbuild > "$whereReport" 2>&1
where cl >> "$whereReport" 2>&1
where link >> "$whereReport" 2>&1
"$($msbuild.FullName)" "$projectPath" /t:Rebuild /m /nr:false /p:Configuration=Release /p:Platform=x64 /p:WindowsTargetPlatformVersion=$sdkVersion /p:DDK_INC_PATH="$wdkIncPath" /p:DDK_LIB_PATH="$wdkLibPath" /p:ACX_VERSION_MAJOR=1 /p:ACX_VERSION_MINOR=0 /p:KMDF_VERSION_MAJOR=1 /p:KMDF_VERSION_MINOR=31 /v:normal
exit /b %errorlevel%
"@
    Set-Content -LiteralPath $batchPath -Value $batch -Encoding ascii
    $cmdArgs = '/d /c "' + $batchPath + '"'
    $process = Start-Process -FilePath $env:ComSpec -ArgumentList $cmdArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput $msbuildLog -RedirectStandardError $msbuildError
    if ($process.ExitCode -ne 0) {
        throw "WDK 20348.1 / VS2019 MSBuild failed with exit code $($process.ExitCode)."
    }

    $sys = Get-ChildItem -LiteralPath $buildRoot -Filter 'AcxAudioCodecProbe.sys' -File -Recurse | Select-Object -First 1
    $pdb = Get-ChildItem -LiteralPath $buildRoot -Filter 'AcxAudioCodecProbe.pdb' -File -Recurse | Select-Object -First 1
    if (-not $sys -or -not $pdb) { throw 'Legacy WDK build completed without SYS or PDB output.' }
    $sourceInf = Join-Path $PSScriptRoot 'AcxAudioCodecProbe.inf'
    $builtInf = Get-ChildItem -LiteralPath $buildRoot -Filter 'AcxAudioCodecProbe.inf' -File -Recurse | Select-Object -First 1
    Copy-Item -LiteralPath $sys.FullName -Destination (Join-Path $packageRoot 'AcxAudioCodecProbe.sys') -Force
    Copy-Item -LiteralPath $pdb.FullName -Destination (Join-Path $packageRoot 'AcxAudioCodecProbe.pdb') -Force
    if ($builtInf) { Copy-Item -LiteralPath $builtInf.FullName -Destination (Join-Path $packageRoot 'AcxAudioCodecProbe.inf') -Force }
    else { Copy-Item -LiteralPath $sourceInf -Destination (Join-Path $packageRoot 'AcxAudioCodecProbe.inf') -Force }

    $infVerifLog = Join-Path $buildRoot 'infverif-windows-driver.log'
    $infVerifOutput = & $infverif.FullName /w (Join-Path $packageRoot 'AcxAudioCodecProbe.inf') 2>&1
    $infVerifOutput | Set-Content -LiteralPath $infVerifLog -Encoding utf8
    $infVerifExit = $LASTEXITCODE
    if ($infVerifExit -ne 0) { throw "InfVerif /w failed: $infVerifExit" }

    $inf2CatLog = Join-Path $buildRoot 'inf2cat-server2022.log'
    $inf2CatOutput = & $inf2cat.FullName "/driver:$packageRoot" /os:Server2022_X64 2>&1
    $inf2CatOutput | Set-Content -LiteralPath $inf2CatLog -Encoding utf8
    $inf2CatExit = $LASTEXITCODE
    if ($inf2CatExit -ne 0) { throw "Inf2Cat Server2022_X64 failed: $inf2CatExit" }

    $cat = Join-Path $packageRoot 'AcxAudioCodecProbe.cat'
    if (-not (Test-Path -LiteralPath $cat)) { throw 'Inf2Cat did not create AcxAudioCodecProbe.cat.' }

    $allFiles = [ordered]@{}
    foreach ($name in @('AcxAudioCodecProbe.sys','AcxAudioCodecProbe.inf','AcxAudioCodecProbe.cat','AcxAudioCodecProbe.pdb')) {
        $allFiles[$name] = Get-HashInfo (Join-Path $packageRoot $name)
    }
    $msbuildVersion = & $msbuild.FullName -version -nologo 2>&1 | Out-String
    $manifest = [ordered]@{
        Experiment = 'ACX 1.0 Microsoft AudioCodec sample-derived bind probe — WDK 20348.1 control'
        Repository = 'as-0101/ldac-a2dp-windows'
        RepositoryBranch = $env:GITHUB_REF_NAME
        RepositoryCommit = $env:GITHUB_SHA
        WorkflowRunId = $env:GITHUB_RUN_ID
        WorkflowRunNumber = $env:GITHUB_RUN_NUMBER
        SourceSampleCommit = 'd49bb7d72f3651952b2b6e4ad28d14fe2247eb69'
        SourceSampleDriverCppBlob = '452b0d99eaf24451d965bd1b0f3ef140417e6d98'
        SourceSampleProjectBlob = '0cdc9e6154c6340d384c8b07550d6ecf11a2e6d3'
        SourceSampleInfBlob = '0bc5fe2314b32e30e13827e3d421911048d8f579'
        SourceSampleSolutionVisualStudioVersion = '16.0.31409.214'
        Toolchain = [ordered]@{
            EwdkIso = $isoInfo
            WdkKitVersion = $wdkKitVersion
            WindowsTargetPlatformVersion = $sdkVersion
            DdkIncludePath = $wdkIncPath
            DdkLibraryPath = $wdkLibPath
            AcxVersion = '1.0'
            KmdfVersion = '1.31'
            DriverTargetPlatform = 'Windows Driver'
            Platform = 'x64'
            MsBuildPath = $msbuild.FullName
            MsBuildVersion = $msbuildVersion.Trim()
            ClPath = $cl.FullName
            ClVersion = (Get-Item -LiteralPath $cl.FullName).VersionInfo.FileVersion
            LinkPath = $link.FullName
            LinkVersion = (Get-Item -LiteralPath $link.FullName).VersionInfo.FileVersion
            WdfDriverEntryPath = $wdfDriverEntry.FullName
            WdfDriverEntrySHA256 = (Get-FileHash -LiteralPath $wdfDriverEntry.FullName -Algorithm SHA256).Hash
            WdfLdrPath = $wdfLdr.FullName
            WdfLdrSHA256 = (Get-FileHash -LiteralPath $wdfLdr.FullName -Algorithm SHA256).Hash
            Inf2CatPath = $inf2cat.FullName
            Inf2CatVersion = (Get-Item -LiteralPath $inf2cat.FullName).VersionInfo.FileVersion
            InfVerifPath = $infverif.FullName
            InfVerifVersion = (Get-Item -LiteralPath $infverif.FullName).VersionInfo.FileVersion
        }
        AcxStubLibrary = Get-HashInfo $acx10Stub.FullName
        AcxHeader = Get-HashInfo $acx10Header.FullName
        AcxStubSameAsWdk26100 = ((Get-FileHash -LiteralPath $acx10Stub.FullName -Algorithm SHA256).Hash -eq '9846617F4DFB2B5C60A33FC531D53825562C6C8CE15B04013079CE74E6DFCF74')
        InfVerifExitCode = $infVerifExit
        Inf2CatServer2022ExitCode = $inf2CatExit
        DriverVer = [regex]::Match((Get-Content -LiteralPath (Join-Path $packageRoot 'AcxAudioCodecProbe.inf') -Raw), '(?im)^\s*DriverVer\s*=\s*(?<value>.+)$').Groups['value'].Value.Trim()
        Files = $allFiles
    }
    Write-Json (Join-Path $reportRoot 'build-manifest.json') $manifest
    $preflight.Status = 'BUILT'
    $preflight.WdkKitVersion = $wdkKitVersion
    $preflight.WindowsTargetPlatformVersion = $sdkVersion
    $preflight.AcXStubSha256 = $manifest.AcxStubLibrary.SHA256
    Write-Json (Join-Path $reportRoot 'build-preflight.json') $preflight
    Set-ProbeOutput $true
    Write-Host 'EWDK_20348_ACX10_BUILD_SUCCESS=true'
} catch {
    $errorInfo = [ordered]@{
        Status = 'BUILD_FAILED'
        Error = $_.Exception.Message
        ScriptStackTrace = $_.ScriptStackTrace
        TimestampUtc = [DateTime]::UtcNow.ToString('o')
    }
    Write-Json (Join-Path $reportRoot 'build-error.json') $errorInfo
    Set-ProbeOutput $false
    throw
} finally {
    if ($diskImage) {
        Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $isoPath -Force -ErrorAction SilentlyContinue
}
