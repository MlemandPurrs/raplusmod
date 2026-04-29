@echo off
REM Delegiert an launch-game.ps1 — zuverlässige argv-Übergabe bei Leerzeichen im Pfad (cmd.exe ist dafür ungeeignet).
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-game.ps1" %*
exit /b %ERRORLEVEL%
