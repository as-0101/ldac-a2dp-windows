@echo off
setlocal
call "%~dp0..\vsenv.cmd" || exit /b 1
if not exist "%~dp0..\..\build" mkdir "%~dp0..\..\build"
cl /nologo /std:c++17 /EHsc /W4 /D_WIN32_WINNT=0x0A00 "%~dp0oppo-driver-tool.cpp" /Fe:"%~dp0..\..\build\oppo-driver-tool.exe" /link Setupapi.lib Newdev.lib Cfgmgr32.lib Advapi32.lib
exit /b %ERRORLEVEL%
