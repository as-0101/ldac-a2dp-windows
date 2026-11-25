param([Parameter(Mandatory)][string]$MountDirectory,[Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$windows = Join-Path $MountDirectory 'Windows'
$store = Join-Path $windows 'System32\DriverStore\FileRepository'
$packages = @(Get-ChildItem -LiteralPath $store -Directory | Where-Object Name -match '^(microsoft_bluetooth_hfp|bthhf|bthag)')
if (!$packages.Count) { throw 'HFP DriverStore positive control absent from donor' }
$infs = @(Get-ChildItem -LiteralPath (Join-Path $windows 'INF') -File | Where-Object Name -match '^(microsoft_bluetooth_hfp|bthhf|bthag).*\.inf$')
$files = @($packages | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -File -Recurse })
$payload = @(Get-ChildItem -LiteralPath (Join-Path $windows 'System32'),(Join-Path $windows 'System32\drivers') -File | Where-Object Name -match '^(bthhf|bthag)')
$infRecords = foreach ($inf in @($infs + @($files | Where-Object Extension -eq '.inf'))) {
  $sec = ''
  $selected = foreach ($line in (Get-Content -LiteralPath $inf.FullName)) {
    if ($line -match '^\s*\[([^\]]+)\]') { $sec = $Matches[1] }
    if ($line -match '^\s*(Include|Needs|CopyFiles|CopyINF|AddService|ServiceBinary|CatalogFile(?:\.[\w.]+)?)\s*=|BTHHFENUM\\|0000111e-') {
      [ordered]@{ section=$sec; entry=$line.Trim() }
    }
  }
  [ordered]@{ name=$inf.Name; path=$inf.FullName.Substring($MountDirectory.Length+1); directives=@($selected) }
}
$peScript = Join-Path $PSScriptRoot 'audit_pe_binary.py'
$peDir = Join-Path $OutputDirectory 'hfp-pe'
New-Item -Path $peDir -ItemType Directory -Force | Out-Null
$hasBthHfAud = $false
$hashes = foreach ($file in @($files + $payload | Sort-Object FullName -Unique)) {
  if ($file.Name -ieq 'BthHfAud.sys') { $hasBthHfAud = $true }
  $sha=(Get-FileHash -LiteralPath $file.FullName).Hash
  if ($file.Extension -in '.sys','.dll') {
    $report=Join-Path $peDir ($file.Name+'-'+$sha.Substring(0,12)+'.json')
    if (!(Test-Path -LiteralPath $report)) {
      & python $peScript --input $file.FullName --output $report
      if ($LASTEXITCODE) { throw "PE parser failed for $($file.Name)" }
    }
  }
  [ordered]@{ path=$file.FullName.Substring($MountDirectory.Length+1); sha256=$sha; bytes=$file.Length }
}
if (!$hasBthHfAud) { throw 'BthHfAud positive control absent' }
[ordered]@{ packages=@($packages.Name); files=@($hashes); infs=@($infRecords) } | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $OutputDirectory 'hfp-donor.json')
"HFP_DONOR packages=$($packages.Count) files=$(@($hashes).Count) infs=$(@($infRecords).Count)"
