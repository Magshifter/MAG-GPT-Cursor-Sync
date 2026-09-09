```markdown
# [MAG] GPT|Cursor|Sync — Development Plan

## 1. Document purpose

This document preserves the current verified state, approved product direction, research conclusions, architectural boundaries, and proposed future development sequence for:

`[MAG] GPT|Cursor|Sync`

Public release title:

`[MAG] GPT|Cursor|Sync — ChatGPT vs Cursor Synchronization Tool`

Author:

`Magshifter`

Repository:

`MAG-GPT-Cursor-Sync`

Current local repository directory:

`MAG-Workflow-Bridge`

Current version baseline:

`1.0.0`

This document exists to preserve continuity between ChatGPT Project conversations and future development sessions.

It is a planning and coordination document.

It does not independently authorize implementation, Git operations, version changes, packaging, publication, or release.

---

## 2. Project classification

`[MAG] GPT|Cursor|Sync` is a standalone MAG-branded development utility.

It is NOT currently a numbered MAG Ecosystem product project.

Do not assign:

`#3`

or any other permanent MAG project number unless the Product Owner explicitly approves that classification in the future.

The tool may follow applicable MAG development discipline and AI-agent rules without becoming a numbered XenForo/MAG product project.

It must remain isolated from:

- `MAG-Ecosystem`
- `GlobalLinksFavicons`
- `TagSynchronizer`
- other MAG project repositories

unless a future explicitly approved task requires cross-project work.

---

## 3. Product purpose

The product reduces manual context switching between:

- ChatGPT Desktop
- Cursor Agent
- Cursor integrated Terminal
- Windows Terminal

The core design principle is:

> Explicit user action should move the required context to the required destination with the minimum number of manual steps while preserving user control.

The application must not silently execute unrelated actions or guess the user's intended source when that guess could send incorrect content.

---

## 4. Current verified baseline

Current stable baseline:

`v1.0.0`

The existing implementation combines:

- AutoHotkey v2 Windows integration;
- Cursor extension commands;
- ChatGPT Desktop integration;
- Windows Terminal integration;
- Cursor Terminal Shell Integration;
- Status Bar actions;
- ChatGPT companion controls;
- paste-only global hotkeys;
- explicit send/execute actions.

### 4.1 Global paste-only hotkeys

Current behavior:

```text
Ctrl+Alt+C
→ Cursor
→ paste clipboard only

Ctrl+Alt+T
→ Windows Terminal
→ paste clipboard only

Ctrl+Alt+G
→ ChatGPT Desktop
→ paste clipboard only
```

These actions must not automatically press Enter or otherwise submit/execute the pasted content.

### 4.2 Explicit Cursor → ChatGPT actions

Current Status Bar group:

```text
TER → GPT | 2 | 3 | AGT → GPT
```

Behavior:

`TER → GPT`

Sends the latest completed Cursor Terminal command and output to ChatGPT Desktop.

`2`

Sends the last two captured completed Terminal executions in chronological order.

`3`

Sends the last three captured completed Terminal executions in chronological order.

`AGT → GPT`

Sends the current clipboard contents to ChatGPT Desktop.

These are explicit auto-send actions.

### 4.3 ChatGPT companion

The ChatGPT Desktop companion provides:

```text
CLEAR | TER | AGT
```

`CLEAR`

Logically resets TER eligibility (recovery). Does not clear the Windows clipboard or execute anything.

`TER`

Sends the current clipboard contents to the active Cursor integrated Terminal (**paste only**; user presses Enter to run).

`AGT`

Sends the current clipboard contents to Cursor Agent and submits them.

The companion:

- is implemented through AutoHotkey;
- is shown only while ChatGPT Desktop is active;
- is AlwaysOnTop;
- does not activate itself when shown;
- hides while the ChatGPT window is being moved or resized;
- does not use UI Automation to inspect ChatGPT content;
- does not automatically copy ChatGPT responses.

Browser ChatGPT is not a supported integration target.

### 4.4 Terminal history

Terminal history is runtime-only.

The extension captures completed Terminal shell executions through public terminal Shell Integration APIs.

History is maintained separately per Terminal.

Maximum retained history:

```text
3 completed executions
```

A Cursor restart, Developer Reload, or new Terminal starts with empty runtime history.

