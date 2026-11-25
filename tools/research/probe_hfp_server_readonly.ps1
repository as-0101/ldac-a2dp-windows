# Read-only Windows Server 2022 HFP INF/CAT/signing and runtime prerequisite inventory.
param([string]$OutputDirectory = 'evidence')
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$win = $env:windir
$keys = @('BthPort', 'BthEnum', 'BTHUSB', 'BthHfEnum', 'BthHfAud', 'BthHFSrv', 'BTAGService', 'BtaMPM', 'BthA2dp')
$service = foreach ($name in $keys) {
  $path = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
  $item = if (Test-Path -LiteralPath $path) { Get-ItemProperty -LiteralPath $path } else { $null }
  [pscustomobject]@{ name=$name; exists=($null -ne $item); start=if ($item) { $item.Start } else { $null }; type=if ($item) { $item.Type } else { $null }; image=if ($item) { $item.ImagePath } else { $null } }
}
$driverFiles = @('bthport.sys','BthHfAud.sys','BthHfEnum.sys','BtaMPM.sys')
$files = foreach ($name in $driverFiles) {
  $path = Join-Path $win "System32\drivers\$name"
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $item = Get-Item -LiteralPath $path
    $signature = Get-AuthenticodeSignature -LiteralPath $path
    [pscustomobject]@{ file=$name; present=$true; size=$item.Length; sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash; embeddedOrCatalogSignatureStatus="$($signature.Status)"; signer=if($signature.SignerCertificate){$signature.SignerCertificate.Subject}else{$null} }
  } else {
    [pscustomobject]@{ file=$name; present=$false; size=$null; sha256=$null; embeddedOrCatalogSignatureStatus='NOT_AVAILABLE'; signer=$null }
  }
}
$inf = Join-Path $win 'INF\microsoft_bluetooth_hfp.inf'
$infPresent = Test-Path -LiteralPath $inf -PathType Leaf
$store = Join-Path $win 'System32\DriverStore\FileRepository'
$hfpDirs = @(Get-ChildItem -LiteralPath $store -Directory -ErrorAction SilentlyContinue | Where-Object Name -Match '^(microsoft_bluetooth_hfp|bthhf|bthag)')
$index = foreach ($d in $hfpDirs) {
  [pscustomobject]@{ name=$d.Name; files=@(Get-ChildItem -LiteralPath $d.FullName -File -ErrorAction SilentlyContinue | ForEach-Object { [pscustomobject]@{ name=$_.Name; size=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash } }) }
}
$hfpRegistry = @(Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Enum\BTHHFENUM' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName)
$generic = @()
$bthInfPath = Join-Path $win 'INF\bth.inf'
if (Test-Path -LiteralPath $bthInfPath -PathType Leaf) {
  $generic = @(Select-String -LiteralPath $bthInfPath -Pattern '0000111e-0000-1000-8000-00805f9b34fb' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Line | Select-Object -First 8)
}
# Inspect tooling availability; do not create, import, sign, stage or load anything.
$kit = 'C:\Program Files (x86)\Windows Kits\10\bin'
$signTool = if (Test-Path -LiteralPath $kit) { Get-ChildItem -LiteralPath $kit -Filter signtool.exe -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq 'x64' } | Sort-Object FullName -Descending | Select-Object -First 1 } else { $null }
$inf2cat = if (Test-Path -LiteralPath $kit) { Get-ChildItem -LiteralPath $kit -Filter inf2cat.exe -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq 'x64' } | Sort-Object FullName -Descending | Select-Object -First 1 } else { $null }
$signToolControl = [ordered]@{ attempted=$false; exit_code=$null; last_lines=@() }
$bthPort = Join-Path $win 'System32\drivers\bthport.sys'
if ($signTool -and (Test-Path -LiteralPath $bthPort)) {
  # Verify a known present inbox transport file by its OWN catalog (never reuse this proof for HFP).
  $lines = @(& $signTool.FullName verify /kp /v /a $bthPort 2>&1 | ForEach-Object { "$_" })
  $signToolControl.attempted = $true
  $signToolControl.exit_code = $LASTEXITCODE
  $signToolControl.last_lines = @($lines | Select-Object -Last 12)
}
$report = [ordered]@{
  scope='READ_ONLY_SIGNATURE_PREFLIGHT_NOT_HFP_DRIVER_LOADING'
  environment=[ordered]@{ product=$os.ProductName; edition=$os.EditionID; installationType=$os.InstallationType; build=$os.CurrentBuild; UBR=$os.UBR; physicalHostTouched=$false }
  hfp_inf_in_windows_inf=$infPresent
  hfp_driverstore_directories=@($index)
  hfp_bthenum_root_children=@($hfpRegistry)
  services=@($service)
  driver_files=@($files)
  generic_bth_inf_uuid111e_lines=@($generic)
  sign_tool_available=[bool]$signTool
  inf2cat_available=[bool]$inf2cat
  inf2cat_server2022_target='ServerFE_X64'
  positive_control_bthport_signature=$signToolControl
  donor_hfp_cat_membership='UNTESTED_NO_GENUINE_COMPLETE_DONOR_PACKAGE'
  hfp_pnp_staging='NOT_ATTEMPTED'
  hfp_service_load='NOT_ATTEMPTED'
  hfp_endpoint='UNTESTED'
  note='SignTool /kp /a on Server BthPort (if available) validates only that file, not foreign HFP CAT compatibility.'
}
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'server-hfp-signing-gate.json') -Encoding utf8
Write-Host "HFP_SERVER_PREFLIGHT build=$($os.CurrentBuild).$($os.UBR) hfp_inf=$infPresent packages=$($hfpDirs.Count) catalog_membership=UNTESTED load=NOT_ATTEMPTED"