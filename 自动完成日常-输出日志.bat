REM @echo off
chcp 65001
setlocal enabledelayedexpansion
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo 请右键以管理员身份运行此脚本！
    pause
    exit
)

cd /d "%~dp0"
:: ====== 1. 生成标准日期字符串 ======
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "datetime=%%a"
REM 提取并去掉月份和日期的前导零
set /a "mm=1%datetime:~4,2% - 100"
set /a "dd=1%datetime:~6,2% - 100"
REM 组合成目标格式：2026-1-1_11:11:11
set "D=%datetime:~0,4%-!mm!-!dd!_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"

:: ====== 2. 创建日志目录 ======
if not exist ".\logs\主脚本运行日志" mkdir ".\logs\主脚本运行日志"
set "mainlog=.\logs\主脚本运行日志\%D%-日常.log"
set "logmanlog=.\logs\主脚本运行日志\%D%-性能日志"
REM 创建带 BOM 的 UTF-8 日志文件，解决中文乱码
break > "%mainlog%"
powershell -Command "$utf8 = New-Object System.Text.UTF8Encoding $true; [System.IO.File]::WriteAllText('%mainlog%', '', $utf8)"

:: ====== 3. 配置 logman 采集器 ======
echo [%date% %time%] 配置 logman 采集器 >> "%mainlog%"
set "logmanName=DailyTaskPerfCollector" >> "%mainlog%"
echo [%date% %time%] 先删除可能重名的旧采集器 >> "%mainlog%"
logman stop "%logmanName%" >> "%mainlog%"
logman delete "%logmanName%" >> "%mainlog%"
echo [%date% %time%] 创建新的计数器采集器（记录内存百分比和可用 MB） >> "%mainlog%"
logman create counter "%logmanName%" -o "%logmanlog%" -f bincirc -max 500 -si 30 -v mmddhhmm -c "\Memory\%% Committed Bytes In Use" "\Memory\Available MBytes" "\Processor(_Total)\%% Processor Time" >> "%mainlog%"

:: ====== 4. 启动性能日志记录 ======
echo [%date% %time%] 启动性能日志记录 >> "%mainlog%"
logman start "%logmanName%" >> "%mainlog%"
echo [%date% %time%] 性能监控已启动，数据保存到: %logmanlog%.blg >> "%mainlog%"

:: ====== 5. 运行自动完成日常.bat，并将输出重定向到日志文件 ======
echo [%date% %time%] 自动完成日常.bat开始执行 >> "%mainlog%"
call ".\自动完成日常.bat" >> "%mainlog%" 2>&1
echo [%date% %time%] 自动完成日常.bat执行完毕 >> "%mainlog%"

:: ====== 6. 停止并删除性能采集器 ======
echo [%date% %time%] 停止性能采集器 >> "%mainlog%"
logman stop "%logmanName%" >> "%mainlog%"
logman delete "%logmanName%" >> "%mainlog%"
echo [%date% %time%] 性能监控已停止。 >> "%mainlog%"
pause