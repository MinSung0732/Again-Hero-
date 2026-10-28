@echo off
rem Double-click to start the Again-Hero local test match server.
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0localtest_server.ps1" %*
set "server_exit=%ERRORLEVEL%"
echo.
pause
exit /b %server_exit%
