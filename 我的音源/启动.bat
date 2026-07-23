@echo off
chcp 65001 >nul
title 我的音源后端 (lx 自定义源用)

REM 只监听本机，避免局域网访问
set HOST=127.0.0.1
set PORT=3000
REM 关闭联网更新检查，纯本地取址后端
set MINERADIO_UPDATE_MANIFEST=disabled

cd /d "%~dp0"

echo ============================================
echo  我的音源后端 (独立于 mineradio)
echo  地址: http://127.0.0.1:3000
echo  登录信息: 本文件夹下 .netease-cookie / .qq-cookie
echo  关闭此窗口即停止服务。lx 播放时需保持开启。
echo ============================================
echo.

node server.js

echo.
echo 服务已退出。按任意键关闭窗口...
pause >nul