Insufficient history must produce a warning and send nothing.

### 4.5 Status Bar position

Supported positions:

```text
Left
Center
```

Default:

```text
Center
```

`Right` is intentionally unsupported because native Cursor Status Bar items may interleave with MAG items.

The intended order in both supported positions is:

```text
TER → GPT | 2 | 3 | AGT → GPT
```

Position is persisted.

### 4.6 Automatic Cursor Models After telemetry (verified)

**Status:** verified in daily use (Product Owner, 2026).

When **Cursor Models Telemetry** is enabled (tray menu → **Enabled**; persisted in local `settings.ini` under `[Telemetry]`), **AGT → GPT** automatically obtains the current **Cursor Models** displayed percentage when available and appends a single MAG telemetry footer to the clipboard payload immediately before transfer to ChatGPT Desktop:

```text
Cursor Models After: NN%
```

Verified behavior:

- telemetry is obtained through the isolated `cursorUsageProvider` (`getCursorModelsPercentage()`);
- duplicate MAG footers are stripped before append;
- a valid primary report (clipboard / Agent content the user explicitly sends) still transfers when telemetry lookup fails;
- telemetry failure does not block send;
- no routine Product Owner manual **After** reporting is required when a valid footer is present.

**ChatGPT consumption and failure handling** are defined by MAG Global methodology, not this document. See:

```text
MAG-Ecosystem / CURSOR_USAGE_ANALYTICS.md
```

In summary (product boundary only):

- ChatGPT consumes a valid automatic **After** line silently under current Global rules;
- missing, blank, malformed, or otherwise unusable telemetry must be surfaced to the Product Owner as a likely MAG GPT|Cursor|Sync tooling/telemetry failure;
- telemetry must never be guessed, copied from an earlier value, or substituted with **Before**;
- telemetry failure must not prevent review of an otherwise valid Cursor Agent report.

**Not in scope for this verified capability:**

- `TER → GPT`, `2`, and `3` do not append Cursor Models telemetry;
- companion **AGT** sends to Cursor Agent only (no automatic telemetry on that path);
- true one-click extraction of the latest completed Agent response without prior Copy remains future work (§7, §16).

---

## 5. Environment baseline

Verified Windows environment includes:

- AutoHotkey v2
- Cursor Desktop
- ChatGPT Desktop Store application
- Windows Terminal
- PowerShell 7

Cursor executable:

```text
C:\Users\user\AppData\Local\Programs\cursor\Cursor.exe
```

Cursor process:

```text
Cursor.exe
```

ChatGPT Desktop process:

```text
ChatGPT.exe
```

Windows Terminal process:

```text
WindowsTerminal.exe
```

PowerShell 7 must be selected as the actual Cursor integrated Terminal profile for reliable Terminal Shell Integration.

Launching `pwsh` manually inside an existing Windows PowerShell 5.1 terminal is not considered an equivalent configuration.

---

## 6. Technical identity

Current technical identifiers intentionally remain unchanged unless a separate migration is approved.

Examples:

```text
magWorkflowBridge.sendToChatGPT
magWorkflowBridge.sendLastTerminalOutputToChatGPT
magWorkflowBridge.sendLast2TerminalOutputsToChatGPT
magWorkflowBridge.sendLast3TerminalOutputsToChatGPT
magWorkflowBridge.sendToCursorAgent
magWorkflowBridge.sendToCursorTerminal
```

Extension ID:

```text
magshifter.mag-workflow-bridge
```

Package name:

```text
mag-workflow-bridge
```

Main AutoHotkey source:

```text
MAG-Workflow-Bridge.ahk
```

Startup shortcut:

```text
MAG Workflow Bridge.lnk
```

Existing technical identity must not be renamed merely to match the newer public product name.

Any such migration requires separate review.

---

## 7. Target product direction

The main future objective remains:

# True One-Click Cursor → ChatGPT transfer

**Partial progress (verified):** automatic **Cursor Models After** telemetry on the explicit **AGT → GPT** path (§4.6). The user still supplies Agent report content via clipboard (for example Cursor Copy Message) before **AGT → GPT**.

**Still future:** MAG obtains the latest completed Cursor Agent response without requiring the user to copy it first.

The desired end-to-end workflow is:

