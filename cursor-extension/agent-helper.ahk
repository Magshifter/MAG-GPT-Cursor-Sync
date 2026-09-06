#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

; [MAG] GPT|Cursor|Sync — Cursor Agent one-shot helper
; by Magshifter
;
; Assumes Cursor already has Agent input focused.
; Pastes the clipboard and submits once.
; Does not stay loaded.

Send "^v"
Sleep 150
Send "{Enter}"
ExitApp 0
