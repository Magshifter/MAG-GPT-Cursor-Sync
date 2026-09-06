# [MAG] GPT|Cursor|Sync

by Magshifter

Standalone Windows development utility. A lightweight clipboard bridge between ChatGPT desktop, Cursor, and Windows Terminal.

This is not a numbered MAG Ecosystem project.

Current repository directory: `MAG-Workflow-Bridge`. Future filesystem-safe name: `MAG-GPT-Cursor-Sync`. That directory has not been renamed yet.

## Purpose

| Direction | Action |
|---|---|
| ChatGPT → Cursor | Activate Cursor and paste the clipboard |
| ChatGPT → Windows Terminal | Activate Windows Terminal and paste the clipboard |
| Cursor → ChatGPT | Activate ChatGPT, paste the clipboard, and Send |
| ChatGPT → Cursor Agent | Clipboard → Cursor Agent → automatic submit |
| ChatGPT → Cursor Terminal | Clipboard → Cursor integrated Terminal → automatic execute |

Source for ChatGPT → Cursor actions is ChatGPT's native Copy. This product does not scrape ChatGPT messages.

## Verified

**Global hotkeys (paste only, never Enter):**

| Hotkey | Target |
|---|---|
| Ctrl+Alt+C | Cursor |
| Ctrl+Alt+T | Windows Terminal |
| Ctrl+Alt+G | ChatGPT |

**Cursor → ChatGPT**

Cursor Copy Message → status bar **→ ChatGPT** → ChatGPT desktop activates → clipboard pasted → automatic Send.

**ChatGPT → Cursor Agent**

ChatGPT Copy → invoke Cursor Agent action → `composer.focusComposer` → paste → one Enter.

Triggers:

- ChatGPT companion action bar: **Cursor Agent**
- Tray: **Cursor Agent**
- Command Palette: `[MAG] GPT|Cursor|Sync: Send Clipboard to Cursor Agent`

URI: `cursor://magshifter.mag-workflow-bridge/agent`

**ChatGPT → Cursor Terminal**

ChatGPT Copy → invoke Cursor Terminal action → active Cursor integrated terminal → `sendText(..., true)`.

Triggers:

- ChatGPT companion action bar: **Cursor Terminal**
- Tray: **Cursor Terminal**
- Command Palette: `[MAG] GPT|Cursor|Sync: Execute Clipboard in Cursor Terminal`

URI: `cursor://magshifter.mag-workflow-bridge/terminal`

That is not Windows Terminal. `Ctrl+Alt+T` still pastes only into Windows Terminal.

If no integrated terminal is active, the command warns and does nothing. Multi-line clipboard is not executed.

`Ctrl+Alt+C` does not submit to Agent.

## ChatGPT companion action bar

This is a MAG-controlled Windows companion UI. It is **not** a native ChatGPT plugin. It does not patch, inject, or modify ChatGPT.

While ChatGPT desktop (`ChatGPT.exe`) is active, a small bar with **Cursor Agent** and **Cursor Terminal** appears next to that window. It hides when ChatGPT is not active. Browser ChatGPT is not supported.

**ChatGPT → Cursor Agent**

1. Copy the desired ChatGPT text normally.
2. Click **Cursor Agent** on the companion action bar.
3. Cursor activates.
4. Agent receives the clipboard.
5. The prompt is submitted automatically.

**ChatGPT → Cursor Terminal**

1. Copy a single-line command normally.
2. Click **Cursor Terminal**.
3. Cursor activates.
4. The active Cursor integrated terminal executes it automatically.

Tray **Cursor Agent** / **Cursor Terminal** remain as a fallback. Tray **ChatGPT action bar** enables or disables the companion for the current session (default enabled; not persisted). Existing Startup still launches this same script, so the companion is available after login if startup is enabled.

Native buttons inside the ChatGPT app remain **planned, not implemented**.

## Safety model

Global hotkeys never press Enter, Submit, or Send. They activate the target app and paste the clipboard. You review and submit or execute yourself.

These actions are explicit execute intent:

- **→ ChatGPT** (status bar)
- Cursor Agent (companion bar, tray, or Command Palette)
- Cursor Terminal (companion bar, tray, or Command Palette)

If you want to edit first, use Copy and paste (`Ctrl+Alt+C` / `Ctrl+Alt+T` / `Ctrl+Alt+G`) instead.

## Requirement

AutoHotkey v2 and Cursor (for the status bar button and Cursor actions).

## Installation

1. Install AutoHotkey v2.
2. Clone or download this repository.
3. In PowerShell, from the repository folder, run:

```powershell
.\setup.ps1
```

4. Reload Cursor if it is already open.
5. Run `MAG-Workflow-Bridge.ahk`.
6. Optional: tray menu → **Enable startup**.

`setup.ps1` packages the Cursor extension and installs it with Cursor CLI. It does not enable Windows startup and does not launch ChatGPT, Cursor, or Windows Terminal.

The script stays loaded while AutoHotkey is running. Use **Exit** on the tray menu, or exit AutoHotkey, to stop the hotkeys, tray actions, and ChatGPT companion action bar.

## Current targets

- Cursor desktop app (`Cursor.exe`)
- Windows Terminal (`WindowsTerminal.exe`)
- ChatGPT desktop app (`ChatGPT.exe`)

Browser ChatGPT is not supported in this version.

If several windows of the same app are open, the most recently active matching window is used. Cursor URI actions are handled by the topmost Cursor window.

## Optional Windows startup

Startup is optional, per-user, and off until you enable it. The product never turns it on by itself.

1. Run `MAG-Workflow-Bridge.ahk`.
2. Open the AutoHotkey tray menu.
3. Choose **Enable startup**.
4. To remove it, choose **Disable startup**.

That creates or removes a single shortcut named `MAG Workflow Bridge.lnk` in the current user's Windows Startup folder (`shell:startup`). The filename is kept so an existing Startup shortcut still matches. It does not install a service and does not write Registry Run keys.

If you move or re-clone the repository, the existing shortcut still points at the old path. Disable startup, run the script from the new location, then Enable startup again.

## Cursor native button

**→ ChatGPT** (status bar) sends the **current clipboard** to the ChatGPT desktop app: paste, then automatic Send. It does not copy a Cursor Agent response by itself.

To send a specific Agent response:

1. Click Cursor's native **Copy Message** on that response.
2. Click **→ ChatGPT**.
3. ChatGPT activates, the copied text is pasted, and the message is sent.

If you want to edit before sending, use **Copy Message** and `Ctrl+Alt+G` (paste only), or paste manually.

After `setup.ps1`, Cursor copies the extension into its own extensions folder. The button does not depend on a junction back to this repository.

## Removal

1. If startup is enabled, use the tray menu **Disable startup**.
2. Use the tray menu **Exit** to stop `[MAG] GPT|Cursor|Sync`.
3. Uninstall the Cursor extension:

```powershell
cursor --uninstall-extension magshifter.mag-workflow-bridge
```

Do not uninstall AutoHotkey unless you no longer need it. Do not delete the repository unless you want to remove the source files.

## Known limitations

- The target application must already be running for paste hotkeys. The product does not launch apps from those hotkeys.
- Paste goes to whichever control already has focus inside the activated window.
- Multiple matching windows may select the most recently active one.
- Cursor URI actions target the topmost Cursor window, not a user-selected window.
- The ChatGPT companion action bar tracks ChatGPT desktop only. It is not injected into ChatGPT.
- Hotkeys can conflict with third-party software.
- An elevated app may block interaction from an unelevated script (Windows privilege isolation).
- An existing Startup shortcut still points at the old script path if the repository is moved.
