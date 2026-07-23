' one-click launcher: start backend hidden + open lx-music,
' then auto-stop backend when lx exits.
Dim shell, fso, base, lg, logFile, fldr, backendBat, lxExe
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
base = fso.GetParentFolderName(WScript.ScriptFullName)
logFile = base & "\launcher-log.txt"
Set lg = fso.CreateTextFile(logFile, True)
lg.WriteLine "base=" & base

backendBat = ""
lxExe = ""
For Each fldr In fso.GetFolder(base).SubFolders
  If backendBat = "" And fso.FileExists(fldr.Path & "\backend-silent.bat") Then backendBat = fldr.Path & "\backend-silent.bat"
  If lxExe = "" And fso.FileExists(fldr.Path & "\lx-music-desktop.exe") Then lxExe = fldr.Path & "\lx-music-desktop.exe"
Next
lg.WriteLine "backendBat=" & backendBat
lg.WriteLine "lxExe=" & lxExe

' 1) start backend hidden
If backendBat <> "" Then
  shell.Run "cmd /c """ & backendBat & """", 0, False
  lg.WriteLine "backend launched"
Else
  lg.WriteLine "ERROR: backend-silent.bat not found"
End If

' 2) wait then launch lx
WScript.Sleep 2500
If lxExe = "" Then
  lg.WriteLine "ERROR: lx exe not found"
  lg.Close
  WScript.Quit
End If
shell.Run """" & lxExe & """", 1, False
lg.WriteLine "lx launched"
lg.Close

' 3) poll until lx has fully exited
Dim wmi, procs, alive
Set wmi = GetObject("winmgmts:\\.\root\cimv2")
Do
  WScript.Sleep 4000
  Set procs = wmi.ExecQuery("Select ProcessId from Win32_Process Where Name = 'lx-music-desktop.exe'")
  alive = 0
  Dim p
  For Each p In procs
    alive = alive + 1
  Next
Loop While alive > 0

' 4) lx gone -> stop backend by running stop-backend.ps1 (found next to backend bat)
Dim stopPs
stopPs = fso.GetParentFolderName(backendBat) & "\stop-backend.ps1"
If fso.FileExists(stopPs) Then
  shell.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & stopPs & """", 0, True
End If

Set shell = Nothing
Set fso = Nothing
