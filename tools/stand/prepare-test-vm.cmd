@echo off
setlocal
echo ============================================================
echo LDAC A2DP - PREPARE DISPOSABLE VM ONLY
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cs=Get-CimInstance Win32_ComputerSystem; if($cs.Manufacturer -notmatch 'VMware'){Write-Error 'VMware virtual machine not detected'; exit 10}; Write-Host ($cs.Manufacturer+' / '+$cs.Model)"
if errorlevel 1 exit /b 10
net session >nul 2>&1
if errorlevel 1 (echo Run this file as Administrator.& exit /b 11)
certutil -addstore -f Root "%~dp0ldac-a2dp-test.cer"
if errorlevel 1 exit /b 12
certutil -addstore -f TrustedPublisher "%~dp0ldac-a2dp-test.cer"
if errorlevel 1 exit /b 13
bcdedit /set testsigning on
if errorlevel 1 (echo Could not enable test signing. Do NOT disable Secure Boot to bypass this automatically.& exit /b 14)
echo.
echo Test certificate installed and test signing enabled.
echo Restart this disposable VM manually before running install-oppo.cmd.
echo Do NOT run this on the production server.
pause
