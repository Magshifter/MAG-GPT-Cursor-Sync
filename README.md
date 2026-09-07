
by Magshifter

Standalone Windows development utility for fast synchronization between **ChatGPT Desktop**, **Cursor Agent**, and **Cursor Terminal**.

This is not a numbered MAG Ecosystem project.

Current repository directory: `MAG-Workflow-Bridge`.

Public repository name: `MAG-GPT-Cursor-Sync`.

Some internal technical identifiers intentionally retain the historical `MAG Workflow Bridge` name for compatibility.

Current version: **1.0.0**

## Purpose

`[MAG] GPT|Cursor|Sync` reduces repetitive manual actions when continuously transferring prompts, responses, commands, and terminal results between ChatGPT and Cursor.

Instead of repeatedly using:

`Copy → switch window → find input → Paste → Send`

the workflow can be reduced to explicit actions:

| Direction | Action |
|---|---|
| ChatGPT → Cursor Agent | Native ChatGPT Copy → companion **AGT** or tray **Cursor Agent** |
| ChatGPT → Cursor Terminal | Native ChatGPT Copy → companion **TER** or tray **Cursor Terminal** |
| Cursor clipboard → ChatGPT | **AGT → GPT** |
| Last Cursor Terminal execution → ChatGPT | **TER → GPT** |
| Last 2 Cursor Terminal executions → ChatGPT | **2** |
| Last 3 Cursor Terminal executions → ChatGPT | **3** |
| Clipboard → Cursor | `Ctrl+Alt+C` |
| Clipboard → Windows Terminal | `Ctrl+Alt+T` |
| Clipboard → ChatGPT | `Ctrl+Alt+G` |

The product does not scrape ChatGPT messages.

Companion **TER / AGT** and tray **Cursor Agent / Cursor Terminal** use the current clipboard.

## Cursor status bar

The Cursor extension provides one MAG status-bar group:

**TER → GPT | 2 | 3 | AGT → GPT**

The four actions are intentionally separate.

### AGT → GPT

Sends the **current clipboard** to ChatGPT Desktop.

Typical workflow:

1. Copy the desired text in Cursor.
2. Click **AGT → GPT**.
3. ChatGPT Desktop activates.
4. The clipboard is pasted.
5. The message is automatically sent.

Workflow:

`Copy → AGT → GPT → ChatGPT`

### TER → GPT

Sends the **last completed command and its output** from the active Cursor integrated Terminal to ChatGPT Desktop.

Example terminal command:

```powershell
git status
```

After clicking **TER → GPT**, ChatGPT receives the latest command together with its output and automatically sends the message.

This action uses Cursor / VS Code Terminal Shell Integration.

### 2

Sends the **last 2 completed terminal executions** and their outputs from the active Cursor Terminal.

Example:

```text
Command 1:
Write-Output "Test 2"

Output:
Test 2


Command 2:
Write-Output "Test 3"

Output:
Test 3
```

### 3

Sends the **last 3 completed terminal executions** and their outputs from the active Cursor Terminal.

Example:

```text
Command 1:
Write-Output "Test 1"

Output:
Test 1


Command 2:
Write-Output "Test 2"

Output:
Test 2


Command 3:
Write-Output "Test 3"

Output:
Test 3
```

The captured executions are sent in chronological order.

## Terminal history

Buttons **2** and **3** use an in-memory runtime history maintained by the Cursor extension through the public Terminal Shell Integration API.

The history:

- is stored separately for each Cursor Terminal;
- contains up to the last 3 completed executions;
- includes the command line and captured output;
- is not persisted to disk;
- does not combine histories from different terminals;
- contains only executions observed while the current extension runtime is active.

The extension starts reading execution output while the command is running.

It cannot reconstruct older terminal output retroactively.

History is therefore reset after events such as:

- `Developer: Reload Window`;
- Cursor restart;
- extension reload;
- closing the Terminal;
- opening a new Terminal.

If insufficient history has been captured, nothing is sent.

Example:

```text
Need 2 completed terminal command(s) in the active Terminal. Captured: 0.
```

After a reload, simply execute new commands before using **2** or **3**.

Example:

```powershell
Write-Output "History test 1"
Write-Output "History test 2"
Write-Output "History test 3"
```

## Status bar position

The MAG status-bar group supports two user-selectable positions:

- **Center**
- **Left**

The setting is available from the Windows tray menu:

```text
Status Bar Position
├─ Left
└─ Center
```

Default position:

**Center**

The selected position is persisted between restarts.

### Center

