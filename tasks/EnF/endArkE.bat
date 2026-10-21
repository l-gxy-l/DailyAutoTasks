@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
echo [%date% %time%] -------------------------endArkE.bat--------------------------------
echo [%date% %time%] 等待 Endfield.exe 关闭（超时 3600 秒，每 600 秒检查一次）...
set "endfield_wait=0"
:wait_endfield_loop
timeout /t 600 /nobreak >nul
set /a endfield_wait+=600
echo !endfield_wait!
tasklist /fi "imagename eq Endfield.exe" 2>nul | find /i "Endfield.exe" >nul
if !errorlevel! equ 0 (
    if !endfield_wait! geq 3600 (
        echo [%date% %time%] Endfield.exe 等待超时，强制结束...
        set "screenshot_path="
        for /f "delims=" %%s in ('powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0..\..\tools\capture-screenshot.ps1" -EventName EnFTimeout') do set "screenshot_path=%%s"
        taskkill /f /im Endfield.exe >nul 2>&1
        set "kill_exit_code=!errorlevel!"
        powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0..\..\tools\send-notification.ps1" -EventName EnFTimeout -WaitSeconds 3600 -TerminationExitCode !kill_exit_code! -ScreenshotPath "!screenshot_path!"
        goto :after_endfield
    )
    goto :wait_endfield_loop
)
:after_endfield
echo [%date% %time%] Endfield.exe 已关闭，继续后续操作
echo [%date% %time%] 关闭MaaEnd
taskkill /f /im MaaEnd.exe
echo [%date% %time%] 删除阻止出站规则
netsh advfirewall firewall delete rule name="BlockMaaEnd"
echo [%date% %time%] --------------------------------------------------------------------
echo=
