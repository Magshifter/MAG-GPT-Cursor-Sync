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

Notify(message)
{
    ToolTip message
    SetTimer () => ToolTip(), -1500
}
