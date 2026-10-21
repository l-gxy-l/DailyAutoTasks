@echo off
chcp 65001
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~自动完成日常.bat~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo [%date% %time%] 设置代码页为UTF-8，启用延迟扩展，检测管理员权限
setlocal enabledelayedexpansion
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo 请右键以管理员身份运行此脚本！
    pause
    exit
)
echo=
cd /d "%~dp0"
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~前系统操作~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo [%date% %time%] 关闭系统声音
call .\tools\audioMute.exe mute
if %errorlevel% equ 0 (
    echo %date% %time% 已静音
	echo [%date% %time%] 已静音
) else if %errorlevel% equ 2 (
    echo %date% %time% 静音失败，错误码: %errorlevel%
	echo [%date% %time%] 静音失败，错误码: %errorlevel%
) else (
	echo %date% %time% 错误码: %errorlevel%。4是无效参数，5是参数不足。
	echo [%date% %time%] 错误码: %errorlevel%。4是无效参数，5是参数不足。
)
echo=
echo [%date% %time%] 调亮度
WMIC /NAMESPACE:\\root\wmi PATH WmiMonitorBrightnessMethods WHERE "Active=TRUE" CALL WmiSetBrightness Brightness=1 Timeout=0
echo=
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~领取时长~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
start /min .\tools\GIcloud.url >nul 2>&1
echo=
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~MAA任务~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo [%date% %time%] 开模拟器
taskkill /f /im adb.exe
for /f "tokens=2 delims==" %%a in ('findstr /b "path_mumu=" ".\config\paths.ini"') do set "PATH_MUMU=%%a"
start "" "!PATH_MUMU!"  >nul 2>&1
timeout /t 15
echo=
echo [%date% %time%] 关浏览器,以下一行如果没有任何内容就表明关闭失败
taskkill /IM msedge.exe 2>&1 | findstr /i "SUCCESS"
echo=
for /f "tokens=2 delims==" %%a in ('findstr /b "path_maa=" ".\config\paths.ini"') do set "PATH_MAA=%%a"
echo [%date% %time%] 禁止maa出站，阻止自动更新，并检查管理员权限
netsh advfirewall firewall add rule name="BlockMaa" dir=out program="!PATH_MAA!" action=block
if %errorlevel% neq 0 (
    echo 添加防火墙规则失败，请检查管理员权限！
    pause
    exit /b
)
echo [%date% %time%] 启动MAA
start /min "" "!PATH_MAA!" >nul 2>&1
timeout /t 30
echo=
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~BGI任务~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
explorer.exe shell:::{3080F90D-D7AD-11D9-BD98-0000947B0257}
echo [%date% %time%] 异步运行，监控 YuanShen.exe 关闭及超时
start /min "" ".\tasks\BGI\endBGI.bat"
call .\tasks\BGI\BGIAutoRun.bat
echo=
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HSR任务~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for /f "tokens=2 delims==" %%a in ('findstr /b "path_march7th=" ".\config\paths.ini"') do set "PATH_MARCH7TH=%%a"
echo [%date% %time%] 异步运行，一段时间后开始检测HSR关闭
start /min "" ".\tasks\HSR\endHSR.bat"
echo [%date% %time%] 启动M7th
call "!PATH_MARCH7TH!" -S main -e
echo=
echo [%date% %time%] 当前内存使用：
systeminfo | find "Available Physical Memory"
echo [%date% %time%] 当前进程数：
tasklist | find /c /v ""
echo=
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~EnF任务~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
call .\tasks\EnF\startMaaEnd.bat
call .\tasks\EnF\endArkE.bat
echo=
echo [%date% %time%] 关mumu模拟器
taskkill /f /im "MuMuPlayer.exe"
echo [%date% %time%] 删除阻止出站规则
netsh advfirewall firewall delete rule name="BlockMaa"
echo=
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~MFW任务~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo [%date% %time%] 开模拟器
taskkill /f /im adb.exe
for /f "tokens=2 delims==" %%a in ('findstr /b "path_mumu=" ".\config\paths.ini"') do set "PATH_MUMU=%%a"
start "" "!PATH_MUMU!"  >nul 2>&1
timeout /t 25
echo=
echo [%date% %time%] 启动FOS,同步启动会导致cmd被FOS一直占用，bat内部采取异步启动
call .\tasks\MFW\startMFW-FOS.bat
echo [%date% %time%] 等待模拟器启动

echo=
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~后系统操作~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo [%date% %time%] 等待FOS结束...
set "fos_wait=0"
:wait_fos_loop
timeout /t 60 /nobreak >nul
set /a fos_wait+=60
echo !fos_wait!
tasklist /fi "imagename eq FOS.exe" 2>nul | find /i "FOS.exe" >nul
if !errorlevel! equ 0 (
    if !fos_wait! geq 2400 (
        echo [%date% %time%] FOS等待超时，强制结束相关进程...
        set "screenshot_path="
        for /f "delims=" %%s in ('powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\tools\capture-screenshot.ps1" -EventName FOSTimeout') do set "screenshot_path=%%s"
        taskkill /f /im FOS.exe
        set "fos_kill_exit_code=!errorlevel!"
		taskkill /f /im adb.exe
        powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\tools\send-notification.ps1" -EventName FOSTimeout -WaitSeconds 2400 -TerminationExitCode !fos_kill_exit_code! -ScreenshotPath "!screenshot_path!"
        goto :after_fos
    )
    goto :wait_fos_loop
)
:after_fos
echo [%date% %time%] FOS已关闭，继续执行...
echo [%date% %time%] 关mumu模拟器
taskkill /f /im "MuMuPlayer.exe"
taskkill /f /im MuMuPlayerService.exe
echo [%date% %time%] 释放模拟器adb
taskkill /f /im adb.exe
echo=
echo [%date% %time%] 调节亮度为50
WMIC /NAMESPACE:\\root\wmi PATH WmiMonitorBrightnessMethods WHERE "Active=TRUE" CALL WmiSetBrightness Brightness=50 Timeout=0
echo [%date% %time%] 取消系统静音
call .\tools\audioMute.exe unmute
if %errorlevel% equ 1 (
    echo %date% %time% 声音已打开
) else if %errorlevel% equ 3 (
    echo %date% %time% 打开声音失败，错误码: %errorlevel%
) else (
	echo %date% %time% 错误码: %errorlevel%。4是无效参数，5是参数不足。
)
echo [%date% %time%] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
