@echo off
setlocal
cd /d %~dp0\..
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\prepare-web-release.ps1 %*
endlocal