Uses the verified center-adjacent Cursor status-bar placement.

### Left

Moves the complete MAG block toward the left side of the Cursor status bar.

In both modes the internal order remains:

**TER → GPT | 2 | 3 | AGT → GPT**

Only one MAG status-bar group exists at a time.

### Why there is no Right mode

A Right mode was tested.

Cursor may insert native informational status items between separate extension `StatusBarItem` controls in the right-side status cluster.

That can visually split the MAG controls.

Because `[MAG] GPT|Cursor|Sync` requires the controls to remain a contiguous group, the unstable Right mode is intentionally not supported.

## ChatGPT companion action bar

`[MAG] GPT|Cursor|Sync` provides a small Windows companion UI associated with ChatGPT Desktop.

It is **not** a native ChatGPT plugin.

It does not:

- patch ChatGPT;
- inject UI into ChatGPT;
- use UI Automation;
- automatically click ChatGPT Copy;
- scrape ChatGPT responses.

While ChatGPT Desktop is active, the companion displays:

**TER | AGT**

near the lower part of the ChatGPT window.

It hides when ChatGPT is not active.

It also hides while the ChatGPT window is moving or resizing and reappears after the window position stabilizes.

Browser ChatGPT is not supported.

### ChatGPT → Cursor Agent

1. Use ChatGPT's native **Copy** action on the desired response or prompt.
2. Click **AGT**.
3. Cursor activates.
4. Cursor Agent receives the current clipboard.
5. The prompt is automatically submitted.

Workflow:

`ChatGPT Copy → AGT → Cursor Agent`

Tray action:

**Cursor Agent**

uses the same current-clipboard behavior.

URI:

```text
cursor://magshifter.mag-workflow-bridge/agent
```

Command:

```text
magWorkflowBridge.sendToCursorAgent
```

### ChatGPT → Cursor Terminal

1. Copy the desired command or command block in ChatGPT.
2. Make sure a Cursor integrated Terminal is already open.
3. Click **TER**.
4. Cursor activates.
5. The clipboard is sent to the active integrated Terminal.
6. The shell executes it.

Single-line commands are supported:

```powershell
git status
```

Multi-line clipboard content is also supported:

```powershell
git add .
git commit -m "Example commit"
git status
```

The clipboard block is sent as one block.

`[MAG] GPT|Cursor|Sync` does not:

- parse the command;
- split it into separate commands;
- reorder commands;
- rewrite the command.

The active shell interprets the content.

If no Cursor integrated Terminal is active, the action warns and does nothing.

The utility does not automatically create a Terminal.

Tray action:

**Cursor Terminal**

uses the same behavior.

URI:

```text
cursor://magshifter.mag-workflow-bridge/terminal
```

Command:

```text
magWorkflowBridge.sendToCursorTerminal
```

## Global hotkeys

Three global hotkeys are available.

| Hotkey | Target |
|---|---|
| `Ctrl+Alt+C` | Cursor |
| `Ctrl+Alt+T` | Windows Terminal |
| `Ctrl+Alt+G` | ChatGPT Desktop |

These hotkeys are intentionally **paste-only**.

They:

- activate the target application;
- paste the current clipboard;
- never press Enter;
- never automatically send a message;
- never automatically execute a command.

### Ctrl+Alt+C

Activates Cursor and pastes the clipboard.

It does not submit to Cursor Agent.

### Ctrl+Alt+T

Activates **Windows Terminal** and pastes the clipboard.

This is separate from companion/tray **TER**, which targets the integrated Cursor Terminal and executes the clipboard.

### Ctrl+Alt+G

Activates ChatGPT Desktop and pastes the clipboard.

It does not automatically send the message.

## Safety model

The utility deliberately separates **paste-only** actions from explicit **send/execute** actions.

Paste-only actions:

```text
Ctrl+Alt+C
Ctrl+Alt+T
Ctrl+Alt+G
```

These never press Enter.

Explicit automatic actions:

```text
AGT → GPT
TER → GPT
2
3
AGT
TER
```

Their behavior:

- **AGT → GPT** — sends the current clipboard to ChatGPT;
- **TER → GPT** — sends the latest Cursor Terminal command and output to ChatGPT;
- **2** — sends the last 2 captured terminal executions to ChatGPT;
- **3** — sends the last 3 captured terminal executions to ChatGPT;
- **AGT** — sends the current clipboard to Cursor Agent;
- **TER** — executes the current clipboard in Cursor Terminal.

If you want to inspect or edit content first, use normal Copy/Paste or the paste-only global hotkeys.

### Important TER warning

