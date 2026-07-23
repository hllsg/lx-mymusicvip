@echo off
REM Silent backend launcher for the one-click starter.
REM Skips if backend already running on port 3000.

set HOST=127.0.0.1
set PORT=3000
set MINERADIO_UPDATE_MANIFEST=disabled

netstat -ano | findstr ":3000" | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 exit /b 0

cd /d "%~dp0"
node server.js
