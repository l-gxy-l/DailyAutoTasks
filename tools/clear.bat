echo [%date% %time%] 删除系统日志记录器
logman stop DailyTaskPerfCollector
logman stop DailyTaskPerfCollector_misc
echo [%date% %time%] 删除阻止出站规则
netsh advfirewall firewall delete rule name="BlockMaa"
netsh advfirewall firewall delete rule name="BlockMaaEnd"
