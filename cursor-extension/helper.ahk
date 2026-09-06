#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

; [MAG] GPT|Cursor|Sync — Cursor one-shot helper
; by Magshifter
;
; Activates ChatGPT, pastes the current clipboard, then submits.
; Used only by the Cursor → ChatGPT status bar button.
; Does not stay loaded.

exitCode := SendClipboardToChatGPT()
Sleep 50
ExitApp exitCode

SendClipboardToChatGPT()
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
    Sleep 150
    Send "{Enter}"
    return 0
}

Notify(message)
{
    ToolTip message
    SetTimer () => ToolTip(), -1500
}
