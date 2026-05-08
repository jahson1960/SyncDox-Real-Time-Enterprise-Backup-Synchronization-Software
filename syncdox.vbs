' =========================================================
' Real-Time Enterprise Backup & Synchronization Application
' =========================================================

Option Explicit

Dim WshShell, FSO
Dim logPath, logFile, today
Dim baseSrc, destRoot
Dim folders
Dim excludePatterns
Dim intervalSeconds
Dim lockFile
Dim username, domain

Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' ================= DYNAMIC USER INFO =================

username = WshShell.ExpandEnvironmentStrings("%USERNAME%")
domain   = WshShell.ExpandEnvironmentStrings("%USERDOMAIN%")

baseSrc  = WshShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\"

' Example:
' \\fileserver\Backups\REFUGEHOMES\john\
destRoot = "\\fileserver\Backups\" & domain & "\" & username & "\"

' Central log location
logPath = "\\fileserver\logs\"

' =====================================================

folders = Array( _
    "Desktop", _
    "Downloads", _
    "Documents", _
    "Pictures", _
    "Music", _
    "Videos" _
)

' Sync every 5 seconds
intervalSeconds = 5

' Prevent multiple running instances
lockFile = "C:\Windows\Temp\UserFolderSync_" & username & ".lock"

If FSO.FileExists(lockFile) Then
    WScript.Quit
End If

Dim lockObj
Set lockObj = FSO.CreateTextFile(lockFile, True)
lockObj.WriteLine "RUNNING"
lockObj.Close

' ================= CREATE REQUIRED FOLDERS =================

On Error Resume Next

' Create log directory if missing
If Not FSO.FolderExists(logPath) Then
    FSO.CreateFolder logPath
End If

' Create destination root if missing
CreateFolderRecursive destRoot

On Error GoTo 0

' ================= LOG FILE =================

today = Year(Date) & "-" & Right("0" & Month(Date),2) & "-" & Right("0" & Day(Date),2)

logFile = logPath & username & "_" & today & ".log"

' ================= EXCLUDED FILE TYPES =================

excludePatterns = _
    " /XF *.mp4 *.mkv *.avi *.mov *.wmv *.flv *.mpeg *.mpg *.3gp *.webm" & _
    " *.mp3 *.wav *.wma *.aac *.flac *.ogg"

' ================= MAIN LOOP =================

Do

    ' Verify server reachable
    If FSO.FolderExists("\\fileserver\Backups") Then

        Dim i

        For i = LBound(folders) To UBound(folders)

            SyncFolder folders(i)

        Next

    Else

        WriteLog "SERVER UNREACHABLE"

    End If

    WScript.Sleep intervalSeconds * 1000

Loop

' =========================================================
' SYNC FUNCTION
' =========================================================

Sub SyncFolder(folderName)

    On Error Resume Next

    Dim src, dest
    Dim cmd
    Dim exitCode
    Dim logText

    src  = """" & baseSrc  & folderName & """"
    dest = """" & destRoot & folderName & """"

    cmd = "robocopy " & src & " " & dest _
        & " /E" _
        & excludePatterns _
        & " /XO" _
        & " /FFT" _
        & " /Z" _
        & " /XJ" _
        & " /MT:8" _
        & " /R:1" _
        & " /W:1" _
        & " /NP /NFL /NDL" _
        & " /LOG+:""" & logFile & """"

    exitCode = WshShell.Run(cmd, 0, True)

    Select Case exitCode

        Case 0
            logText = folderName & ": No changes"

        Case 1
            logText = folderName & ": Files synced"

        Case 2,3,5,6,7
            logText = folderName & ": Synced with warnings. Exit code " & exitCode

        Case Else
            logText = folderName & ": FAILED. Exit code " & exitCode

    End Select

    WriteLog logText

    On Error GoTo 0

End Sub

' =========================================================
' LOGGING
' =========================================================

Sub WriteLog(text)

    On Error Resume Next

    Dim f

    Set f = FSO.OpenTextFile(logFile, 8, True)

    f.WriteLine Now & " - " & text

    f.Close

    On Error GoTo 0

End Sub

' =========================================================
' CREATE FOLDER RECURSIVELY
' =========================================================

Sub CreateFolderRecursive(path)

    Dim parts, currentPath, i

    parts = Split(path, "\")

    currentPath = parts(0) & "\"

    For i = 1 To UBound(parts)

        If parts(i) <> "" Then

            currentPath = currentPath & parts(i) & "\"

            If Not FSO.FolderExists(currentPath) Then

                On Error Resume Next
                FSO.CreateFolder currentPath
                On Error GoTo 0

            End If

        End If
    Next

End Sub

' =========================================================
' CLEANUP LOCK FILE
' =========================================================

Sub RemoveLock()

    On Error Resume Next

    If FSO.FileExists(lockFile) Then
        FSO.DeleteFile lockFile, True
    End If

    On Error GoTo 0

End Sub

' =========================================================
' SAFETY CLEANUP
' =========================================================

RemoveLock