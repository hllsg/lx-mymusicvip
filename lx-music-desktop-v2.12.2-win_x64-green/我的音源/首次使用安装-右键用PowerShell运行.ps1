Write-Host "============================================"
Write-Host "  MyMusicSource - First Time Setup"
Write-Host "============================================"
Write-Host ""

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "[ERROR] Node.js not found. Install from: https://nodejs.org"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[OK] Node.js: $(node --version)"

Set-Location -LiteralPath $PSScriptRoot
Write-Host ""
Write-Host "[*] Installing dependencies..."
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] npm install failed. Check your network and retry."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Create desktop shortcut via VBS (handles Chinese reliably)
$vbsPath = Join-Path $PSScriptRoot "启动我的LX.vbs"
$lxExe = Join-Path (Split-Path $PSScriptRoot -Parent) "lx-music-desktop.exe"
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "洛雪music.lnk"

$vbsTemp = Join-Path $env:TEMP "create_lx_shortcut.vbs"
$iconLine = ""
if (Test-Path $lxExe) { $iconLine = "sc.IconLocation = `"$lxExe,0`"" }

@"
Set ws = CreateObject("WScript.Shell")
Set sc = ws.CreateShortcut("$shortcutPath")
sc.TargetPath = "$vbsPath"
sc.WorkingDirectory = "$PSScriptRoot"
sc.Description = "洛雪music - 一键启动（含我的音源后端）"
$iconLine
sc.Save()
"@ | Set-Content -Path $vbsTemp -Encoding Default

Write-Host "[*] Creating desktop shortcut..."
try {
    cscript //nologo "$vbsTemp"
    Remove-Item $vbsTemp -Force
    Write-Host "[OK] Desktop shortcut created on your desktop"
} catch {
    Write-Host "[WARN] Failed to create shortcut: $_"
}

Write-Host ""
Write-Host "============================================"
Write-Host "  Setup complete!"
Write-Host ""
Write-Host "  Desktop shortcut: 洛雪music"
Write-Host "  Login page: http://127.0.0.1:3000"
Write-Host "============================================"
Read-Host "Press Enter to exit"
