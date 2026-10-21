@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
echo [%date% %time%] --------------------------endBGI.bat--------------------------------
echo 等待游戏启动
timeout /nobreak /t 60 >nul
echo [%date% %time%] 等待 YuanShen.exe 关闭（超时 7500 秒，约2小时）...
set "yuan_shen_wait=0"
:wait_yuan_shen_loop
timeout /t 2500 /nobreak >nul
set /a yuan_shen_wait+=2500
echo !yuan_shen_wait!
tasklist /fi "imagename eq YuanShen.exe" 2>nul | find /i "YuanShen.exe" >nul
if !errorlevel! equ 0 (
    if !yuan_shen_wait! geq 7500 (
        echo [%date% %time%] YuanShen.exe 等待超时，强制结束...
        set "screenshot_path="
        for /f "delims=" %%s in ('powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0..\..\tools\capture-screenshot.ps1" -EventName YuanShenTimeout') do set "screenshot_path=%%s"
        taskkill /f /im YuanShen.exe >nul 2>&1
        set "kill_exit_code=!errorlevel!"
        powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0..\..\tools\send-notification.ps1" -EventName YuanShenTimeout -WaitSeconds 7500 -TerminationExitCode !kill_exit_code! -ScreenshotPath "!screenshot_path!"
        goto :after_yuan_shen
    )
    goto :wait_yuan_shen_loop
)
:after_yuan_shen
echo [%date% %time%] YuanShen.exe 已关闭，继续后续操作
taskkill /f /im BetterGI.exe
echo [%date% %time%] --------------------------------------------------------------------
pause
