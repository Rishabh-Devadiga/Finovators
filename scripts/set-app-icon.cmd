@echo off
setlocal
cd /d %~dp0\..

powershell -ExecutionPolicy Bypass -File scripts\set-app-icon.ps1 %*
