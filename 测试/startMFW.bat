REM 设置代码页为UTF-8，启用延迟扩展
chcp 65001
setlocal enabledelayedexpansion
REM ---------------------运行次数判断----------------------------
set "idx=0"
for /f "tokens=1" %%a in (E:\Games\BetterGI\自启动任务\MFWjudge.txt) do (
    set /a idx+=1
    if !idx! equ 1 set "L1=%%a"
)
for /f "tokens=1" %%a in ("!date!") do set "D=%%a"
break > "E:\Games\BetterGI\自启动任务\MFWjudge.txt"
echo !D! > "E:\Games\BetterGI\自启动任务\MFWjudge.txt"
REM 启动PGR
if "!D!" == "!L1!" (
	echo 今日已运行，上一次（L1）：!L1!，今天（D）：!D! >> "E:\Games\BetterGI\自启动任务\MFWjudge.txt"
) else (
	start "" "E:\YXArkNights-12.0\shell\MuMuPlayer.exe" -p com.kurogame.haru.hero -v 0 
	powershell -Command "$code='[DllImport(\"user32.dll\")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; Add-Type -MemberDefinition $code -Name Win32 -Namespace Win32; $hwnd = [Win32.Win32]::FindWindow([NullString]::Value, 'MuMu模拟器12'); if ($hwnd -ne [IntPtr]::Zero) { [Win32.Win32]::ShowWindow($hwnd, 6) } else { Write-Host '未找到MuMu模拟器12窗口' }"
    timeout /t 1
	powershell -Command "$code='[DllImport(\"user32.dll\")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; Add-Type -MemberDefinition $code -Name Win32 -Namespace Win32; $hwnd = [Win32.Win32]::FindWindow([NullString]::Value, 'MuMu模拟器12'); if ($hwnd -ne [IntPtr]::Zero) { [Win32.Win32]::ShowWindow($hwnd, 6) } else { Write-Host '未找到MuMu模拟器12窗口' }"
)
