REM @echo off
chcp 65001
echo [%date% %time%] 设置代码页为UTF-8，启用延迟扩展，检测管理员权限
setlocal enabledelayedexpansion

NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo 请右键以管理员身份运行此脚本！
    pause
    exit
)

cd /d "%~dp0"
echo [%date% %time%] 关闭系统声音
call .\tools\audioMute.exe mute
if %errorlevel% equ 0 (
    echo %date% %time% 已静音 >> .\logs\音频日志.log
) else if %errorlevel% equ 2 (
    echo %date% %time% 静音失败，错误码: %errorlevel% >> .\logs\音频日志.log
) else (
	echo %date% %time% 错误码: %errorlevel%。4是无效参数，5是参数不足。 >> .\logs\音频日志.log
)

echo [%date% %time%] 调亮度
WMIC /NAMESPACE:\\root\wmi PATH WmiMonitorBrightnessMethods WHERE "Active=TRUE" CALL WmiSetBrightness Brightness=1 Timeout=0

echo [%date% %time%] ----------------------领取时长------------------------------
start .\tools\GIcloud.url  >nul 2>&1

echo [%date% %time%] -----------------------MAA任务------------------------------
echo [%date% %time%] 开模拟器
taskkill /f /im adb.exe
for /f "tokens=2 delims==" %%a in ('findstr /b "path_mumu=" ".\config\paths.ini"') do set "PATH_MUMU=%%a"
start "" "!PATH_MUMU!"  >nul 2>&1
timeout /t 15

echo [%date% %time%] 关浏览器
taskkill /IM msedge.exe
echo [%date% %time%] MAA
for /f "tokens=2 delims==" %%a in ('findstr /b "path_maa=" ".\config\paths.ini"') do set "PATH_MAA=%%a"
start "" "!PATH_MAA!"  >nul 2>&1
timeout /t 30

echo [%date% %time%] -----------------------BGI任务------------------------------
explorer.exe shell:::{3080F90D-D7AD-11D9-BD98-0000947B0257}
call .\tasks\BGI\BGIAutoRun.bat
taskkill /f /im "MuMuPlayerService.exe"

echo [%date% %time%] -----------------------HSR任务------------------------------
for /f "tokens=2 delims==" %%a in ('findstr /b "path_march7th=" ".\config\paths.ini"') do set "PATH_MARCH7TH=%%a"
call "!PATH_MARCH7TH!" -S main -e
call ".\tasks\HSR\endHSR.bat"

echo [%date% %time%] -----------------------EnF任务------------------------------
call .\tasks\EnF\startMaaEnd.bat
call .\tasks\EnF\endArkE.bat

echo [%date% %time%] 调节亮度为50
WMIC /NAMESPACE:\\root\wmi PATH WmiMonitorBrightnessMethods WHERE "Active=TRUE" CALL WmiSetBrightness Brightness=50 Timeout=0

echo [%date% %time%] -----------------------MFW任务------------------------------
call .\tasks\MFW\startMFW-FOS.bat
taskkill /f /im "MuMuPlayerService.exe"

echo [%date% %time%] 取消系统静音
call .\tools\audioMute.exe unmute
if %errorlevel% equ 1 (
    echo %date% %time% 声音已打开 >> .\logs\音频日志.log
) else if %errorlevel% equ 3 (
    echo %date% %time% 打开声音失败，错误码: %errorlevel% >> .\logs\音频日志.log
) else (
	echo %date% %time% 错误码: %errorlevel%。4是无效参数，5是参数不足。 >> .\logs\音频日志.log
)
echo [%date% %time%] -----------------------任务结束------------------------------
