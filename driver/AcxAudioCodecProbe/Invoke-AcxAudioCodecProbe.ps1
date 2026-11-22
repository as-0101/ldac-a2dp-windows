param([switch]$CleanupOnly,[switch]$StrictCleanup)
$ErrorActionPreference = 'Stop'

$runRoot = Join-Path $env:RUNNER_TEMP 'acx10-sample-bind-probe'
$packageRoot = Join-Path $runRoot 'package'
$reportRoot = Join-Path $runRoot 'report'
$privateRoot = Join-Path $env:RUNNER_TEMP 'acx10-sample-bind-probe-private'
$statePath = Join-Path $reportRoot 'cleanup-state.json'
New-Item -ItemType Directory -Path $packageRoot,$reportRoot,$privateRoot -Force | Out-Null

function Save-State([object]$Value) {
    $Value | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $statePath -Encoding utf8
}

function Get-PnpValue([string]$InstanceId,[string]$KeyName) {
    $property = Get-PnpDeviceProperty -InstanceId $InstanceId -KeyName $KeyName -ErrorAction SilentlyContinue
    if ($null -ne $property) { return $property.Data }
    return $null
}

function Invoke-LiveKdDump([string]$Phase,[string[]]$Commands) {
    $kdPath = $env:KD_PATH
    $liveKdPath = $env:LIVEKD_PATH
    if (-not $kdPath -or -not (Test-Path -LiteralPath $kdPath)) { throw 'KD_PATH missing or kd.exe absent.' }
    if (-not $liveKdPath -or -not (Test-Path -LiteralPath $liveKdPath)) { throw 'LIVEKD_PATH missing or livekd.exe absent.' }
    if (-not $env:_NT_SYMBOL_PATH) { throw '_NT_SYMBOL_PATH is not set.' }

    $dump = Join-Path $privateRoot "$Phase-mirror.dmp"
    $captureLog = Join-Path $reportRoot "$Phase-livekd-capture.txt"
    $commandFile = Join-Path $privateRoot "$Phase-kd-commands.txt"
    $kdLog = Join-Path $reportRoot "$Phase-kd-output.txt"
    $Commands | Set-Content -LiteralPath $commandFile -Encoding ascii

    $liveOutput = & $liveKdPath -o $dump -m -b 2>&1
    $liveExit = $LASTEXITCODE
    $liveOutput | Out-File -LiteralPath $captureLog -Encoding utf8
    if ($liveExit -ne 0 -or -not (Test-Path -LiteralPath $dump)) { throw "LiveKD $Phase capture failed: $liveExit" }

    $kdOutput = & $kdPath -z $dump -y $env:_NT_SYMBOL_PATH -logo $kdLog -cf $commandFile 2>&1
    $kdExit = $LASTEXITCODE
    if ($kdOutput) { $kdOutput | Out-File -LiteralPath $kdLog -Append -Encoding utf8 }
    if (-not (Test-Path -LiteralPath $kdLog)) {
        Remove-Item -LiteralPath $dump -Force -ErrorAction SilentlyContinue
        throw "KD $Phase did not produce an inspection log (exit $kdExit)."
    }
    if ($kdExit -ne 0) {
        "KD_EXIT_CODE=$kdExit" | Set-Content -LiteralPath (Join-Path $reportRoot "$Phase-kd-exit.txt") -Encoding utf8
    }
    $content = Get-Content -LiteralPath $kdLog -Raw
    Remove-Item -LiteralPath $dump -Force -ErrorAction SilentlyContinue
    return $content
}

