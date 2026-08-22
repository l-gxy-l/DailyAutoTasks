@echo off
chcp 65001
setlocal enabledelayedexpansion
cd /d "%~dp0"
cd ..\..\
echo [%date% %time%] -----------------------startMaaEnd.bat------------------------------
for /f "tokens=2 delims==" %%a in ('findstr /b "path_maaend=" ".\config\paths.ini"') do set "PATH_MAAEND=%%a"
echo [%date% %time%] 禁止maaend出站，阻止自动更新，并检查管理员权限
netsh advfirewall firewall add rule name="BlockMaaEnd" dir=out program="!PATH_MAAEND!" action=block
if %errorlevel% neq 0 (
    echo 添加防火墙规则失败，请检查管理员权限！
    pause
    exit /b
)
call "!PATH_MAAEND!" --autostart -i="Normal"
echo [%date% %time%] --------------------------------------------------------------------