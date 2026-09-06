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
; Tray and ChatGPT companion bar trigger Cursor URI handlers.
; They do not duplicate Agent paste or terminal sendText logic.

A_IconTip := "[MAG] GPT|Cursor|Sync"

actionBarEnabled := true
companionVisible := false
companionTarget := 0
companionGui := 0
companionW := 0
companionH := 0
companionLastX := ""
companionLastY := ""

InitTray()
InitCompanionBar()
SetTimer(UpdateCompanionBar, 200)

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

CompanionClick(actionPath, *)
{
    if Trim(A_Clipboard, " `t`r`n") = ""
    {
        Notify("Clipboard is empty.")
        return
    }
    TriggerCursorCommand(actionPath)
}

InitCompanionBar()
{
    global companionGui, companionW, companionH
    companionGui := Gui("+AlwaysOnTop -Caption +ToolWindow -SysMenu +E0x08000000")
    companionGui.BackColor := "F3F3F3"
    companionGui.MarginX := 8
    companionGui.MarginY := 6
    companionGui.SetFont("s9", "Segoe UI")
    btnAgent := companionGui.Add("Button", "w118 h28", "Cursor Agent")
    btnTerminal := companionGui.Add("Button", "x+8 yp w130 h28", "Cursor Terminal")
    btnAgent.OnEvent("Click", CompanionClick.Bind("agent"))
    btnTerminal.OnEvent("Click", CompanionClick.Bind("terminal"))
    try btnAgent.ToolTip := "Send clipboard to Cursor Agent"
    try btnTerminal.ToolTip := "Execute clipboard in Cursor Terminal"
    companionGui.Show("Hide")
    companionGui.GetPos(,, &companionW, &companionH)
}

HideCompanion()
{
    global companionVisible, companionTarget, companionGui, companionLastX, companionLastY
    if companionVisible
    {
        companionGui.Hide()
        companionVisible := false
    }
    companionTarget := 0
    companionLastX := ""
    companionLastY := ""
}

PositionCompanion(hwnd)
{
    global companionGui, companionW, companionH, companionVisible, companionLastX, companionLastY
    WinGetPos(&cx, &cy, &cw, &ch, hwnd)
    GetWorkAreaForPoint(cx + cw // 2, cy + ch // 2, &workL, &workT, &workR, &workB)

    x := cx + Max(0, (cw - companionW) // 2)
    y := cy - companionH - 4

    if y < workT
    {
        x := cx + cw + 4
        y := cy
        if x + companionW > workR
        {
            x := Min(cx + cw - companionW - 8, workR - companionW)
            y := Max(cy + 8, workT)
        }
    }

    x := Max(workL, Min(x, workR - companionW))
    y := Max(workT, Min(y, workB - companionH))
    if !companionVisible || companionLastX != x || companionLastY != y
    {
        companionGui.Show("NA x" x " y" y)
        companionLastX := x
        companionLastY := y
    }
}

GetWorkAreaForPoint(px, py, &workL, &workT, &workR, &workB)
{
    loop MonitorGetCount()
    {
        MonitorGet(A_Index, &ml, &mt, &mr, &mb)
        if px >= ml && px < mr && py >= mt && py < mb
        {
            MonitorGetWorkArea(A_Index, &workL, &workT, &workR, &workB)
            return
        }
    }
    MonitorGetWorkArea(MonitorGetPrimary(), &workL, &workT, &workR, &workB)
}

UpdateCompanionBar()
{
    global actionBarEnabled, companionVisible, companionTarget, companionGui
    if !actionBarEnabled
    {
        HideCompanion()
        return
    }

    if !WinExist("ahk_exe ChatGPT.exe")
    {
        HideCompanion()
        return
    }

    active := WinExist("A")
    chatgpt := WinActive("ahk_exe ChatGPT.exe")
    if chatgpt
        companionTarget := chatgpt
    else if active != companionGui.Hwnd || !companionTarget || !WinExist(companionTarget)
    {
        HideCompanion()
        return
    }

    PositionCompanion(companionTarget)
    companionVisible := true
}

ToggleActionBar(*)
{
    global actionBarEnabled
    actionBarEnabled := !actionBarEnabled
    if actionBarEnabled
        A_TrayMenu.Check("ChatGPT action bar")
    else
    {
        A_TrayMenu.Uncheck("ChatGPT action bar")
        HideCompanion()
    }
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
    A_TrayMenu.Add("ChatGPT action bar", ToggleActionBar)
    A_TrayMenu.Check("ChatGPT action bar")
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
