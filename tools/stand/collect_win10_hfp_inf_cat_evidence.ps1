# Read-only Windows 10 source collector. No driver binaries or full Microsoft INF/CAT are exported.
# Run only on a Windows 10 donor (not on the physical Windows Server).
param([string]$OutputDirectory = "$env:USERPROFILE\Desktop\HFP-Donor-Metadata")
$ErrorActionPreference = 'Stop'
$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
if ($os.InstallationType -ne 'Client' -or [string]$os.CurrentBuild -notmatch '^1904[0-9]$') { throw "Windows 10 donor required; actual $($os.InstallationType) $($os.CurrentBuild)" }
New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
$store = Join-Path $env:windir 'System32\DriverStore\FileRepository'
$packages = @(Get-ChildItem -LiteralPath $store -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(microsoft_bluetooth_hfp|bthhf|bthag)' })
$infDir = Join-Path $env:windir 'INF'
$hfpInfs = @(Get-ChildItem -LiteralPath $infDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(microsoft_bluetooth_hfp|bthhf|bthag).*\.inf$' })
$kit = 'C:\Program Files (x86)\Windows Kits\10\bin'
$signTool = if (Test-Path -LiteralPath $kit) { Get-ChildItem -LiteralPath $kit -Filter signtool.exe -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq 'x64' } | Sort-Object FullName -Descending | Select-Object -First 1 } else { $null }
$records = foreach ($file in @($hfpInfs + @($packages | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Filter '*.inf' -File -ErrorAction SilentlyContinue }) | Sort-Object FullName -Unique)) {
    $section = ''
    $directives = @()
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        if ($line -match '^\s*\[([^\]]+)\]') { $section = $Matches[1] }
        if ($line -match '^\s*(CatalogFile(?:\.[\w.]+)?|Include|Needs|CopyFiles|AddService|ServiceBinary|AddReg|CopyINF)\s*=|BTHHFENUM\\') {
            $directives += [pscustomobject]@{ section=$section; directive=$line.Trim() }
        }
    }
    [pscustomobject]@{ name=$file.Name; parent=$file.Directory.Name; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash; size=$file.Length; directives=@($directives) }
}
$catRecords = @()
$driverRecords = @()
$verifyRecords = @()
foreach ($package in $packages) {
    $cats = @(Get-ChildItem -LiteralPath $package.FullName -File -Filter '*.cat' -ErrorAction SilentlyContinue)
    $sys = @(Get-ChildItem -LiteralPath $package.FullName -File -Filter '*.sys' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(BthHfAud|BthHfEnum)\.sys$' })
    foreach ($cat in $cats) {
        $sig = Get-AuthenticodeSignature -LiteralPath $cat.FullName
        $catRecords += [pscustomobject]@{ package=$package.Name; name=$cat.Name; sha256=(Get-FileHash -LiteralPath $cat.FullName -Algorithm SHA256).Hash; signatureStatus="$($sig.Status)"; signer=if($sig.SignerCertificate){$sig.SignerCertificate.Subject}else{$null} }
        foreach ($member in $sys) {
            $v = [ordered]@{ package=$package.Name; catalog=$cat.Name; driver=$member.Name; invoked=[bool]$signTool; exitCode=$null; tail=@(); platform='Windows10_SOURCE_ONLY' }
            if ($signTool) {
                $out = @(& $signTool.FullName verify /kp /v /c $cat.FullName $member.FullName 2>&1 | ForEach-Object { "$_" })
                $v.exitCode = $LASTEXITCODE
                $v.tail = @($out | Select-Object -Last 16)
            }
            $verifyRecords += [pscustomobject]$v
        }
    }
    foreach ($f in $sys) {
        $driverRecords += [pscustomobject]@{ package=$package.Name; name=$f.Name; bytes=$f.Length; sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
    }
}
$report = [ordered]@{ source='Windows 10 client only'; os=[ordered]@{build=$os.CurrentBuild; ubr=$os.UBR; edition=$os.EditionID}; packages=@($packages.Name); infRecords=@($records); catRecords=@($catRecords); driverRecords=@($driverRecords); win10MembershipVerification=@($verifyRecords); signtoolPresent=[bool]$signTool; catalogTrustOnServer2022='UNTESTED'; windowsServerDriverLoad='UNTESTED'; includesMicrosoftBinaries=$false; note='Local Win10 /kp verification cannot prove WinServer2022 CAT applicability; full original signed package must be checked separately in a disposable Server runner.' }
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'hfp-win10-inf-cat-metadata.json') -Encoding utf8
Write-Host "HFP_WIN10_METADATA infs=$(@($records).Count) driverstore_packages=$($packages.Count) cats=$(@($catRecords).Count) membership_checks=$(@($verifyRecords).Count) exported=JSON_ONLY"