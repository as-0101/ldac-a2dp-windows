[CmdletBinding()]
param([string]$OutputDirectory = "build/uup-image-audit")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$AuditScript = Join-Path $RepoRoot "tools\research\audit_pe_binary.py"
if (-not (Test-Path -LiteralPath $AuditScript)) { throw "PE audit script not found: $AuditScript" }

$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$PeDirectory = Join-Path $OutputDirectory "pe-audit"
$InfReportPath = Join-Path $OutputDirectory "inf-summary.txt"
$ComponentReportPath = Join-Path $OutputDirectory "component-hits.json"
$ServerReferenceDirectory = Join-Path $OutputDirectory "server-reference"
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $PeDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $ServerReferenceDirectory -Force | Out-Null
Import-Module Dism -ErrorAction Stop

$Targets = @(
    [pscustomobject]@{ Name="server2022-20348.5761"; Role="server"; Id="008aacce-b0b7-4aeb-a3b2-43286434832c"; ExpectedBuild="20348.5761"; PreferredEdition="ServerDatacenter"; FallbackEdition="ServerStandard"; ImagePattern="Datacenter|Standard" },
    [pscustomobject]@{ Name="win10-19045.5917"; Role="win10"; Id="598d27dc-ad81-41aa-8c83-42b88e60c823"; ExpectedBuild="19045.5917"; PreferredEdition="Professional"; FallbackEdition="Professional"; ImagePattern="Professional" }
)

$TargetFileNames = @(
    "BthA2dp.sys", "BtaMPM.sys", "BthPort.sys", "BthEnum.sys", "BthLEEnum.sys",
    "BTHUSB.sys", "BthMini.sys", "ks.sys", "portcls.sys", "ntoskrnl.exe",
    "cng.sys", "WppRecorder.sys", "wdmaud.drv", "AudioEndpointBuilder.dll",
    "AudioSrv.dll", "audioeng.dll", "MMDevAPI.dll", "WMALFXGFXDSP.dll", "SysFxUI.dll"
)
$ServerReferenceNames = @(
    "ntoskrnl.exe", "cng.sys", "WppRecorder.sys", "BthPort.sys", "BthEnum.sys",
    "BthLEEnum.sys", "BTHUSB.sys", "BthMini.sys", "ks.sys", "portcls.sys",
    "wdmaud.drv", "AudioEndpointBuilder.dll", "AudioSrv.dll", "audioeng.dll",
    "MMDevAPI.dll", "WMALFXGFXDSP.dll", "SysFxUI.dll"
)
$InfNames = @(
    "microsoft_bluetooth_a2dp.inf", "microsoft_bluetooth_a2dp_src.inf",
    "microsoft_bluetooth_a2dp_snk.inf", "btampm.inf", "ks.inf",
    "wdmaudio.inf", "bth.inf", "bthusb.inf"
)
$ComponentPattern = "BthA2dp|BtaMPM|microsoft_bluetooth_a2dp|btampm|BthPort|BthEnum|BTHUSB"
$ExpectedHashes = @{
    "BthA2dp.sys|DriverStore" = "5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3"
    "BthA2dp.sys|System32" = "0442A18BBED4E323265C66561C8F8C171D8E934E9089C12B94D1DFDBB057B737"
    "BtaMPM.sys|Any" = "DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD"
}

function Invoke-UupApi {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][hashtable]$Query)
    $parts = @($Query.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$([uri]::EscapeDataString([string]$_.Value))" })
    $uri = "https://api.uupdump.net/$Name.php?" + ($parts -join "&")
    Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec 90
}

function Get-UupEdition {
    param([Parameter(Mandatory)]$Target)
    $languageInfo = Invoke-UupApi -Name "listlangs" -Query @{ id = $Target.Id }
    $languages = @($languageInfo.response.langFancyNames.PSObject.Properties.Name)
    if ($languages -notcontains "en-us") { throw "UUP build $($Target.Id) does not advertise en-us. Available: $($languages -join ', ')" }

    $editionInfo = Invoke-UupApi -Name "listeditions" -Query @{ id = $Target.Id; lang = "en-us" }
    $editions = @($editionInfo.response.editionFancyNames.PSObject.Properties.Name)
    $edition = $Target.PreferredEdition
    if ($editions -notcontains $edition) { $edition = $Target.FallbackEdition }
    if ($editions -notcontains $edition) { throw "Required UUP edition not found for $($Target.Name). Available: $($editions -join ', ')" }
    [pscustomobject]@{ Edition=$edition; AvailableEditions=$editions; AvailableLanguages=$languages }
}

