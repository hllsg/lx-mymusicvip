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
Write-Host "============================================"
Write-Host "  Setup complete!"
Write-Host ""
Write-Host "  Launch script: $PSScriptRoot\启动我的LX.vbs"
Write-Host "  Login page: http://127.0.0.1:3000"
Write-Host "============================================"
Read-Host "Press Enter to exit"