```text
Cursor Agent completes a response
        ↓
User performs one explicit MAG action
        ↓
MAG obtains latest completed Cursor Agent response   ← not yet implemented
        ↓
MAG obtains current Cursor Models percentage        ← verified on AGT → GPT
        ↓
MAG appends usage telemetry                         ← verified on AGT → GPT
        ↓
MAG transfers the complete report to ChatGPT Desktop
        ↓
MAG sends it
```

Target result:

```text
Latest Cursor Agent response
+
Cursor Models After: NN%
```

without requiring the user to manually use Cursor's Copy Message command first.

---

## 8. One-click research conclusion

A smart button must NOT attempt to determine whether the user currently means Agent, Terminal, or another Cursor UI surface by inspecting Cursor's visible interface.

Cursor extensions do not have a stable public API for inspecting arbitrary Cursor UI DOM/state.

Cursor's Agent UI also changes between Cursor versions and layouts.

Therefore the product must not depend on:

- Cursor UI DOM scraping;
- UI Automation for Cursor Agent content;
- OCR;
- screenshot parsing;
- coordinate-based Copy button clicking;
- synthetic Cursor UI interaction;
- guessing the intended source.

The preferred direction is structured local data access.

---

## 9. Cursor Agent report extraction concept

Research indicates that Cursor stores chat/conversation information locally using VS Code-style storage infrastructure.

Potential sources include:

```text
workspaceStorage
state.vscdb
```

However, Cursor's internal chat storage schema is undocumented and may change.

Before implementation, a read-only feasibility probe is required.

The probe must determine whether MAG can reliably identify:

- the current workspace;
- the relevant Agent conversation;
- the latest assistant response;
- user vs assistant messages;
- completed vs streaming messages;
- exact response text;
- Markdown/raw representation;
- tool-call content boundaries;
- conversation ordering;
- storage behavior after Cursor restart;
- schema stability for the installed Cursor version.

No production Agent-response reader should be implemented until this probe succeeds.

---

## 10. Cursor Models telemetry

### 10.1 Product goal

After a Cursor procedure, ChatGPT should receive:

```text
Cursor Models After: NN%
```

automatically when reliable telemetry is available.

This reduces routine Product Owner manual **After** reporting when MAG appends a valid footer and ChatGPT applies current Global methodology.

**Methodology authority:** interpretation, silent consumption, failure surfacing, visible-delta rules, and metric finalization are owned by:

```text
MAG-Ecosystem / CURSOR_USAGE_ANALYTICS.md
```

This development plan documents MAG GPT|Cursor|Sync product behavior only.

### 10.1.1 Verified current implementation (AGT → GPT)

When **Cursor Models Telemetry** is enabled:

1. User places the Cursor Agent report on the clipboard (explicit copy workflow).
2. User clicks **AGT → GPT** (Status Bar) or invokes `magWorkflowBridge.sendToChatGPT`.
3. MAG calls `getCursorModelsPercentage()` via `cursorUsageProvider.js` (bounded Cursor-owned HTTPS request using transient local session access; no credential persistence).
4. On success, MAG strips any existing MAG telemetry footer and appends `Cursor Models After: NN%` to the clipboard payload.
5. MAG transfers the prepared text to ChatGPT Desktop and sends it.

On telemetry failure (`null` / timeout / invalid response), the original clipboard report is sent unchanged and send is not blocked.

### 10.2 Official limitation

Cursor currently provides no supported public individual-plan usage API or CLI intended for this integration.

Therefore any automated account-usage provider must be treated as an undocumented integration.

### 10.3 Community evidence

Multiple community implementations demonstrate that Cursor usage information can currently be obtained from structured account/session data without OCR.

Observed approaches include:

- local Cursor authentication/session data;
- Cursor-owned HTTPS usage endpoints;
- Cursor dashboard service endpoints;
- Cursor usage-summary endpoints.

Current community evidence maps:

```text
autoPercentUsed
→ Cursor Models

apiPercentUsed
→ Other Models
```

The visible Cursor UI percentage must not be reconstructed from raw monetary usage when an actual percentage field is available.

### 10.4 Preferred semantic source

The strongest current semantic match for the visible Cursor UI bars is the Cursor usage-summary data that exposes:

```text
autoPercentUsed
```

for:

```text
Cursor Models
```