function Download-UupIso {
    param([Parameter(Mandatory)]$Target, [Parameter(Mandatory)][string]$WorkDirectory)
    New-Item -ItemType Directory -Path $WorkDirectory -Force | Out-Null
    $selection = Get-UupEdition -Target $Target
    $edition = $selection.Edition
    $packageUrl = "https://uupdump.net/get.php?id=$($Target.Id)&pack=en-us&edition=$([uri]::EscapeDataString($edition))"
    $packageZip = Join-Path $WorkDirectory "uup-download-package.zip"

    Write-Host "Downloading UUP package: $($Target.Name), edition=$edition, id=$($Target.Id)"
    Invoke-WebRequest -Method Post -Uri $packageUrl -Body @{ autodl="2"; updates="1"; cleanup="1" } -OutFile $packageZip -TimeoutSec 180 -MaximumRedirection 10
    Expand-Archive -LiteralPath $packageZip -DestinationPath $WorkDirectory -Force
    Remove-Item -LiteralPath $packageZip -Force

    $downloadCommand = Get-ChildItem -LiteralPath $WorkDirectory -Filter "uup_download_windows.cmd" -File -Recurse | Select-Object -First 1
    if (-not $downloadCommand) { throw "UUP download package did not contain uup_download_windows.cmd: $WorkDirectory" }
    $commandDirectory = $downloadCommand.Directory.FullName
    $convertConfig = Join-Path $commandDirectory "ConvertConfig.ini"
    if (Test-Path -LiteralPath $convertConfig) {
        $configText = Get-Content -LiteralPath $convertConfig -Raw
        $configText = $configText -replace "(?m)^(AutoExit\s*)=.*$", '$1=1'
        $configText = $configText -replace "(?m)^(ResetBase\s*)=.*$", '$1=1'
        $configText = $configText -replace "(?m)^(SkipWinRE\s*)=.*$", '$1=1'
        Set-Content -LiteralPath $convertConfig -Value $configText -Encoding ascii
    }

    Write-Host "Running UUP download/conversion in $commandDirectory"
    $process = Start-Process -FilePath $env:ComSpec -ArgumentList @("/c", "uup_download_windows.cmd") -WorkingDirectory $commandDirectory -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) { throw "uup_download_windows.cmd failed for $($Target.Name), exit=$($process.ExitCode)" }

    $iso = Get-ChildItem -LiteralPath $commandDirectory -Filter "*.iso" -File -Recurse | Sort-Object Length -Descending | Select-Object -First 1
    if (-not $iso) { throw "UUP conversion completed without producing an ISO for $($Target.Name)" }
    [pscustomobject]@{
        Edition=$edition
        AvailableEditions=$selection.AvailableEditions
        AvailableLanguages=$selection.AvailableLanguages
        PackageUrl=$packageUrl
        IsoPath=$iso.FullName
        IsoSha256=(Get-FileHash -LiteralPath $iso.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        IsoSizeBytes=$iso.Length
    }
}

function Get-ExpectedHash {
    param([Parameter(Mandatory)][System.IO.FileInfo]$File, [Parameter(Mandatory)][string]$RelativePath)
    if ($File.Name -ieq "BthA2dp.sys") {
        if ($RelativePath -match "DriverStore\\FileRepository") { return $ExpectedHashes["BthA2dp.sys|DriverStore"] }
        if ($RelativePath -match "System32\\drivers") { return $ExpectedHashes["BthA2dp.sys|System32"] }
    }
    if ($File.Name -ieq "BtaMPM.sys") { return $ExpectedHashes["BtaMPM.sys|Any"] }
    return $null
}

function Get-SignatureRecord {
    param([Parameter(Mandatory)][string]$Path)
    try {
        $signature = Get-AuthenticodeSignature -FilePath $Path
        [pscustomobject]@{
            status=[string]$signature.Status
            statusMessage=[string]$signature.StatusMessage
            signerSubject=if ($signature.SignerCertificate) { $signature.SignerCertificate.Subject } else { $null }
            signerThumbprint=if ($signature.SignerCertificate) { $signature.SignerCertificate.Thumbprint } else { $null }
            note="Embedded Authenticode only; catalog membership is evaluated separately."
        }
    } catch {
        [pscustomobject]@{ status="error"; statusMessage=$_.Exception.Message; signerSubject=$null; signerThumbprint=$null; note="Embedded signature query failed." }
    }
}

