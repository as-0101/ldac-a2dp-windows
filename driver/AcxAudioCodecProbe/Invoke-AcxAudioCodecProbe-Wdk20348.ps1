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

[CmdletBinding()]
function Get-PnpDeviceCompat([string]$InstanceId,[switch]$PresentOnly) {
    $devices = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop
    foreach ($device in $devices) {
        $id = [string]$device.PNPDeviceID
        if (-not $id) { continue }
        if ($InstanceId -and $id -ne $InstanceId) { continue }
        $isPresent = $true
        if ($device.PSObject.Properties.Name -contains 'Present') { $isPresent = [bool]$device.Present }
        if ($PresentOnly -and (-not $isPresent -or [int]$device.ConfigManagerErrorCode -eq 45)) { continue }
        [pscustomobject]@{
            InstanceId = $id
            FriendlyName = [string]$device.Name
            Status = [string]$device.Status
            ConfigManagerErrorCode = $device.ConfigManagerErrorCode
            DriverVersion = [string]$device.DriverVersion
            Manufacturer = [string]$device.Manufacturer
            Service = [string]$device.Service
            HardwareID = $device.HardwareID
            Present = $isPresent
        }
    }
}

function Get-PnpValue([string]$InstanceId,[string]$KeyName) {
    $device = Get-PnpDeviceCompat -InstanceId $InstanceId | Select-Object -First 1
    $enumKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$InstanceId"
    $enum = Get-ItemProperty -LiteralPath $enumKey -ErrorAction SilentlyContinue
    $class = $null
    if ($enum -and $enum.Driver) {
        $classKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$($enum.Driver)"
        $class = Get-ItemProperty -LiteralPath $classKey -ErrorAction SilentlyContinue
    }
    switch ($KeyName) {
        'DEVPKEY_Device_DriverInfPath' { return [string]$class.InfPath }
        'DEVPKEY_Device_DriverVersion' {
            if ($class -and $class.DriverVersion) { return [string]$class.DriverVersion }
            return [string]$device.DriverVersion
        }
        'DEVPKEY_Device_DriverProvider' {
            if ($class -and $class.ProviderName) { return [string]$class.ProviderName }
            return [string]$device.Manufacturer
        }
        'DEVPKEY_Device_Service' {
            if ($class -and $class.Service) { return [string]$class.Service }
            return [string]$device.Service
        }
        'DEVPKEY_Device_ProblemCode' { return $device.ConfigManagerErrorCode }
        'DEVPKEY_Device_HardwareIds' { return $device.HardwareID }
        'DEVPKEY_Device_ProblemStatus' {
            $output = & pnputil.exe /enum-devices /instanceid $InstanceId /properties 2>&1
            $output | Out-File -LiteralPath (Join-Path $reportRoot 'pnp-properties-pnputil.txt') -Encoding utf8
            $raw = $output -join [Environment]::NewLine
            $match = [regex]::Match($raw, '(?im)(?:Problem Status|DEVPKEY_Device_ProblemStatus)\s*:\s*(0x[0-9a-f]{8})')
            if ($match.Success) { return [Convert]::ToInt64($match.Groups[1].Value.Substring(2),16) }
            return $null
        }
        default { return $null }
    }
}

function Test-DriverServiceRunning([string]$Name) {
    $output = & sc.exe query $Name 2>&1
    if ($LASTEXITCODE -ne 0) { return $false }
    return (($output -join [Environment]::NewLine) -match '(?im)^\s*STATE\s*:\s*4\s+RUNNING')
}

function Get-WdfServiceDiagnosticsSnapshot([string]$ServiceName) {
    $keyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName\Parameters\Wdf"
    $keyExisted = Test-Path -LiteralPath $keyPath
    $key = if ($keyExisted) { Get-Item -LiteralPath $keyPath } else { $null }
    $values = [ordered]@{}
    foreach ($name in @('VerboseOn','LogPages')) {
        $exists = $false
        $value = $null
        $kind = $null
        if ($key) {
            $exists = $key.GetValueNames() -contains $name
            if ($exists) {
                $kind = [string]$key.GetValueKind($name)
                if ($kind -ne 'DWord') { throw "Existing $ServiceName WDF $name value has unexpected registry type: $kind." }
                $value = [int]$key.GetValue($name)
            }
        }
        $values[$name] = [ordered]@{ Exists = $exists; Value = $value; Kind = $kind }
    }
    return [ordered]@{
        ServiceName = $ServiceName
        KeyPath = $keyPath
        KeyExisted = $keyExisted
        Values = $values
        EnabledByProbe = $false
    }
}

