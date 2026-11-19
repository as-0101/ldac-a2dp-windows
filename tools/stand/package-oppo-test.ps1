$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$build = Join-Path $root "build"
$driverSource = Join-Path $build "LdacA2dp/Release/LdacA2dp"
$tool = Join-Path $build "oppo-driver-tool.exe"
$package = Join-Path $build "oppo-test-package"
$zip = Join-Path $build "ldac-a2dp-oppo-server2022-test.zip"
foreach ($name in @("LdacA2dp.sys", "LdacA2dp.inf", "ldaca2dp.cat")) {
    $path = Join-Path $driverSource $name
    if (!(Test-Path $path)) { throw "Missing driver package file: $path" }
}
if (!(Test-Path $tool)) { throw "Missing installer tool: $tool" }
if (Test-Path $package) { Remove-Item $package -Recurse -Force }
New-Item $package -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $driverSource "LdacA2dp.sys") $package
Copy-Item (Join-Path $driverSource "LdacA2dp.inf") $package
Copy-Item (Join-Path $driverSource "ldaca2dp.cat") (Join-Path $package "LdacA2dp.cat")
Copy-Item $tool $package
foreach ($file in @("prepare-oppo-host.cmd", "install-oppo.cmd", "rollback-oppo.cmd", "status-oppo.cmd", "README_OPPO_TEST_RU.txt")) {
    Copy-Item (Join-Path $PSScriptRoot $file) $package
}
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=LDAC A2DP OPPO Physical Server 2022 Test Only" -CertStoreLocation "Cert:/CurrentUser/My" -KeyExportPolicy Exportable -KeyLength 2048 -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(2)
$pfx = Join-Path $env:RUNNER_TEMP "ldac-a2dp-test.pfx"
$cer = Join-Path $package "ldac-a2dp-test.cer"
$password = ConvertTo-SecureString "Physical-Server-2022-Test-Only-2026" -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $pfx -Password $password | Out-Null
Export-Certificate -Cert $cert -FilePath $cer | Out-Null
$kitRoots = @((Join-Path $env:ProgramFiles "Windows Kits/10/bin"))
$pf86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
if ($pf86) { $kitRoots += (Join-Path $pf86 "Windows Kits/10/bin") }
$signtool = $null
foreach ($kitRoot in $kitRoots) {
    if (Test-Path $kitRoot) {
        $signtool = Get-ChildItem $kitRoot -Filter signtool.exe -Recurse | Where-Object { $_.FullName.Contains("x64") -and $_.FullName.EndsWith("signtool.exe") } | Sort-Object FullName -Descending | Select-Object -First 1
        if ($signtool) { break }
    }
}
if (!$signtool) { throw "Windows SDK signtool.exe x64 was not found." }
$catalog = Join-Path $package "LdacA2dp.cat"
& $signtool.FullName sign /v /fd SHA256 /f $pfx /p "Physical-Server-2022-Test-Only-2026" $catalog
if ($LASTEXITCODE -ne 0) { throw "signtool failed with exit code $LASTEXITCODE" }
Remove-Item $pfx -Force
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $package "*") -DestinationPath $zip -CompressionLevel Optimal
Write-Host "Created test package: $zip"
Get-FileHash $zip -Algorithm SHA256 | Format-List
