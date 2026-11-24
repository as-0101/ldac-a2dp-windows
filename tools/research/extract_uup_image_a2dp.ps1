[CmdletBinding()]
param(
    [string]$OutputDirectory = "build/uup-image-audit",
    [switch]$Win10Only,
    [switch]$StagePackageOnRunner
)

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
$Win10PackageFilesDirectory = Join-Path $OutputDirectory "win10-package-files"
$StagePackageDirectory = Join-Path $OutputDirectory "stage-package"
$StageTestReportPath = Join-Path $OutputDirectory "stage-test.json"
$ExpectedWin10CatalogName = "Microsoft-Windows-Client-Desktop-Required-Package~31bf3856ad364e35~amd64~~10.0.19041.5917.cat"
$ExpectedWin10CatalogSha256 = "78772FA12959C072D687283F08D08367B8A8EF1A2F07D7B72F20BCAFD12483BF"
$script:Win10CatalogTargetFiles = @()
$script:StagePackageFiles = @()
$script:StagePackageCatalogPath = $null
$script:StageTestResult = $null
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $PeDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $ServerReferenceDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $Win10PackageFilesDirectory -Force | Out-Null
if ($StagePackageOnRunner -and -not $Win10Only) { throw "-StagePackageOnRunner requires -Win10Only; the target runner supplies the Server 2022 environment." }
if ($StagePackageOnRunner -and $env:GITHUB_ACTIONS -ne "true") { throw "Package staging is permitted only on a disposable GitHub-hosted runner." }
if ($StagePackageOnRunner) { New-Item -ItemType Directory -Path $StagePackageDirectory -Force | Out-Null }
Import-Module Dism -ErrorAction Stop

$Targets = @(
    # Win10 is mounted first so its exact signed A2DP package files can be
    # retained temporarily and checked against the Server 2022 catalog set.
    [pscustomobject]@{ Name="win10-19045.5917"; Role="win10"; Id="598d27dc-ad81-41aa-8c83-42b88e60c823"; ExpectedBuild="19045.5917"; ExpectedEditionId="Professional"; PreferredEdition="Professional"; FallbackEdition="Professional"; ImagePattern="Pro|Professional" },
    [pscustomobject]@{ Name="server2022-20348.5761"; Role="server"; Id="008aacce-b0b7-4aeb-a3b2-43286434832c"; ExpectedBuild="20348.5761"; ExpectedEditionId="ServerDatacenter"; PreferredEdition="ServerDatacenter"; FallbackEdition="ServerStandard"; ImagePattern="Datacenter|Standard" }
)

$TargetFileNames = @(
    "BthA2dp.sys", "BtaMPM.sys", "BthPort.sys", "BthEnum.sys", "BthLEEnum.sys",
    "BTHUSB.sys", "BthMini.sys", "ks.sys", "portcls.sys", "ntoskrnl.exe",
    "HAL.dll", "SleepStudyHelper.sys", "WDFLDR.SYS", "ksecdd.sys",
    "cng.sys", "WppRecorder.sys", "wdmaud.drv", "AudioEndpointBuilder.dll",
    "AudioSrv.dll", "audioeng.dll", "MMDevAPI.dll", "WMALFXGFXDSP.dll", "SysFxUI.dll"
)
$ServerReferenceNames = @(
    "ntoskrnl.exe", "HAL.dll", "cng.sys", "WppRecorder.sys", "SleepStudyHelper.sys",
    "WDFLDR.SYS", "ksecdd.sys", "BthPort.sys", "BthEnum.sys",
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
    "microsoft_bluetooth_a2dp.inf|Any" = "4F3B988B658E1E7F8B97E645C1C92BE0BA270D4DB76832DAB871516EEDCBCF0C"
    "microsoft_bluetooth_a2dp_src.inf|Any" = "B97D1DD53BB6FD040CE5C2527015A09416C29FCBD6B528802D595CBDEEAD4A6A"
    "btampm.inf|Any" = "C657A6B32AC8CCFDEEF3C12630686B87C973DD114BEE73AEC288D86B989961EF"
}

