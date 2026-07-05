@echo off
cd /d "%~dp0"
set /p CHAR=Character name (e.g. Jotaro): 
set /p STAND=Stand name (e.g. Star Platinum): 
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\new-character-mod.ps1" -CharacterName "%CHAR%" -StandName "%STAND%"
echo.
pause
