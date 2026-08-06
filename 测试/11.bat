@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

if not exist ".\config\paths.ini" (
    echo 文件不存在！
) else (
    echo 文件存在
)

echo 正在查找配置...
findstr /b "path_bgi=" ".\config\paths.ini"
if %errorlevel% neq 0 (
    echo 未找到 path_bgi= 配置行！
    pause
    exit /b
)

for /f "tokens=2 delims==" %%a in ('findstr /b "path_maaend=" ".\config\paths.ini"') do set "PATH_MAAEND=%%a"
echo kkk 路径=[!PATH_MAAEND!]




pause