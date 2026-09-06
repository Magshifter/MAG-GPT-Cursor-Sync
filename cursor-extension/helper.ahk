#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

; MAG Workflow Bridge — Cursor one-shot helper
; by Magshifter
;
; Activates ChatGPT and pastes the current clipboard.
; Never sends Enter, Submit, or Send.
; Does not stay loaded.

exitCode := PasteToChatGPT()
Sleep 150
ExitApp exitCode

PasteToChatGPT()
{
    hwnds := WinGetList("ahk_exe ChatGPT.exe")
    if hwnds.Length = 0
    {
        Notify("ChatGPT is not running.")
        return 2
    }

    hwnd := hwnds[1]
    WinActivate hwnd
    if !WinWaitActive(hwnd, , 1)
    {
        Notify("Could not activate ChatGPT.")
        return 3
    }

    Send "^v"
    return 0
}

Notify(message)
{
    ToolTip message
    SetTimer () => ToolTip(), -1500
}