Pressing **TER** means:

**execute the current clipboard in Cursor Terminal**

Always verify the clipboard before pressing **TER**.

## Requirements

Required:

- Windows;
- Cursor;
- ChatGPT Desktop;
- AutoHotkey v2;
- PowerShell.

Recommended for terminal integration:

- **PowerShell 7 (`pwsh`)**

PowerShell 7 is strongly recommended for:

- **TER → GPT**
- **2**
- **3**

because these functions depend on Cursor / VS Code Terminal Shell Integration.

Windows PowerShell 5.1 may not expose the command/output boundaries required by these features.

Browser ChatGPT is not supported.

## Install AutoHotkey

Install:

**AutoHotkey v2**

Official website:

https://www.autohotkey.com/

AutoHotkey v1 is not supported.

After installation, the Windows component can be launched by running:

```text
MAG-Workflow-Bridge.ahk
```

## Install PowerShell 7

PowerShell 7 can be installed side-by-side with Windows PowerShell 5.1.

It does not remove Windows PowerShell 5.1.

Install PowerShell 7 using WinGet:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

Verify the installation:

```powershell
pwsh --version
```

Expected:

```text
PowerShell 7.x.x
```

You can also verify that `pwsh` is available:

```powershell
Get-Command pwsh
```

If PowerShell 7 was just installed but `pwsh` is not available yet, close and reopen the Terminal or restart Cursor.

## Configure PowerShell 7 in Cursor

Installing PowerShell 7 is not enough.

Cursor should open a **new integrated Terminal directly using the PowerShell 7 profile**.

In Cursor choose:

```text
Terminal → Select Default Profile → PowerShell
```

Then close the old integrated Terminal and create a new one:

```text
Terminal → New Terminal
```

Inside the new Cursor Terminal run:

```powershell
$PSVersionTable.PSVersion
```

Expected major version:

```text
7
```

You can also verify:

```powershell
$PSVersionTable.PSEdition
```

Expected:

```text
Core
```

To verify the executable currently running:

```powershell
(Get-Process -Id $PID).Path
```

Expected path is similar to:

```text
C:\Program Files\PowerShell\7\pwsh.exe
```

If `$PSVersionTable.PSVersion` still reports `5.1`, Cursor is still using Windows PowerShell 5.1.

Select the PowerShell profile again, close the old Terminal, and create a fresh Terminal.

### Do not rely on a pwsh subshell

Starting:

```powershell
pwsh
```

inside an already-open Windows PowerShell 5.1 Cursor Terminal is not the recommended configuration for `[MAG] GPT|Cursor|Sync`.

Although PowerShell 7 itself starts, the existing terminal session may not provide the Shell Integration context required for reliable command/output capture.

Prefer:

```text
Cursor
→ Terminal
→ Select Default Profile
→ PowerShell
→ New Terminal
```

Then confirm:

```powershell
$PSVersionTable.PSVersion
```

shows `7.x`.

## Installation

1. Install AutoHotkey v2.
2. Install PowerShell 7 if you want reliable terminal-result integration.
3. Clone or download this repository.
4. Open PowerShell in the repository directory.
5. Install the Cursor extension.
6. Reload Cursor.
7. Run `MAG-Workflow-Bridge.ahk`.

### Install Cursor extension

From the repository directory run:

```powershell
powershell -ExecutionPolicy Bypass -File ".\setup.ps1"
```

