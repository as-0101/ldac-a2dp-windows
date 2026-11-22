@echo off
setlocal
title LDAC ACX LiveKD diagnostic
fltmc >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
set "SCRIPT=%~dp0Launch-WinDbg-LiveKD.ps1"
if not exist "%SCRIPT%" (
    echo Keep Launch-WinDbg-LiveKD.bat and Launch-WinDbg-LiveKD.ps1 in the same folder.
    pause
    exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
echo.
pause
