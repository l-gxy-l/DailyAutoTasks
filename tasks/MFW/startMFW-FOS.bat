chcp 65001
setlocal enabledelayedexpansion
cd /d "%~dp0"
cd ..\..\
REM -----------------------MFW-FOS-------------------------------
REM 判断
set "idx=0"
for /f "tokens=1" %%a in (.\config\MFWjudge.txt) do (
    set /a idx+=1
    if !idx! equ 1 set "L1=%%a"
)
for /f "tokens=1" %%a in ("!date!") do set "D=%%a"
break > ".\config\MFWjudge.txt"
echo !D! > ".\config\MFWjudge.txt"
REM 启动
for /f "tokens=2 delims==" %%a in ('findstr /b "path_fos=" ".\config\paths.ini"') do set "PATH_FOS=%%a"
if "!D!" == "!L1!" (
	echo 今日已运行，上一次（L1）：!L1!，今天（D）：!D! >> ".\config\MFWjudge.txt"
) else (
	taskkill /f /im adb.exe
	call "" "!PATH_FOS!" --direct-run
)
