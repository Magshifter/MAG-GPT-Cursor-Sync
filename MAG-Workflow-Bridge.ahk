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
; Companion TER | AGT and tray Cursor Agent / Cursor Terminal
; use the current clipboard, then the Cursor URI.

A_IconTip := "[MAG] GPT|Cursor|Sync"

actionBarEnabled := true
companionVisible := false
companionTarget := 0
companionGui := 0
companionW := 0
companionH := 0
companionLastX := ""
companionLastY := ""
lastWinX := ""
lastWinY := ""
lastWinW := ""
lastWinH := ""
stableTicks := 0

TraySetIcon(A_ScriptDir "\assets\MAG-GPT-Cursor-Sync.ico")
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
    if Trim(A_Clipboard, " `t`r`n") = ""
    {
        Notify("Clipboard is empty.")
        return
    }
    uri := "cursor://magshifter.mag-workflow-bridge/" actionPath
    launched := DllCall("shell32\ShellExecuteW", "Ptr", 0, "WStr", "open", "WStr", uri, "Ptr", 0, "Ptr", 0, "Int", 1, "Ptr")
    if launched <= 32
        Notify("Could not trigger Cursor (" actionPath ").")
}

InitCompanionBar()
{
    global companionGui, companionW, companionH
    ; WS_EX_NOACTIVATE (E0x08000000): do not steal ChatGPT focus on click.
    ; Do not use WS_EX_TRANSPARENT (E0x20) or TransColor: keyed pixels are
    ; HTTRANSPARENT and the click falls through to ChatGPT (Send/composer).
    companionGui := Gui("+AlwaysOnTop -Caption -Border +ToolWindow -SysMenu +E0x08000000")
    companionGui.BackColor := "F3F3F3"
    companionGui.MarginX := 0
    companionGui.MarginY := 0
    companionGui.SetFont("s9", "Segoe UI")
    ter := companionGui.Add("Button", "x0 y0 w46 h28", "TER")
    agt := companionGui.Add("Button", "x+6 yp w46 h28", "AGT")
    try ter.ToolTip := "Execute current clipboard in Cursor Terminal"
    try agt.ToolTip := "Send current clipboard to Cursor Agent"
    ter.OnEvent("Click", (*) => TriggerCursorCommand("terminal"))
    agt.OnEvent("Click", (*) => TriggerCursorCommand("agent"))
    companionGui.Show("Hide")
    companionGui.GetPos(,, &companionW, &companionH)
}

HideCompanion()
{
    global companionVisible, companionGui, companionLastX, companionLastY
    if companionVisible
    {
        companionGui.Hide()
        companionVisible := false
    }
    companionLastX := ""
    companionLastY := ""
}

HideEverything()
{
    global companionTarget, lastWinX, lastWinY, lastWinW, lastWinH, stableTicks
    HideCompanion()
    companionTarget := 0
    lastWinX := ""
    lastWinY := ""
    lastWinW := ""
    lastWinH := ""
    stableTicks := 0
}

IsMagGui(hwnd)
{
    global companionGui
    return hwnd = companionGui.Hwnd
}

ShowCompanionAt(hwnd)
{
    global companionGui, companionW, companionH, companionVisible, companionLastX, companionLastY
    WinGetPos(&cx, &cy, &cw, &ch, hwnd)
    GetWorkAreaForPoint(cx + cw // 2, cy + ch // 2, &workL, &workT, &workR, &workB)
    rightGap := 72
    bottomGap := Max(148, Min(176, ch // 6))
    x := cx + cw - companionW - rightGap
    y := cy + ch - companionH - bottomGap
    x := Max(cx + 8, Min(x, cx + cw - companionW - 8))
    y := Max(cy + 8, Min(y, cy + ch - companionH - 8))
    x := Max(workL, Min(x, workR - companionW))
    y := Max(workT, Min(y, workB - companionH))
    if !companionVisible || companionLastX != x || companionLastY != y
    {
        companionGui.Show("NA x" x " y" y)
        companionLastX := x
        companionLastY := y
    }
    companionVisible := true
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
    global actionBarEnabled, companionTarget, lastWinX, lastWinY, lastWinW, lastWinH, stableTicks
    if !actionBarEnabled
    {
        HideEverything()
        return
    }

    if !WinExist("ahk_exe ChatGPT.exe")
    {
        HideEverything()
        return
    }

    active := WinExist("A")
    chatgpt := WinActive("ahk_exe ChatGPT.exe")
    if chatgpt
        companionTarget := DllCall("user32\GetAncestor", "ptr", chatgpt, "uint", 2, "ptr") || chatgpt
    else if !IsMagGui(active) || !companionTarget || !WinExist(companionTarget)
    {
        HideEverything()
        return
    }

    WinGetPos(&cx, &cy, &cw, &ch, companionTarget)
    if lastWinX = ""
    {
        lastWinX := cx
        lastWinY := cy
        lastWinW := cw
        lastWinH := ch
        stableTicks := 3
        ShowCompanionAt(companionTarget)
        return
    }
    if cx != lastWinX || cy != lastWinY || cw != lastWinW || ch != lastWinH
    {
        lastWinX := cx
        lastWinY := cy
        lastWinW := cw
        lastWinH := ch
        stableTicks := 0
        HideCompanion()
        return
    }
    if stableTicks < 3
    {
        stableTicks += 1
        HideCompanion()
        return
    }
    ShowCompanionAt(companionTarget)
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
        HideEverything()
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
