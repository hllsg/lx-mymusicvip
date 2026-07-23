@echo off
chcp 65001 >nul
title 我的音源 — 首次安装
cd /d "%~dp0"

echo ============================================
echo  我的音源 — 首次使用安装
echo ============================================
echo.

REM 检查 Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
  echo [错误] 未检测到 Node.js，请先安装：https://nodejs.org
  echo 安装后重新运行本脚本即可。
  pause
  exit /b 1
)
echo [✓] Node.js 已就绪:
node --version

echo.
echo [*] 正在安装依赖...
call npm install

if %errorlevel% neq 0 (
  echo [错误] 依赖安装失败，请检查网络后重试。
  pause
  exit /b 1
)

echo.
echo ============================================
echo  安装完成！
echo.
echo  使用方法：
echo    双击「启动我的LX.vbs」即可一键听歌
echo.
echo  首次使用需登录：
echo    启动后会自动打开 http://127.0.0.1:3000
echo    网易云扫码 / QQ粘贴Cookie 即可
echo ============================================
pause
