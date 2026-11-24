param(
    [string]$OutputDirectory = 'build/catalog-a2dp-audit'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$DownloadRoot = Join-Path $env:RUNNER_TEMP 'ldac-catalog-downloads'
$ExtractRoot = Join-Path $env:RUNNER_TEMP 'ldac-catalog-extracted'
$ReferenceRoot = Join-Path $env:RUNNER_TEMP 'ldac-server2022-reference'
$PeAuditRoot = Join-Path $OutputDirectory 'pe-audit'

foreach ($path in @($OutputDirectory, $DownloadRoot, $ExtractRoot, $ReferenceRoot, $PeAuditRoot)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
}

$PackageSpecs = @(
    [pscustomobject]@{
        KB = 'KB5036979'
        Role = 'win10-a2dp-captured-19041.4355'
        ExpectedProduct = 'Windows 10 Version 22H2'
        ExpectedSha256 = @{ 'btha2dp.sys' = '5fba5ee606aac39d9cbda51c0a14dbabbb3a9b47bbd8ac5485ed137b4f354ec3' }
    },
    [pscustomobject]@{
        KB = 'KB5058379'
        Role = 'win10-btampm-captured-19041.5848'
        ExpectedProduct = 'Windows 10 Version 22H2'
        ExpectedSha256 = @{ 'btampm.sys' = 'da5cbbdce6ac511ef8400e121df6b6eaca7d05c0f40a01f7353ce9f220eb3dcd' }
    },
    [pscustomobject]@{
        KB = 'KB5126657'
        Role = 'win10-current-2026-10'
        ExpectedProduct = 'Windows 10 Version 22H2'
        ExpectedSha256 = @{}
    },
    [pscustomobject]@{
        KB = 'KB5126655'
        Role = 'server2022-20348.5761'
        ExpectedProduct = 'Windows Server 2022'
        ExpectedSha256 = @{}
    }
)

$PackageResults = [System.Collections.Generic.List[object]]::new()
$ExpandResults = [System.Collections.Generic.List[object]]::new()
$ManifestHits = [System.Collections.Generic.List[object]]::new()
$ExpandedArchives = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

function Get-FileMetadata {
    param([System.IO.FileInfo]$File)

    $version = $null
    try { $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($File.FullName).FileVersion } catch {}
    $hash = $null
    try { $hash = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash.ToLowerInvariant() } catch {}

    [pscustomobject]@{
        Name = $File.Name
        Path = $File.FullName
        Size = $File.Length
        FileVersion = $version
        Sha256 = $hash
    }
}

function Expand-CabTree {
    param(
        [string]$ArchivePath,
        [string]$Destination,
        [int]$Depth = 0
    )

    if ($Depth -gt 3) { return }
    $full = [System.IO.Path]::GetFullPath($ArchivePath)
    if (-not $ExpandedArchives.Add($full)) { return }
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) { return }

    $extension = [System.IO.Path]::GetExtension($ArchivePath).ToLowerInvariant()
    if ($extension -notin @('.msu', '.cab')) { return }

    $leaf = [System.IO.Path]::GetFileNameWithoutExtension($ArchivePath)
    $target = Join-Path $Destination ($leaf + '-depth' + $Depth)
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    $output = & "$env:SystemRoot\System32\expand.exe" -F:* $ArchivePath $target 2>&1
    $exitCode = $LASTEXITCODE
    $ExpandResults.Add([pscustomobject]@{
        Archive = $ArchivePath
        Destination = $target
        Depth = $Depth
        ExitCode = $exitCode
        Output = (($output | ForEach-Object { "$_" }) -join [Environment]::NewLine)
    }) | Out-Null

    if ($exitCode -ne 0) { return }
    $nested = Get-ChildItem -LiteralPath $target -Filter '*.cab' -File -Recurse -ErrorAction SilentlyContinue
    foreach ($cab in $nested) {
        Expand-CabTree -ArchivePath $cab.FullName -Destination $Destination -Depth ($Depth + 1)
    }
}