function Get-PeAudit {
    param([Parameter(Mandatory)][System.IO.FileInfo]$File, [Parameter(Mandatory)][string]$Role, [Parameter(Mandatory)][string]$Hash, [string]$ReferenceDirectory)
    if ($File.Extension -notin @(".sys", ".dll", ".exe", ".drv")) { return $null }
    $name = "$Role-$($File.Name)-$($Hash.Substring(0,12)).json"
    $output = Join-Path $PeDirectory $name
    $arguments = @($AuditScript, "--input", $File.FullName, "--output", $output)
    if ($ReferenceDirectory -and (Test-Path -LiteralPath $ReferenceDirectory)) { $arguments += @("--reference-dir", $ReferenceDirectory) }
    & python @arguments
    if ($LASTEXITCODE -ne 0) { throw "PE audit failed for $($File.FullName), exit=$LASTEXITCODE" }
    [System.IO.Path]::GetFileName($output)
}

function Get-InfSummary {
    param([Parameter(Mandatory)][string]$MountDirectory, [Parameter(Mandatory)][string]$Role)
    $roots = @((Join-Path $MountDirectory "Windows\System32\DriverStore\FileRepository"), (Join-Path $MountDirectory "Windows\INF"))
    $found = foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -Filter "*.inf" -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $InfNames -contains $_.Name }
        }
    }
    $records = @()
    foreach ($inf in ($found | Sort-Object FullName -Unique)) {
        $hash = (Get-FileHash -LiteralPath $inf.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        $relative = $inf.FullName.Substring($MountDirectory.Length).TrimStart("\")
        $lines = Get-Content -LiteralPath $inf.FullName
        $selected = @($lines | Where-Object {
            $_ -match "^\s*\[.*\]\s*$" -or
            $_ -match "^\s*(Class|ClassGuid|Provider|DriverVer|CatalogFile[^=]*|Include|Needs|AddService|ServiceBinary|AddReg|CopyFiles|AddInterface|ServiceType|StartType|LoadOrderGroup|Characteristics)\s*=" -or
            $_ -match "BTHENUM|KSCATEGORY|BthA2dp|BtaMPM|MSSysFx"
        })
        $records += [pscustomobject]@{ role=$Role; path=$relative; sizeBytes=$inf.Length; sha256=$hash; selectedLines=$selected }
    }
    return $records
}

function Get-ComponentHits {
    param([Parameter(Mandatory)][string]$MountDirectory, [Parameter(Mandatory)][string]$Role)
    $manifestRoot = Join-Path $MountDirectory "Windows\WinSxS\Manifests"
    $mumRoot = Join-Path $MountDirectory "Windows\servicing\Packages"
    $hits = @()
    if (Test-Path -LiteralPath $manifestRoot) {
        $manifestFiles = Get-ChildItem -LiteralPath $manifestRoot -Filter "*.manifest" -File | Where-Object { $_.Name -match "btha2dp|btampm|bluetooth_a2dp|bthport|bthenum|bthusb" }
        foreach ($file in $manifestFiles) {
            $matches = Select-String -LiteralPath $file.FullName -Pattern $ComponentPattern -ErrorAction SilentlyContinue
            foreach ($match in $matches) {
                $hits += [pscustomobject]@{ role=$Role; kind="component-manifest"; file=$file.Name; lineNumber=$match.LineNumber; line=$match.Line.Trim() }
            }
        }
    }
    if (Test-Path -LiteralPath $mumRoot) {
        $mumFiles = Get-ChildItem -LiteralPath $mumRoot -Filter "*.mum" -File
        $matches = Select-String -Path $mumFiles.FullName -Pattern $ComponentPattern -ErrorAction SilentlyContinue
        foreach ($match in $matches) {
            $hits += [pscustomobject]@{ role=$Role; kind="CBS-MUM"; file=[System.IO.Path]::GetFileName($match.Path); lineNumber=$match.LineNumber; line=$match.Line.Trim() }
        }
    }
    return $hits
}

function Get-CatalogSummary {
    param([Parameter(Mandatory)][string]$MountDirectory, [Parameter(Mandatory)][string]$Role)
    $driverStore = Join-Path $MountDirectory "Windows\System32\DriverStore\FileRepository"
    if (-not (Test-Path -LiteralPath $driverStore)) { return @() }
    $packageDirectories = Get-ChildItem -LiteralPath $driverStore -Directory | Where-Object { $_.Name -match "microsoft_bluetooth_a2dp|btampm" }
    $records = @()
    foreach ($directory in $packageDirectories) {
        $cats = Get-ChildItem -LiteralPath $directory.FullName -Filter "*.cat" -File -Recurse -ErrorAction SilentlyContinue
        foreach ($cat in $cats) {
            $hash = (Get-FileHash -LiteralPath $cat.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
            $records += [pscustomobject]@{
                role=$Role
                packageDirectory=$directory.Name
                path=$cat.FullName.Substring($MountDirectory.Length).TrimStart("\")
                sizeBytes=$cat.Length
                sha256=$hash
                embeddedSignature=Get-SignatureRecord -Path $cat.FullName
            }
        }
    }
    return $records
}

function Collect-Image {
    param([Parameter(Mandatory)]$Target, [Parameter(Mandatory)][string]$WorkDirectory)
    $download = Download-UupIso -Target $Target -WorkDirectory $WorkDirectory
    $disk = $null
    $mountDirectory = Join-Path $WorkDirectory "mounted-image"
    New-Item -ItemType Directory -Path $mountDirectory -Force | Out-Null

    try {
        $disk = Mount-DiskImage -ImagePath $download.IsoPath -PassThru
        $volume = $disk | Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
        if (-not $volume) { throw "Could not resolve mounted ISO volume for $($Target.Name)" }

        $sources = Join-Path "$($volume.DriveLetter):\" "sources"
        $imagePath = Join-Path $sources "install.wim"
        if (-not (Test-Path -LiteralPath $imagePath)) { $imagePath = Join-Path $sources "install.esd" }
        if (-not (Test-Path -LiteralPath $imagePath)) { throw "No install.wim/install.esd found in $sources" }

        $images = @(Get-WindowsImage -ImagePath $imagePath)
        $selected = if ($Target.Role -eq "win10") {
            $images | Where-Object { $_.ImageName -match "Professional" } | Select-Object -First 1
        } else {
            $images | Where-Object { $_.ImageName -match "Datacenter" } | Select-Object -First 1
        }
        if (-not $selected) { $selected = $images | Where-Object { $_.ImageName -match $Target.ImagePattern } | Select-Object -First 1 }
        if (-not $selected) { throw "Could not select edition for $($Target.Name). Available: $($images.ImageName -join '; ')" }
        if ($selected.Version -and ([string]$selected.Version -notmatch [regex]::Escape($Target.ExpectedBuild))) {
            throw "Image version mismatch for $($Target.Name): expected $($Target.ExpectedBuild), got $($selected.Version)"
        }

        Write-Host "Mounting $($Target.Name): $($selected.ImageName), version=$($selected.Version)"
        Mount-WindowsImage -ImagePath $imagePath -Index $selected.ImageIndex -Path $mountDirectory -ReadOnly | Out-Null
        try {
            $searchRoots = @(
                (Join-Path $mountDirectory "Windows\System32\drivers"),
                (Join-Path $mountDirectory "Windows\System32"),
                (Join-Path $mountDirectory "Windows\System32\DriverStore\FileRepository")
            )
            $allFiles = foreach ($root in $searchRoots) {
                if (Test-Path -LiteralPath $root) { Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue }
            }
            $matchedFiles = @($allFiles | Where-Object { $TargetFileNames -contains $_.Name } | Sort-Object FullName -Unique)

            $fileRecords = @()
            foreach ($file in $matchedFiles) {
                $relative = $file.FullName.Substring($mountDirectory.Length).TrimStart("\")
                $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
                $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($file.FullName)
                $expected = Get-ExpectedHash -File $file -RelativePath $relative
                $expectedMatch = if ($expected) { $hash -eq $expected } else { $null }
                $reference = if ($Target.Role -eq "win10") { $ServerReferenceDirectory } else { $null }
                $peReport = Get-PeAudit -File $file -Role $Target.Role -Hash $hash -ReferenceDirectory $reference
                $fileRecords += [pscustomobject]@{
                    role=$Target.Role
                    path=$relative
                    name=$file.Name
                    sizeBytes=$file.Length
                    sha256=$hash
                    fileVersion=$version.FileVersion
                    productVersion=$version.ProductVersion
                    companyName=$version.CompanyName
                    expectedSha256=$expected
                    expectedHashMatch=$expectedMatch
                    embeddedSignature=Get-SignatureRecord -Path $file.FullName
                    peAudit=$peReport
                }
            }

            if ($Target.Role -eq "server") {
                foreach ($name in $ServerReferenceNames) {
                    $candidates = @($matchedFiles | Where-Object { $_.Name -ieq $name })
                    if ($name -match "\.(sys|drv)$") {
                        $preferred = @($candidates | Where-Object { $_.FullName -like "*\Windows\System32\drivers\*" })
                    } else {
                        $preferred = @($candidates | Where-Object { $_.FullName -like "*\Windows\System32\*" })
                    }
                    if (-not $preferred) { $preferred = $candidates }
                    $source = $preferred | Select-Object -First 1
                    if ($source) { Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $ServerReferenceDirectory $name) -Force }
                }
            }

            $infRecords = Get-InfSummary -MountDirectory $mountDirectory -Role $Target.Role
            $componentHits = Get-ComponentHits -MountDirectory $mountDirectory -Role $Target.Role
            $catalogRecords = Get-CatalogSummary -MountDirectory $mountDirectory -Role $Target.Role

            [pscustomobject]@{
                name=$Target.Name
                role=$Target.Role
                expectedBuild=$Target.ExpectedBuild
                selectedEdition=$download.Edition
                availableEditions=$download.AvailableEditions
                availableLanguages=$download.AvailableLanguages
                uupId=$Target.Id
                uupPackageUrl=$download.PackageUrl
                isoSha256=$download.IsoSha256
                isoSizeBytes=$download.IsoSizeBytes
                imageName=$selected.ImageName
                imageVersion=[string]$selected.Version
                imageIndex=$selected.ImageIndex
                files=$fileRecords
                infs=$infRecords
                componentHits=$componentHits
                catalogs=$catalogRecords
            }
        } finally {
            Dismount-WindowsImage -Path $mountDirectory -Discard -ErrorAction SilentlyContinue | Out-Null
        }
    } finally {
        if ($disk) { Dismount-DiskImage -ImagePath $download.IsoPath -ErrorAction SilentlyContinue | Out-Null }
        Remove-Item -LiteralPath $WorkDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$results = @()
$allInfLines = @()
$allComponentHits = @()
foreach ($target in $Targets) {
    $workDirectory = Join-Path $OutputDirectory ("work-" + $target.Role)
    $result = Collect-Image -Target $target -WorkDirectory $workDirectory
    $results += $result
    foreach ($inf in $result.infs) {
        $allInfLines += "## $($result.name) :: $($inf.path)"
        $allInfLines += "SHA-256: $($inf.sha256)"
        $allInfLines += $inf.selectedLines
        $allInfLines += ""
    }
    $allComponentHits += $result.componentHits
}

$manifest = [ordered]@{
    generatedUtc=(Get-Date).ToUniversalTime().ToString("o")
    githubRunId=$env:GITHUB_RUN_ID
    githubSha=$env:GITHUB_SHA
    scope="Offline UUP image extraction and static PE analysis only. No package installation, driver load, device enumeration, audio test, or physical-host access."
    expectedCapturedHashes=$ExpectedHashes
    images=$results
}
$manifest | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $OutputDirectory "manifest.json") -Encoding utf8
$allInfLines | Set-Content -LiteralPath $InfReportPath -Encoding utf8
$allComponentHits | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $ComponentReportPath -Encoding utf8

@"
# UUP image A2DP component audit

- Win10 reference image: 19045.5917 x64, UUP ID 598d27dc-ad81-41aa-8c83-42b88e60c823.
- Server target image: 20348.5761 x64, UUP ID 008aacce-b0b7-4aeb-a3b2-43286434832c.
- Source: UUP dump download packages; payloads are fetched from Microsoft's update infrastructure. UUP dump is an independent third-party service, not Microsoft.
- The selected image version is checked before extracting files.
- SHA-256 comparisons are made against the already-recorded Win10 archive hashes.
- PE reports include imports, delay imports, exports, API-set imports and a static comparison of Win10 imports against Server 2022 exports.
- Catalog membership is not inferred from Get-AuthenticodeSignature on SYS files. INF/CAT and CBS/WinSxS hits are recorded separately.
- No Microsoft binary payloads or ISO files are uploaded by this workflow; only metadata and text reports are retained.
- Static export presence does not prove driver load or runtime compatibility.
"@ | Set-Content -LiteralPath (Join-Path $OutputDirectory "README.md") -Encoding utf8

Remove-Item -LiteralPath $ServerReferenceDirectory -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "UUP image audit complete. Manifest: $(Join-Path $OutputDirectory 'manifest.json')"