function Invoke-UupApi {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][hashtable]$Query)
    $parts = @($Query.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$([uri]::EscapeDataString([string]$_.Value))" })
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

    # The UUP helper package's get_aria2.ps1 can run under a reduced child PowerShell
    # environment where Get-FileHash is not auto-loaded. Prefer Windows PowerShell 5.1
    # and provide a narrow SHA-256 compatibility function in that helper only.
    $windowsPowerShellDirectory = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0"
    if (Test-Path -LiteralPath $windowsPowerShellDirectory) {
        $env:PATH = "$windowsPowerShellDirectory;$env:PATH"
    }
    $ariaScript = Get-ChildItem -LiteralPath $WorkDirectory -Filter "get_aria2.ps1" -File -Recurse | Select-Object -First 1
    if ($ariaScript) {
        $ariaText = Get-Content -LiteralPath $ariaScript.FullName -Raw
        if ($ariaText -match "Get-FileHash") {
            $hashShim = @'
function Get-FileHash {
    param([Alias("LiteralPath")][string]$Path, [string]$Algorithm = "SHA256")
    if ($Algorithm -ne "SHA256") { throw "UUP helper hash shim supports SHA256 only." }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hex = [System.BitConverter]::ToString($sha.ComputeHash($stream)).Replace("-", "")
        [pscustomobject]@{ Algorithm = $Algorithm; Hash = $hex; Path = $Path }
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}
'@
            Set-Content -LiteralPath $ariaScript.FullName -Value ($hashShim + "`r`n" + $ariaText) -Encoding ascii
        }
    }

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
    if ($File.Name -ieq "microsoft_bluetooth_a2dp.inf") { return $ExpectedHashes["microsoft_bluetooth_a2dp.inf|Any"] }
    if ($File.Name -ieq "microsoft_bluetooth_a2dp_src.inf") { return $ExpectedHashes["microsoft_bluetooth_a2dp_src.inf|Any"] }
    if ($File.Name -ieq "btampm.inf") { return $ExpectedHashes["btampm.inf|Any"] }
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
        $mumFiles = @(Get-ChildItem -LiteralPath $mumRoot -Filter "*.mum" -File)
        $matches = if ($mumFiles.Count -gt 0) { Select-String -Path $mumFiles.FullName -Pattern $ComponentPattern -ErrorAction SilentlyContinue } else { @() }
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

function Get-OfflineImageIdentity {
    param(
        [Parameter(Mandatory)][string]$MountDirectory,
        [Parameter(Mandatory)][string]$WorkDirectory,
        [Parameter(Mandatory)]$Target
    )
    $sourceHive = Join-Path $MountDirectory "Windows\System32\Config\SOFTWARE"
    if (-not (Test-Path -LiteralPath $sourceHive)) { throw "Offline SOFTWARE hive not found: $sourceHive" }

    # DISM mounts the WIM read-only. Load a temporary copy so the registry
    # manager can open it without modifying the source image.
    $hiveCopy = Join-Path $WorkDirectory "SOFTWARE.audit.hiv"
    Copy-Item -LiteralPath $sourceHive -Destination $hiveCopy -Force
    $hiveName = "LDAC_UUP_AUDIT_SOFTWARE"
    $loaded = $false
    try {
        $loadOutput = & reg.exe load "HKLM\$hiveName" $hiveCopy 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Could not load offline SOFTWARE hive (exit=$LASTEXITCODE): $($loadOutput -join ' ')"
        }
        $loaded = $true
        $key = "Registry::HKEY_LOCAL_MACHINE\$hiveName\Microsoft\Windows NT\CurrentVersion"
        $current = Get-ItemProperty -LiteralPath $key
        $build = [string]$current.CurrentBuild
        if ([string]::IsNullOrWhiteSpace($build)) { $build = [string]$current.CurrentBuildNumber }
        if ($null -eq $current.UBR) { throw "Offline SOFTWARE hive has no UBR value for $($Target.Name)" }
        $ubr = [int]$current.UBR
        $editionId = [string]$current.EditionID
        $imageVersion = "$build.$ubr"

        if ($imageVersion -ne $Target.ExpectedBuild) {
            throw "Mounted image version mismatch for $($Target.Name): expected $($Target.ExpectedBuild), got $imageVersion"
        }
        if ($Target.ExpectedEditionId -and $editionId -ne $Target.ExpectedEditionId) {
            throw "Mounted image edition mismatch for $($Target.Name): expected $($Target.ExpectedEditionId), got $editionId"
        }

        return [pscustomobject]@{
            imageVersion = $imageVersion
            currentBuild = $build
            ubr = $ubr
            editionId = $editionId
            productName = [string]$current.ProductName
            installationType = [string]$current.InstallationType
            buildLabEx = [string]$current.BuildLabEx
            registrySource = "Offline SOFTWARE hive copied from mounted WIM; read-only source image"
        }
    } finally {
        if ($loaded) {
            & reg.exe unload "HKLM\$hiveName" 2>&1 | Out-Null
        }
        Remove-Item -LiteralPath $hiveCopy -Force -ErrorAction SilentlyContinue
    }
}


function Get-OptionalPropertyValue {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )
    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

# Strict-mode regression guard: registry objects do not all expose ServiceDll.
$optionalPropertyProbe = [pscustomobject]@{ Type = 1; Start = 3 }
if ($null -ne (Get-OptionalPropertyValue -InputObject $optionalPropertyProbe -Name "ServiceDll")) {
    throw "Optional registry-property helper returned a value for an absent property."
}
if ((Get-OptionalPropertyValue -InputObject $optionalPropertyProbe -Name "Start") -ne 3) {
    throw "Optional registry-property helper failed to return a present property."
}