function Enable-WdfServiceDiagnostics([object]$Snapshot) {
    if (-not (Test-Path -LiteralPath $Snapshot.KeyPath)) { New-Item -Path $Snapshot.KeyPath -Force | Out-Null }
    New-ItemProperty -LiteralPath $Snapshot.KeyPath -Name 'VerboseOn' -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -LiteralPath $Snapshot.KeyPath -Name 'LogPages' -PropertyType DWord -Value 16 -Force | Out-Null
    $verbose = [int](Get-ItemPropertyValue -LiteralPath $Snapshot.KeyPath -Name 'VerboseOn' -ErrorAction Stop)
    $pages = [int](Get-ItemPropertyValue -LiteralPath $Snapshot.KeyPath -Name 'LogPages' -ErrorAction Stop)
    if ($verbose -ne 1 -or $pages -ne 16) { throw "WDF diagnostics values for $($Snapshot.ServiceName) did not verify (VerboseOn=$verbose, LogPages=$pages)." }
    $Snapshot.EnabledValues = [ordered]@{ VerboseOn = $verbose; LogPages = $pages }
    $Snapshot.EnabledAtUtc = [DateTime]::UtcNow.ToString('o')
}

function Restore-WdfServiceDiagnostics([object]$Snapshot,[System.Collections.Generic.List[string]]$Errors,[System.Collections.Generic.List[string]]$Warnings) {
    if (-not $Snapshot -or -not $Snapshot.EnabledByProbe) { return }
    $keyPath = [string]$Snapshot.KeyPath
    try {
        if (-not (Test-Path -LiteralPath $keyPath) -and ($Snapshot.Values.VerboseOn.Exists -or $Snapshot.Values.LogPages.Exists)) {
            New-Item -Path $keyPath -Force | Out-Null
        }
        foreach ($name in @('VerboseOn','LogPages')) {
            $entry = $Snapshot.Values.$name
            if ($entry.Exists) {
                New-ItemProperty -LiteralPath $keyPath -Name $name -PropertyType DWord -Value ([int]$entry.Value) -Force | Out-Null
            } elseif (Test-Path -LiteralPath $keyPath) {
                Remove-ItemProperty -LiteralPath $keyPath -Name $name -ErrorAction SilentlyContinue
            }
        }
        if (-not $Snapshot.KeyExisted -and (Test-Path -LiteralPath $keyPath)) {
            $key = Get-Item -LiteralPath $keyPath
            if ($key.ValueCount -eq 0 -and $key.SubKeyCount -eq 0) {
                Remove-Item -LiteralPath $keyPath -Force
            } else {
                $Warnings.Add("WDF Parameters key for $($Snapshot.ServiceName) was created by the probe but contains other data; it was preserved after restoring VerboseOn/LogPages.")
            }
        }
        $restored = $true
        $keyExistsAfter = Test-Path -LiteralPath $keyPath
        $key = if ($keyExistsAfter) { Get-Item -LiteralPath $keyPath } else { $null }
        foreach ($name in @('VerboseOn','LogPages')) {
            $entry = $Snapshot.Values.$name
            $existsAfter = $false
            $valueAfter = $null
            if ($key) {
                $existsAfter = $key.GetValueNames() -contains $name
                if ($existsAfter) { $valueAfter = [int]$key.GetValue($name) }
            }
            if ($entry.Exists) {
                if (-not $existsAfter -or $valueAfter -ne [int]$entry.Value) { $restored = $false }
            } elseif ($existsAfter) {
                $restored = $false
            }
        }
        if ($restored) {
            $Snapshot.EnabledByProbe = $false
            $Snapshot.RestoredAtUtc = [DateTime]::UtcNow.ToString('o')
        } else {
            $Errors.Add("WDF VerboseOn/LogPages for $($Snapshot.ServiceName) did not return to their original values.")
        }
        $Snapshot | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'acx01000-wdf-diagnostics-restored.json') -Encoding utf8
    } catch {
        $Errors.Add("WDF service diagnostics restore failed for $($Snapshot.ServiceName): $($_.Exception.Message)")
    }
}

