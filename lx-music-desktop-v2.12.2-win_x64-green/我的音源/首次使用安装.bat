@echo off
title MyMusicSource - Setup
cd /d "%~dp0"

echo ============================================
echo   MyMusicSource - First Time Setup
echo ============================================
echo.

where node >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] Node.js not found. Please install: https://nodejs.org
  pause
  exit /b 1
)
echo [OK] Node.js ready
node --version

echo.
echo [*] Installing dependencies...
npm install

if %errorlevel% neq 0 (
  echo [ERROR] npm install failed. Check network and retry.
  pause
  exit /b 1
)

echo.
echo ============================================
echo   Setup complete!
echo.
echo   Double-click "启动我的LX.vbs" to start
echo   Login page: http://127.0.0.1:3000
echo   Netease: scan QR  /  QQ: paste cookie
echo ============================================
pause
