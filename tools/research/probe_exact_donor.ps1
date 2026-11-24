param([Parameter(Mandatory)][string]$InputDirectory)
$ErrorActionPreference = 'Stop'
if ($env:RUNNER_ENVIRONMENT -ne 'github-hosted' -or [Environment]::OSVersion.Version.Build -ne 20348) { throw 'Requires hosted Server 2022' }
$files = [ordered]@{
  'microsoft_bluetooth_a2dp_src.inf'='B97D1DD53BB6FD040CE5C2527015A09416C29FCBD6B528802D595CBDEEAD4A6A'
  'microsoft_bluetooth_a2dp.inf'='4F3B988B658E1E7F8B97E645C1C92BE0BA270D4DB76832DAB871516EEDCBCF0C'
  'btampm.inf'='C657A6B32AC8CCFDEEF3C12630686B87C973DD114BEE73AEC288D86B989961EF'
}
$dir = (New-Item -Type Directory (Join-Path $env:RUNNER_TEMP ([guid]::NewGuid().ToString()))).FullName
foreach ($name in $files.Keys) {
  $entry = Join-Path $InputDirectory (([IO.Path]::GetFileNameWithoutExtension($name))+'-'+$files[$name].Substring(0,12)+'.inf')
  if ((Get-FileHash -LiteralPath $entry).Hash -ne $files[$name]) { throw "Wrong bytes $name" }
  Copy-Item -LiteralPath $entry -Destination (Join-Path $dir $name)
  "DONOR $name $($files[$name])"
}
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Probe {
 [DllImport("setupapi.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern IntPtr SetupOpenInfFileW(string path,IntPtr cls,uint style,IntPtr line);
 [DllImport("setupapi.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern bool SetupOpenAppendInfFileW(string path,IntPtr inf,IntPtr line);
 [DllImport("setupapi.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern int SetupGetLineCountW(IntPtr inf,string section);
 [DllImport("setupapi.dll")] public static extern void SetupCloseInfFile(IntPtr inf);
 [DllImport("setupapi.dll",SetLastError=true)] public static extern IntPtr SetupOpenFileQueue();
 [DllImport("setupapi.dll",SetLastError=true)] public static extern bool SetupCloseFileQueue(IntPtr queue);
 [DllImport("setupapi.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern bool SetupInstallFilesFromInfSectionW(IntPtr inf,IntPtr layout,IntPtr queue,string sec,string root,uint flags);
 [DllImport("setupapi.dll",SetLastError=true)] public static extern bool SetupGetFileQueueCount(IntPtr queue,uint op,out uint count);
 public static string Queue(IntPtr inf,string section,string root) {
   IntPtr q=SetupOpenFileQueue(); if(q==new IntPtr(-1))throw new Exception("Open queue failed");
   try {
     bool ok=SetupInstallFilesFromInfSectionW(inf,IntPtr.Zero,q,section,root,0);
     int err=ok?0:Marshal.GetLastWin32Error(); uint count;
     if(!SetupGetFileQueueCount(q,0,out count))throw new Exception("Count failed");
     return String.Format("ok={0} error=0x{1:X8} copyCount={2}",ok,err,count);
   }finally{SetupCloseFileQueue(q);}
 }
}
'@
$nullPtr=[IntPtr]::Zero
$common='Common_BthA2dp_Install'
$mpm='BtaMPM.CopyFilesOnly'
foreach ($mode in 'source-only','donor-chain','complete') {
 $h=[Probe]::SetupOpenInfFileW((Join-Path $dir 'microsoft_bluetooth_a2dp_src.inf'),$nullPtr,2,$nullPtr)
 if ($h.ToInt64() -eq -1) { throw 'Source open failed' }
 try {
  $providers=@()
  if ($mode -ne 'source-only') { $providers+=@(Join-Path $dir 'microsoft_bluetooth_a2dp.inf'; Join-Path $dir 'btampm.inf') }
  if ($mode -eq 'complete') { $providers+=@(Join-Path $env:windir 'INF\ks.inf'; Join-Path $env:windir 'INF\wdmaudio.inf') }
  foreach ($path in $providers) { if (![Probe]::SetupOpenAppendInfFileW($path,$h,$nullPtr)){throw "Append failed $path"} }
  foreach ($sec in 'BthA2dpSrc',$common,"$common.Services","$common.Interfaces",$mpm,'KS.Registration','WDMAUDIO.Registration','MSSYSFX.CopyFilesAndRegister') {
   $n=[Probe]::SetupGetLineCountW($h,$sec)
   "SECTION mode=$mode section=$sec lines=$n"
   if ($mode -eq 'complete' -and $n -lt 1) { throw "Missing section $sec" }
  }
  foreach ($sec in 'BthA2dpSrc',$common,$mpm) { "QUEUE mode=$mode section=$sec $([Probe]::Queue($h,$sec,$dir))" }
 } finally { [Probe]::SetupCloseInfFile($h) }
}
