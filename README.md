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
4. Optionally load the Cursor extension (see **Cursor native button**).

The script stays loaded while AutoHotkey is running. Use **Exit** on the tray menu, or exit AutoHotkey, to stop the hotkeys.

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

## Optional Windows startup

Startup is optional, per-user, and off until you enable it. The bridge never turns it on by itself.

1. Run `MAG-Workflow-Bridge.ahk`.
2. Open the AutoHotkey tray menu.
3. Choose **Enable startup**.
4. To remove it, choose **Disable startup**.

That creates or removes a single shortcut named `MAG Workflow Bridge.lnk` in the current user's Windows Startup folder (`shell:startup`). It does not install a service and does not write Registry Run keys. You can remove it at any time from the tray menu or by deleting that shortcut.

If you move or re-clone the repository, the existing shortcut still points at the old path. Disable startup, run the script from the new location, then Enable startup again. The bridge does not migrate the shortcut automatically.

## Cursor native button

The Cursor status bar item **→ ChatGPT** pastes the **current clipboard** into the ChatGPT desktop app, then stops. It never presses Enter, Submit, or Send. It does not read or copy a Cursor Agent response by itself.

To send a specific Agent response:

1. Click Cursor's native **Copy Message** on that response.
2. Click **→ ChatGPT**.
3. ChatGPT activates and the copied text is pasted.
4. Review and send the message yourself.

This two-step flow is required because MAG Workflow Bridge cannot attach to Cursor's internal per-message UI.

It is the same paste action as `Ctrl+Alt+G`. Browser ChatGPT is not used.

Local load (not Marketplace published):

1. Copy or junction `cursor-extension` to `%USERPROFILE%\.cursor\extensions\magshifter.mag-workflow-bridge-0.0.1`.
2. Reload Cursor.
3. Keep AutoHotkey v2 installed. The button launches `cursor-extension/helper.ahk` as a one-shot paste. The persistent MAG Workflow Bridge tray script can keep running separately.

## Known limitations

- The target application must already be running. The bridge does not launch apps.
- Paste goes to whichever control already has focus inside the activated window.
- Multiple matching windows may select the most recently active one.
- Hotkeys can conflict with third-party software.
- An elevated app may block interaction from an unelevated bridge (Windows privilege isolation).
- An existing Startup shortcut still points at the old script path if the repository is moved.