An alternative Connect RPC dashboard endpoint may be retained only as a carefully isolated fallback if later justified.

Both mechanisms are undocumented and must be considered unstable.

---

## 11. Telemetry security rules

Cursor authentication credentials are sensitive.

MAG must never:

- send Cursor credentials to ChatGPT;
- send Cursor credentials to MAG servers;
- write Cursor credentials into MAG configuration;
- write Cursor credentials into logs;
- expose Cursor credentials in error messages;
- copy Cursor credentials to clipboard;
- persist unnecessary copies of Cursor credentials.

If local authentication data must be read, it should be used only long enough to perform the required request.

Network access must be restricted to the expected Cursor-owned HTTPS origin.

Unexpected origins must fail closed.

Usage telemetry is secondary functionality.

Failure to obtain usage telemetry must never prevent an otherwise valid Agent report from being transferred.

---

## 12. Cursor usage interpretation

The product must distinguish between:

```text
displayed Cursor Models percentage
```

and:

```text
exact underlying Cursor consumption
```

These are not equivalent.

Example:

```text
Cursor Models Before: 54%
Cursor Models After: 54%
```

means:

```text
Visible delta: 0 percentage points
```

It does NOT prove:

```text
actual usage = 0
```

Cursor's displayed percentage may also be cached or delayed.

MAG must not invent precision that Cursor does not provide.

---

## 13. Proposed provider architecture

Future functionality should be separated into small providers rather than added directly to UI handlers.

Conceptual structure:

```text
TransferController
├── AgentReportProvider
├── TerminalProvider
├── ClipboardProvider
├── CursorUsageProvider
└── ChatGPTTransport
```

### AgentReportProvider

Responsibility:

```text
Obtain latest completed Cursor Agent response
```

It must not send the response anywhere.

### TerminalProvider

Responsibility:

```text
Obtain latest / last 2 / last 3 completed Terminal executions
```

Existing terminal behavior should eventually be isolated behind this boundary without changing current behavior unnecessarily.

### ClipboardProvider

Responsibility:

```text
Obtain explicit clipboard content
```

Used for existing manual clipboard workflows.

### CursorUsageProvider

Responsibility:

```text
getCursorModelsPercentage()
→ integer or null
```

It must not contain ChatGPT transfer logic.

### ChatGPTTransport

Responsibility:

```text
Transfer prepared text to ChatGPT Desktop
and explicitly submit it when requested
```

### TransferController

Responsibility:

```text
Select explicitly requested source
→ obtain content
→ optionally obtain telemetry
→ prepare final payload
→ invoke ChatGPT transport
```

It must not silently substitute another source when the requested source fails.

---

## 14. Failure policy

Source content and telemetry have different importance.

### Agent report failure

If the user requests an Agent report and the latest completed Agent response cannot be reliably obtained:

```text
WARN
SEND NOTHING
```

MAG must NOT silently fall back to:

- clipboard;
- Terminal output;
- an older unrelated Agent response;
- guessed Cursor content.

Wrong context is worse than no transfer.

### Usage telemetry failure

If the Agent report is valid but Cursor Models telemetry fails:

```text
SEND AGENT REPORT
WITHOUT TELEMETRY
```

Usage telemetry must never block the primary workflow.

MAG GPT|Cursor|Sync does not guess or substitute a percentage when lookup fails.

ChatGPT must surface missing/invalid automatic **After** to the Product Owner as a likely tooling/telemetry failure per `MAG-Ecosystem / CURSOR_USAGE_ANALYTICS.md` (§8.0.1). That surfacing is methodology-owned; this product must not invent **After** values locally.

### Terminal failure

Existing Terminal safety behavior remains:

- no active Terminal → warn;
- insufficient history → warn;
- stale clipboard must not be treated as Terminal output;
- send nothing when the requested Terminal source cannot be obtained reliably.

---

## 15. Duplicate telemetry prevention

**Status:** implemented for the **AGT → GPT** telemetry path.

MAG must not repeatedly append telemetry to a report that already contains the same MAG telemetry footer.

Example target footer:

```text
Cursor Models After: 54%
```

Before appending, the transfer pipeline must detect an existing MAG-generated usage footer.

Repeated one-click actions must not produce:

