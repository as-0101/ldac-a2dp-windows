$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$work = 'C:\LDAC-Test\Tools\LiveKD'
$symbols = 'C:\Symbols'
New-Item -ItemType Directory -Force -Path $work,$symbols,'C:\LDAC-Test' | Out-Null

$pf86 = [Environment]::GetFolderPath('ProgramFilesX86')
$pf = [Environment]::GetFolderPath('ProgramFiles')
$kd = @(
    (Join-Path $pf86 'Windows Kits\10\Debuggers\x64\kd.exe'),
    (Join-Path $pf 'Windows Kits\10\Debuggers\x64\kd.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $kd) {
    $cmd = Get-Command kd.exe -ErrorAction SilentlyContinue
    if ($cmd) { $kd = $cmd.Source }
}
if (-not $kd) {
    Write-Host 'KD.EXE not found. Install Windows SDK component OptionId.WindowsDesktopDebuggers, then run again.'
    Write-Host '$p="$env:TEMP\winsdksetup.exe"; Invoke-WebRequest "https://download.microsoft.com/download/9d2b0e7e-c04f-402c-8ce6-51f1e56028e8/KIT_BUNDLE_WINDOWSSDK_MEDIACREATION/winsdksetup.exe" -OutFile $p; Start-Process $p -ArgumentList "/features OptionId.WindowsDesktopDebuggers /quiet /norestart" -Verb RunAs -Wait'
    exit 2
}
if ((Get-AuthenticodeSignature -FilePath $kd).Status -ne 'Valid') { throw 'KD signature is not Valid.' }

$live = Get-ChildItem $work -Filter 'LiveKD64.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $live) { $live = Get-ChildItem $work -Filter 'LiveKD.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1 }
if (-not $live) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zip = Join-Path $work 'LiveKD.zip'
    Invoke-WebRequest 'https://download.sysinternals.com/files/LiveKD.zip' -OutFile $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $work -Force
    $live = Get-ChildItem $work -Filter 'LiveKD64.exe' -File | Select-Object -First 1
    if (-not $live) { $live = Get-ChildItem $work -Filter 'LiveKD.exe' -File | Select-Object -First 1 }
}
if (-not $live -or (Get-AuthenticodeSignature -FilePath $live.FullName).Status -ne 'Valid') {
    throw 'LiveKD is missing or its Authenticode signature is not Valid.'
}

# Per-user Sysinternals EULA acceptance only; no machine-wide setting is changed.
$eula = 'HKCU:\Software\Sysinternals\LiveKd'
New-Item -Path $eula -Force | Out-Null
New-ItemProperty -Path $eula -Name EulaAccepted -Value 1 -PropertyType DWord -Force | Out-Null

$kdDir = Split-Path -Parent $kd
$env:PATH = "$kdDir;$env:PATH"
$existingSymbols = $env:_NT_SYMBOL_PATH
$publicSymbols = "srv*$symbols*https://msdl.microsoft.com/download/symbols"
$env:_NT_SYMBOL_PATH = if ($existingSymbols) { "$existingSymbols;$symbols;$publicSymbols" } else { "$symbols;$publicSymbols" }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dump = "C:\LDAC-Test\ACX-Live-$stamp.dmp"
$log = Join-Path ([Environment]::GetFolderPath('Desktop')) "ldac-acx-runtime-$stamp.txt"

"LiveKD capture: $([DateTime]::Now)" | Set-Content -LiteralPath $log
"Computer: $env:COMPUTERNAME" | Add-Content -LiteralPath $log
"OS: $((Get-CimInstance Win32_OperatingSystem).Caption), build $((Get-CimInstance Win32_OperatingSystem).BuildNumber)" | Add-Content -LiteralPath $log
"UBR: $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR)" | Add-Content -LiteralPath $log
"KD: $kd" | Add-Content -LiteralPath $log
"LiveKD: $($live.FullName)" | Add-Content -LiteralPath $log
"Symbol path: $env:_NT_SYMBOL_PATH" | Add-Content -LiteralPath $log
"BCD debug/testsigning (read-only):" | Add-Content -LiteralPath $log
(bcdedit /enum '{current}' | Select-String 'debug|testsigning') | Out-String | Add-Content -LiteralPath $log

foreach ($p in @("$env:windir\System32\drivers\Acx01000.sys","$env:windir\System32\drivers\Wdf01000.sys")) {
    if (Test-Path $p) {
        $f = Get-Item $p
        $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
        "$($f.Name): $($f.VersionInfo.FileVersion) | SHA256 $h" | Add-Content -LiteralPath $log
    }
}

"Dump: $dump" | Add-Content -LiteralPath $log
"Starting native LiveKD capture; this can take several minutes." | Add-Content -LiteralPath $log
Push-Location $kdDir
try {
    & $live.FullName -o $dump -ml
    $liveExit = $LASTEXITCODE
} finally {
    Pop-Location
}
"LIVEKD_EXIT=$liveExit" | Add-Content -LiteralPath $log
if ($liveExit -ne 0 -or -not (Test-Path $dump)) { throw "LiveKD capture failed. See $log" }

$debugCommand = '.symfix C:\Symbols; .sympath+ C:\Symbols; !sym noisy; .reload /f Wdf01000.sys; .reload /f Acx01000.sys; lmvm Wdf01000; lmvm Acx01000; !wdfkd.wdfldr Acx01000.sys; q'
& $kd -z $dump -logo $log -c $debugCommand
$kdExit = $LASTEXITCODE
"KD_EXIT=$kdExit" | Add-Content -LiteralPath $log

Write-Host "Log saved: $log"
Write-Host "Kernel dump retained: $dump"
Write-Host 'No driver was installed, no device was restarted, and no BCD setting was changed.'
Write-Host 'If WdfLdrGlobals/private symbols are unavailable, send the log; do not change BCD.'
Get-Content -LiteralPath $log -Tail 60
