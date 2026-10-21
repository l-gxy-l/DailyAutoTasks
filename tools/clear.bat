@echo off
chcp 65001 >nul
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0clear.ps1" %*
exit /b %errorlevel%
