@echo off
chcp 65001
echo [%date% %time%] --------------------------endHSR.bat--------------------------------
taskkill /f /im StarRail.exe
taskkill /f /im PaddleOCR-json.exe
taskkill /f /im "March7th Launcher.exe"
echo [%date% %time%] --------------------------------------------------------------------