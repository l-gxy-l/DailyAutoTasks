@echo off
chcp 65001
echo [%date% %time%] -------------------------endArkE.bat--------------------------------
echo [%date% %time%] 关Endfield.exe和MaaEnd
taskkill /f /im Endfield.exe
taskkill /f /im MaaEnd.exe
echo [%date% %time%] 删除阻止出站规则
netsh advfirewall firewall delete rule name="BlockMaaEnd"
echo [%date% %time%] --------------------------------------------------------------------
echo=