function Get-OfflineServiceSummary {
    param(
        [Parameter(Mandatory)][string]$MountDirectory,
        [Parameter(Mandatory)][string]$WorkDirectory,
        [Parameter(Mandatory)][string]$Role
    )
    $sourceHive = Join-Path $MountDirectory "Windows\System32\Config\SYSTEM"
    if (-not (Test-Path -LiteralPath $sourceHive)) { throw "Offline SYSTEM hive not found: $sourceHive" }
    $hiveCopy = Join-Path $WorkDirectory "SYSTEM.audit.hiv"
    Copy-Item -LiteralPath $sourceHive -Destination $hiveCopy -Force
    $hiveName = "LDAC_UUP_AUDIT_SYSTEM_$Role"
    $loaded = $false
    try {
        $loadOutput = & reg.exe load "HKLM\$hiveName" $hiveCopy 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Could not load offline SYSTEM hive (exit=$LASTEXITCODE): $($loadOutput -join ' ')" }
        $loaded = $true
        $selectPath = "Registry::HKEY_LOCAL_MACHINE\$hiveName\Select"
        $select = Get-ItemProperty -LiteralPath $selectPath
        $currentValue = Get-OptionalPropertyValue -InputObject $select -Name "Current"
        if ($null -eq $currentValue) { throw "Offline SYSTEM hive has no Select\Current value." }
        $current = [int]$currentValue
        $controlSet = "ControlSet{0:D3}" -f $current
        $serviceNames = @("BthA2dp", "BtaMPM", "BthPort", "BthEnum", "BTHUSB", "AudioSrv", "AudioEndpointBuilder")
        $records = foreach ($serviceName in $serviceNames) {
            $servicePath = "Registry::HKEY_LOCAL_MACHINE\$hiveName\$controlSet\Services\$serviceName"
            if (Test-Path -LiteralPath $servicePath) {
                $item = Get-ItemProperty -LiteralPath $servicePath
                $parametersPath = Join-Path $servicePath "Parameters"
                $serviceDll = $null
                if (Test-Path -LiteralPath $parametersPath) {
                    $parameters = Get-ItemProperty -LiteralPath $parametersPath
                    $serviceDll = Get-OptionalPropertyValue -InputObject $parameters -Name "ServiceDll"
                }
                $typeValue = Get-OptionalPropertyValue -InputObject $item -Name "Type"
                $startValue = Get-OptionalPropertyValue -InputObject $item -Name "Start"
                $imagePathValue = Get-OptionalPropertyValue -InputObject $item -Name "ImagePath"
                $groupValue = Get-OptionalPropertyValue -InputObject $item -Name "Group"
                $dependOnServiceValue = Get-OptionalPropertyValue -InputObject $item -Name "DependOnService"
                [pscustomobject]@{
                    role=$Role
                    controlSet=$controlSet
                    service=$serviceName
                    exists=$true
                    type=if ($null -ne $typeValue) { [int]$typeValue } else { $null }
                    start=if ($null -ne $startValue) { [int]$startValue } else { $null }
                    imagePath=if ($null -ne $imagePathValue) { [string]$imagePathValue } else { $null }
                    group=if ($null -ne $groupValue) { [string]$groupValue } else { $null }
                    dependOnService=if ($null -ne $dependOnServiceValue) { @($dependOnServiceValue) } else { @() }
                    serviceDll=if ($null -ne $serviceDll) { [string]$serviceDll } else { $null }
                    source="copied offline SYSTEM hive; read-only source image"
                }
            } else {
                [pscustomobject]@{
                    role=$Role
                    controlSet=$controlSet
                    service=$serviceName
                    exists=$false
                    type=$null
                    start=$null
                    imagePath=$null
                    group=$null
                    dependOnService=@()
                    serviceDll=$null
                    source="copied offline SYSTEM hive; read-only source image"
                }
            }
        }
        return $records
    } finally {
        if ($loaded) { & reg.exe unload "HKLM\$hiveName" 2>&1 | Out-Null }
        Remove-Item -LiteralPath $hiveCopy -Force -ErrorAction SilentlyContinue
    }
}

