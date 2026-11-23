$ErrorActionPreference = 'Stop'

$runRoot = Join-Path $env:RUNNER_TEMP 'acx10-sample-bind-probe'
$reportRoot = Join-Path $runRoot 'report'
$dbgViewRoot = Join-Path $env:RUNNER_TEMP 'acx10-dbgview-private'
$cliPath = $env:DBGVIEWCLI_PATH
$probeScript = Join-Path $PSScriptRoot 'Invoke-AcxAudioCodecProbe.ps1'
$logPath = Join-Path $reportRoot 'kernel-dbgprint.log'
$stdoutPath = Join-Path $reportRoot 'dbgviewcli-stdout.txt'
$stderrPath = Join-Path $reportRoot 'dbgviewcli-stderr.txt'

New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
$process = $null
$startUtc = [DateTime]::UtcNow.ToString('o')
$stopUtc = $null
$startError = $null
$stopOutput = $null
$stopExitCode = $null
$probeError = $null
$probeExitCode = 0
$cliInfo = $null
$captureStarted = $false
$captureStopped = $false
$statusOutput = $null

try {
    if (-not $cliPath -or -not (Test-Path -LiteralPath $cliPath)) {
        throw 'DBGVIEWCLI_PATH missing or dbgviewcli64.exe absent.'
    }
    if (-not (Test-Path -LiteralPath $probeScript)) {
        throw "Probe script missing: $probeScript"
    }
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'DbgViewCLI kernel capture requires an elevated runner process.'
    }

    $signature = Get-AuthenticodeSignature -FilePath $cliPath
    if ($signature.Status -ne 'Valid') {
        throw "DbgViewCLI Authenticode signature is not valid: $($signature.Status)"
    }
    $cliFile = Get-Item -LiteralPath $cliPath
    $cliInfo = [ordered]@{
        Path = $cliPath
        FileVersion = $cliFile.VersionInfo.FileVersion
        LengthBytes = [long]$cliFile.Length
        SHA256 = (Get-FileHash -LiteralPath $cliPath -Algorithm SHA256).Hash
        SignatureStatus = [string]$signature.Status
        Signer = $signature.SignerCertificate.Subject
        Source = 'https://live.sysinternals.com/dbgviewcli64.exe'
    }

    $arguments = @('--accepteula','--kernel','--verbose-kernel','--no-banner','--format','text','--log',$logPath,'--duration','1800','--max-lines','50000')
    $process = Start-Process -FilePath $cliPath -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    $captureStarted = $true
    Start-Sleep -Seconds 3
    $statusOutput = (& $cliPath --status 2>&1 | Out-String).Trim()
    $processAlive = [bool](Get-Process -Id $process.Id -ErrorAction SilentlyContinue)
    if (-not $processAlive) {
        throw "DbgViewCLI exited before the probe started. --status output: $statusOutput"
    }

    & $probeScript
} catch {
    $probeError = $_.Exception.Message
    $probeExitCode = 1
} finally {
    if ($process -and $captureStarted) {
        try {
            $stopOutput = (& $cliPath --stop 2>&1 | Out-String).Trim()
            $stopExitCode = $LASTEXITCODE
        } catch {
            $stopOutput = $_.Exception.Message
            $stopExitCode = -1
        }
        try {
            Wait-Process -Id $process.Id -Timeout 30 -ErrorAction Stop
        } catch {
            $stillRunning = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
            if ($stillRunning -and $stillRunning.Path -eq $cliPath) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
        }
        $captureStopped = -not [bool](Get-Process -Id $process.Id -ErrorAction SilentlyContinue)
    }
    $stopUtc = [DateTime]::UtcNow.ToString('o')

    $logExists = Test-Path -LiteralPath $logPath
    $logLength = $null
    $logHash = $null
    $logLines = @()
    $bindLines = @()
    $bindFailureLine = $null
    if ($logExists) {
        $logItem = Get-Item -LiteralPath $logPath
        $logLength = [long]$logItem.Length
        $logHash = (Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash
        $logLines = @(Get-Content -LiteralPath $logPath -ErrorAction SilentlyContinue)
        $bindLines = @($logLines | Where-Object {
            $_ -match '(?i)(FxStubBindClasses|FxGetNextClassBindInfo|WdfVersionBindClass|VersionBindClass|ClientBindClass|STATUS_INVALID_PARAMETER|0xC000000D|0xC000007B)'
        })
        $bindFailureLine = $bindLines | Where-Object {
            $_ -match '(?i)(returned status|STATUS_INVALID_PARAMETER|0xC000000D|0xC000007B|bind.*fail|fail.*bind)'
        } | Select-Object -First 1
    }
    $bindLines | Set-Content -LiteralPath (Join-Path $reportRoot 'dbgview-bind-lines.txt') -Encoding utf8

    $summary = [ordered]@{
        Tool = 'Sysinternals DbgViewCLI'
        CaptureMode = 'Kernel DbgPrint / DbgPrintEx'
        VerboseKernel = $true
        Started = $captureStarted
        Stopped = $captureStopped
        StartedAtUtc = $startUtc
        StoppedAtUtc = $stopUtc
        ProcessId = if ($process) { [int]$process.Id } else { $null }
        StatusOutput = $statusOutput
        StopExitCode = $stopExitCode
        StopOutput = $stopOutput
        StartError = $startError
        ProbeError = $probeError
        ProbeExitCode = $probeExitCode
        Cli = $cliInfo
        LogExists = $logExists
        LogLengthBytes = $logLength
        LogSHA256 = $logHash
        LogLineCount = $logLines.Count
        BindLines = $bindLines
        BindFailureLine = $bindFailureLine
    }
    $summary | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $reportRoot 'dbgview-capture-summary.json') -Encoding utf8

    $runtimePath = Join-Path $reportRoot 'runtime-result.json'
    if (Test-Path -LiteralPath $runtimePath) {
        try {
            $runtime = Get-Content -LiteralPath $runtimePath -Raw | ConvertFrom-Json
            $runtime | Add-Member -NotePropertyName DbgViewCapture -NotePropertyValue $summary -Force
            $runtime | Add-Member -NotePropertyName DbgViewBindLines -NotePropertyValue $bindLines -Force
            $runtime | Add-Member -NotePropertyName DbgViewBindFailureLine -NotePropertyValue $bindFailureLine -Force
            $combinedBindLines = @(@($runtime.WdfBindDebugLines) + @($bindLines) | Select-Object -Unique)
            $runtime | Add-Member -NotePropertyName WdfBindDebugLines -NotePropertyValue $combinedBindLines -Force
            if ($bindFailureLine -and $runtime.PnP.ProblemStatusHex -eq '0xC000000D') {
                $runtime.Classification = "NO_DRIVERENTRY_MARKER; PnP reports STATUS_INVALID_PARAMETER; DbgView kernel trace: $bindFailureLine"
                if ($bindFailureLine -match '(?i)VersionBindClass') {
                    $runtime.FirstObservedFailingStage = 'WdfVersionBindClass'
                } elseif ($bindFailureLine -match '(?i)FxStubBindClasses') {
                    $runtime.FirstObservedFailingStage = 'FxStubBindClasses'
                } else {
                    $runtime.FirstObservedFailingStage = $bindFailureLine
                }
                $runtime.WdfBindFailureLine = $bindFailureLine
            }
            $runtime | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $runtimePath -Encoding utf8
        } catch {
            $_ | Out-String | Set-Content -LiteralPath (Join-Path $reportRoot 'dbgview-runtime-merge-error.txt') -Encoding utf8
        }
    }

    if ($probeError) {
        [ordered]@{
            Error = $probeError
            ProbeExitCode = $probeExitCode
            DbgViewCapture = $summary
        } | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $reportRoot 'dbgview-wrapper-error.json') -Encoding utf8
    }

    if (Test-Path -LiteralPath $dbgViewRoot) {
        Remove-Item -LiteralPath $dbgViewRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($probeError) {
    throw "ACX sample probe wrapper failed: $probeError"
}
