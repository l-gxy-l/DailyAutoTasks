@echo off
chcp 65001
setlocal enabledelayedexpansion
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo 请右键以管理员身份运行此脚本！
    pause
    exit
)

cd /d "%~dp0"
echo [%date% %time%] ================ 1. 生成标准日期字符串 ==================
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "datetime=%%a"
REM 提取并去掉月份和日期的前导零
set /a "mm=1%datetime:~4,2% - 100"
set /a "dd=1%datetime:~6,2% - 100"
REM 组合成目标格式：2026-1-1_11:11:11
set "D=%datetime:~0,4%-!mm!-!dd!_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"

echo [%date% %time%] ================ 2. 创建日志目录 ========================
if not exist ".\logs\主脚本运行日志" mkdir ".\logs\主脚本运行日志"
set "mainlog=.\logs\主脚本运行日志\%D%-日常.log"
if not exist ".\config" mkdir ".\config"
set "temp_output=.\config\temp_DailyOutput_%random%.log"
set "logmanlog=.\logs\主脚本运行日志\%D%-性能日志"
set "logmanlogMisc=%logmanlog%_misc"
REM 创建带 BOM 的 UTF-8 日志文件，解决中文乱码
break > "%mainlog%"
powershell -Command "$utf8 = New-Object System.Text.UTF8Encoding $true; [System.IO.File]::WriteAllText('%mainlog%', '', $utf8)"
echo [%date% %time%] -------------------------------- 前置任务已完成 ---------------------------------------- >> "%mainlog%"
echo [%date% %time%] ================ 3. 配置 logman 采集器 ================== >> "%mainlog%"
echo (DEBUG: 3. 配置 logman 采集器)
echo [%date% %time%] 配置 logman 采集器 >> "%mainlog%"
set "logmanName=DailyTaskPerfCollector"
set "logmanNameMisc=%logmanName%_misc"

echo [%date% %time%] 先删除可能重名的旧采集器 >> "%mainlog%"
echo [%date% %time%] 停止 >> "%mainlog%"
logman stop "%logmanName%" >> "%mainlog%"
logman stop "%logmanNameMisc%" >> "%mainlog%"
echo [%date% %time%] 删除 >> "%mainlog%"
logman delete "%logmanName%" >> "%mainlog%"
logman delete "%logmanNameMisc%" >> "%mainlog%"

echo [%date% %time%] 创建新的计数器采集器%logmanName% >> "%mainlog%"
logman create counter "%logmanName%" -o "%logmanlog%" -f bincirc -max 500 -si 30 -v mmddhhmm ^
-c "\Memory\%% Committed Bytes In Use" ^
   "\Processor(_Total)\%% Processor Time" ^
   "\Process(_Total)\Handle Count" ^
   "\Memory\Pool Nonpaged Bytes"
echo [%date% %time%] 配置辅助采集器%logmanNameMisc% >> "%mainlog%"
logman create counter "%logmanNameMisc%" -o "%logmanlogMisc%" -f bincirc -max 300 -si 60 -v mmddhhmm ^
-c "\System\Processes" ^
   "\System\Threads" ^
   "\Memory\Pool Paged Bytes"

echo [%date% %time%] ================ 4. 启动性能日志记录 ==================== >> "%mainlog%"
echo (DEBUG: 4. 启动性能日志记录)
echo [%date% %time%] 启动性能日志记录 >> "%mainlog%"
logman start "%logmanName%" >> "%mainlog%"
logman start "%logmanNameMisc%" >> "%mainlog%"
echo [%date% %time%] 性能监控已启动，数据保存到: %logmanlog%.blg >> "%mainlog%"

echo [%date% %time%] ================ 5. 运行自动完成日常.bat ================ >> "%mainlog%"
echo (DEBUG: 5. 运行自动完成日常.bat)
echo [%date% %time%] 查看mainlog占用情况
handle %mainlog%
echo [%date% %time%] 自动完成日常.bat开始执行 >> "%mainlog%"
call ".\自动完成日常.bat" >> "%temp_output%" 2>&1
echo [%date% %time%] 查看mainlog占用情况
handle %mainlog%
echo 清除日志文件占用
taskkill /f /im adb.exe
taskkill /f /im MuMuPlayer.exe
taskkill /f /im MuMuPlayerService.exe
type "%temp_output%" >> "%mainlog%"
echo [%date% %time%] 删除临时文件%temp_output% >> "%mainlog%"
del "%temp_output%"
echo=
echo (DEBUG: 已从自动完成日常.bat返回)

echo [%date% %time%] ================ 6. 停止并删除性能采集器 ================ >> "%mainlog%"
echo (DEBUG: 6. 停止并删除性能采集器)
echo [%date% %time%] 停止性能采集器 >> "%mainlog%"
logman stop "%logmanName%"
logman stop "%logmanNameMisc%"

echo [%date% %time%] 删除性能采集器 >> "%mainlog%"
logman delete "%logmanName%" >> "%mainlog%"
logman delete "%logmanNameMisc%" >> "%mainlog%"

echo [%date% %time%] 性能监控已停止。 >> "%mainlog%"
shutdown -s -t 30
pause