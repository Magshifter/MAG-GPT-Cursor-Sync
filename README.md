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

Global hotkeys never press Enter, Submit, or Send. They activate the target app and paste the clipboard. You review and submit or execute yourself.

The Cursor status bar button **→ ChatGPT** is different: clicking it is explicit send intent. It pastes the clipboard into ChatGPT desktop and then submits that message.

## Requirement

AutoHotkey v2 and Cursor (for the status bar button).

## Installation

1. Install AutoHotkey v2.
2. Clone or download MAG Workflow Bridge.
3. In PowerShell, from the repository folder, run:

```powershell
.\setup.ps1
```

4. Reload Cursor if it is already open.
5. Run `MAG-Workflow-Bridge.ahk`.
6. Optional: tray menu → **Enable startup**.

`setup.ps1` packages the Cursor extension and installs it with Cursor CLI. It does not enable Windows startup and does not launch ChatGPT, Cursor, or Windows Terminal.

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

**→ ChatGPT** (status bar) sends the **current clipboard** to the ChatGPT desktop app: paste, then automatic Send. It does not copy a Cursor Agent response by itself.

To send a specific Agent response:

1. Click Cursor's native **Copy Message** on that response.
2. Click **→ ChatGPT**.
3. ChatGPT activates, the copied text is pasted, and the message is sent.

If you want to edit before sending, use **Copy Message** and `Ctrl+Alt+G` (paste only), or paste manually.

`Ctrl+Alt+G` still pastes only. Browser ChatGPT is not used.

After `setup.ps1`, Cursor copies the extension (including `helper.ahk`) into its own extensions folder. The button does not depend on a junction back to this repository.

## Removal

1. If startup is enabled, use the tray menu **Disable startup**.
2. Use the tray menu **Exit** to stop MAG Workflow Bridge.
3. Uninstall the Cursor extension:

```powershell
cursor --uninstall-extension magshifter.mag-workflow-bridge
```

Do not uninstall AutoHotkey unless you no longer need it. Do not delete the repository unless you want to remove the source files.

## Known limitations

- The target application must already be running. The bridge does not launch apps.
- Paste goes to whichever control already has focus inside the activated window.
- Multiple matching windows may select the most recently active one.
- Hotkeys can conflict with third-party software.
- An elevated app may block interaction from an unelevated bridge (Windows privilege isolation).
- An existing Startup shortcut still points at the old script path if the repository is moved.