```text
Cursor Models After: 54%
Cursor Models After: 54%
Cursor Models After: 54%
```

---

## 16. Proposed development sequence

The following sequence is proposed.

It is NOT automatically authorized by this document.

Each implementation stage requires Product Owner approval.

### U1 — Read-Only Feasibility Probe

Goal:

Prove that both future one-click inputs can be obtained reliably.

Inputs:

```text
Latest completed Cursor Agent response
Current Cursor Models percentage
```

**Status:**

```text
Cursor Models percentage — verified (production telemetry; §4.6, §10.1.1)
Latest completed Cursor Agent response — not verified; formal read-only probe still proposed
```

Expected research output (Agent portion still outstanding):

```text
Latest Agent response:
<exact latest completed response>

Cursor Models:
54%
```

Requirements:

- read-only;
- no `[MAG] GPT|Cursor|Sync` production modification;
- no clipboard modification;
- no ChatGPT send;
- no Cursor send;
- no credential persistence;
- no Git changes;
- no version changes.

The probe must document exactly where each value came from.

Success requires comparison against the visible Cursor UI.

U1 must fail rather than guess.

### U2 — CursorUsageProvider

**Status:** implemented and verified in production (`cursorUsageProvider.js`).

Implement an isolated provider:

```text
getCursorModelsPercentage()
→ integer or null
```

Requirements (met by current implementation):

- minimal local credential access;
- one bounded request;
- short timeout;
- percentage validation;
- Cursor-owned HTTPS only;
- no token persistence;
- no logs containing credentials;
- graceful null result on failure;
- no ChatGPT logic.

### U3 — CursorAgentReportProvider

**Status:** not implemented — proposed.

Only after successful U1 Agent-storage verification.

Implement an isolated provider for:

```text
latest completed Cursor Agent response
```

Requirements:

- read-only local storage access;
- current conversation/workspace resolution;
- completed response only;
- assistant response only;
- deterministic selection;
- no UI Automation;
- no OCR;
- no Cursor UI DOM assumptions;
- explicit failure when selection is ambiguous.

Because Cursor storage is undocumented, all schema-specific logic must remain isolated.

### U4 — One-Click GPT Pipeline

**Status:** partial — telemetry append on explicit **AGT → GPT** is verified; automatic Agent report extraction (U3) is not.

Only after U2 and U3 are independently reliable.

Target:

```text
one explicit MAG action
→ latest completed Agent response
→ Cursor Models percentage
→ append telemetry
→ ChatGPT Desktop
→ Send
```

Primary failure rule:

```text
Agent extraction failure
→ send nothing
```

Secondary failure rule:

```text
Usage extraction failure
→ send Agent report without usage footer
```

### U5 — Regression and Failure Validation

**Status:** not complete — proposed full validation pass after U3/U4.

Validate:

- Agent extraction;
- completed-response detection;
- streaming-response rejection;
- Cursor restart behavior;
- workspace/conversation switching;
- usage/UI percentage match;
- telemetry timeout;
- telemetry endpoint failure;
- missing auth;
- duplicate footer prevention;
- Agent extraction failure;
- clipboard regression;
- `TER → GPT` regression;
- `2` regression;
- `3` regression;
- ChatGPT companion TER regression;
- ChatGPT companion AGT regression;
- paste-only hotkey regression;
- Status Bar positioning regression.

No existing workflow may be broken merely to introduce one-click Agent transfer.

### U6 — UX Simplification

Future concept only.

After one-click is proven reliable, evaluate whether the Status Bar can be simplified.

Potential primary action:

```text
MAG GPT
```

or equivalent.

Secondary operations could remain available through:

- Command Palette;
- MAG commands;
- context menus;
- future MAG Control View;
- tray menu.

Do not remove existing controls until the replacement workflow is proven better and explicitly approved.

### U7 — Windows Packaging

Only after the runtime architecture is stable.

Target:

```text
AutoHotkey source
→ compiled executable
→ Windows installer
```

The source remains authoritative.

Potential artifacts:

```text
MAG-Workflow-Bridge.ahk
MAG-GPT-Cursor-Sync.exe
Installer.exe
```

Exact installer technology remains undecided.

Candidate technologies include:

- Inno Setup;
- NSIS.

Selection requires a separate packaging decision.

---

## 17. Future MAG Control View