function Invoke-LiveKdDump([string]$Phase,[string[]]$Commands,[switch]$FullMirror) {
    $kdPath = $env:KD_PATH
    $liveKdPath = $env:LIVEKD_PATH
    if (-not $kdPath -or -not (Test-Path -LiteralPath $kdPath)) { throw 'KD_PATH missing or kd.exe absent.' }
    if (-not $liveKdPath -or -not (Test-Path -LiteralPath $liveKdPath)) { throw 'LIVEKD_PATH missing or livekd.exe absent.' }
    if (-not $env:_NT_SYMBOL_PATH) { throw '_NT_SYMBOL_PATH is not set.' }

    $captureLog = Join-Path $reportRoot "$Phase-livekd-capture.txt"
    $commandFile = Join-Path $privateRoot "$Phase-kd-commands.txt"
    $kdLog = Join-Path $reportRoot "$Phase-kd-output.txt"
    $Commands | Set-Content -LiteralPath $commandFile -Encoding ascii

    if ($FullMirror) {
        $liveMode = 'mirror-all-regions-0x3FFF'
        $dump = Join-Path $privateRoot "$Phase-mirror.dmp"
        $liveOutput = & $liveKdPath -o $dump '-m0x3FFF' 2>&1
        $liveExit = $LASTEXITCODE
    } else {
        $liveMode = 'native-live-dump'
        $dump = Join-Path $privateRoot "$Phase-native.dmp"
        $liveOutput = & $liveKdPath -o $dump -ml 2>&1
        $liveExit = $LASTEXITCODE
        if ($liveExit -ne 0 -or -not (Test-Path -LiteralPath $dump)) {
            $liveMode = 'mirror-all-regions-0x3FFF-fallback'
            Remove-Item -LiteralPath $dump -Force -ErrorAction SilentlyContinue
            $dump = Join-Path $privateRoot "$Phase-mirror.dmp"
            $liveOutput = & $liveKdPath -o $dump '-m0x3FFF' 2>&1
            $liveExit = $LASTEXITCODE
        }
    }
    if ($liveOutput) { $liveOutput | Out-File -LiteralPath $captureLog -Encoding utf8 }
    $dumpLength = 0
    $dumpHash = $null
    if (Test-Path -LiteralPath $dump) {
        $dumpItem = Get-Item -LiteralPath $dump
        $dumpLength = [long]$dumpItem.Length
        $dumpHash = (Get-FileHash -LiteralPath $dump -Algorithm SHA256).Hash
    }
    @(
        "LiveKD_MODE=$liveMode"
        "LiveKD_EXIT_CODE=$liveExit"
        "DUMP_LENGTH_BYTES=$dumpLength"
        "DUMP_SHA256=$dumpHash"
    ) | Set-Content -LiteralPath $captureLog -Encoding utf8
    if ($liveOutput) { $liveOutput | Out-File -LiteralPath $captureLog -Append -Encoding utf8 }
    if ($liveExit -ne 0 -or -not (Test-Path -LiteralPath $dump)) { throw "LiveKD $Phase capture failed: $liveExit ($liveMode)" }

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
    $missingPageCount = [regex]::Matches($content, '(?im)Page\s+[\da-f]+\s+not present in the dump file').Count
    "KD_MISSING_DUMP_PAGE_COUNT=$missingPageCount" | Out-File -LiteralPath $captureLog -Append -Encoding utf8
    if ($missingPageCount -gt 0) {
        "MISSING_DUMP_PAGES=$missingPageCount" | Set-Content -LiteralPath (Join-Path $reportRoot "$Phase-missing-dump-pages.txt") -Encoding utf8
    }
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
            $found = Get-PnpDeviceCompat -PresentOnly -ErrorAction SilentlyContinue |
                Where-Object { $_.InstanceId -like "*$($state.InstanceToken)*" } | Select-Object -First 1
            if ($found) { $deviceId = $found.InstanceId }
        }
        if ($deviceId) {
            $existing = Get-PnpDeviceCompat -PresentOnly -InstanceId $deviceId -ErrorAction SilentlyContinue
            if ($existing) {
                $devgenPath = [string]$state.DevGenPath
                if ($devgenPath -and (Test-Path -LiteralPath $devgenPath)) {
                    & $devgenPath /remove $deviceId /subtree 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-devgen.txt') -Encoding utf8
                    $cleanup.DevGenExitCode = $LASTEXITCODE
                }
                Start-Sleep -Seconds 1
                if (Get-PnpDeviceCompat -PresentOnly -InstanceId $deviceId -ErrorAction SilentlyContinue) {
                    & pnputil.exe /remove-device $deviceId /subtree 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-pnputil-fallback.txt') -Encoding utf8
                    $cleanup.PnPUtilRemoveExitCode = $LASTEXITCODE
                    Start-Sleep -Seconds 2
                }
            }
            if (Get-PnpDeviceCompat -PresentOnly -InstanceId $deviceId -ErrorAction SilentlyContinue) { $errors.Add("ROOT test device remains: $deviceId") }
            else { $cleanup.DeviceRemoved = $true }
        } else { $cleanup.DeviceRemoved = $true }

        if ($state.CandidateSelected -and $state.CandidateInfPath -match '^oem\d+\.inf$') {
            & pnputil.exe /delete-driver $state.CandidateInfPath /uninstall /force 2>&1 |
                Out-File (Join-Path $reportRoot 'cleanup-driverstore.txt') -Encoding utf8
            $cleanup.DriverStoreDeleteExitCode = $LASTEXITCODE
        }

        if (-not $state.ProbeServiceExistedBefore) {
            $probeServiceKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\AcxAudioCodecProbe'
            $probeServiceQuery = & sc.exe query AcxAudioCodecProbe 2>&1
            if ($LASTEXITCODE -eq 0) {
                if (Test-DriverServiceRunning 'AcxAudioCodecProbe') {
                    & sc.exe stop AcxAudioCodecProbe 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-probe-service-stop.txt') -Encoding utf8
                    Start-Sleep -Seconds 2
                }
                & sc.exe delete AcxAudioCodecProbe 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-probe-service-delete.txt') -Encoding utf8
                $cleanup.ProbeServiceDeleteExitCode = $LASTEXITCODE
                Start-Sleep -Seconds 1
            }
            if (Test-Path -LiteralPath $probeServiceKey) {
                Remove-Item -LiteralPath $probeServiceKey -Recurse -Force -ErrorAction SilentlyContinue
            }
            $probeServiceAfter = & sc.exe query AcxAudioCodecProbe 2>&1
            $cleanup.ProbeServiceRemoved = ($LASTEXITCODE -ne 0 -and -not (Test-Path -LiteralPath $probeServiceKey))
            if (-not $cleanup.ProbeServiceRemoved) { $errors.Add('AcxAudioCodecProbe service or registry key remains after cleanup.') }
        } else {
            $cleanup.ProbeServiceWasPreexisting = $true
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
            $acxRunning = Test-DriverServiceRunning 'Acx01000'
            $previousStopRejected = ($state.CleanupResult -and [int]$state.CleanupResult.AcxStopExitCode -eq 1061)
            if ($acxRunning -and -not $previousStopRejected) {
                & sc.exe stop Acx01000 2>&1 | Out-File (Join-Path $reportRoot 'cleanup-acx-service.txt') -Encoding utf8
                $cleanup.AcxStopExitCode = $LASTEXITCODE
                Start-Sleep -Seconds 3
            } elseif ($previousStopRejected) {
                $cleanup.AcxStopExitCode = 1061
                $cleanup.AcxStopRetrySkipped = $true
            }
            $acxRunningAfter = Test-DriverServiceRunning 'Acx01000'
            if ($acxRunningAfter) {
                if ([int]$cleanup.AcxStopExitCode -eq 1061) {
                    $cleanup.AcxServiceRestored = $false
                    $warnings.Add('Acx01000 remained RUNNING because SCM rejected STOP with 1061; disposable hosted runner will be destroyed after the job.')
                } else { $errors.Add('Acx01000 remains running after a non-1061 stop result.') }
            } else { $cleanup.AcxServiceRestored = $true }
        } else {
            $cleanup.AcxServiceWasNotStartedByProbe = $true
            $cleanup.AcxServiceRestored = $true
        }

        if ($state.AcxWdfDiagnostics) {
            Restore-WdfServiceDiagnostics -Snapshot $state.AcxWdfDiagnostics -Errors $errors -Warnings $warnings
            $cleanup.AcxWdfDiagnosticsRestored = -not [bool]$state.AcxWdfDiagnostics.EnabledByProbe
        }

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
    AcxWdfDiagnostics = $null
    ProbeServiceExistedBefore = $false
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

    $serviceBefore = & sc.exe query Acx01000 2>&1
    $serviceBeforeExit = $LASTEXITCODE
    $serviceBeforeText = $serviceBefore -join [Environment]::NewLine
    $serviceBefore | Out-File -LiteralPath (Join-Path $reportRoot 'acx-service-before.txt') -Encoding utf8
    if ($serviceBeforeExit -ne 0) { throw "Acx01000 service query failed or service is not registered: $serviceBeforeExit" }
    $state.AcxWasRunning = ($serviceBeforeText -match '(?im)^\s*STATE\s*:\s*4\s+RUNNING')
    if (-not $state.AcxWasRunning) {
        $state.AcxWdfDiagnostics = Get-WdfServiceDiagnosticsSnapshot 'Acx01000'
        $state.AcxWdfDiagnostics.EnabledByProbe = $true
        $state.AcxWdfDiagnostics | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'acx01000-wdf-diagnostics-before.json') -Encoding utf8
        Save-State $state
        Enable-WdfServiceDiagnostics -Snapshot $state.AcxWdfDiagnostics
        $state.AcxWdfDiagnostics | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'acx01000-wdf-diagnostics-enabled.json') -Encoding utf8
        Save-State $state
        & sc.exe start Acx01000 2>&1 | Out-File -LiteralPath (Join-Path $reportRoot 'acx-service-start.txt') -Encoding utf8
        $startExit = $LASTEXITCODE
        if ($startExit -ne 0 -and $startExit -ne 1056) { throw "sc.exe start Acx01000 failed: $startExit" }
        $state.AcxStartedByProbe = $true
        Save-State $state
    }
    $running = $false
    for ($i=0; $i -lt 15; $i++) {
        if (Test-DriverServiceRunning 'Acx01000') { $running = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $running) { throw 'Acx01000 did not reach RUNNING according to sc.exe query.' }
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
        '!wdfkd.wdflogdump Acx01000 -f',
        '!wdfkd.wdflogdump Acx01000 -d',
        'x Wdf01000!*WdfLdrDbgPrintOn*',
        'dd Wdf01000!WdfLdrDbgPrintOn L1',
        'x Wdf01000!*Class*',
        'dt Wdf01000!WDF_CLASS_BIND_INFO',
        'dt Wdf01000!WDF_CLASS_BIND_INFO2',
        'dt Wdf01000!WDF_CLASS_EXTENSION_DESCRIPTOR',
        'dt Wdf01000!WDF_CLASS_LIBRARY_INFO',
        'dt Wdf01000!WDF_CLASS_VERSION',
        'dt Wdf01000!_CLASS_MODULE',
        '!dbgprint',
        'x Acx01000!*AcxFunctionCount*',
        'x Acx01000!*AcxStructureCount*',
        'x Acx01000!*AcxMinimumVersionRequired*',
        'x Acx01000!*AcxClientVersionHigherThanFramework*',
        'x Acx01000!*Acx_BIND_INFO*',
        'q'
    )
    $preLog = Invoke-LiveKdDump -Phase 'preinstall' -Commands $preCommands -FullMirror
    $preCaptureText = Get-Content -LiteralPath (Join-Path $reportRoot 'preinstall-livekd-capture.txt') -Raw
    $preCaptureMode = [regex]::Match($preCaptureText, '(?im)^LiveKD_MODE=(?<value>.+)$').Groups['value'].Value.Trim()
    $preDumpHash = [regex]::Match($preCaptureText, '(?im)^DUMP_SHA256=(?<value>.+)$').Groups['value'].Value.Trim()
    $preDumpLength = [regex]::Match($preCaptureText, '(?im)^DUMP_LENGTH_BYTES=(?<value>\d+)$').Groups['value'].Value.Trim()
    $preMissingPageCount = [regex]::Match($preCaptureText, '(?im)^KD_MISSING_DUMP_PAGE_COUNT=(?<value>\d+)$').Groups['value'].Value.Trim()
    $preWdfIfrLines = @($preLog -split '\r?\n' | Where-Object { $_ -match '(?i)(wdflogdump|FxStub|BindClasses|VersionBindClass|InitTypes|WdfVersionBindClass|AcxAudioCodecProbe|Acx01000|STATUS_INVALID_PARAMETER|0xC000000D|Error events encountered in logs)' })
    $preWdfIfrLines | Set-Content -LiteralPath (Join-Path $reportRoot 'preinstall-wdf-ifr-lines.txt') -Encoding utf8
    $classModuleMatch = [regex]::Match($preLog, '(?ims)CLASS_MODULE.{0,1200}?^\s*Version\s+v?1\.0')
    $missingDumpPage = ($preLog -match '(?i)Page\s+[\da-f]+\s+not present in the dump file')
    $wdfRuntimeVisible = ($preLog -match '(?is)LIBRARY_MODULE.{0,500}?\n\s*Version\s+v?1\.33')
    $wdfClientVisible = ($preLog -match '(?is)CLIENT_MODULE.{0,400}?WDF Version\s+v?1\.31') -or ($preLog -match '(?im)^\s*<missing name>\s+v1\.31')
    $classModuleStatus = if ($classModuleMatch.Success) { 'CONFIRMED_1.0' } elseif ($missingDumpPage) { 'NOT_VISIBLE_DUE_TO_MISSING_DUMP_PAGE' } else { 'NOT_VISIBLE_IN_WDF_LOADER_OUTPUT' }
    $versionSummary = @(
        "ACX_MODULE_FILE_VERSION=$($acxFile.VersionInfo.FileVersion)"
        "ACX_MODULE_SHA256=$acxHash"
        "ACX_CLASS_MODULE_CAPTURE=$classModuleStatus"
        "WDF_RUNTIME_1.33_VISIBLE_IN_LIVEKD=$wdfRuntimeVisible"
        "WDF_CLIENT_1.31_VISIBLE_IN_LIVEKD=$wdfClientVisible"
        "ACX_SERVICE_WAS_RUNNING_BEFORE_PROBE=$($state.AcxWasRunning)"
        "ACX_SERVICE_STARTED_BY_PROBE=$($state.AcxStartedByProbe)"
        "MISSING_DUMP_PAGE_OBSERVED=$missingDumpPage"
    )
    $versionSummary | Set-Content -LiteralPath (Join-Path $reportRoot 'preinstall-version-summary.txt') -Encoding utf8
    $preinstallRuntime = [ordered]@{
        AcxModuleFileVersion = $acxFile.VersionInfo.FileVersion
        AcxModuleSHA256 = $acxHash
        AcxClassModuleVersion = if ($classModuleMatch.Success) { '1.0' } else { $null }
        AcxClassModuleCaptureStatus = $classModuleStatus
        WdfRuntimeVersionVisible = $wdfRuntimeVisible
        WdfClientVersionVisible = $wdfClientVisible
        MissingDumpPageObserved = $missingDumpPage
        LiveKdCaptureMode = $preCaptureMode
        LiveKdDumpSHA256 = $preDumpHash
        LiveKdDumpLengthBytes = if ($preDumpLength) { [long]$preDumpLength } else { $null }
        MissingDumpPageCount = if ($preMissingPageCount) { [int]$preMissingPageCount } else { $null }
        WdfIfrLineCount = $preWdfIfrLines.Count
        AcxServiceWasRunningBeforeProbe = $state.AcxWasRunning
        AcxServiceStartedByProbe = $state.AcxStartedByProbe
    }
    $preinstallRuntime | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'preinstall-runtime-status.json') -Encoding utf8
    if (-not $classModuleMatch.Success) {
        'ACX CLASS_MODULE v1.0 was not directly readable in this LiveKD bitmap dump; pinned Acx01000.sys/Wdf01000.sys hashes are verified, and the class-loader output is retained as partial evidence.' |
            Set-Content -LiteralPath (Join-Path $reportRoot 'preinstall-class-version-partial.txt') -Encoding utf8
    }

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

    $existing = Get-PnpDeviceCompat -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -like "*$($state.InstanceToken)*" } | Select-Object -First 1
    if ($existing) { throw "Probe instance token already exists: $($existing.InstanceId)" }

    & $devgen.FullName /add /bus ROOT /instanceid $state.InstanceToken /hardwareid 'ROOT\AudioCodec' 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'devgen-add.txt') -Encoding utf8
    $devgenExit = $LASTEXITCODE
    if ($devgenExit -ne 0) { throw "DevGen ROOT device creation failed: $devgenExit" }

    $device = $null
    for ($i=0; $i -lt 15; $i++) {
        $device = Get-PnpDeviceCompat -PresentOnly -ErrorAction SilentlyContinue |
            Where-Object { $_.InstanceId -like "*$($state.InstanceToken)*" } | Select-Object -First 1
        if ($device) { break }
        Start-Sleep -Seconds 1
    }
    if (-not $device) { throw 'DevGen created no discoverable ROOT\AudioCodec device.' }
    $state.DeviceInstanceId = $device.InstanceId
    Save-State $state
    $device.InstanceId | Set-Content -LiteralPath (Join-Path $reportRoot 'device-instance-id.txt') -Encoding utf8

    $probeServiceBefore = & sc.exe query AcxAudioCodecProbe 2>&1
    $state.ProbeServiceExistedBefore = ($LASTEXITCODE -eq 0)
    $probeServiceBefore | Out-File -LiteralPath (Join-Path $reportRoot 'probe-service-before.txt') -Encoding utf8
    Save-State $state

    $testStart = Get-Date
    $state.TestAttempted = $true
    Save-State $state
    & pnputil.exe /add-driver $packageInf /install 2>&1 |
        Out-File -LiteralPath (Join-Path $reportRoot 'pnputil-install.txt') -Encoding utf8
    $pnputilExit = $LASTEXITCODE
    "PNPUTIL_EXIT=$pnputilExit" | Set-Content -LiteralPath (Join-Path $reportRoot 'install-result.txt') -Encoding utf8
    Start-Sleep -Seconds 7

    $deviceNow = Get-PnpDeviceCompat -InstanceId $state.DeviceInstanceId -ErrorAction SilentlyContinue
    if (-not $deviceNow) { throw 'Root device disappeared before PnP state capture.' }
    $deviceNow | Format-List * | Out-File -LiteralPath (Join-Path $reportRoot 'pnp-device.txt') -Encoding utf8
    $pnputilDrivers = & pnputil.exe /enum-devices /instanceid $state.DeviceInstanceId /drivers 2>&1
    $pnputilDrivers | Out-File -LiteralPath (Join-Path $reportRoot 'pnp-drivers-pnputil.txt') -Encoding utf8

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
        ConfigManagerErrorCode = $deviceNow.ConfigManagerErrorCode
        PnPQueryBackend = 'Win32_PnPEntity + Enum/Class registry + PnPUtil'
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

    $postCommands = @(
        '.symfix C:\Symbols',
        '.reload /f nt',
        '.reload /f Wdf01000.sys',
        '.reload /f Acx01000.sys',
        'lmvm AcxAudioCodecProbe',
        '!wdfkd.wdfldr AcxAudioCodecProbe.sys',
        '!wdfldr',
        '!wdfldr acx01000',
        '!wdfkd.wdflogdump Acx01000 -f',
        '!wdfkd.wdflogdump Acx01000 -d',
        '!wdfkd.wdflogdump AcxAudioCodecProbe -f',
        '!wdfkd.wdflogdump AcxAudioCodecProbe -d',
        '!wdfkd.wdflogdump Wdf01000 -f',
        'x Wdf01000!*WdfLdrDbgPrintOn*',
        'dd Wdf01000!WdfLdrDbgPrintOn L1',
        '!dbgprint',
        'q'
    )
    $postLog = Invoke-LiveKdDump -Phase 'postinstall' -Commands $postCommands
    $driverEntrySeen = $postLog -match 'AcxAudioCodecProbe: DriverEntry ENTER'
    $wdfMatch = [regex]::Match($postLog, 'AcxAudioCodecProbe: WdfDriverCreate STATUS=0x(?<status>[0-9A-Fa-f]{8})')
    $acxMatch = [regex]::Match($postLog, 'AcxAudioCodecProbe: AcxDriverInitialize STATUS=0x(?<status>[0-9A-Fa-f]{8})')
    $deviceAddSeen = $postLog -match 'AcxAudioCodecProbe: EvtDeviceAdd REACHED'
    $postWdfIfrLines = @($postLog -split '\r?\n' | Where-Object { $_ -match '(?i)(wdflogdump|FxStub|BindClasses|VersionBindClass|InitTypes|WdfVersionBindClass|AcxAudioCodecProbe|Acx01000|STATUS_INVALID_PARAMETER|0xC000000D|Error events encountered in logs)' })
    $postWdfIfrLines | Set-Content -LiteralPath (Join-Path $reportRoot 'postinstall-wdf-ifr-lines.txt') -Encoding utf8
    $wdfIfrLines = @(
        @($preWdfIfrLines | ForEach-Object { "PREINSTALL: $_" })
        @($postWdfIfrLines | ForEach-Object { "POSTINSTALL: $_" })
    )
    $wdfIfrLines | Set-Content -LiteralPath (Join-Path $reportRoot 'wdf-ifr-lines.txt') -Encoding utf8
    $wdfBindDebugLines = @($postWdfIfrLines | Where-Object { $_ -match '(?i)(FxStub|BindClasses|VersionBindClass|InitTypes|WdfVersionBindClass|STATUS_INVALID_PARAMETER|0xC000000D)' })
    $wdfBindDebugLines | Set-Content -LiteralPath (Join-Path $reportRoot 'wdf-bind-debug-lines.txt') -Encoding utf8
    $wdfBindFailureLine = $wdfBindDebugLines | Where-Object { $_ -match '(?i)(returned status|STATUS_INVALID_PARAMETER|0xC000000D|bind.*fail|fail.*bind)' } | Select-Object -First 1
    $wdfIfrFailureLine = $wdfIfrLines | Where-Object { $_ -match '(?i)(returned status|STATUS_INVALID_PARAMETER|0xC000000D|bind.*fail|fail.*bind)' } | Select-Object -First 1
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
    } elseif ($problemStatusHex -eq '0xC000000D' -and $wdfIfrFailureLine) {
        $classification = "NO_DRIVERENTRY_MARKER; PnP reports STATUS_INVALID_PARAMETER; WDF IFR trace: $wdfIfrFailureLine"
        $firstStage = $wdfIfrFailureLine
    } elseif ($problemStatusHex -eq '0xC000000D' -and $wdfBindFailureLine) {
        $classification = "NO_DRIVERENTRY_MARKER; PnP reports STATUS_INVALID_PARAMETER; WDF bind trace: $wdfBindFailureLine"
        $firstStage = $wdfBindFailureLine
    } elseif ($problemStatusHex -eq '0xC000000D') {
        $classification = 'NO_DRIVERENTRY_MARKER; PnP reports STATUS_INVALID_PARAMETER. WDF IFR dumps were attempted; no internal bind stage was identified.'
        $firstStage = 'Pre-DriverEntry WDF/ACX load/bind stage; IFR log did not expose internal substage'
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
        PreinstallClassVersionConfirmed = [bool]$classModuleMatch.Success
        PreinstallClassVersionCaptureStatus = $classModuleStatus
        PreinstallWdfRuntimeVisible = $wdfRuntimeVisible
        PreinstallWdfClientVisible = $wdfClientVisible
        PreinstallLiveKdCaptureMode = $preCaptureMode
        PreinstallLiveKdDumpSHA256 = $preDumpHash
        PreinstallLiveKdDumpLengthBytes = if ($preDumpLength) { [long]$preDumpLength } else { $null }
        PreinstallMissingDumpPageCount = if ($preMissingPageCount) { [int]$preMissingPageCount } else { $null }
        PreinstallWdfIfrLines = $preWdfIfrLines
        PostinstallWdfIfrLines = $postWdfIfrLines
        WdfBindDebugLines = $wdfBindDebugLines
        WdfBindFailureLine = $wdfBindFailureLine
        WdfIfrLines = $wdfIfrLines
        WdfIfrFailureLine = $wdfIfrFailureLine
        AcxWdfDiagnostics = $state.AcxWdfDiagnostics
        ProbeServiceExistedBefore = $state.ProbeServiceExistedBefore
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