function Invoke-PeAudit {
    param(
        [string]$BinaryPath,
        [string]$Role,
        [string]$ReferenceDirectory
    )

    $scriptPath = Join-Path $PSScriptRoot 'audit_pe_binary.py'
    $safe = ($Role -replace '[^A-Za-z0-9._-]', '-')
    $jsonPath = Join-Path $PeAuditRoot ($safe + '.json')
    $summaryPath = Join-Path $PeAuditRoot ($safe + '.md')

    $arguments = @(
        $scriptPath,
        '--input', $BinaryPath,
        '--output', $jsonPath,
        '--summary', $summaryPath
    )
    if (Test-Path -LiteralPath $ReferenceDirectory -PathType Container) {
        $arguments += @('--reference-dir', $ReferenceDirectory)
    }

    $output = & python @arguments 2>&1
    [pscustomobject]@{
        Role = $Role
        BinaryName = [System.IO.Path]::GetFileName($BinaryPath)
        ReturnCode = $LASTEXITCODE
        Output = (($output | ForEach-Object { "$_" }) -join [Environment]::NewLine)
        JsonReport = $jsonPath
        SummaryReport = $summaryPath
    }
}

# Record the disposable Windows Server 2022 runner. This is not the physical host.
$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$RunnerInfo = [pscustomobject]@{
    ProductName = $os.ProductName
    EditionID = $os.EditionID
    InstallationType = $os.InstallationType
    DisplayVersion = $os.DisplayVersion
    CurrentBuild = $os.CurrentBuild
    CurrentBuildNumber = $os.CurrentBuildNumber
    UBR = $os.UBR
    BuildLabEx = $os.BuildLabEx
    Architecture = $env:PROCESSOR_ARCHITECTURE
    Is64BitOS = [Environment]::Is64BitOperatingSystem
}
$RunnerInfo | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'runner-os.json') -Encoding utf8

Install-Module -Name MSCatalogLTS -RequiredVersion 2.1.0.2 -Scope CurrentUser -Force -AllowClobber
Import-Module MSCatalogLTS -RequiredVersion 2.1.0.2 -Force
(Get-Module MSCatalogLTS | Select-Object Name, Version, Path) |
    ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath (Join-Path $OutputDirectory 'catalog-client.json') -Encoding utf8