function Get-TargetCatalogMembership {
    param([Parameter(Mandatory)][string]$MountDirectory, [Parameter(Mandatory)][string]$Role)

    $driverStore = Join-Path $MountDirectory "Windows\System32\DriverStore\FileRepository"
    $infRoot = Join-Path $MountDirectory "Windows\INF"
    $targetSpecs = @(
        @{ name="BthA2dp.sys"; pattern="microsoft_bluetooth_a2dp.inf_amd64"; policy="/kp" },
        @{ name="BtaMPM.sys"; pattern="btampm.inf_amd64"; policy="/kp" },
        @{ name="microsoft_bluetooth_a2dp.inf"; pattern="microsoft_bluetooth_a2dp.inf_amd64"; policy="/pa" },
        @{ name="microsoft_bluetooth_a2dp_src.inf"; pattern="microsoft_bluetooth_a2dp_src.inf_amd64"; policy="/pa" },
        @{ name="btampm.inf"; pattern="btampm.inf_amd64"; policy="/pa" }
    )
    $targets = @()

    if ($Role -eq "win10") {
        foreach ($spec in $targetSpecs) {
            $roots = @($driverStore, $infRoot)
            $matches = foreach ($root in $roots) {
                if (Test-Path -LiteralPath $root) {
                    Get-ChildItem -LiteralPath $root -Filter $spec.name -File -Recurse -ErrorAction SilentlyContinue |
                        Where-Object {
                            if ($spec.pattern) { $_.FullName -match [regex]::Escape($spec.pattern) } else { $true }
                        }
                }
            }
            $file = $matches |
                Sort-Object @{Expression={ if ($_.FullName -match "\\DriverStore\\FileRepository\\") { 0 } else { 1 } }}, FullName |
                Select-Object -First 1
            if ($file) {
                $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
                $copyName = "{0}-{1}{2}" -f $file.BaseName, $hash.Substring(0, 12), $file.Extension
                $copyPath = Join-Path $Win10PackageFilesDirectory $copyName
                Copy-Item -LiteralPath $file.FullName -Destination $copyPath -Force
                if ($StagePackageOnRunner) {
                    $stageCopyPath = Join-Path $StagePackageDirectory $spec.name
                    Copy-Item -LiteralPath $file.FullName -Destination $stageCopyPath -Force
                    $stageCopyHash = (Get-FileHash -LiteralPath $stageCopyPath -Algorithm SHA256).Hash.ToUpperInvariant()
                    if ($stageCopyHash -ne $hash) { throw "Staging copy hash mismatch for $($spec.name): $stageCopyHash != $hash" }
                    $script:StagePackageFiles += [pscustomobject]@{ name=$spec.name; sourcePath=$file.FullName; stagedPath=$stageCopyPath; sha256=$stageCopyHash }
                }
                $targets += [pscustomobject]@{
                    name=$spec.name
                    sourceRole="win10"
                    sourcePath=$file.FullName.Substring($MountDirectory.Length).TrimStart("\")
                    fullPath=$file.FullName
                    copyPath=("win10-package-files\" + $copyName)
                    sha256=$hash
                    policy=$spec.policy
                    missing=$false
                }
            } else {
                $targets += [pscustomobject]@{
                    name=$spec.name; sourceRole="win10"; sourcePath=$null
                    fullPath=$null; copyPath=$null; sha256=$null
                    policy=$spec.policy; missing=$true
                }
            }
        }
        $script:Win10CatalogTargetFiles = $targets
    }
    elseif ($Role -eq "server") {
        foreach ($source in @($script:Win10CatalogTargetFiles)) {
            $copyFullPath = if ($source.copyPath) { Join-Path $OutputDirectory $source.copyPath } else { $null }
            $targets += [pscustomobject]@{
                name=$source.name
                sourceRole="win10"
                sourcePath=$source.sourcePath
                fullPath=$copyFullPath
                copyPath=$source.copyPath
                sha256=$source.sha256
                policy=$source.policy
                missing=($null -eq $copyFullPath -or -not (Test-Path -LiteralPath $copyFullPath))
            }
        }

        # Positive controls prove that the Server catalog scan itself works.
        $serverControls = @(
            @{ name="BthPort.sys"; relative="Windows\System32\drivers\BTHport.sys"; policy="/kp" },
            @{ name="BthEnum.sys"; relative="Windows\System32\drivers\BthEnum.sys"; policy="/kp" },
            @{ name="BTHUSB.sys"; relative="Windows\System32\drivers\BTHUSB.sys"; policy="/kp" },
            @{ name="bth.inf"; relative="Windows\INF\bth.inf"; policy="/pa" }
        )
        foreach ($control in $serverControls) {
            $controlPath = Join-Path $MountDirectory $control.relative
            if (Test-Path -LiteralPath $controlPath) {
                $targets += [pscustomobject]@{
                    name=$control.name
                    sourceRole="server"
                    sourcePath=$control.relative
                    fullPath=$controlPath
                    copyPath=$null
                    sha256=(Get-FileHash -LiteralPath $controlPath -Algorithm SHA256).Hash.ToUpperInvariant()
                    policy=$control.policy
                    missing=$false
                }
            } else {
                $targets += [pscustomobject]@{
                    name=$control.name
                    sourceRole="server"
                    sourcePath=$control.relative
                    fullPath=$null
                    copyPath=$null
                    sha256=$null
                    policy=$control.policy
                    missing=$true
                }
            }
        }
    } else {
        return @()
    }

    $catalogRoots = @(
        (Join-Path $MountDirectory "Windows\servicing\Packages"),
        (Join-Path $MountDirectory "Windows\WinSxS\Catalogs"),
        (Join-Path $MountDirectory "Windows\System32\CatRoot"),
        (Join-Path $MountDirectory "Windows\System32\CatRoot2"),
        $driverStore
    )
    $catalogFiles = foreach ($root in $catalogRoots) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -Filter "*.cat" -File -Recurse -ErrorAction SilentlyContinue
        }
    }
    $catalogFiles = @($catalogFiles | Sort-Object FullName -Unique)
    if ($Role -eq "win10" -and $StagePackageOnRunner) {
        $knownCatalogs = @($catalogFiles | Where-Object { $_.Name -ieq $ExpectedWin10CatalogName })
        if ($knownCatalogs.Count -ne 1) { throw "Expected exact Win10 servicing CAT was not found: $ExpectedWin10CatalogName" }
        $catalogFiles = $knownCatalogs
    }

    $signToolPath = $null
    $signToolCommand = Get-Command signtool.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($signToolCommand) {
        $signToolPath = [string]$signToolCommand.Source
        if ([string]::IsNullOrWhiteSpace($signToolPath)) {
            $signToolPath = [string]$signToolCommand.Path
        }
    }
    if ([string]::IsNullOrWhiteSpace($signToolPath)) {
        $programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
        $kitsRoot = Join-Path $programFilesX86 "Windows Kits\10\bin"
        if (Test-Path -LiteralPath $kitsRoot) {
            $signTool = Get-ChildItem -LiteralPath $kitsRoot -Filter "signtool.exe" -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
                Sort-Object FullName -Descending | Select-Object -First 1
            if ($signTool) { $signToolPath = $signTool.FullName }
        }
    }

    $results = foreach ($target in $targets) {
        $base = @{
            role=$Role
            sourceImageRole=$target.sourceRole
            catalogImageRole=$Role
            file=$target.name
            filePath=$target.sourcePath
            fileSha256=$target.sha256
            targetCopyPath=$target.copyPath
            catalogPath=$null
            catalogSha256=$null
            catalogSignature=$null
            catalogsScanned=0
            catalogCount=$catalogFiles.Count
            verificationPolicy=$target.policy
            signtool=$signToolPath
            output=$null
        }
        if ($target.missing -or -not $target.fullPath -or -not (Test-Path -LiteralPath $target.fullPath)) {
            $base.status = "TARGET_FILE_NOT_FOUND"
            $base.output = "Source target file or retained Win10 package copy was not found."
            [pscustomobject]$base
            continue
        }
        if (-not $signToolPath) {
            $base.status = "SIGNTOOL_NOT_FOUND"
            $base.output = "Windows SDK SignTool was not found on the disposable runner."
            [pscustomobject]$base
            continue
        }

        $match = $null
        $tested = 0
        $lastOutput = $null
        foreach ($catalog in $catalogFiles) {
            $tested++
            $verifyOutput = & $signToolPath verify $target.policy /c $catalog.FullName $target.fullPath 2>&1
            $exitCode = $LASTEXITCODE
            if ($exitCode -eq 0) {
                $match = $catalog
                $lastOutput = ($verifyOutput | Out-String).Trim()
                break
            }
            if ($tested -le 3) { $lastOutput = ($verifyOutput | Out-String).Trim() }
        }
        $base.status = if ($match) { "CATALOG_MEMBER_VERIFIED" } elseif ($catalogFiles.Count -eq 0) { "NO_CATALOG_FILES_FOUND" } else { "NO_MATCH_IN_SCANNED_CATALOGS" }
        $base.catalogsScanned = $tested
        $base.catalogPath = if ($match) { $match.FullName.Substring($MountDirectory.Length).TrimStart("\") } else { $null }
        $base.catalogSha256 = if ($match) { (Get-FileHash -LiteralPath $match.FullName -Algorithm SHA256).Hash.ToUpperInvariant() } else { $null }
        $base.catalogSignature = if ($match) { Get-SignatureRecord -Path $match.FullName } else { $null }
        if ($Role -eq "win10" -and $StagePackageOnRunner -and $match) {
            if ($match.Name -ine $ExpectedWin10CatalogName -or $base.catalogSha256 -ne $ExpectedWin10CatalogSha256) {
                throw "Unexpected Win10 A2DP CAT identity: $($match.Name) / $($base.catalogSha256)"
            }
            $catalogCopyPath = Join-Path $StagePackageDirectory $match.Name
            if (-not (Test-Path -LiteralPath $catalogCopyPath)) { Copy-Item -LiteralPath $match.FullName -Destination $catalogCopyPath -Force }
            $script:StagePackageCatalogPath = $catalogCopyPath
        }
        $base.output = $lastOutput
        [pscustomobject]$base
    }
    return $results
}
function Get-DriverStoreSnapshot {
    $pnputilPath = Join-Path $env:WINDIR "System32\pnputil.exe"
    $output = & $pnputilPath /enum-drivers 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    $blocks = [regex]::Split($text, "(?m)(?=^\s*Published Name\s*:)")
    $records = @()
    foreach ($block in $blocks) {
        if ($block -match "(?im)^\s*Published Name\s*:\s*(?<published>oem\d+\.inf)") {
            $published = $Matches["published"]
            if ($block -match "(?im)^\s*Original Name\s*:\s*(?<original>.+)$") {
                $records += [pscustomobject]@{
                    publishedName=$published
                    originalName=$Matches["original"].Trim()
                    block=$block.Trim()
                }
            }
        }
    }
    [pscustomobject]@{ exitCode=$exitCode; text=$text; records=$records }
}

function Get-NewDriverStoreEntries {
    param([Parameter(Mandatory)]$Before, [Parameter(Mandatory)]$After)
    $beforeNames = @($Before.records | ForEach-Object { $_.publishedName })
    @($After.records | Where-Object { $beforeNames -notcontains $_.publishedName })
}

function Remove-StagedDriverStoreEntries {
    param([object[]]$Entries)
    $pnputilPath = Join-Path $env:WINDIR "System32\pnputil.exe"
    $results = @()
    foreach ($entry in @($Entries)) {
        $output = & $pnputilPath /delete-driver $entry.publishedName 2>&1
        $results += [pscustomobject]@{
            publishedName=$entry.publishedName
            originalName=$entry.originalName
            exitCode=$LASTEXITCODE
            output=($output | Out-String).Trim()
        }
    }
    $results
}

function Invoke-StagePackageSmokeTest {
    $result = [ordered]@{
        status="NOT_RUN"
        timestampUtc=(Get-Date).ToUniversalTime().ToString("o")
        scope="Disposable GitHub-hosted Windows Server 2022 runner only. Signature verification and DriverStore staging only; no /install, device enumeration, service start, driver load, audio, BCD/security/test-signing, certificate-store changes, or physical-host access."
        runner=$null
        package=$null
        signatureChecks=@()
        preCatalogStage=$null
        catalogDbRegistration=$null
        postCatalogStage=$null
        cleanup=$null
        setupApiLogTail=@()
        error=$null
    }
    $signToolPath = $null
    $catalog = $null
    $catalogAdded = $false
    $stagedEntries = @()
    try {
        if ($env:GITHUB_ACTIONS -ne "true" -or $env:RUNNER_ENVIRONMENT -ne "github-hosted") {
            throw "Refusing to stage outside a disposable GitHub-hosted runner."
        }
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $result.runner = [ordered]@{
            caption=$os.Caption
            version=$os.Version
            buildNumber=$os.BuildNumber
            productType=$os.ProductType
            currentBuild=[string]$cv.CurrentBuild
            ubr=[int]$cv.UBR
            editionId=[string]$cv.EditionID
            installationType=[string]$cv.InstallationType
            runnerEnvironment=$env:RUNNER_ENVIRONMENT
            githubActions=$env:GITHUB_ACTIONS
        }
        if ($os.Caption -notmatch "Windows Server 2022" -or [string]$cv.CurrentBuild -ne "20348" -or [string]$cv.InstallationType -ne "Server") {
            throw "Runner is not Windows Server 2022 build 20348; refusing package staging."
        }

        $catalog = Get-ChildItem -LiteralPath $StagePackageDirectory -Filter "*.cat" -File | Select-Object -First 1
        if (-not $catalog) { throw "The exact Win10 servicing CAT was not copied to the stage directory." }
        $expected = [ordered]@{
            "BthA2dp.sys"="5FBA5EE606AAC39D9CBDA51C0A14DBABBB3A9B47BBD8AC5485ED137B4F354EC3"
            "BtaMPM.sys"="DA5CBBDCE6AC511EF8400E121DF6B6EACA7D05C0F40A01F7353CE9F220EB3DCD"
            "microsoft_bluetooth_a2dp.inf"="4F3B988B658E1E7F8B97E645C1C92BE0BA270D4DB76832DAB871516EEDCBCF0C"
            "microsoft_bluetooth_a2dp_src.inf"="B97D1DD53BB6FD040CE5C2527015A09416C29FCBD6B528802D595CBDEEAD4A6A"
            "btampm.inf"="C657A6B32AC8CCFDEEF3C12630686B87C973DD114BEE73AEC288D86B989961EF"
        }
        $packageFiles = @()
        foreach ($name in $expected.Keys) {
            $path = Join-Path $StagePackageDirectory $name
            if (-not (Test-Path -LiteralPath $path)) { throw "Missing stage package file: $name" }
            $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
            if ($hash -ne $expected[$name]) { throw "Hash mismatch for $name: $hash != $($expected[$name])" }
            $packageFiles += [pscustomobject]@{ name=$name; sizeBytes=(Get-Item -LiteralPath $path).Length; sha256=$hash }
        }
        $catalogHash = (Get-FileHash -LiteralPath $catalog.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($catalog.Name -ine $ExpectedWin10CatalogName -or $catalogHash -ne $ExpectedWin10CatalogSha256) {
            throw "CAT identity mismatch: $($catalog.Name) / $catalogHash"
        }
        $result.package = [ordered]@{
            catalogName=$catalog.Name
            catalogSha256=$catalogHash
            catalogSizeBytes=$catalog.Length
            files=$packageFiles
            originalInfHasCatalogFile=$false
            sourceInf="microsoft_bluetooth_a2dp_src.inf"
            installCommand="pnputil /add-driver <source-inf> (no /install)"
        }

        $kitsRoot = Join-Path ([Environment]::GetFolderPath("ProgramFilesX86")) "Windows Kits\10\bin"
        $signTool = Get-ChildItem -LiteralPath $kitsRoot -Filter "signtool.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if (-not $signTool) { throw "Windows SDK x64 SignTool not found on Server 2022 runner." }
        $signToolPath = $signTool.FullName
        $checks = @(
            @{ name="BthA2dp.sys"; policy="/kp" },
            @{ name="BtaMPM.sys"; policy="/kp" },
            @{ name="microsoft_bluetooth_a2dp.inf"; policy="/pa" },
            @{ name="microsoft_bluetooth_a2dp_src.inf"; policy="/pa" },
            @{ name="btampm.inf"; policy="/pa" }
        )
        foreach ($check in $checks) {
            $path = Join-Path $StagePackageDirectory $check.name
            $verifyOutput = & $signToolPath verify $check.policy /v /c $catalog.FullName $path 2>&1
            $verifyExit = $LASTEXITCODE
            $result.signatureChecks += [pscustomobject]@{
                file=$check.name
                policy=$check.policy
                exitCode=$verifyExit
                status=if ($verifyExit -eq 0) { "VERIFIED" } else { "FAILED" }
                output=($verifyOutput | Out-String).Trim()
            }
            if ($verifyExit -ne 0) { throw "SignTool verification failed on Server 2022 runner for $($check.name)." }
        }

        $sourceInf = Join-Path $StagePackageDirectory "microsoft_bluetooth_a2dp_src.inf"
        $before = Get-DriverStoreSnapshot
        $preOutput = & (Join-Path $env:WINDIR "System32\pnputil.exe") /add-driver $sourceInf 2>&1
        $preExit = $LASTEXITCODE
        $after = Get-DriverStoreSnapshot
        $preEntries = @(Get-NewDriverStoreEntries -Before $before -After $after)
        $preSourceStaged = @($preEntries | Where-Object { $_.originalName -ieq "microsoft_bluetooth_a2dp_src.inf" }).Count -gt 0
        $result.preCatalogStage = [ordered]@{
            exitCode=$preExit
            sourceInfStaged=$preSourceStaged
            newDriverStoreEntries=$preEntries
            output=($preOutput | Out-String).Trim()
        }
        if ($preSourceStaged -and $preExit -eq 0) {
            $stagedEntries = $preEntries
            $result.status = "PASS_WITH_EXISTING_CATALOG_DATABASE"
        } else {
            $preCleanup = Remove-StagedDriverStoreEntries -Entries $preEntries
            $result.preCatalogStage.cleanup=$preCleanup
            $catdbOutput = & $signToolPath catdb /v /u $catalog.FullName 2>&1
            $catdbExit = $LASTEXITCODE
            $result.catalogDbRegistration = [ordered]@{
                exitCode=$catdbExit
                status=if ($catdbExit -eq 0) { "CATALOG_ADDED_TO_SYSTEM_COMPONENT_AND_DRIVER_DATABASE" } else { "FAILED" }
                output=($catdbOutput | Out-String).Trim()
                certificateStoreChanged=$false
            }
            if ($catdbExit -ne 0) { throw "SignTool catdb could not register the original Microsoft CAT in the disposable runner." }
            $catalogAdded = $true

            $before2 = Get-DriverStoreSnapshot
            $postOutput = & (Join-Path $env:WINDIR "System32\pnputil.exe") /add-driver $sourceInf 2>&1
            $postExit = $LASTEXITCODE
            $after2 = Get-DriverStoreSnapshot
            $postEntries = @(Get-NewDriverStoreEntries -Before $before2 -After $after2)
            $postSourceStaged = @($postEntries | Where-Object { $_.originalName -ieq "microsoft_bluetooth_a2dp_src.inf" }).Count -gt 0
            $result.postCatalogStage = [ordered]@{
                exitCode=$postExit
                sourceInfStaged=$postSourceStaged
                newDriverStoreEntries=$postEntries
                output=($postOutput | Out-String).Trim()
            }
            $stagedEntries = $postEntries
            if ($postSourceStaged -and $postExit -eq 0) {
                $result.status = "PASS_AFTER_CATALOG_DB_ADD"
            } else {
                $result.status = "FAILED"
            }
        }
    } catch {
        $result.status = "FAILED"
        $result.error = $_.Exception.Message
    } finally {
        $cleanupDriver = Remove-StagedDriverStoreEntries -Entries $stagedEntries
        $cleanupCatalog = $null
        if ($catalogAdded -and $catalog -and $signToolPath) {
            $removeOutput = & $signToolPath catdb /v /r /u $catalog.FullName 2>&1
            $cleanupCatalog = [pscustomobject]@{
                exitCode=$LASTEXITCODE
                output=($removeOutput | Out-String).Trim()
                attempted=$true
            }
        } else {
            $cleanupCatalog = [pscustomobject]@{ attempted=$false; reason="Catalog was not added by this test." }
        }
        $finalSnapshot = Get-DriverStoreSnapshot
        $remaining = @($finalSnapshot.records | Where-Object { $_.originalName -match "^(microsoft_bluetooth_a2dp_src\.inf|microsoft_bluetooth_a2dp\.inf|btampm\.inf)$" })
        $result.cleanup = [ordered]@{
            driverStoreRemoval=$cleanupDriver
            catalogDatabaseRemoval=$cleanupCatalog
            remainingA2dpPackages=$remaining
        }
        $setupLogPath = Join-Path $env:WINDIR "INF\setupapi.dev.log"
        if (Test-Path -LiteralPath $setupLogPath) {
            $result.setupApiLogTail = @(Get-Content -LiteralPath $setupLogPath -Tail 250)
        }
    }
    [pscustomobject]$result
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
        Write-Host "Mounting $($Target.Name): $($selected.ImageName), index=$($selected.ImageIndex); exact version will be read from the offline SOFTWARE hive"
        Mount-WindowsImage -ImagePath $imagePath -Index $selected.ImageIndex -Path $mountDirectory -ReadOnly | Out-Null
        $identity = Get-OfflineImageIdentity -MountDirectory $mountDirectory -WorkDirectory $WorkDirectory -Target $Target
        Write-Host "Verified offline image identity: $($identity.productName); $($identity.imageVersion); EditionID=$($identity.editionId); InstallationType=$($identity.installationType)"
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

            # BthA2dp imports profile-management entry points from the matching
            # BtaMPM companion. Server 2022 has no inbox BtaMPM.sys, so place the
            # Win10 image's companion in the same export-reference set used to
            # resolve the Win10 A2DP profile. Prefer the DriverStore copy.
            if ($Target.Role -eq "win10") {
                $btaCompanion = $matchedFiles |
                    Where-Object { $_.Name -ieq "BtaMPM.sys" } |
                    Sort-Object @{ Expression = { if ($_.FullName -match "\\DriverStore\\FileRepository\\") { 0 } else { 1 } } }, FullName |
                    Select-Object -First 1
                if ($btaCompanion) {
                    $companionPath = Join-Path $ServerReferenceDirectory "BtaMPM.sys"
                    Copy-Item -LiteralPath $btaCompanion.FullName -Destination $companionPath -Force
                    Write-Host "Added Win10 BtaMPM companion export reference: $($btaCompanion.FullName)"
                } else {
                    Write-Warning "No BtaMPM.sys found in $($Target.Name); BthA2dp companion imports will remain unresolved."
                }
            }

            $fileRecords = @()
            foreach ($file in $matchedFiles) {
                $relative = $file.FullName.Substring($mountDirectory.Length).TrimStart("\")
                $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
                $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($file.FullName)
                $expected = Get-ExpectedHash -File $file -RelativePath $relative
                $expectedMatch = if ($expected) { $hash -eq $expected } else { $null }
                $reference = if ($Target.Role -eq "win10" -and (Test-Path -LiteralPath (Join-Path $ServerReferenceDirectory "ntoskrnl.exe"))) { $ServerReferenceDirectory } else { $null }
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
            $catalogMembership = Get-TargetCatalogMembership -MountDirectory $mountDirectory -Role $Target.Role
            $serviceRegistrations = Get-OfflineServiceSummary -MountDirectory $mountDirectory -WorkDirectory $WorkDirectory -Role $Target.Role

            [pscustomobject]@{
                name=$Target.Name
                role=$Target.Role
                status="COMPLETED"
                expectedBuild=$Target.ExpectedBuild
                selectedEdition=$download.Edition
                availableEditions=$download.AvailableEditions
                availableLanguages=$download.AvailableLanguages
                uupId=$Target.Id
                uupPackageUrl=$download.PackageUrl
                isoSha256=$download.IsoSha256
                isoSizeBytes=$download.IsoSizeBytes
                imageName=$selected.ImageName
                imageVersion=$identity.imageVersion
                imageIdentity=$identity
                imageIndex=$selected.ImageIndex
                files=$fileRecords
                infs=$infRecords
                componentHits=$componentHits
                catalogs=$catalogRecords
                catalogMembership=$catalogMembership
                serviceRegistrations=$serviceRegistrations
            }
        } finally {
            Dismount-WindowsImage -Path $mountDirectory -Discard -ErrorAction SilentlyContinue | Out-Null
        }
    } finally {
        if ($disk) { Dismount-DiskImage -ImagePath $download.IsoPath -ErrorAction SilentlyContinue | Out-Null }
        Remove-Item -LiteralPath $WorkDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Save-AuditReports {
    param([Parameter(Mandatory)][object[]]$Results)

    $completed = @($Results | Where-Object { $_.status -eq "COMPLETED" })
    $allInfLines = @()
    $allComponentHits = @()
    $allCatalogMembership = @()
    $allServiceRegistrations = @()
    foreach ($image in $completed) {
        foreach ($inf in @($image.infs)) {
            $allInfLines += "## $($image.name) :: $($inf.path)"
            $allInfLines += "SHA-256: $($inf.sha256)"
            $allInfLines += $inf.selectedLines
            $allInfLines += ""
        }
        $allComponentHits += @($image.componentHits)
        $allCatalogMembership += @($image.catalogMembership)
        $allServiceRegistrations += @($image.serviceRegistrations)
    }

    $manifest = [ordered]@{
        generatedUtc=(Get-Date).ToUniversalTime().ToString("o")
        githubRunId=$env:GITHUB_RUN_ID
        githubSha=$env:GITHUB_SHA
        scope=if ($StagePackageOnRunner) { "Offline Win10 UUP extraction plus disposable GitHub-hosted Windows Server 2022 DriverStore staging smoke only. No /install, device enumeration, service start, driver load, audio test, certificate-store change, or physical-host access." } else { "Offline UUP image extraction, static PE analysis, offline SYSTEM service registration inventory, and offline catalog membership verification only. No package staging, driver load, device enumeration, audio test, or physical-host access." }
        expectedCapturedHashes=$ExpectedHashes
        images=$Results
        stageTest=$script:StageTestResult
    }
    $manifest | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $OutputDirectory "manifest.json") -Encoding utf8
    $allInfLines | Set-Content -LiteralPath $InfReportPath -Encoding utf8
    $allComponentHits | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $ComponentReportPath -Encoding utf8
    $allCatalogMembership | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutputDirectory "catalog-membership.json") -Encoding utf8
    $allServiceRegistrations | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutputDirectory "service-registrations.json") -Encoding utf8

    @"
# UUP image A2DP component audit

- Win10 reference image: 19045.5917 x64, UUP ID 598d27dc-ad81-41aa-8c83-42b88e60c823.
- Server target image: 20348.5761 x64, UUP ID 008aacce-b0b7-4aeb-a3b2-43286434832c.
- Source: UUP dump download packages; payloads are fetched from Microsoft's update infrastructure. UUP dump is an independent third-party service, not Microsoft.
- The selected image version is checked before extracting files.
- SHA-256 comparisons are made against the already-recorded Win10 archive hashes.
- PE reports include imports, delay imports, exports, API-set imports and a static comparison of Win10 imports against Server 2022 exports.
- Win10 A2DP files are checked against Win10 system catalogs and then the same exact file hashes are checked against the Server 2022 offline catalog set. Server Bluetooth core files are positive controls for the Server catalog scan.
- Catalog membership is checked with SignTool; the matched catalog's embedded Authenticode signer/status is recorded separately. A successful Win10 membership check alone does not prove Server 2022 can validate the package.
- Offline SYSTEM hive service registrations are captured from a temporary copy; source images remain read-only.
- Win10 package file copies are temporary and removed before the workflow uploads metadata.
- No Microsoft binary payloads or ISO files are uploaded by this workflow; only metadata and text reports are retained.
- Static export presence does not prove driver load or runtime compatibility.
- When -StagePackageOnRunner is used, the exact original Win10 CAT is verified and the unmodified A2DP Source INF is staged only into the disposable GitHub-hosted Server 2022 DriverStore. The command never uses /install and never binds or starts a device.
- The stage smoke test records its runner build/UBR, SignTool verification, catalog-database add/remove, PnPUtil result, SetupAPI log tail and cleanup. It does not prove device enumeration, BthA2dp service start, driver load, endpoint creation, SBC negotiation or audio.
- Per-image status is recorded in manifest.json; completed image results are checkpointed before the next image starts.
"@ | Set-Content -LiteralPath (Join-Path $OutputDirectory "README.md") -Encoding utf8
}

if ($Win10Only) { $Targets = @($Targets | Where-Object { $_.Role -eq "win10" }) }
if ($StagePackageOnRunner -and @($Targets | Where-Object { $_.Role -eq "win10" }).Count -ne 1) { throw "Stage smoke mode requires exactly one Win10 source image." }

$results = @()
$hadFailures = $false
foreach ($target in $Targets) {
    $workDirectory = Join-Path $OutputDirectory ("work-" + $target.Role)
    try {
        $result = Collect-Image -Target $target -WorkDirectory $workDirectory
        $results += $result
        Write-Host "Completed offline audit for $($target.Name)."
    } catch {
        $hadFailures = $true
        $results += [pscustomobject]@{
            name=$target.Name
            role=$target.Role
            status="FAILED"
            expectedBuild=$target.ExpectedBuild
            error=$_.Exception.Message
            errorLine=$_.InvocationInfo.ScriptLineNumber
            errorCommand=$_.InvocationInfo.MyCommand.Name
        }
        Write-Warning "Offline audit failed for $($target.Name): $($_.Exception.Message)"
    }
    Save-AuditReports -Results $results
}

if ($hadFailures) {
    throw "One or more offline image audits failed. Per-image status and completed results are preserved in manifest.json."
}

if ($StagePackageOnRunner) {
    try {
        $script:StageTestResult = Invoke-StagePackageSmokeTest
    } catch {
        $script:StageTestResult = [pscustomobject]@{ status="FAILED"; error=$_.Exception.Message; scope="Disposable GitHub-hosted Server 2022 runner only; no physical-host access." }
    }
    $script:StageTestResult | ConvertTo-Json -Depth 24 | Set-Content -LiteralPath $StageTestReportPath -Encoding utf8
    Save-AuditReports -Results $results
    Remove-Item -LiteralPath $StagePackageDirectory -Recurse -Force -ErrorAction SilentlyContinue
    if ($script:StageTestResult.status -notlike "PASS*") {
        throw "A2DP DriverStore staging smoke did not pass. See stage-test.json and manifest.json."
    }
}

Remove-Item -LiteralPath $ServerReferenceDirectory -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Win10PackageFilesDirectory -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "UUP image audit complete. Manifest: $(Join-Path $OutputDirectory 'manifest.json')"
exit 0
