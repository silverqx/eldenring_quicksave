; Silver Zachara <silver.zachara@gmail.com> 2023-2024

#Requires AutoHotkey v2

Persistent
#SingleInstance Force
#UseHook True

;@Ahk2Exe-Base ../v2/AutoHotkey64.exe
;@Ahk2Exe-SetCompanyName Crystal Studio
;@Ahk2Exe-SetCopyright Copyright (©) 2024 Silver Zachara
;@Ahk2Exe-SetDescription Elden Ring Save Manager (AutoHotkey)
;@Ahk2Exe-SetFileVersion %A_AhkVersion%
;@Ahk2Exe-SetMainIcon %A_ScriptName~\.[^\.]+$~.ico%
;@Ahk2Exe-SetName Elden Ring Save Manager
;@Ahk2Exe-SetOrigFilename %A_ScriptName~\.[^\.]+$~.exe%
;@Ahk2Exe-SetProductVersion 1.0.0.0
;@Ahk2Exe-UseResourceLang 0x0409

; Initialize variables
SaveFileDir := A_AppData . '\EldenRing\76561197960267366\'
SaveFileName := 'ER0000.sl2'
SaveBakFileName := 'ER0000.sl2.bak'
SaveFile := SaveFileDir . SaveFileName
SaveBakFile := SaveFileDir . SaveBakFileName

BackupDirName := 'first_playthrough\'
BackupDir := SaveFileDir . BackupDirName

IndexFileName := '.index'
IndexFile := BackupDir . IndexFileName
Index := 0

EldenRingExeName := 'eldenring.exe'
ToggleSuspended := false

ERWindowTitle := 'ELDEN RING™'

; If the Backup Save File was not found, try to Restore previous one
; This is the counter, which counts, how how many times to try to Restore
TryRestoreCounter := 8

; Create Backup Folder if doesn't exist
if (!FileExist(BackupDir))
    DirCreate(BackupDir)

SetWorkingDir(BackupDir)

; Save game (CREATE a new Save file).
F5::CreateSave(false)

; Save game (OVERWRITE a last Save file).
F6::CreateSave(true)

; Load game (restore the most recent Save file).
F8::
{
    global Index

    ; Execute function only when Elden Ring window is active
    ; if !IsEldenRingWindowActive()
    ;     return

    if (!FileExist(IndexFile))
        return MsgBox("Index File doesn't exist, nothing to Restore.`n`n" . IndexFile)

    ; On the first run, a Index may not be valid
    if (!Index) {
        file := FileOpen(IndexFile, 'r', 'UTF-8-RAW')
        if (!IsObject(file)) {
            MsgBox("Can't open Index File for reading.`n`n" . IndexFile)
            return
        }
        Index := file.Read(20)
        file.Close()
    }

    ; Restore Backup File loop
    wasRestored := false
    Loop TryRestoreCounter {
        ; Calculate Current / Previous Index
        tmpIndex := Index - (A_Index - 1)
        ; Get Backup File Name by Index
        bakFileName := tmpIndex . '_' . SaveFileName

        ; If Save File does not exist, try next one
        if (!FileExist(bakFileName))
            continue

        ; Backup current Save File
        FileCopy(SaveFile, SaveBakFile, true)
        ; Restore Last Backup File
        FileCopy(bakFileName, SaveFile, true)

        ; Break after successful restore
        wasRestored := true
        break
    }

    if (!wasRestored)
        MsgBox('Failed to Restore Save File.`n`n' .
               'Tried to Restore last ' . TryRestoreCounter . ' Backed Up Save Files, ' .
               'but neither was found.')
}

; Suspend / Resume Elden Ring process (Ctrl+F2)
^F2::
{
    global ToggleSuspended

    if (ToggleSuspended) {
        ProcessResume(EldenRingExeName)
        ToggleSuspended := false
    } else {
        ProcessSuspend(EldenRingExeName)
        ToggleSuspended := true
    }
}

; Exit eldenring.ahk itself
^!+F4::
{
    MsgBox('Exiting ' . A_ScriptName, 'Elden Ring', 'T1')
    ExitApp()
}

; Check if DS3 window is active
IsEldenRingWindowActive()
{
    ; Case-sensitive compare
    return ERWindowTitle == WinGetTitle('A')
}

; Create a new Backup Save file
CreateSave(OverwriteLastSave)
{
    global Index

    ; Execute function only when DS3 window is active
    ; if !IsEldenRingWindowActive()
    ;     return

    if (!FileExist(SaveFile))
        return MsgBox("Elden Ring Save File doesn't exist:`n`n" . SaveFile)

    ; Quit, if Backup Folder doesn't exist
    if (!FileExist(BackupDir))
        return MsgBox("Backup Folder doesn't exist:`n`n" . BackupDir)

    ; Read and Write Index from .index file
    file := FileOpen(IndexFile, 'rw', 'UTF-8-RAW')
    if (!IsObject(file))
        return MsgBox("Can't open Index File for rw.`n`n" . IndexFile)

    ; Set hidden attribute for a Index File
    indexFileAttrs := FileGetAttrib(IndexFile)
    if (!InStr(indexFileAttrs, 'H', true))
        FileSetAttrib('+H', IndexFile)

    Index := file.Read(20)
    Index := Index ? Index : 0

    ; Doesn't overwrite a last Backup Save File, instead create a new Backup Save.
    ; The Index = 0 can hit when F6 is pressed and the save folder is empty.
    if (!OverwriteLastSave || Index = 0) {
        ++Index
        file.Pos := 0
        file.Length := 0
        file.Write(Index)
    }
    file.Close()

    ; Create Backup Save File by Index variable
    bakFileName := Index . '_' . SaveFileName
    FileCopy(SaveFile, bakFileName, true)

    ; Errors Shorcut Code
    ; MsgBox ErrorLevel
    ; MsgBox A_LastError
}

; Suspend the given process
ProcessSuspend(PID_or_Name)
{
    pid := InStr(PID_or_Name, '.') ? ProcessExist(PID_or_Name) : PID_or_Name

    handle := DllCall('OpenProcess', 'UInt', 0x1F0FFF, 'Int', 0, 'Int', pid)
    ; Nothing to resume
    if (!handle)
        return -1

    DllCall('ntdll.dll\NtSuspendProcess', 'Int', handle)
    DllCall('CloseHandle', 'Int', handle)

    return pid
}

; Resume the given process
ProcessResume(PID_or_Name)
{
    pid := InStr(PID_or_Name, '.') ? ProcessExist(PID_or_Name) : PID_or_Name

    handle := DllCall('OpenProcess', 'UInt', 0x1F0FFF, 'Int', 0, 'Int', pid)
    ; Nothing to resume
    if (!handle)
        return -1

    DllCall('ntdll.dll\NtResumeProcess', 'Int', handle)
    DllCall('CloseHandle', 'Int', handle)

    return pid
}
