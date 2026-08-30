@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-dsh.ps1"
if %errorlevel% neq 0 (
    echo.
    echo Process exited with code %errorlevel%.
    pause
)