function Invoke-Cleanup([switch]$Strict) {
    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $cleanup = [ordered]@{ TimestampUtc = [DateTime]::UtcNow.ToString('o') }
    $state = $null
    if (Test-Path -LiteralPath $statePath) {
        try { $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json }
        catch { $errors.Add("Cleanup state parse failed: $($_.Exception.Message)") }
    }
    if ($state) {
        if (-not ($state.PSObject.Properties.Name -contains 'CleanupComplete')) {
            $state | Add-Member -NotePropertyName CleanupComplete -NotePropertyValue $false
        }
        if (-not ($state.PSObject.Properties.Name -contains 'CleanupResult')) {
            $state | Add-Member -NotePropertyName CleanupResult -NotePropertyValue $null
        }
    }

    if ($state) {
        $deviceId = [string]$state.DeviceInstanceId
        if (-not $deviceId -and $state.InstanceToken) {
            $found = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
                Where-Object { $_.InstanceId -like "*$($state.InstanceToken)*" } | Select-Object -First 1
            if ($found) { $deviceId = $found.InstanceId }
        }
        if ($deviceId) {
            $existing = Get-PnpDevice -PresentOnly -InstanceId $deviceId -ErrorAction SilentlyContinue
            if ($existing) {
                $devgenPath = [string]$state.DevGenPath
                if ($devgenPath -and (Test-Path -LiteralPath $devgenPath)) {
                    & $devgenPath /remove $deviceId /subtree 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-devgen.txt') -Encoding utf8
                    $cleanup.DevGenExitCode = $LASTEXITCODE
                }
                Start-Sleep -Seconds 1
                if (Get-PnpDevice -PresentOnly -InstanceId $deviceId -ErrorAction SilentlyContinue) {
                    & pnputil.exe /remove-device $deviceId /subtree 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-pnputil-fallback.txt') -Encoding utf8
                    $cleanup.PnPUtilRemoveExitCode = $LASTEXITCODE
                    Start-Sleep -Seconds 2
                }
            }
            if (Get-PnpDevice -PresentOnly -InstanceId $deviceId -ErrorAction SilentlyContinue) { $errors.Add("ROOT test device remains: $deviceId") }
            else { $cleanup.DeviceRemoved = $true }
        } else { $cleanup.DeviceRemoved = $true }

        if ($state.CandidateSelected -and $state.CandidateInfPath -match '^oem\d+\.inf$') {
            & pnputil.exe /delete-driver $state.CandidateInfPath /uninstall /force 2>&1 |
                Out-File (Join-Path $reportRoot 'cleanup-driverstore.txt') -Encoding utf8
            $cleanup.DriverStoreDeleteExitCode = $LASTEXITCODE
        }

        $thumb = [string]$state.CertThumbprint
        $subject = [string]$state.CertSubject
        foreach ($store in @('Cert:\LocalMachine\My','Cert:\LocalMachine\Root','Cert:\LocalMachine\TrustedPublisher')) {
            $certs = Get-ChildItem -LiteralPath $store -ErrorAction SilentlyContinue |
                Where-Object { ($thumb -and $_.Thumbprint -eq $thumb) -or ($subject -and $_.Subject -eq $subject) }
            foreach ($cert in $certs) {
                if ($store -eq 'Cert:\LocalMachine\My') {
                    try { Remove-Item -LiteralPath $cert.PSPath -DeleteKey -Force -ErrorAction Stop }
                    catch { Remove-Item -LiteralPath $cert.PSPath -Force -ErrorAction SilentlyContinue }
                } else {
                    Remove-Item -LiteralPath $cert.PSPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
        $remainingCerts = foreach ($store in @('Cert:\LocalMachine\My','Cert:\LocalMachine\Root','Cert:\LocalMachine\TrustedPublisher')) {
            Get-ChildItem -LiteralPath $store -ErrorAction SilentlyContinue |
                Where-Object { ($thumb -and $_.Thumbprint -eq $thumb) -or ($subject -and $_.Subject -eq $subject) }
        }
        if ($remainingCerts) { $errors.Add('Ephemeral certificate remains in a LocalMachine store.') }
        else { $cleanup.CertificateRemovedFromAllStores = $true }

        if ($state.AcxStartedByProbe) {
            $svc = Get-CimInstance Win32_SystemDriver -Filter "Name='Acx01000'" -ErrorAction SilentlyContinue
            $previousStopRejected = ($state.CleanupResult -and [int]$state.CleanupResult.AcxStopExitCode -eq 1061)
            if ($svc -and $svc.Started -and -not $previousStopRejected) {
                & sc.exe stop Acx01000 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-acx-service.txt') -Encoding utf8
                $cleanup.AcxStopExitCode = $LASTEXITCODE
                Start-Sleep -Seconds 3
            } elseif ($previousStopRejected) {
                $cleanup.AcxStopExitCode = 1061
                $cleanup.AcxStopRetrySkipped = $true
            }
            $svc = Get-CimInstance Win32_SystemDriver -Filter "Name='Acx01000'" -ErrorAction SilentlyContinue
            if ($svc -and $svc.Started) {
                if ([int]$cleanup.AcxStopExitCode -eq 1061) {
                    $cleanup.AcxServiceRestored = $false
                    $warnings.Add('Acx01000 remained RUNNING because SCM rejected STOP with 1061; this is a disposable hosted runner and it is destroyed after the job.')
                } else {
                    $errors.Add('Acx01000 remains running after a non-1061 stop result.')
                }
            } else { $cleanup.AcxServiceRestored = $true }
        } else { $cleanup.AcxServiceWasNotStartedByProbe = $true }

    }

    $badExt = @('.pfx','.p12','.pvk','.key')
    $scanRoots = @($runRoot,$privateRoot) | Where-Object { Test-Path -LiteralPath $_ }
    $badFiles = foreach ($scanRoot in $scanRoots) {
        Get-ChildItem -LiteralPath $scanRoot -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension.ToLowerInvariant() -in $badExt }
    }
    foreach ($file in $badFiles) { Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue }
    if ($badFiles) { $errors.Add("Private-key files found and deleted: $($badFiles.Name -join ', ')") }

    $textFiles = foreach ($scanRoot in $scanRoots) {
        Get-ChildItem -LiteralPath $scanRoot -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension.ToLowerInvariant() -in @('.txt','.log','.json','.pem') }
    }
    $keyMarkers = foreach ($file in $textFiles) {
        if (Select-String -LiteralPath $file.FullName -Pattern 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|PRIVATE KEY-----' -Quiet -ErrorAction SilentlyContinue) {
            $file.FullName
        }
    }
    if ($keyMarkers) {
        foreach ($file in ($keyMarkers | Select-Object -Unique)) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue }
        $errors.Add('Private-key PEM marker found and affected text files deleted.')
    }

    $cleanup.PrivateKeyArtifactScan = if (-not $badFiles -and -not $keyMarkers) { 'NO_PRIVATE_KEY_FILES_OR_MARKERS' } else { 'PRIVATE_KEY_MATERIAL_FOUND_AND_DELETED' }
    $cleanup.Warnings = @($warnings)
    $cleanup.Errors = @($errors)
    $privateTempDirectoryRemoved = $false
    if (Test-Path -LiteralPath $privateRoot) {
        try {
            Remove-Item -LiteralPath $privateRoot -Recurse -Force -ErrorAction Stop
            $privateTempDirectoryRemoved = -not (Test-Path -LiteralPath $privateRoot)
        } catch {
            $errors.Add("Private temporary directory cleanup failed: $($_.Exception.Message)")
        }
    } else { $privateTempDirectoryRemoved = $true }
    $cleanup.PrivateTempDirectoryRemoved = $privateTempDirectoryRemoved
    $cleanup.Errors = @($errors)
    $cleanup.Warnings = @($warnings)
    $cleanup.Success = ($errors.Count -eq 0)
    $cleanup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'cleanup-result.json') -Encoding utf8
    if ($state) {
        $state.CleanupComplete = $cleanup.Success
        $state.CleanupResult = $cleanup
        Save-State $state
    }
    if ($Strict -and $errors.Count -gt 0) { throw "Strict cleanup failed: $($errors -join '; ')" }
}