A future native Cursor View may provide a better location for secondary information and controls.

Potential information:

```text
MAG GPT|Cursor|Sync
-------------------
Cursor Models: 54%

Status:
ChatGPT Desktop    Connected
PowerShell 7       Ready
Shell Integration  Ready

Actions:
Send Agent → GPT
Send Terminal → GPT
Settings
Diagnostics
```

This is a future concept only.

It is not approved implementation.

The Status Bar should remain the quick-action surface unless a better tested UX replaces it.

A Webview should not be introduced merely to implement the one-click command.

Prefer native Cursor/VS Code UI APIs whenever they are sufficient.

---

## 18. Windows EXE packaging

The final Windows application should not require ordinary users to manually install AutoHotkey.

AutoHotkey v2 source may be compiled using the official AutoHotkey compilation toolchain.

Conceptual distribution:

```text
Source repository
    ↓
AutoHotkey source
    ↓
Compiled MAG executable
    ↓
Windows installer
```

The compiled executable does not replace the source as the development authority.

---

## 19. Installer concept

Desired user experience:

```text
Download installer
→ Next
→ Install
→ Finish
```

The installer may eventually handle:

- MAG executable installation;
- required assets;
- application icon;
- Start Menu shortcut;
- optional Startup shortcut;
- Cursor extension installation;
- dependency checks;
- PowerShell 7 detection;
- uninstall support;
- settings preservation where appropriate.

Exact behavior requires separate implementation planning.

---

## 20. PowerShell 7 installer behavior

PowerShell 7 is required for the full supported Cursor Terminal integration.

The installer should detect whether a suitable PowerShell 7 installation exists.

If missing, the user should be asked explicitly.

Example:

```text
PowerShell 7 is required for full Terminal integration.

Install PowerShell 7 now?

Yes
No
```

If:

```text
Yes
```

the installer may use the approved Windows package-management path and verify the resulting `pwsh` installation.

If:

```text
No
```

MAG may still install, but the installer must clearly warn that Terminal integration may be limited.

The installer must not silently force installation of PowerShell 7.

Automatic modification of Cursor's default Terminal profile is NOT currently approved.

That requires separate research and Product Owner approval.

---

## 21. Cursor extension installation

The future installer should investigate automatic installation of the MAG Cursor extension.

Target user experience:

```text
Install MAG
→ Cursor extension becomes available
→ minimal/no manual extension setup
```

This must use a supported or sufficiently reliable Cursor/VS Code extension installation mechanism.

Do not implement unsupported file injection merely to eliminate one manual step.

The exact mechanism must be verified before implementation.

---

## 22. Security principles

Future development must preserve:

### Explicit action

No automatic send/execute without a clearly explicit user action for that workflow.

### Least privilege

Read only the minimum local data necessary.

### Credential isolation

Cursor credentials never leave the Cursor-owned authentication boundary except as required to authenticate directly to the expected Cursor service.

### No content guessing

When the requested source cannot be determined reliably, fail.

### No hidden fallback

Never substitute Terminal, clipboard, or an older Agent response for a failed requested Agent response.

### No UI scraping when structured data exists

Prefer structured local/API data over:

- OCR;
- screenshots;
- UI Automation;
- coordinate clicking;
- DOM assumptions.

### Fail-safe integration

Optional telemetry failure must not break core transfer functionality.

---

## 23. Performance principles

The normal workflow should remain lightweight.

Avoid:

- continuous polling when unnecessary;
- database scans on every UI event;
- repeated usage requests;
- long network waits before ChatGPT transfer;
- expensive UI Automation;
- persistent background work without demonstrated need.

Cursor usage lookup should use a short bounded timeout.

Agent response extraction should target only the relevant local conversation data.

---

## 24. Undocumented Cursor integration risk

Two planned capabilities currently depend on undocumented Cursor implementation details:

```text
Cursor usage telemetry
Cursor Agent local response extraction
```

These must be treated as replaceable providers.

Cursor may change:

- local database schema;
- authentication storage;
- usage endpoints;
- response fields;
- chat storage format;
- workspace/conversation identifiers.

Therefore Cursor-specific implementation details must not leak throughout the rest of the application.

A provider failure after a Cursor update should degrade one capability rather than break the entire MAG workflow.