If running setup from another location:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\path\to\MAG-Workflow-Bridge\setup.ps1"
```

`-ExecutionPolicy Bypass` applies only to this PowerShell invocation.

It does not globally change the Windows PowerShell execution policy.

`setup.ps1` packages and installs the local Cursor extension using Cursor CLI.

It does not:

- enable Windows startup;
- launch ChatGPT;
- launch Windows Terminal;
- automatically configure PowerShell 7.

After installation, reload Cursor:

```text
Ctrl+Shift+P
Developer: Reload Window
```

## Updating

After updating the repository, reinstall the Cursor extension:

```powershell
powershell -ExecutionPolicy Bypass -File ".\setup.ps1"
```

Then in Cursor:

```text
Ctrl+Shift+P
Developer: Reload Window
```

Changes inside `cursor-extension` are not applied merely by restarting the AutoHotkey script.

If the update also changes:

```text
MAG-Workflow-Bridge.ahk
```

restart the Windows component as well.

Example:

```powershell
Get-Process AutoHotkey64 -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process ".\MAG-Workflow-Bridge.ahk"
```

A full Windows restart is not required.

## Running the Windows component

Run:

```text
MAG-Workflow-Bridge.ahk
```

The script remains loaded while AutoHotkey is running.

The tray icon uses:

```text
assets\MAG-GPT-Cursor-Sync.ico
```

The tray provides application controls and actions.

Use tray **Exit** to stop:

- global hotkeys;
- tray actions;
- ChatGPT companion;
- the Windows component.

## Tray menu

The tray provides access to:

- Cursor Agent action;
- Cursor Terminal action;
- ChatGPT companion control;
- Status Bar Position;
- Startup control;
- Exit.

### Status Bar Position

```text
Status Bar Position
├─ Left
└─ Center
```

The selected option uses the native Windows menu checkmark.

The selection is stored locally outside the Git repository.

Settings path:

```text
%LOCALAPPDATA%\MAG-GPT-Cursor-Sync\settings.ini
```

Example:

```ini
[StatusBar]
Position=center
```

Allowed values:

```text
left
center
```

Missing or invalid values default to:

```text
center
```

The Cursor extension also persists its selected position using extension `globalState`.

Changing the position from the tray updates the Cursor extension immediately through the existing Cursor URI mechanism.

The script does not continuously poll Cursor and does not use filesystem watchers for synchronization.

## Optional Windows startup

Startup is optional and per-user.

It is disabled until explicitly enabled.

1. Run `MAG-Workflow-Bridge.ahk`.
2. Open the tray menu.
3. Choose **Enable startup**.
4. To remove it, choose **Disable startup**.

Startup uses one shortcut in the current user's Windows Startup folder.

Shortcut name:

```text
MAG Workflow Bridge.lnk
```

The historical filename is intentionally retained for compatibility.

The utility does not create:

- Windows services;
- Scheduled Tasks;
- Registry Run entries.

If the repository is moved, the existing shortcut still points at the previous path.

In that case:

1. disable startup;
2. run the script from the new location;
3. enable startup again.

## Current application targets

### Cursor

Process:

```text
Cursor.exe
```

### Windows Terminal

Process:

```text
WindowsTerminal.exe
```

### ChatGPT Desktop

Process:

```text
ChatGPT.exe
```

Browser ChatGPT is not targeted.

If several matching windows exist, the most recently active matching window may be selected.

Cursor URI actions are handled by Cursor itself.

## Cursor extension commands

Current technical command IDs include:

```text
magWorkflowBridge.sendToChatGPT
magWorkflowBridge.sendLastTerminalOutputToChatGPT
magWorkflowBridge.sendLast2TerminalOutputsToChatGPT
magWorkflowBridge.sendLast3TerminalOutputsToChatGPT
magWorkflowBridge.sendToCursorAgent
magWorkflowBridge.sendToCursorTerminal
```

The historical `magWorkflowBridge` namespace is intentionally retained for compatibility.

## Cursor URIs

Current technical URI actions include:

```text
cursor://magshifter.mag-workflow-bridge/agent
cursor://magshifter.mag-workflow-bridge/terminal
cursor://magshifter.mag-workflow-bridge/statusbar-left
cursor://magshifter.mag-workflow-bridge/statusbar-center
```

The historical extension identifier is intentionally retained.

## Troubleshooting

### TER → GPT cannot obtain terminal output

If this warning appears:

```text
Could not obtain last terminal command and output. Shell integration may be unavailable.
```

check the PowerShell version inside the active Cursor integrated Terminal:

```powershell
$PSVersionTable.PSVersion
```

If it reports:

```text
5.1
```

you are using Windows PowerShell 5.1.

Install PowerShell 7 and create a fresh Cursor Terminal using the PowerShell 7 profile.

Expected:

```text
7.x
```

### Buttons 2 or 3 report Captured: 0

Example:

```text
Need 2 completed terminal command(s) in the active Terminal. Captured: 0.
```

This means the current runtime has not yet captured enough completed executions.

This commonly happens after:

- Cursor restart;
- `Developer: Reload Window`;
- extension reload;
- closing the previous Terminal;
- opening a new Terminal.

Execute new commands and try again.

Example:

```powershell
Write-Output "History test 1"
Write-Output "History test 2"
Write-Output "History test 3"
```

Then:

- **TER → GPT** sends the latest command;
- **2** sends the last two;
- **3** sends the last three.

### Cursor still shows old buttons or behavior

Reinstall the extension:

```powershell
powershell -ExecutionPolicy Bypass -File ".\setup.ps1"
```

Then:

```text
Ctrl+Shift+P
Developer: Reload Window
```

Restarting only `MAG-Workflow-Bridge.ahk` does not reload extension changes.

### Tray changes are missing

If the update changed:

```text
MAG-Workflow-Bridge.ahk
```

restart the AutoHotkey script:

```powershell
Get-Process AutoHotkey64 -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process ".\MAG-Workflow-Bridge.ahk"
```

### PowerShell blocks setup.ps1

If Windows reports:

```text
running scripts is disabled on this system
```

use:

```powershell
powershell -ExecutionPolicy Bypass -File ".\setup.ps1"
```

There is no need to globally weaken the Windows PowerShell execution policy.

## Known limitations

- Target applications must already be running for the global paste hotkeys.
- Paste goes to the control that already has focus inside the activated target window.
- Browser ChatGPT is not supported.
- Multiple matching application windows may cause the most recently active matching window to be selected.
- Cursor integrated Terminal must already exist before using **TER**.
- **TER** does not create a new Terminal automatically.
- **2** and **3** cannot retroactively capture output that occurred before the current extension runtime started listening.
- Terminal runtime history is intentionally not persisted.
- The ChatGPT companion uses the current clipboard and does not automatically copy ChatGPT responses.
- The companion is an external MAG-controlled Windows UI and is not injected into ChatGPT.
- Hotkeys may conflict with other software.
- Elevated applications may reject interaction from an unelevated AutoHotkey script because of Windows privilege isolation.
- Status-bar placement depends partly on Cursor's own status-bar layout.
- A true center-alignment API is not available; the Center mode uses the verified practical placement.
- Right-side placement is intentionally unsupported because Cursor native information items may split the MAG status-bar group.
- An existing Startup shortcut continues to point at the old script location if the repository is moved.

## Removal

1. If Startup is enabled, use tray **Disable startup**.
2. Use tray **Exit**.
3. Uninstall the Cursor extension:

```powershell
cursor --uninstall-extension magshifter.mag-workflow-bridge
```

4. Reload Cursor.

Do not uninstall AutoHotkey unless you no longer need it for other scripts.

Delete the repository only if you also want to remove the source files.

## Project page

The official resource page for `[MAG] GPT|Cursor|Sync` is available at:

https://magshifter.com/resources/chatgpt-vs-cursor-synchronization-tool.8/

The resource page contains the project description, usage information, updates, and related information.

## Support, discussion and feedback

Questions, bug reports, suggestions, feedback, and general discussion are welcome in the dedicated forum thread:

https://magshifter.com/threads/chatgpt-vs-cursor-synchronization-tool.18/

If you encounter a problem, please include:

- what action you were using;
- what you expected to happen;
- what actually happened;
- your Cursor version;
- your PowerShell version when the issue involves Terminal integration;
- any visible warning or error message.

This makes troubleshooting much easier.

## Technical notes

Public product name:

```text
[MAG] GPT|Cursor|Sync
```

Repository:

```text
https://github.com/Magshifter/MAG-GPT-Cursor-Sync
```

Current version:

```text
1.0.0
```

Author:

```text
Magshifter
```

Technical extension ID:

```text
magshifter.mag-workflow-bridge
```

Main AutoHotkey file:

```text
MAG-Workflow-Bridge.ahk
```

Startup shortcut:

```text
MAG Workflow Bridge.lnk
```

Some internal identifiers intentionally retain the historical `MAG Workflow Bridge` identity for compatibility.

They should not be renamed independently without a separate compatibility decision.

This project is not a XenForo add-on.

It is a standalone Windows/Cursor utility designed to simplify the development workflow between ChatGPT and Cursor.

## Why this exists

In this workflow, ChatGPT is used for analysis, architecture, planning, technical decisions, and preparing precise implementation tasks.

Cursor works directly with the local repository and implementation.

When these transitions happen many times per day, the repeated workflow:

`Copy → switch window → find input → Paste → Send`

creates unnecessary friction.

`[MAG] GPT|Cursor|Sync` does not replace ChatGPT or Cursor.

It makes communication between them faster.

Typical workflow:

```text
ChatGPT → Cursor Agent:
Copy → AGT

ChatGPT → Cursor Terminal:
Copy → TER

Cursor → ChatGPT:
AGT → GPT

Cursor Terminal → ChatGPT:
TER → GPT / 2 / 3
```

A terminal-focused loop becomes:

```text
ChatGPT
→ TER
→ execute command
→ TER → GPT / 2 / 3
→ analyze result in ChatGPT
```

Use **TER → GPT** when one command is enough.

Use **2** or **3** when ChatGPT needs the context of several consecutive terminal operations.
```
