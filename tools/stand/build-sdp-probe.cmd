@echo off
setlocal
call "%~dp0..\vsenv.cmd" || exit /b 1
if not exist "%~dp0..\..\build" mkdir "%~dp0..\..\build"
cl /nologo /std:c++17 /EHsc /W4 /D_WIN32_WINNT=0x0601 "%~dp0sdp-probe.cpp" /Fe:"%~dp0..\..\build\sdp-probe.exe" /link Ws2_32.lib Bthprops.lib
exit /b %ERRORLEVEL%