foreach ($spec in $PackageSpecs) {
    $result = [ordered]@{
        KB = $spec.KB
        Role = $spec.Role
        ExpectedProduct = $spec.ExpectedProduct
        Status = 'not-started'
        Candidates = @()
        SelectedUpdate = $null
        DownloadedFiles = @()
        ExpandedFiles = @()
        DriverCandidates = @()
        ManifestHits = @()
        CatalogChecks = @()
        PeAudits = @()
        Error = $null
    }

    try {
        $updates = @(Get-MSCatalogUpdate -Search $spec.KB -Architecture x64 -IncludePreview -AllPages -IncludeFileNames)
        $matches = @($updates | Where-Object {
            $_.Title -like "*$($spec.KB)*" -and $_.Title -like '*x64-based Systems*'
        })

        if ($spec.ExpectedProduct -eq 'Windows Server 2022') {
            $preferred = @($matches | Where-Object {
                $_.Title -match 'Windows Server 2022|Microsoft server operating system' -or
                $_.Products -match 'Windows Server 2022|Microsoft server operating system'
            })
        } else {
            $preferred = @($matches | Where-Object {
                $_.Title -match [regex]::Escape($spec.ExpectedProduct) -or
                $_.Products -match [regex]::Escape($spec.ExpectedProduct)
            })
        }
        if ($preferred.Count -gt 0) { $matches = $preferred }

        $result.Candidates = @($matches | ForEach-Object {
            [pscustomobject]@{
                Title = $_.Title
                Products = $_.Products
                Classification = $_.Classification
                LastUpdated = $_.LastUpdated
                Version = $_.Version
                Size = $_.Size
                SizeInBytes = $_.SizeInBytes
                Guid = $_.Guid
                FileNames = @($_.FileNames)
                SupportUrl = $_.SupportUrl
                CatalogSha1 = $_.SHA1
            }
        })

        if ($matches.Count -eq 0) {
            $result.Status = 'catalog-update-not-found'
            $PackageResults.Add([pscustomobject]$result) | Out-Null
            continue
        }
        if ($matches.Count -ne 1) {
            $result.Status = 'catalog-update-ambiguous'
            $PackageResults.Add([pscustomobject]$result) | Out-Null
            continue
        }

        $update = $matches[0]
        $result.SelectedUpdate = [pscustomobject]@{
            Title = $update.Title
            Products = $update.Products
            Classification = $update.Classification
            LastUpdated = $update.LastUpdated
            Version = $update.Version
            Size = $update.Size
            SizeInBytes = $update.SizeInBytes
            Guid = $update.Guid
            FileNames = @($update.FileNames)
            SupportUrl = $update.SupportUrl
            CatalogSha1 = $update.SHA1
        }

        $downloadDir = Join-Path $DownloadRoot $spec.KB
        New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
        $saveOutput = Save-MSCatalogUpdate -Update $update -Destination $downloadDir -DownloadAll -Force 2>&1

        $downloaded = @(Get-ChildItem -LiteralPath $downloadDir -File -Recurse -ErrorAction SilentlyContinue)
        $result.DownloadedFiles = @($downloaded | ForEach-Object { Get-FileMetadata -File $_ })

        $extractDir = Join-Path $ExtractRoot $spec.KB
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
        foreach ($file in $downloaded) {
            Expand-CabTree -ArchivePath $file.FullName -Destination $extractDir -Depth 0
        }

        $expanded = @(Get-ChildItem -LiteralPath $extractDir -File -Recurse -ErrorAction SilentlyContinue)
        $result.ExpandedFiles = @($expanded | Where-Object {
            $_.Extension -in @('.cab', '.msu', '.mum', '.manifest', '.inf', '.cat', '.psf')
        } | ForEach-Object { Get-FileMetadata -File $_ })

        $drivers = @($expanded | Where-Object { $_.Name -match '^(btha2dp|btampm)\.sys$' })
        $result.DriverCandidates = @($drivers | ForEach-Object {
            $meta = Get-FileMetadata -File $_
            $expected = $spec.ExpectedSha256[$_.Name.ToLowerInvariant()]
            [pscustomobject]@{
                Name = $meta.Name
                Path = $meta.Path
                Size = $meta.Size
                FileVersion = $meta.FileVersion
                Sha256 = $meta.Sha256
                ExpectedSha256 = $expected
                ExactHashMatch = [bool]($expected -and $meta.Sha256 -eq $expected)
            }
        })

        $textFiles = @($expanded | Where-Object { $_.Extension -in @('.mum', '.manifest', '.inf') })
        foreach ($textFile in $textFiles) {
            try {
                $hits = Select-String -LiteralPath $textFile.FullName -Pattern 'btha2dp\.sys|btampm\.sys|microsoft_bluetooth_a2dp|btampm\.inf' -AllMatches -ErrorAction SilentlyContinue
                foreach ($hit in @($hits | Select-Object -First 8)) {
                    $ManifestHits.Add([pscustomobject]@{
                        KB = $spec.KB
                        File = $textFile.FullName
                        LineNumber = $hit.LineNumber
                        Line = $hit.Line.Trim()
                    }) | Out-Null
                }
            } catch {}
        }
        $result.ManifestHits = @($ManifestHits | Where-Object { $_.KB -eq $spec.KB })

        $signtoolRoot = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Windows Kits\10\bin'
        $signtool = $null
        if (Test-Path -LiteralPath $signtoolRoot -PathType Container) {
            $signtool = Get-ChildItem -Path $signtoolRoot -Filter 'signtool.exe' -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match '\\x64\\' } |
                Sort-Object FullName -Descending |
                Select-Object -First 1
        }
        $infs = @($expanded | Where-Object { $_.Extension -eq '.inf' })
        $cats = @($expanded | Where-Object { $_.Extension -eq '.cat' })
        foreach ($inf in $infs) {
            $catalogNames = @(
                Select-String -LiteralPath $inf.FullName -Pattern '^\s*CatalogFile(?:\.NTamd64)?\s*=\s*(.+)$' |
                ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
            )
            foreach ($catalogName in $catalogNames) {
                $cat = $cats | Where-Object { $_.Name -ieq $catalogName } | Select-Object -First 1
                if (-not $cat) { continue }
                foreach ($driver in $drivers) {
                    $verifyOutput = @()
                    $verifyCode = $null
                    if ($signtool) {
                        $verifyOutput = & $signtool.FullName verify /kp /v /c $cat.FullName $driver.FullName 2>&1
                        $verifyCode = $LASTEXITCODE
                    }
                    $catSignature = Get-AuthenticodeSignature -FilePath $cat.FullName
                    $result.CatalogChecks += [pscustomobject]@{
                        Inf = $inf.Name
                        Catalog = $cat.Name
                        Driver = $driver.Name
                        SigntoolAvailable = [bool]$signtool
                        SigntoolExitCode = $verifyCode
                        SigntoolOutput = (($verifyOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine)
                        CatalogSignatureStatus = "$($catSignature.Status)"
                        CatalogSigner = $catSignature.SignerCertificate.Subject
                    }
                }
            }
        }

        $result.Status = if ($drivers.Count -gt 0) { 'package-extracted-driver-binaries' } else { 'package-downloaded-no-direct-sys-payload' }
        $result.DownloadLog = (($saveOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine)
    } catch {
        $result.Status = 'error'
        $result.Error = "$($_.Exception.GetType().FullName): $($_.Exception.Message)"
    }

    $PackageResults.Add([pscustomobject]$result) | Out-Null
}

# Collect the disposable Server 2022 runner's runtime files. This is not the physical host.
$ServerRuntimeSpecs = @(
    @{ Name = 'ntoskrnl.exe'; Relative = 'ntoskrnl.exe' },
    @{ Name = 'hal.dll'; Relative = 'hal.dll' },
    @{ Name = 'cng.sys'; Relative = 'drivers\cng.sys' },
    @{ Name = 'WppRecorder.sys'; Relative = 'drivers\WppRecorder.sys' },
    @{ Name = 'bthport.sys'; Relative = 'drivers\bthport.sys' },
    @{ Name = 'bthenum.sys'; Relative = 'drivers\bthenum.sys' },
    @{ Name = 'bthusb.sys'; Relative = 'drivers\bthusb.sys' },
    @{ Name = 'bthmini.sys'; Relative = 'drivers\bthmini.sys' },
    @{ Name = 'ks.sys'; Relative = 'drivers\ks.sys' },
    @{ Name = 'portcls.sys'; Relative = 'drivers\portcls.sys' },
    @{ Name = 'ksecdd.sys'; Relative = 'drivers\ksecdd.sys' },
    @{ Name = 'WDFLDR.SYS'; Relative = 'drivers\WDFLDR.SYS' },
    @{ Name = 'SleepStudyHelper.sys'; Relative = 'drivers\SleepStudyHelper.sys' },
    @{ Name = 'BtaMPM.sys'; Relative = 'drivers\BtaMPM.sys' },
    @{ Name = 'BthA2dp.sys'; Relative = 'drivers\BthA2dp.sys' }
)

$ServerRuntime = [System.Collections.Generic.List[object]]::new()
foreach ($spec in $ServerRuntimeSpecs) {
    $path = Join-Path (Join-Path $env:SystemRoot 'System32') $spec.Relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $ServerRuntime.Add([pscustomobject]@{ Name = $spec.Name; Present = $false; Path = $path }) | Out-Null
        continue
    }

    $file = Get-Item -LiteralPath $path
    $meta = Get-FileMetadata -File $file
    $ServerRuntime.Add([pscustomobject]@{
        Name = $spec.Name
        Present = $true
        Path = $path
        Size = $meta.Size
        FileVersion = $meta.FileVersion
        Sha256 = $meta.Sha256
    }) | Out-Null
    Copy-Item -LiteralPath $path -Destination (Join-Path $ReferenceRoot $spec.Name) -Force
}

