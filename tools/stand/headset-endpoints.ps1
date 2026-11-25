# Read-only inventory of Windows audio input/output endpoints and PnP containers.
param([string]$Match = 'OPPO Enco Buds2')
$ErrorActionPreference = 'Stop'
$root = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio'
function Get-EndpointFlow([string]$InstanceId, $Flows) {
    if ($InstanceId -match '^SWD\\MMDEVAPI\\\{[^{}]+\}\.(\{[0-9a-f-]{36}\})$') {
        $Flows[$Matches[1]]
    }
}
$flows = @{}
foreach ($flow in 'Render','Capture') {
    $path = Join-Path $root $flow
    if (Test-Path -LiteralPath $path) {
        foreach ($key in Get-ChildItem -LiteralPath $path) {
            $flows[$key.PSChildName] = $flow
        }
    }
}
# Verify that flow comes from the endpoint hive, with an unmatched ID left unknown.
$testRender = '{10000000-0000-0000-0000-000000000001}'
$testCapture = '{10000000-0000-0000-0000-000000000002}'
$fixture = @{}
$fixture[$testRender] = 'Render'
$fixture[$testCapture] = 'Capture'
if ((Get-EndpointFlow "SWD\MMDEVAPI\{0.0.0.00000000}.$testRender" $fixture) -ne 'Render' -or
    (Get-EndpointFlow "SWD\MMDEVAPI\{0.0.1.00000000}.$testCapture" $fixture) -ne 'Capture' -or
    (Get-EndpointFlow 'SWD\MMDEVAPI\{0.0.1.00000000}.{10000000-0000-0000-0000-000000000003}' $fixture)) {
    throw 'Endpoint flow control failed'
}
$known = @()
$present = @(Get-PnpDevice -PresentOnly)
foreach ($device in $present | Where-Object Class -eq 'AudioEndpoint') {
    $flow = Get-EndpointFlow $device.InstanceId $flows
    $container = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName DEVPKEY_Device_ContainerId -ErrorAction SilentlyContinue
    $known += [pscustomobject]@{
        Name = $device.FriendlyName
        Direction = $flow
        PnpStatus = $device.Status
        ContainerId = $container.Data
        InstanceId = $device.InstanceId
    }
}
$result = @($known | Where-Object { $_.Name -like "*$Match*" })
$render = @($result | Where-Object Direction -eq 'Render')
$capture = @($result | Where-Object Direction -eq 'Capture')
$shared = @($render.ContainerId | Where-Object { $_ -and $_ -ne [guid]::Empty -and $_ -in $capture.ContainerId } | Sort-Object -Unique)
[ordered]@{
    Build = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
    Match = $Match
    PresentAudioEndpoints = $known.Count
    MatchedRender = $render.Count
    MatchedCapture = $capture.Count
    SharedContainerIds = $shared
    MatchedEndpoints = $result
} | ConvertTo-Json -Depth 5
