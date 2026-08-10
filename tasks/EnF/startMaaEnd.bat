chcp 65001
setlocal enabledelayedexpansion
cd /d "%~dp0"
cd ..\..\
REM -----------------------EnF任务------------------------------
for /f "tokens=2 delims==" %%a in ('findstr /b "path_maaend=" ".\config\paths.ini"') do set "PATH_MAAEND=%%a"
call "!PATH_MAAEND!" --autostart -i="Normal"