# Add exact Win10 BtaMPM binary to the reference set when the package extraction found it.
foreach ($item in $PackageResults | Where-Object { $_.KB -ne 'SERVER-RUNTIME' }) {
    foreach ($driver in @($item.DriverCandidates)) {
        if ($driver.Name -ieq 'btampm.sys' -and (Test-Path -LiteralPath $driver.Path -PathType Leaf)) {
            Copy-Item -LiteralPath $driver.Path -Destination (Join-Path $ReferenceRoot 'btampm.sys') -Force
        }
    }
}

# Run PE audits after all reference binaries are staged, so import comparisons are meaningful.
foreach ($item in $PackageResults | Where-Object { $_.KB -ne 'SERVER-RUNTIME' }) {
    foreach ($driver in @($item.DriverCandidates)) {
        if (Test-Path -LiteralPath $driver.Path -PathType Leaf) {
            $item.PeAudits += Invoke-PeAudit -BinaryPath $driver.Path -Role ($item.KB + '-' + $driver.Name) -ReferenceDirectory $ReferenceRoot
        }
    }
}

foreach ($item in $ServerRuntime | Where-Object { $_.Present }) {
    $auditPath = Join-Path (Join-Path $env:SystemRoot 'System32') ($item.Name -replace '^(ntoskrnl|hal)\.dll$', '$1.dll')
    if (-not (Test-Path -LiteralPath $auditPath -PathType Leaf)) {
        $auditPath = Join-Path (Join-Path $env:SystemRoot 'System32\drivers') $item.Name
    }
    if (Test-Path -LiteralPath $auditPath -PathType Leaf) {
        $PackageResults.Add([pscustomobject]@{
            KB = 'SERVER-RUNTIME'
            Role = $item.Name
            Status = 'audited'
            PeAudit = (Invoke-PeAudit -BinaryPath $auditPath -Role ('server-runtime-' + $item.Name) -ReferenceDirectory $ReferenceRoot)
        }) | Out-Null
    }
}

