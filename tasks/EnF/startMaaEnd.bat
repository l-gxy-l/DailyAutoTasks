chcp 65001
REM -----------------------EnF任务------------------------------
for /f "tokens=2 delims==" %%a in ('findstr /b "path_maaend=" ".\config\paths.ini"') do set "PATH_MAAEND=%%a"
"!PATH_MAAEND!" --autostart -i="Normal"
