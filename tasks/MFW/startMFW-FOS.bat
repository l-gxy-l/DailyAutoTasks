@echo off
chcp 65001
setlocal enabledelayedexpansion
cd /d "%~dp0"
cd ..\..\
echo [%date% %time%] ---------------------startMFW-FOS.bat-------------------------------
echo [%date% %time%] 判断当日是否已经执行
set "idx=0"
for /f "tokens=1" %%a in (.\config\MFWjudge.txt) do (
    set /a idx+=1
    if !idx! equ 1 set "L1=%%a"
)
echo [%date% %time%] 上一次运行日期 L1 ：!L1!
for /f "tokens=1" %%a in ("!date!") do set "D=%%a"
echo [%date% %time%] 今天日期 D 是：!L1!
break > ".\config\MFWjudge.txt"
echo !D! > ".\config\MFWjudge.txt"

echo [%date% %time%] 执行启动任务
for /f "tokens=2 delims==" %%a in ('findstr /b "path_fos=" ".\config\paths.ini"') do set "PATH_FOS=%%a"
if "!D!" == "!L1!" (
	echo 今日已运行，上一次（L1）：!L1!，今天（D）：!D! >> ".\config\MFWjudge.txt"
) else (
	taskkill /f /im adb.exe
	call "" "!PATH_FOS!" --direct-run
)
echo [%date% %time%] --------------------------------------------------------------------