$ServerRuntime | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'server-runtime.json') -Encoding utf8
$PackageResults | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'catalog-package-results.json') -Encoding utf8
$ExpandResults | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'expand-results.json') -Encoding utf8
$ManifestHits | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'manifest-search-hits.json') -Encoding utf8

$summary = [System.Collections.Generic.List[string]]::new()
$summary.Add('# Microsoft Update Catalog A2DP package audit')
$summary.Add('')
$summary.Add("- Disposable runner: $($RunnerInfo.ProductName), build $($RunnerInfo.CurrentBuild).$($RunnerInfo.UBR)")
$summary.Add('- No driver installation, service start, device restart, OS update, BCD/security change or physical-host access was performed.')
$summary.Add('- Catalog client: MSCatalogLTS 2.1.0.2.')
$summary.Add('')
$summary.Add('## Package resolution')
$summary.Add('')
$summary.Add('| KB | Role | Status | Candidate count | Extracted A2DP files |')
$summary.Add('|---|---|---|---:|---|')
foreach ($item in $PackageResults | Where-Object { $_.KB -ne 'SERVER-RUNTIME' }) {
    $count = @($item.Candidates).Count
    $files = @($item.DriverCandidates | ForEach-Object { "$($_.Name) $($_.FileVersion) hash=$($_.Sha256)" }) -join '; '
    $summary.Add("| $($item.KB) | $($item.Role) | $($item.Status) | $count | $files |")
}
$summary.Add('')
$summary.Add('## Server runtime')
$summary.Add('')
$summary.Add('| File | Present | Version | SHA-256 |')
$summary.Add('|---|---|---|---|')
foreach ($item in $ServerRuntime) {
    $summary.Add("| $($item.Name) | $($item.Present) | $($item.FileVersion) | $($item.Sha256) |")
}
$summary.Add('')
$summary.Add('## Interpretation')
$summary.Add('')
$summary.Add('- A package is an exact captured-binary source only when an extracted SYS SHA-256 equals the previously recorded archive SHA-256.')
$summary.Add('- If the package contains PSF payloads but no direct SYS file, a base image and PSF reconstruction step will be required; no binary identity is inferred.')
$summary.Add('- Catalog membership is confirmed only when SignTool verifies the target SYS against the matching CAT. A CAT signature alone is not enough.')
$summary.Add('- PE comparisons are static and do not prove driver load, A2DP endpoint creation, SBC negotiation or actual audio.')
$summary.Add('- Full import/export, package identity, hashes and manifest search details are in the JSON evidence files.')
$summary | Set-Content -LiteralPath (Join-Path $OutputDirectory 'README.md') -Encoding utf8

# Delete downloaded MSU/CAB payloads and copied reference binaries before artifact upload.
Remove-Item -LiteralPath $DownloadRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $ExtractRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $ReferenceRoot -Recurse -Force -ErrorAction SilentlyContinue
