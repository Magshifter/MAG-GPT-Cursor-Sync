# MAG Workflow Bridge

by Magshifter

Standalone Windows development utility. A lightweight hotkey bridge between ChatGPT, Cursor, and Windows Terminal.

This is not a numbered MAG Ecosystem project.

## Purpose

| Direction | Action |
|---|---|
| ChatGPT → Cursor | Activate Cursor and paste the clipboard |
| ChatGPT → Windows Terminal | Activate Windows Terminal and paste the clipboard |
| Cursor → ChatGPT | Activate ChatGPT and paste the clipboard |

## Safety model

The bridge never automatically presses Enter, Submit, or Send.

It only activates the target application and pastes the current clipboard content.

You always review the pasted text and submit or execute it yourself.

## Requirement

AutoHotkey v2

## Running

1. Install AutoHotkey v2.
2. Clone or download this repository.
3. Run `MAG-Workflow-Bridge.ahk`.

The script stays loaded while AutoHotkey is running. Close the script from the AutoHotkey tray icon, or exit AutoHotkey, to stop the hotkeys.

## Hotkeys

| Hotkey | Target |
|---|---|
| Ctrl+Alt+C | Cursor |
| Ctrl+Alt+T | Windows Terminal |
| Ctrl+Alt+G | ChatGPT |

## Current targets

- Cursor desktop app (`Cursor.exe`)
- Windows Terminal (`WindowsTerminal.exe`)
- ChatGPT desktop app (`ChatGPT.exe`)

Browser ChatGPT is not supported in this version.

If several windows of the same app are open, the most recently active matching window is used.

## Known limitations

- The target application must already be running. The bridge does not launch apps.
- Paste goes to whichever control already has focus inside the activated window.
- Multiple matching windows may select the most recently active one.
- Hotkeys can conflict with third-party software.
- An elevated app may block interaction from an unelevated bridge (Windows privilege isolation).
- Windows autostart is not implemented yet.
