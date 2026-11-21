@echo off
setlocal
net session >nul 2>&1
if errorlevel 1 (echo Right-click and Run as administrator.& pause & exit /b 1)
"%~dp0oppo-driver-tool.exe" upgrade
set RC=%ERRORLEVEL%
echo.
echo Upgrade exit code: %RC%
pause
exit /b %RC%
