#Requires AutoHotkey v2.0
#SingleInstance Force

; [MAG] GPT|Cursor|Sync
; by Magshifter
;
; Activates a target window and pastes the current clipboard.
; Never sends Enter, Submit, or Send from global hotkeys.
;
; Ctrl+Alt+C -> Cursor
; Ctrl+Alt+T -> Windows Terminal
; Ctrl+Alt+G -> ChatGPT
;
; Tray Cursor Agent / Cursor Terminal trigger Cursor URI handlers.
; They do not duplicate Agent paste or terminal sendText logic.

A_IconTip := "[MAG] GPT|Cursor|Sync"
InitTray()

^!c:: PasteToTarget("Cursor.exe", "Cursor")
^!t:: PasteToTarget("WindowsTerminal.exe", "Windows Terminal")
^!g:: PasteToTarget("ChatGPT.exe", "ChatGPT")

PasteToTarget(exeName, displayName)
{
    hwnds := WinGetList("ahk_exe " exeName)
    if hwnds.Length = 0
    {
        Notify(displayName " is not running.")
        return
    }

    hwnd := hwnds[1]
    WinActivate hwnd
    if !WinWaitActive(hwnd, , 1)
    {
        Notify("Could not activate " displayName ".")
        return
    }

    Send "^v"
}

TriggerCursorCommand(actionPath)
{
    uri := "cursor://magshifter.mag-workflow-bridge/" actionPath
    try
        Run uri
    catch
        Notify("Could not trigger Cursor (" actionPath ").")
}

StartupShortcutPath()
{
    return A_Startup "\MAG Workflow Bridge.lnk"
}

StartupIsEnabled()
{
    return FileExist(StartupShortcutPath()) ? true : false
}

InitTray()
{
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Cursor Agent", (*) => TriggerCursorCommand("agent"))
    A_TrayMenu.Add("Cursor Terminal", (*) => TriggerCursorCommand("terminal"))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Enable startup", EnableStartup)
    A_TrayMenu.Add("Disable startup", DisableStartup)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    RefreshTray()
}

RefreshTray()
{
    if StartupIsEnabled()
    {
        A_TrayMenu.Disable("Enable startup")
        A_TrayMenu.Enable("Disable startup")
    }
    else
    {
        A_TrayMenu.Enable("Enable startup")
        A_TrayMenu.Disable("Disable startup")
    }
}

EnableStartup(*)
{
    linkPath := StartupShortcutPath()
    SplitPath A_LineFile, , &bridgeDir
    args := '"' A_LineFile '"'
    FileCreateShortcut(A_AhkPath, linkPath, bridgeDir, args, "[MAG] GPT|Cursor|Sync")
    RefreshTray()
    Notify("Startup enabled.")
}

DisableStartup(*)
{
    linkPath := StartupShortcutPath()
    if FileExist(linkPath)
        FileDelete linkPath
    RefreshTray()
    Notify("Startup disabled.")
}

Notify(message)
{
    ToolTip message
    SetTimer () => ToolTip(), -1500
}