---

## 25. Version policy

Current stable baseline remains:

```text
1.0.0
```

Research procedures do not require a version bump.

Read-only probes do not establish a new release.

A future functional release containing reliable automated Cursor telemetry and/or true one-click Agent transfer may justify:

```text
1.1.0
```

but no version number is approved merely by this document.

Version changes require Product Owner approval after the intended release scope is known.

---

## 26. Git and repository safety

All repository operations for this product must begin by explicitly entering:

```text
C:\laragon\repos\MAG-Workflow-Bridge
```

Do not assume the active terminal repository.

This is especially important because unrelated MAG repositories exist under the same development environment.

Never modify, stage, restore, reset, commit, or otherwise touch unrelated files in:

```text
TagSynchronizer
GlobalLinksFavicons
MAG-Ecosystem
```

unless the Product Owner explicitly authorizes a task involving those repositories.

Git commits and pushes remain under Product Owner control.

---

## 27. Explicit non-goals

Unless separately approved, do NOT implement:

- automatic Agent response sending immediately when Cursor finishes;
- continuous Cursor chat monitoring;
- Cursor UI DOM scraping;
- OCR-based usage detection;
- screenshot parsing;
- UI Automation for Cursor Agent extraction;
- synthetic Copy Message clicking;
- browser ChatGPT support;
- cloud MAG account infrastructure;
- MAG telemetry server;
- uploading Cursor credentials;
- persistent Cursor credential copies;
- speculative multi-provider AI integrations;
- automatic Cursor configuration modification;
- automatic project/repository modification;
- silent PowerShell installation;
- unrelated MAG Ecosystem integration.

---

## 28. Current proposed roadmap

Conceptual sequence:

```text
Current v1.0.0 baseline + verified AGT → GPT After telemetry (§4.6)
        ↓
U1 — Agent response read-only feasibility probe (Models portion satisfied)
        ↓
U2 — CursorUsageProvider (implemented)
        ↓
U3 — CursorAgentReportProvider (proposed)
        ↓
U4 — True One-Click GPT pipeline (partial: telemetry only)
        ↓
U5 — Full regression/failure validation (proposed)
        ↓
U6 — Optional UX simplification
        ↓
U7 — EXE + Windows installer
```

This ordering exists to reduce risk.

The most uncertain remaining dependency is reliable local Agent response extraction (U3).

---

## 29. Immediate next step

The next proposed technical procedure is:

```text
U1 — Cursor Agent Report Read-Only Feasibility Probe
```

Purpose:

Prove that MAG can reliably obtain:

```text
Latest completed Cursor Agent response
```

without:

- modifying `[MAG] GPT|Cursor|Sync`;
- modifying Cursor;
- UI Automation;
- OCR;
- screenshots;
- clipboard dependency;
- sending anything to ChatGPT;
- Git changes.

**Cursor Models percentage** is already obtained reliably in production (§4.6); a separate Models-only U1 probe is no longer the gating next step.

Expected proof output:

```text
Latest Agent response:
<exact response>
```

The value must then be manually compared against Cursor itself.

Only after successful Agent verification should U3/U4 production Agent extraction be considered.

---

## 30. Approval boundary

This document preserves the development direction.

It does NOT authorize U1 or any later stage by itself.

The Product Owner retains final approval over:

- research execution;
- implementation;
- architecture changes;
- UX changes;
- dependency installation;
- Git operations;
- version changes;
- packaging;
- release.

Current state:

```text
v1.0.0 baseline: existing
AGT → GPT automatic Cursor Models After telemetry: verified (§4.6)
Future direction: documented
U1 Agent probe: proposed next step
U2: implemented (telemetry provider)
U3–U4 Agent one-click: not implemented
U5–U7: not authorized
```

No future stage should begin automatically.

---

## 31. Core target

The long-term workflow target is:

```text
Cursor Agent finishes work
        ↓
ONE CLICK
        ↓
Latest completed Agent report
+
Cursor Models After
        ↓
ChatGPT Desktop
        ↓
automatic Send
```

while preserving:

```text
explicit user control
+
correct context
+
fail-safe behavior
+
credential security
+
existing Terminal workflows
+
minimal manual work
```

That is the primary future development direction for `[MAG] GPT|Cursor|Sync`.
```