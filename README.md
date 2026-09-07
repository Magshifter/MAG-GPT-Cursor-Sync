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
| ChatGPT → Cursor Agent | Native Copy, then companion **AGT** or tray **Cursor Agent** |
| ChatGPT → Cursor Terminal | Native Copy, then companion **TER** or tray **Cursor Terminal** (single- or multi-line) |

Companion TER/AGT and tray Agent/Terminal use the **current clipboard**. They do not copy ChatGPT for you. This product does not scrape ChatGPT messages.

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

Native ChatGPT Copy → companion **AGT** or tray **Cursor Agent** → current clipboard → Cursor Agent → `composer.focusComposer` → paste → one Enter.

Triggers:

- ChatGPT companion **AGT** (current clipboard)
- Tray: **Cursor Agent** (current clipboard)
- Command Palette: `[MAG] GPT|Cursor|Sync: Send Clipboard to Cursor Agent`

URI: `cursor://magshifter.mag-workflow-bridge/agent`

**ChatGPT → Cursor Terminal**

Native ChatGPT Copy → companion **TER** or tray **Cursor Terminal** → current clipboard (one or many lines) → active Cursor integrated terminal → `sendText(..., true)`.

The clipboard block is sent as-is to the shell. TER does not parse, split, or reorder commands. Single-line and multi-line content are both accepted.

Triggers:

- ChatGPT companion **TER** (current clipboard)
- Tray: **Cursor Terminal** (current clipboard)
- Command Palette: `[MAG] GPT|Cursor|Sync: Execute Clipboard in Cursor Terminal`

URI: `cursor://magshifter.mag-workflow-bridge/terminal`

That is not Windows Terminal. `Ctrl+Alt+T` pastes only into Windows Terminal and does **not** execute.

If no Cursor integrated terminal is active, the command warns and does nothing. TER does not create a terminal automatically.

`Ctrl+Alt+C` does not submit to Agent.

## ChatGPT companion action bar

This is a MAG-controlled Windows companion UI. It is **not** a native ChatGPT plugin. It does not patch, inject, or modify ChatGPT. It does not use UI Automation and does not click ChatGPT Copy for you.

While ChatGPT desktop is active, one stable **TER | AGT** pair sits near the lower-right composer area. It hides while the ChatGPT window is moving or resizing, then reappears in the final position. It hides when ChatGPT is not active. Browser ChatGPT is not supported.

The companion does **not** automatically copy ChatGPT responses. You select exact content with ChatGPT's native Copy. Empty clipboard is refused with `Clipboard is empty.`

**ChatGPT → Cursor Agent**

1. Use ChatGPT native Copy on the desired Plain Text/prompt.
2. Click **AGT** (or tray **Cursor Agent**).
3. Cursor activates.
4. Agent receives the current clipboard.
5. The prompt submits automatically.

**ChatGPT → Cursor Terminal**

1. Use ChatGPT native Copy on the desired command or multi-line terminal block.
2. Click **TER** (or tray **Cursor Terminal**).
3. Cursor activates.
4. The active Cursor integrated terminal receives the clipboard block and the shell executes it.

TER supports single-line and multi-line clipboard content. It does not create a terminal, does not parse commands, and does not strip ChatGPT content. `Ctrl+Alt+T` remains paste-only into Windows Terminal and is a separate action.

Tray **ChatGPT action bar** enables or disables the companion for the current session (default enabled; not persisted).

## Safety model

Global hotkeys never press Enter, Submit, or Send. They activate the target app and paste the clipboard. You review and submit or execute yourself.

These actions are explicit execute intent:

- **→ ChatGPT** (status bar)
- Cursor Agent (companion **AGT** or tray; current clipboard)
- Cursor Terminal (companion **TER** or tray; current clipboard)

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
- The compact ChatGPT companion (**TER | AGT**) is MAG-controlled overlay UI near the composer. It is not injected into ChatGPT. It uses the current clipboard only; it does not auto-copy ChatGPT responses.
- Hotkeys can conflict with third-party software.
- An elevated app may block interaction from an unelevated script (Windows privilege isolation).
- An existing Startup shortcut still points at the old script path if the repository is moved.
