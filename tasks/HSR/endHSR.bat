@echo off
chcp 65001
setlocal enabledelayedexpansion
echo [%date% %time%] --------------------------endHSR.bat--------------------------------
echo 等待游戏启动
timeout /t /nobreak 600 >nul
echo [%date% %time%] 等待 StarRail.exe 关闭（超时 3600 秒）...
set "starrail_wait=0"
:wait_starrail_loop
timeout /t 60 /nobreak >nul
set /a starrail_wait+=60
tasklist /fi "imagename eq StarRail.exe" 2>nul | find /i "StarRail.exe" >nul
if !errorlevel! equ 0 (
    if !starrail_wait! geq 3600 (
        echo [%date% %time%] StarRail.exe 等待超时，强制结束...
        taskkill /f /im StarRail.exe >nul 2>&1
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
echo=