' one-click launcher: start backend hidden, check login status,
' auto-open login page if needed, then launch lx-music,
' auto-stop backend when lx exits.

Dim shell, fso, selfDir, rootDir, lg, logFile, fldr, backendBat, lxExe
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
selfDir = fso.GetParentFolderName(WScript.ScriptFullName)
rootDir = fso.GetParentFolderName(selfDir)
logFile = selfDir & "\launcher-log.txt"
Set lg = fso.CreateTextFile(logFile, True)

Sub L(msg)
  lg.WriteLine Now & " " & msg
End Sub

L "selfDir=" & selfDir
L "rootDir=" & rootDir

' ---- find backend bat and lx exe ----
backendBat = ""
lxExe = ""
' search subfolders for backend
For Each fldr In fso.GetFolder(rootDir).SubFolders
  If backendBat = "" And fso.FileExists(fldr.Path & "\backend-silent.bat") Then backendBat = fldr.Path & "\backend-silent.bat"
Next
' lx exe is in rootDir itself
If fso.FileExists(rootDir & "\lx-music-desktop.exe") Then lxExe = rootDir & "\lx-music-desktop.exe"
L "backendBat=" & backendBat
L "lxExe=" & lxExe

' ---- 1) start backend hidden ----
If backendBat <> "" Then
  shell.Run "cmd /c """ & backendBat & """", 0, False
  L "backend launched"
Else
  L "ERROR: backend-silent.bat not found"
End If

' ---- 2) wait for backend to be ready ----
Dim http, apiBase, maxWait, waited
apiBase = "http://127.0.0.1:3000"
maxWait = 15   ' max seconds to wait for backend startup
waited = 0

Do While waited < maxWait
  WScript.Sleep 1000
  waited = waited + 1
  On Error Resume Next
  Set http = CreateObject("MSXML2.ServerXMLHTTP")
  http.SetTimeouts 3000, 3000, 3000, 3000
  http.Open "GET", apiBase & "/api/app/version", False
  http.Send
  If Err.Number = 0 And http.Status = 200 Then
    L "backend ready after " & waited & "s"
    On Error Goto 0
    Exit Do
  End If
  Err.Clear
  On Error Goto 0
Loop

If waited >= maxWait Then
  L "WARN: backend may not be ready"
End If

' ---- 3) check login status ----
Dim wyLoggedIn, qqLoggedIn
wyLoggedIn = False
qqLoggedIn = False

On Error Resume Next
Set http = CreateObject("MSXML2.ServerXMLHTTP")
http.SetTimeouts 3000, 3000, 3000, 3000
http.Open "GET", apiBase & "/api/login/status", False
http.Send
If Err.Number = 0 And http.Status = 200 Then
  Dim wyResp
  wyResp = http.ResponseText
  L "wy status: " & wyResp
  If InStr(wyResp, """loggedIn"":true") > 0 Then wyLoggedIn = True
End If
Err.Clear

Set http = CreateObject("MSXML2.ServerXMLHTTP")
http.SetTimeouts 3000, 3000, 3000, 3000
http.Open "GET", apiBase & "/api/qq/login/status", False
http.Send
If Err.Number = 0 And http.Status = 200 Then
  Dim qqResp
  qqResp = http.ResponseText
  L "qq status: " & qqResp
  If InStr(qqResp, """loggedIn"":true") > 0 Then qqLoggedIn = True
End If
Err.Clear
On Error Goto 0

L "wyLoggedIn=" & wyLoggedIn & " qqLoggedIn=" & qqLoggedIn

' ---- 4) launch lx first ----
If lxExe = "" Then
  L "ERROR: lx exe not found"
  lg.Close
  WScript.Quit
End If
shell.Run """" & lxExe & """", 1, False
L "lx launched"

' ---- 5) open login page if needed (after lx, so it stays on top) ----
If Not (wyLoggedIn And qqLoggedIn) Then
  Dim missing
  missing = ""
  If Not wyLoggedIn Then missing = missing & "网易云 "
  If Not qqLoggedIn Then missing = missing & "QQ音乐 "
  L "missing login: " & missing & " -> opening control panel in 1.5s"
  WScript.Sleep 1500
  shell.Run "cmd /c start " & apiBase, 0, False
Else
  L "both logged in, skipping browser"
End If
lg.Close

' ---- 6) poll until lx has fully exited ----
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

' ---- 7) lx gone -> stop backend ----
Dim stopPs
stopPs = fso.GetParentFolderName(backendBat) & "\stop-backend.ps1"
If fso.FileExists(stopPs) Then
  shell.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & stopPs & """", 0, True
End If

Set shell = Nothing
Set fso = Nothing
