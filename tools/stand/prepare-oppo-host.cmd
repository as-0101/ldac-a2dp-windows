@echo off
setlocal
echo ============================================================
echo LDAC A2DP - PREPARE PHYSICAL WINDOWS SERVER 2022
echo ============================================================
net session >nul 2>&1
if errorlevel 1 (echo Run this file as Administrator.& exit /b 11)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$v=(Get-CimInstance Win32_OperatingSystem).BuildNumber; if($v -ne '20348'){Write-Error ('Unsupported Windows build: '+$v); exit 10}; Write-Host ('Windows Server build '+$v+' confirmed')"
if errorlevel 1 exit /b 10
certutil -addstore -f Root "%~dp0ldac-a2dp-test.cer"
if errorlevel 1 exit /b 12
certutil -addstore -f TrustedPublisher "%~dp0ldac-a2dp-test.cer"
if errorlevel 1 exit /b 13
bcdedit /set testsigning on
if errorlevel 1 (echo Could not enable test signing. Stop; do not bypass Secure Boot or Code Integrity.& exit /b 14)
echo.
echo Test certificate installed in LocalMachine Root and TrustedPublisher.
echo Test signing enabled. Restart the physical server before installation.
echo Keep this package and rollback-oppo.cmd available.
pause
