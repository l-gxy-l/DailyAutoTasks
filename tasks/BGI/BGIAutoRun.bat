@echo off
:: 设置代码页为UTF-8，启用延迟扩展
chcp 65001
setlocal enabledelayedexpansion
:: 切换到主文件根目录
cd /d "%~dp0"
cd ..\..\
echo [%date% %time%] --------------------------------------BGIAutoRun.bat--------------------------------------------------------
echo [%date% %time%] -------Loop计算-------
echo 读judge文件，赋值给LX。
set "idx=0"
for /f "tokens=1" %%a in (.\config\BGIjudge.txt) do (
    set /a idx+=1
    if !idx! equ 1 set "L1=%%a"
    if !idx! equ 2 set "L2=%%a"
    if !idx! equ 3 set "L3=%%a"
	if !idx! equ 5 set "LP=%%a"
	if !idx! equ 6 set "L6=%%a"
)
echo (L1：!L1!,0-囤 1-刷)
echo (L2：!L2!,1-A 2-B 3-C)
echo (L3：!L3!,ABAC的分支判断-分支1或2)
echo (LP：!LP!,上一次的循环数，即上次运行bat时计算得到的预设名)
echo (L6：!L6!,上次运行日期或错误信息)
echo=
echo 计算下一次BGI需要执行的预设
echo 设置初始值
set "N1=0"
set "N2=1"
set "N3=1"
set "N4=无错误"
set "T5=囤"
for /f "tokens=1" %%a in ("!date!") do set "T6=%%a"
echo 今天日期T6:!T6!
echo=
echo [%date% %time%]  输出到调试txt，共4行，如果运行过了则再打印到第5行,两个break：不知道为什么有时候首个break会不清空文件
break > ".\logs\BGI调试日志.log"
break > ".\logs\BGI调试日志.log"
echo=
echo 上次运行日期L6==!L6!
echo 今天运行日期T6==!T6!
echo 循环数信息：L1,L2,L3==!L1!,!L2!,!L3!
echo 循环数计算结果：上一次循环数（LP）是：!LP!，本次运行的循环数（T5）是：!T5!
echo=
echo [%date% %time%]  进行循环数计算并赋给T5
if "!T6!" == "!L6!" (
	set T5=!LP!
	echo T6（!T6!）==L6（!L6!），今天已经计算过了~
) else (
	if "!L1!" == "0" (
		set "T5=囤"
		set "N1=1"
		set "N2=!L2!"
		set "N3=!L3!"
	) else if "!L1!"=="1" (
		set "N1=0"
		if "!L2!"=="1" (
			set "T5=A"	
			if "!L3!"=="1" (
				set "N2=2"
				set "N3=2"
			) else if "!L3!"=="2" (
				set "N2=3"
				set "N3=1"
			) else (set "N4=BGIjudge文件里的---L3---循环数出现错误,但问题不大，会导致后天的刷C变成刷B。"
				echo [ERROR]!date!,!time!:!N4! >> ".\logs\BGI循环日志.log"
			) 
		) else if "!L2!"=="2" (
			set "T5=B"
			set "N2=1"
			set "N3=!L3!"
		) else if "!L2!"=="3" (
			set "T5=C"
			set "N2=1"
			set "N3=!L3!"		
		) else (set "N4=BGIjudge文件里的---L2---循环数出现错误，本次无法运行BGI"
			echo [ERROR]!date!,!time!:!N4! >> ".\logs\BGI循环日志.log"
			set "T6=L2循环数出现错误，算作今日未运行，最好重开这个bat文件"
		) 
	) else (set "N4=BGIjudge文件里---L1---的循环数出现错误，本次无法运行BGI"
		echo [ERROR]!date!,!time!:!N4! >> ".\logs\BGI循环日志.log"
		set "T6=L1的循环数出现错误，算作今日未运行，最好重开这个bat文件"
	)
	break > ".\config\BGIjudge.txt"
	echo !N1! >> ".\config\BGIjudge.txt"
	echo !N2! >> ".\config\BGIjudge.txt"
	echo !N3! >> ".\config\BGIjudge.txt"
	echo !N4! >> ".\config\BGIjudge.txt"
	echo !T5! >> ".\config\BGIjudge.txt"
	echo !T6! >> ".\config\BGIjudge.txt"
)

echo [%date% %time%]  -------导入BGI路径-------
for /f "tokens=2 delims==" %%a in ('findstr /b "path_bgi=" ".\config\paths.ini"') do set "PATH_BGI=%%a"
echo=
echo [%date% %time%]  根据T5的值，启动BGI预设：!T5!
if "!T5!" == "囤" (
echo !date!,!time!运行了配置---囤体力 >> ".\logs\BGI循环日志.log"
call "!PATH_BGI!" --startOneDragon 循环囤体力 2>&1 | findstr /i "ERROR ERR 错误 失败"
) else if "!T5!" == "A" (
echo !date!,!time!运行了配置---循环A >> ".\logs\BGI循环日志.log"
call "!PATH_BGI!" --startOneDragon 循环A 2>&1 | findstr /i "ERROR ERR 错误 失败"
) else if "!T5!" == "B" (
echo !date!,!time!运行了配置---循环B >> ".\logs\BGI循环日志.log"
call "!PATH_BGI!" --startOneDragon 循环B 2>&1 | findstr /i "ERROR ERR 错误 失败"
) else if "!T5!" == "C" (
echo !date!,!time!运行了配置---循环C >> ".\logs\BGI循环日志.log"
call "!PATH_BGI!" --startOneDragon 循环C 2>&1 | findstr /i "ERROR ERR 错误 失败"
) else (echo [ERROR]!date!,!time!:主程序执行出错，缺少可用数值的L1>> ".\logs\BGI循环日志.log"
	set "T6=上一次主程序执行出错，算作今日未运行，最好重开这个bat文件"
)
echo [%date% %time%] ------------------------------------------------------------------------------------------------------------
echo=



