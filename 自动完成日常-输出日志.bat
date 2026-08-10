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
:: ====== 1. 生成标准日期字符串（格式：2026-08-09） ======
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "datetime=%%a"
set "today=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%"
set "timestamp=%datetime:~8,2%%datetime:~10,2%%datetime:~12,2%"

:: ====== 2. 创建日志目录 ======
set "logdir=.\logs\自动完成日常运行日志"
if not exist "%logdir%" mkdir "%logdir%"
set "mainlog=%logdir%\日常-%today%_%timestamp%.log"

:: ====== 3. 配置 logman 采集器 ======
set "collector_name=DailyTaskPerf_%today%"
set "blg_file=%logdir%\性能日志_%today%"
REM 先删除可能重名的旧采集器
logman stop "%collector_name%" 
logman delete "%collector_name%" 
REM 创建新的计数器采集器（记录内存百分比和可用 MB）
logman create counter "%collector_name%" -o "%blg_file%" -f bincirc -max 500 -si 30 -v mmddhhmm ^
-c "\Memory\%% Committed Bytes In Use" "\Memory\Available MBytes"

:: ====== 4. 启动性能日志记录 ======
logman start "%collector_name%"
echo [%date% %time%] 性能监控已启动，数据保存到: %blg_file%.blg > "%mainlog%"

:: ====== 5. 运行自动完成日常.bat，并将输出重定向到日志文件 ======

REM === 新增：创建带 BOM 的 UTF-8 日志文件，解决中文乱码 ===
powershell -Command "$utf8 = New-Object System.Text.UTF8Encoding $true; [System.IO.File]::WriteAllText('%mainlog%', '', $utf8)"
echo [%date% %time%] 自动完成日常.bat开始执行 >> "%mainlog%"
call ".\自动完成日常.bat" >> "%mainlog%" 2>&1
echo [%date% %time%] 自动完成日常.bat执行完毕 >> "%mainlog%"

:: ====== 6. 停止并删除性能采集器 ======
logman stop "%collector_name%"
logman delete "%collector_name%"
echo [%date% %time%] 性能监控已停止。

echo.
echo 所有日志已保存到: %logdir%
pause