@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
echo [%date% %time%] --------------------------endHSR.bat--------------------------------
echo 等待游戏启动
timeout /nobreak /t 60 >nul
echo [%date% %time%] 等待 StarRail.exe 关闭（超时 1800 秒）...
set "starrail_wait=0"
:wait_starrail_loop
timeout /t 60 /nobreak >nul
set /a starrail_wait+=60
echo !starrail_wait!
tasklist /fi "imagename eq StarRail.exe" 2>nul | find /i "StarRail.exe" >nul
if !errorlevel! equ 0 (
    if !starrail_wait! geq 1800 (
        echo [%date% %time%] StarRail.exe 等待超时，强制结束...
        taskkill /f /im StarRail.exe >nul 2>&1
        set "kill_exit_code=!errorlevel!"
        powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0..\..\tools\send-notification.ps1" -EventName StarRailTimeout -WaitSeconds 1800 -TerminationExitCode !kill_exit_code!
        goto :after_starrail
    )
    goto :wait_starrail_loop
)
:after_starrail
echo [%date% %time%] StarRail.exe 已关闭，继续后续操作
echo [%date% %time%] 关闭OCR、M7th
taskkill /f /im PaddleOCR-json.exe
taskkill /f /im "March7th Launcher.exe"
echo [%date% %time%] --------------------------------------------------------------------
pause
