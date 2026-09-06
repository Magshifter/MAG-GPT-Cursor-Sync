#Requires AutoHotkey v2.0
#SingleInstance Force

; MAG Workflow Bridge
; by Magshifter
;
; Activates a target window and pastes the current clipboard.
; Never sends Enter, Submit, or Send.

; Ctrl+Alt+C -> Cursor
; Ctrl+Alt+T -> Windows Terminal
; Ctrl+Alt+G -> ChatGPT

A_IconTip := "MAG Workflow Bridge"
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
    FileCreateShortcut(A_AhkPath, linkPath, bridgeDir, args, "MAG Workflow Bridge")
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