if ($CleanupOnly) {
    Invoke-Cleanup -Strict:$StrictCleanup
    exit 0
}

$transcriptPath = Join-Path $reportRoot 'runtime-transcript.txt'
$transcriptStarted = $false
$state = [ordered]@{
    InstanceToken = 'ACX_SAMPLE_BIND_PROBE_CI'
    DeviceInstanceId = $null
    DevGenPath = $null
    CertSubject = "CN=ACX Sample Bind Probe CI Only $env:GITHUB_RUN_ID"
    CertThumbprint = $null
    CandidateInfPath = $null
    CandidateSelected = $false
    AcxWasRunning = $false
    AcxStartedByProbe = $false
    TestAttempted = $false
    CleanupComplete = $false
    CleanupResult = $null
}
Save-State $state

try {
    try { Start-Transcript -LiteralPath $transcriptPath -Force | Out-Null; $transcriptStarted = $true } catch { }

    $os = Get-CimInstance Win32_OperatingSystem
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $acxPath = Join-Path $env:windir 'System32\drivers\Acx01000.sys'
    $wdfPath = Join-Path $env:windir 'System32\drivers\Wdf01000.sys'
    if (-not (Test-Path -LiteralPath $acxPath) -or -not (Test-Path -LiteralPath $wdfPath)) { throw 'Acx01000.sys or Wdf01000.sys missing.' }

    $acxFile = Get-Item -LiteralPath $acxPath
    $wdfFile = Get-Item -LiteralPath $wdfPath
    $acxHash = (Get-FileHash -LiteralPath $acxPath -Algorithm SHA256).Hash
    $wdfHash = (Get-FileHash -LiteralPath $wdfPath -Algorithm SHA256).Hash
    $systemInfo = [ordered]@{
        OS = $os.Caption; Version = $os.Version; Build = $os.BuildNumber; UBR = $cv.UBR
        RunnerImage = $env:ImageVersion
        Acx01000 = [ordered]@{ FileVersion = $acxFile.VersionInfo.FileVersion; Length = $acxFile.Length; SHA256 = $acxHash }
        Wdf01000 = [ordered]@{ FileVersion = $wdfFile.VersionInfo.FileVersion; Length = $wdfFile.Length; SHA256 = $wdfHash }
        RepositoryCommit = $env:GITHUB_SHA; WorkflowRunId = $env:GITHUB_RUN_ID; WorkflowRunNumber = $env:GITHUB_RUN_NUMBER
    }
    $systemInfo | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'hosted-system-info.json') -Encoding utf8

    $bcd = & bcdedit.exe /enum '{current}' 2>&1
    $bcd | Out-File -LiteralPath (Join-Path $reportRoot 'bcd-readonly.txt') -Encoding utf8
    if (($bcd -join [Environment]::NewLine) -notmatch 'testsigning\s+Yes') {
        throw 'Runner is not already in testsigning mode. No BCD change or device creation will be attempted.'
    }

    $acxService = Get-CimInstance Win32_SystemDriver -Filter "Name='Acx01000'" -ErrorAction SilentlyContinue
    if (-not $acxService) { throw 'Acx01000 service is not registered on this hosted runner.' }
    $state.AcxWasRunning = [bool]$acxService.Started
    if (-not $acxService.Started) {
        & sc.exe start Acx01000 2>&1 | Out-File -LiteralPath (Join-Path $reportRoot 'acx-service-start.txt') -Encoding utf8
        $startExit = $LASTEXITCODE
        if ($startExit -ne 0 -and $startExit -ne 1056) { throw "sc.exe start Acx01000 failed: $startExit" }
        $state.AcxStartedByProbe = $true
        Save-State $state
    }
    $running = $false
    for ($i=0; $i -lt 15; $i++) {
        $svc = Get-CimInstance Win32_SystemDriver -Filter "Name='Acx01000'" -ErrorAction SilentlyContinue
        if ($svc -and $svc.Started) { $running = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $running) { throw 'Acx01000 did not reach RUNNING.' }
    & sc.exe query Acx01000 2>&1 | Out-File -LiteralPath (Join-Path $reportRoot 'acx-service-preinstall.txt') -Encoding utf8

    $expectedAcxHash = 'D10924E8B8F3E609EA696BFE4724B96460453D654DCBDEEC83E88D07214DA5D0'
    $expectedWdfHash = '32C3A7A3E47765E3B20EC291E73E88664A56C30EA38EDC983F13A812075C943B'
    if ($wdfHash -ne $expectedWdfHash) {
        throw "Wdf01000.sys differs from the hosted LiveKD baseline. Expected $expectedWdfHash; got $wdfHash. Runtime test refused."
    }
    if ($acxHash -ne $expectedAcxHash) {
        throw "Acx01000.sys differs from CI #248 baseline. Expected $expectedAcxHash; got $acxHash. Runtime test refused."
    }

    $preCommands = @(
        '.symfix C:\Symbols',
        '.reload /f Wdf01000.sys',
        '.reload /f Acx01000.sys',
        'lmvm Acx01000',
        '!wdfldr',
        '!wdfkd.wdfldr Acx01000.sys',
        '!wdfldr acx01000',
        'x Acx01000!*AcxFunctionCount*',
        'x Acx01000!*AcxStructureCount*',
        'x Acx01000!*AcxMinimumVersionRequired*',
        'x Acx01000!*AcxClientVersionHigherThanFramework*',
        'x Acx01000!*Acx_BIND_INFO*',
        'q'
    )
    $preLog = Invoke-LiveKdDump -Phase 'preinstall' -Commands $preCommands
    if ($preLog -notmatch '(?ims)CLASS_MODULE.{0,1200}?^\s*Version\s+v?1\.0') {
        $preLog | Set-Content -LiteralPath (Join-Path $reportRoot 'preinstall-class-version-unconfirmed.txt') -Encoding utf8
        throw 'Pre-install !wdfldr did not confirm ACX CLASS_MODULE v1.0; no cert/device was created.'
    }
    if ($preLog -match '(?is)CLIENT_MODULE.{0,400}?WDF Version\s+v?1\.31') { 'WDF_CLIENT_VERSION=1.31' | Set-Content (Join-Path $reportRoot 'preinstall-version-summary.txt') -Encoding utf8 }
    if ($preLog -match '(?i)Wdf01000\.sys\s+v1\.33\s+v1\.33') { 'WDF_RUNTIME_VERSION=1.33' | Add-Content (Join-Path $reportRoot 'preinstall-version-summary.txt') }

    $packageInf = Join-Path $packageRoot 'AcxAudioCodecProbe.inf'
    $packageSys = Join-Path $packageRoot 'AcxAudioCodecProbe.sys'
    $packageCat = Join-Path $packageRoot 'AcxAudioCodecProbe.cat'
    $packagePdb = Join-Path $packageRoot 'AcxAudioCodecProbe.pdb'
    if (-not (Test-Path -LiteralPath $packageInf) -or -not (Test-Path -LiteralPath $packageSys) -or
        -not (Test-Path -LiteralPath $packageCat) -or -not (Test-Path -LiteralPath $packagePdb)) {
        throw 'Build artifact is missing INF, SYS, CAT, or PDB.'
    }

    $kitsRoot = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Windows Kits\10'
    $signTools = Get-ChildItem -LiteralPath (Join-Path $kitsRoot 'bin') -Filter 'signtool.exe' -File -Recurse -ErrorAction SilentlyContinue
    $signTool = $signTools | Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } | Select-Object -First 1
    if (-not $signTool) { $signTool = $signTools | Select-Object -First 1 }
    if (-not $signTool) { throw 'SignTool.exe not found in Windows Kits.' }

    $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $state.CertSubject -CertStoreLocation 'Cert:\LocalMachine\My' -KeyUsage DigitalSignature -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -KeyExportPolicy NonExportable
    $state.CertThumbprint = $cert.Thumbprint
    Save-State $state

    $publicCer = Join-Path $packageRoot 'AcxAudioCodecProbe-TestOnly.cer'
    Export-Certificate -Cert $cert -FilePath $publicCer | Out-Null
    Import-Certificate -FilePath $publicCer -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
    Import-Certificate -FilePath $publicCer -CertStoreLocation 'Cert:\LocalMachine\TrustedPublisher' | Out-Null

    & $signTool.FullName sign /fd SHA256 /sm /s My /sha1 $cert.Thumbprint /v $packageCat 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'signtool-sign.txt') -Encoding utf8
    $signExit = $LASTEXITCODE
    if ($signExit -ne 0) { throw "SignTool signing failed: $signExit" }
    & $signTool.FullName verify /v /pa $packageCat 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'signtool-verify-cat.txt') -Encoding utf8
    $verifyCatExit = $LASTEXITCODE
    if ($verifyCatExit -ne 0) { throw "SignTool test-catalog verification failed: $verifyCatExit" }

    & $signTool.FullName verify /v /pa /c $packageCat $packageSys 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'signtool-verify-sys.txt') -Encoding utf8
    $verifySysExit = $LASTEXITCODE
    if ($verifySysExit -ne 0) { throw "SignTool test-SYS catalog verification failed: $verifySysExit" }

    & $signTool.FullName verify /v /pa /c $packageCat $packageInf 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'signtool-verify-inf.txt') -Encoding utf8
    $verifyInfExit = $LASTEXITCODE
    if ($verifyInfExit -ne 0) { throw "SignTool test-INF catalog verification failed: $verifyInfExit" }

    $devgenRoots = @((Join-Path $kitsRoot 'Tools'),$kitsRoot) | Where-Object { Test-Path -LiteralPath $_ }
    $devgenCandidates = foreach ($rootPath in $devgenRoots) {
        Get-ChildItem -LiteralPath $rootPath -Filter 'devgen.exe' -File -Recurse -ErrorAction SilentlyContinue
    }
    $devgen = $devgenCandidates | Where-Object { $_.FullName -match '\\x64\\devgen\.exe$' } | Select-Object -First 1
    if (-not $devgen) { throw 'DevGen.exe not found; no root device will be created.' }
    $state.DevGenPath = $devgen.FullName
    Save-State $state

    $existing = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -like "*$($state.InstanceToken)*" } | Select-Object -First 1
    if ($existing) { throw "Probe instance token already exists: $($existing.InstanceId)" }

    & $devgen.FullName /add /bus ROOT /instanceid $state.InstanceToken /hardwareid 'ROOT\AudioCodec' 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'devgen-add.txt') -Encoding utf8
    $devgenExit = $LASTEXITCODE
    if ($devgenExit -ne 0) { throw "DevGen ROOT device creation failed: $devgenExit" }

    $device = $null
    for ($i=0; $i -lt 15; $i++) {
        $device = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
            Where-Object { $_.InstanceId -like "*$($state.InstanceToken)*" } | Select-Object -First 1
        if ($device) { break }
        Start-Sleep -Seconds 1
    }
    if (-not $device) { throw 'DevGen created no discoverable ROOT\AudioCodec device.' }
    $state.DeviceInstanceId = $device.InstanceId
    Save-State $state
    $device.InstanceId | Set-Content -LiteralPath (Join-Path $reportRoot 'device-instance-id.txt') -Encoding utf8

    $testStart = Get-Date
    $state.TestAttempted = $true
    Save-State $state
    & pnputil.exe /add-driver $packageInf /install 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'pnputil-install.txt') -Encoding utf8
    $pnputilExit = $LASTEXITCODE
    "PNPUTIL_EXIT=$pnputilExit" | Set-Content -LiteralPath (Join-Path $reportRoot 'install-result.txt') -Encoding utf8
    Start-Sleep -Seconds 7

    $deviceNow = Get-PnpDevice -InstanceId $state.DeviceInstanceId -ErrorAction SilentlyContinue
    if (-not $deviceNow) { throw 'Root device disappeared before PnP state capture.' }
    $deviceNow | Format-List * | Out-File -LiteralPath (Join-Path $reportRoot 'pnp-device.txt') -Encoding utf8

    $pnpProperties = [ordered]@{}
    foreach ($key in @('DEVPKEY_Device_DriverInfPath','DEVPKEY_Device_DriverVersion','DEVPKEY_Device_DriverProvider','DEVPKEY_Device_Service','DEVPKEY_Device_ProblemCode','DEVPKEY_Device_ProblemStatus','DEVPKEY_Device_HardwareIds')) {
        $pnpProperties[$key] = Get-PnpValue -InstanceId $state.DeviceInstanceId -KeyName $key
    }
    $problemStatusHex = $null
    if ($null -ne $pnpProperties['DEVPKEY_Device_ProblemStatus']) {
        try { $problemStatusHex = '0x{0:X8}' -f ([uint32]([int64]$pnpProperties['DEVPKEY_Device_ProblemStatus'] -band 4294967295)) }
        catch { $problemStatusHex = [string]$pnpProperties['DEVPKEY_Device_ProblemStatus'] }
    }

    $driverInfPath = [string]$pnpProperties['DEVPKEY_Device_DriverInfPath']
    $serviceName = [string]$pnpProperties['DEVPKEY_Device_Service']
    $candidateDriverVer = [regex]::Match((Get-Content -LiteralPath $packageInf -Raw), '(?im)^\s*DriverVer\s*=\s*(?<value>.+)$').Groups['value'].Value.Trim()
    $candidateSelected = $false
    if ($driverInfPath -match '^oem\d+\.inf$') {
        $stagedInf = Join-Path $env:windir "INF\$driverInfPath"
        if (Test-Path -LiteralPath $stagedInf) {
            $stagedText = Get-Content -LiteralPath $stagedInf -Raw
            $stagedDriverVer = [regex]::Match($stagedText, '(?im)^\s*DriverVer\s*=\s*(?<value>.+)$').Groups['value'].Value.Trim()
            $candidateSelected = ($stagedDriverVer -eq $candidateDriverVer -and $serviceName -eq 'AcxAudioCodecProbe')
        }
    }
    $state.CandidateInfPath = $driverInfPath
    $state.CandidateSelected = $candidateSelected
    Save-State $state

    $pnpReport = [ordered]@{
        DeviceInstanceId = $state.DeviceInstanceId
        FriendlyName = $deviceNow.FriendlyName
        Status = $deviceNow.Status
        DriverInfPath = $driverInfPath
        DriverVersion = $pnpProperties['DEVPKEY_Device_DriverVersion']
        DriverProvider = $pnpProperties['DEVPKEY_Device_DriverProvider']
        Service = $serviceName
        ProblemCode = $pnpProperties['DEVPKEY_Device_ProblemCode']
        ProblemStatusRaw = $pnpProperties['DEVPKEY_Device_ProblemStatus']
        ProblemStatusHex = $problemStatusHex
        CandidateInfSelected = $candidateSelected
        CandidateDriverVer = $candidateDriverVer
        PnPUtilExitCode = $pnputilExit
    }
    $pnpReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'pnp-result.json') -Encoding utf8
    if (-not $candidateSelected) {
        throw "PnP did not select the exact probe package. INF=$driverInfPath; service=$serviceName. No bind conclusion is valid."
    }

    & sc.exe query Acx01000 2>&1 | Out-File -LiteralPath (Join-Path $reportRoot 'acx-service-postinstall.txt') -Encoding utf8
    & sc.exe query AcxAudioCodecProbe 2>&1 | Out-File -LiteralPath (Join-Path $reportRoot 'probe-service-postinstall.txt') -Encoding utf8

    $events = Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=$testStart } -ErrorAction SilentlyContinue |
        Where-Object { $_.ProviderName -match 'Kernel-PnP' -and $_.Id -in @(219,227,400,410) } |
        Select-Object TimeCreated,ProviderName,Id,LevelDisplayName,Message
    $events | Format-List | Out-File -LiteralPath (Join-Path $reportRoot 'kernel-pnp-events.txt') -Encoding utf8

    $setupLog = Join-Path $env:windir 'INF\setupapi.dev.log'
    if (Test-Path -LiteralPath $setupLog) {
        $tail = Get-Content -LiteralPath $setupLog -Tail 2500
        $matches = $tail | Select-String -Pattern ([regex]::Escape($state.DeviceInstanceId) + '|AcxAudioCodecProbe|ROOT\\AudioCodec|oem\d+\.inf') -Context 2,5
        $matches | Select-Object -Last 120 | Out-String | Set-Content -LiteralPath (Join-Path $reportRoot 'setupapi-device-install.txt') -Encoding utf8
    }

    $postCommands = @('.symfix C:\Symbols','.reload /f nt','.reload /f Wdf01000.sys','.reload /f Acx01000.sys','!wdfldr acx01000','!dbgprint','q')
    $postLog = Invoke-LiveKdDump -Phase 'postinstall' -Commands $postCommands
    $driverEntrySeen = $postLog -match 'AcxAudioCodecProbe: DriverEntry ENTER'
    $wdfMatch = [regex]::Match($postLog, 'AcxAudioCodecProbe: WdfDriverCreate STATUS=0x(?<status>[0-9A-Fa-f]{8})')
    $acxMatch = [regex]::Match($postLog, 'AcxAudioCodecProbe: AcxDriverInitialize STATUS=0x(?<status>[0-9A-Fa-f]{8})')
    $deviceAddSeen = $postLog -match 'AcxAudioCodecProbe: EvtDeviceAdd REACHED'
    $wdfStatus = if ($wdfMatch.Success) { '0x' + $wdfMatch.Groups['status'].Value.ToUpperInvariant() } else { $null }
    $acxStatus = if ($acxMatch.Success) { '0x' + $acxMatch.Groups['status'].Value.ToUpperInvariant() } else { $null }

    if ($driverEntrySeen -and $wdfStatus -eq '0x00000000' -and $acxStatus -eq '0x00000000' -and $deviceAddSeen) {
        $classification = 'ACX_BIND_SUCCEEDED; DriverEntry, WdfDriverCreate, AcxDriverInitialize and EvtDeviceAdd reached; EvtDeviceAdd returned STATUS_NOT_SUPPORTED intentionally.'
        $firstStage = 'EvtDeviceAdd reached after successful ACX initialization; deliberate terminal status is STATUS_NOT_SUPPORTED.'
    } elseif ($driverEntrySeen -and $wdfStatus -and $wdfStatus -ne '0x00000000') {
        $classification = 'DRIVERENTRY_REACHED; WdfDriverCreate failed.'
        $firstStage = 'WdfDriverCreate'
    } elseif ($driverEntrySeen -and $acxStatus -and $acxStatus -ne '0x00000000') {
        $classification = 'DRIVERENTRY_REACHED; WdfDriverCreate passed and AcxDriverInitialize failed.'
        $firstStage = 'AcxDriverInitialize'
    } elseif ($driverEntrySeen -and $wdfStatus -eq '0x00000000' -and $acxStatus -eq '0x00000000') {
        $classification = 'DRIVERENTRY_AND_ACX_INITIALIZE_SUCCEEDED; EvtDeviceAdd marker not observed.'
        $firstStage = 'After AcxDriverInitialize; EvtDeviceAdd not observed'
    } elseif ($problemStatusHex -eq '0xC000000D') {
        $classification = 'NO_DRIVERENTRY_MARKER; PnP reports STATUS_INVALID_PARAMETER. Consistent with pre-DriverEntry bind failure, but exact internal bind substage is not exposed.'
        $firstStage = 'Before DriverEntry (suspected; no stage marker observed)'
    } else {
        $classification = 'INCONCLUSIVE; candidate INF selected, but debugger output has no decisive DriverEntry/ACX status marker.'
        $firstStage = 'Unresolved'
    }

    $runtimeManifest = [ordered]@{
        Classification = $classification
        FirstObservedFailingStage = $firstStage
        DriverEntryReached = $driverEntrySeen
        WdfDriverCreateStatus = $wdfStatus
        AcxDriverInitializeStatus = $acxStatus
        EvtDeviceAddReached = $deviceAddSeen
        EvtDeviceAddExpectedReturn = 'STATUS_NOT_SUPPORTED'
        PnP = $pnpReport
        AcxRuntimeFileVersion = $acxFile.VersionInfo.FileVersion
        AcxRuntimeSHA256 = $acxHash
        WdfRuntimeFileVersion = $wdfFile.VersionInfo.FileVersion
        WdfRuntimeSHA256 = $wdfHash
        PreinstallClassVersionConfirmed = $true
        CertificateThumbprint = $cert.Thumbprint
        SignTool = $signTool.FullName
        RepositoryCommit = $env:GITHUB_SHA
        WorkflowRunId = $env:GITHUB_RUN_ID
        WorkflowRunNumber = $env:GITHUB_RUN_NUMBER
    }
    $runtimeManifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $reportRoot 'runtime-result.json') -Encoding utf8

    $hashes = [ordered]@{}
    foreach ($name in @('AcxAudioCodecProbe.sys','AcxAudioCodecProbe.inf','AcxAudioCodecProbe.cat','AcxAudioCodecProbe.pdb','AcxAudioCodecProbe-TestOnly.cer')) {
        $path = Join-Path $packageRoot $name
        if (Test-Path -LiteralPath $path) {
            $hashes[$name] = [pscustomobject]@{ Length=(Get-Item -LiteralPath $path).Length; SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
        }
    }
    $hashes | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $reportRoot 'runtime-package-hashes.json') -Encoding utf8

    if ($env:GITHUB_STEP_SUMMARY) {
        @(
            '### Hosted Server 2022 ACX 1.0 sample bind probe',
            '',
            "- Classification: $classification",
            "- First observed stage: $firstStage",
            "- DriverEntry: $driverEntrySeen",
            "- WdfDriverCreate: $wdfStatus",
            "- AcxDriverInitialize: $acxStatus",
            "- EvtDeviceAdd reached: $deviceAddSeen (deliberately returns STATUS_NOT_SUPPORTED)",
            "- Candidate INF selected: $candidateSelected ($driverInfPath)",
            "- PnP ProblemStatus: $problemStatusHex",
            "- ACX runtime SHA-256: $acxHash"
        ) | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY
    }
    Write-Host $classification
} catch {
    [ordered]@{
        Error = $_.Exception.Message
        RepositoryCommit = $env:GITHUB_SHA
        WorkflowRunId = $env:GITHUB_RUN_ID
        WorkflowRunNumber = $env:GITHUB_RUN_NUMBER
        TestAttempted = [bool]$state.TestAttempted
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $reportRoot 'runtime-error.json') -Encoding utf8
    throw
} finally {
    try { Invoke-Cleanup } catch {
        $_ | Out-String | Set-Content -LiteralPath (Join-Path $reportRoot 'cleanup-exception.txt') -Encoding utf8
    }
    if ($transcriptStarted) { try { Stop-Transcript | Out-Null } catch { } }
}
