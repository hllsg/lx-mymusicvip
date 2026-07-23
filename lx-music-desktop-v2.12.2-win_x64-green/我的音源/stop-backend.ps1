Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine.Contains('server.js') } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
