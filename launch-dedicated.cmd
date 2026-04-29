@echo off
REM Dedicated-Server — Einstellungen in launch-dedicated.ps1 anpassen.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-dedicated.ps1"
exit /b %ERRORLEVEL%
