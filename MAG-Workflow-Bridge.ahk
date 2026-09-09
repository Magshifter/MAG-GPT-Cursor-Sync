#Requires AutoHotkey v2.0
#SingleInstance Force

; [MAG] GPT|Cursor|Sync
; by Magshifter
;
; Activates a target window and pastes the current clipboard.
; Never sends Enter, Submit, or Send from global hotkeys.
;
; Ctrl+Alt+C -> Cursor
; Ctrl+Alt+T -> Windows Terminal
; Ctrl+Alt+G -> ChatGPT (paste only)
; Ctrl+Alt+Shift+G -> Send clipboard to ChatGPT (AGT → GPT via Cursor URI)
;
; Companion CLEAR | TER | AGT and tray Cursor Agent / Cursor Terminal
; use the current clipboard, then the Cursor URI.
;
; TER (companion + tray Cursor Terminal): sequence + content fingerprint guards,
; one-use consume, manual CLEAR recovery, paste-only (no auto-execute). AGT unchanged.
;
; TER_CLIP_OBS_LOGGING enables passive CLIP_OBS / TER_CLICK metadata logging only.

A_IconTip := "[MAG] GPT|Cursor|Sync"

; Passive clipboard observation logging (metadata only; does not gate TER).
TER_CLIP_OBS_LOGGING := true
; Legacy name retained for diagnostic log helpers.
TER_AUTH_DIAG_MODE := TER_CLIP_OBS_LOGGING

actionBarEnabled := true
companionVisible := false
companionTarget := 0
companionGui := 0
companionW := 0
companionH := 0
companionLastX := ""
companionLastY := ""
lastWinX := ""
lastWinY := ""
lastWinW := ""
lastWinH := ""
stableTicks := 0
statusBarMenu := 0
cursorModelsTelemetryMenu := 0
; TER product state (in-memory only; no clipboard persistence).
; Startup: existing clipboard generation is already consumed / ineligible.
terminalConsumedSeq := GetClipboardSequenceNumber()
lastConsumedTerminalFingerprint := ""
; Ephemeral diagnostic fingerprints only (never persisted / never logged).
diagPrevTextFp := ""
diagConsumedTextFp := ""

if TER_CLIP_OBS_LOGGING
    A_IconTip := "[MAG] GPT|Cursor|Sync [TER-OBS]"

TraySetIcon(A_ScriptDir "\assets\MAG-GPT-Cursor-Sync.ico")
InitTray()
InitCompanionBar()
; Observation only — must never authorize/consume/dispatch.
OnClipboardChange(HandleClipboardObservation, 1)
SetTimer(UpdateCompanionBar, 200)
if TER_CLIP_OBS_LOGGING
{
    EnsureMagSettingsDir()
    DiagLog("BOOT`tevent=DIAG_START`tmode=paste-only`tseq=" GetClipboardSequenceNumber() "`tconsumedSeq=" terminalConsumedSeq)
}

^!c:: PasteToTarget("Cursor.exe", "Cursor")
^!t:: PasteToTarget("WindowsTerminal.exe", "Windows Terminal")
^!g:: PasteToTarget("ChatGPT.exe", "ChatGPT")
^!+g:: DispatchCursorUri("sendtogpt")

PasteToTarget(exeName, displayName)
{
    hwnds := WinGetList("ahk_exe " exeName)
    if hwnds.Length = 0
    {
        Notify(displayName " is not running.")
        return
    }

    hwnd := hwnds[1]
    WinActivate hwnd
    if !WinWaitActive(hwnd, , 1)
    {
        Notify("Could not activate " displayName ".")
        return
    }

    Send "^v"
}

GetClipboardSequenceNumber()
{
    return DllCall("user32\GetClipboardSequenceNumber", "UInt")
}

DiagLogPath()
{
    return EnvGet("LOCALAPPDATA") "\MAG-GPT-Cursor-Sync\ter-auth-diag.log"
}

DiagTimestamp()
{
    return FormatTime(, "yyyy-MM-dd HH:mm:ss") "." Format("{:03d}", A_MSec)
}

; Metadata only — never log clipboard text/hash/fingerprint/URI payloads.
DiagLog(line)
{
    global TER_AUTH_DIAG_MODE
    if !TER_AUTH_DIAG_MODE
        return
    try
    {
        EnsureMagSettingsDir()
        FileAppend(DiagTimestamp() "`t" line "`n", DiagLogPath(), "UTF-8")
    }
}

GetForegroundMeta(&procName, &pid, &hwnd)
{
    procName := "UNKNOWN"
    pid := 0
    hwnd := 0
    try
    {
        hwnd := WinExist("A")
        if !hwnd
            return
        pid := WinGetPID(hwnd)
        procName := WinGetProcessName(hwnd)
        if procName = ""
            procName := "UNKNOWN"
    }
}

; Win32 clipboard owner (observational metadata only; never TER authorization).
GetClipboardOwnerMeta(&ownerProc, &ownerPid, &ownerHwnd)
{
    ownerProc := "UNKNOWN"
    ownerPid := 0
    ownerHwnd := 0
    try
    {
        ownerHwnd := DllCall("user32\GetClipboardOwner", "Ptr")
        if !ownerHwnd
            return
        ownerPid := WinGetPID(ownerHwnd)
        ownerProc := WinGetProcessName(ownerHwnd)
        if ownerProc = ""
            ownerProc := "UNKNOWN"
    }
}

LogClipObs(seq, type, textAvailable, fgProc, fgPid, fgHwnd, textState, consumedState)
{
    GetClipboardOwnerMeta(&ownerProc, &ownerPid, &ownerHwnd)
    DiagLog("CLIP_OBS`tevent=CLIP_OBS`tseq=" seq "`ttype=" type "`ttextAvailable=" textAvailable "`tfgProc=" fgProc "`tfgPid=" fgPid "`tfgHwnd=" fgHwnd "`townerHwnd=" ownerHwnd "`townerPid=" ownerPid "`townerProc=" ownerProc "`ttextState=" textState "`tconsumedState=" consumedState)
}

ClassifyAgainstPrevious(fp, empty)
{
    global diagPrevTextFp
    if empty
        return "EMPTY"
    if fp = ""
        return "UNKNOWN"
    if diagPrevTextFp = ""
        return "FIRST"
    if fp = diagPrevTextFp
        return "SAME_PREVIOUS"
    return "DIFFERENT_PREVIOUS"
}

ClassifyAgainstConsumed(fp, empty)
{
    global diagConsumedTextFp
    if empty
        return "EMPTY"
    if fp = ""
        return "UNKNOWN"
    if diagConsumedTextFp = ""
        return "NONE"
    if fp = diagConsumedTextFp
        return "SAME_CONSUMED"
    return "DIFFERENT_CONSUMED"
}

; Passiveive observation only. Never authorizes, consumes, or dispatches.
HandleClipboardObservation(type)
{
    global TER_AUTH_DIAG_MODE, diagPrevTextFp
    if !TER_AUTH_DIAG_MODE
        return

    seq := GetClipboardSequenceNumber()
    GetForegroundMeta(&fgProc, &fgPid, &fgHwnd)

    textAvailable := 0
    textState := "NONE"
    consumedState := "NONE"
    fp := ""

    if type = 0
    {
        textAvailable := 0
        textState := "EMPTY"
        consumedState := "EMPTY"
        LogClipObs(seq, type, textAvailable, fgProc, fgPid, fgHwnd, textState, consumedState)
        diagPrevTextFp := ""
        return
    }

    if type != 1
    {
        textAvailable := 0
        textState := "UNKNOWN"
        consumedState := "UNKNOWN"
        LogClipObs(seq, type, textAvailable, fgProc, fgPid, fgHwnd, textState, consumedState)
        return
    }

    ; type 1 = text available from AHK's perspective.
    clipText := A_Clipboard
    empty := Trim(clipText, " `t`r`n") = ""
    if empty
    {
        textAvailable := 0
        textState := "EMPTY"
        consumedState := "EMPTY"
        LogClipObs(seq, type, textAvailable, fgProc, fgPid, fgHwnd, textState, consumedState)
        diagPrevTextFp := ""
        return
    }

    textAvailable := 1
    fp := Sha256HexUtf8(NormalizeTerminalPayload(clipText))
    textState := ClassifyAgainstPrevious(fp, false)
    consumedState := ClassifyAgainstConsumed(fp, false)
    LogClipObs(seq, type, textAvailable, fgProc, fgPid, fgHwnd, textState, consumedState)
    if fp != ""
        diagPrevTextFp := fp
}

; Manual TER recovery: mark current clipboard generation consumed/ineligible.
; Does not modify Windows clipboard contents and does not dispatch/execute.
ClearTerminalAuthorization(*)
{
    global terminalConsumedSeq, lastConsumedTerminalFingerprint, TER_AUTH_DIAG_MODE, diagConsumedTextFp
    seq := GetClipboardSequenceNumber()
    terminalConsumedSeq := seq
    lastConsumedTerminalFingerprint := ""
    ; Diagnostic-only: forget last TER-consumed text comparison target.
    diagConsumedTextFp := ""
    if TER_AUTH_DIAG_MODE
        DiagLog("CLEAR`tevent=CLEAR`tseq=" seq "`tconsumedSeq=" terminalConsumedSeq "`tdecision=RESET")
    Notify("TER reset. Copy a command before TER.")
}

; Must match cursor-extension/extension.js normalizeTerminalPayload().
NormalizeTerminalPayload(text)
{
    normalized := StrReplace(text, "`r`n", "`n")
    normalized := StrReplace(normalized, "`r", "`n")
    return RegExReplace(normalized, "\n+$", "")
}

Utf8Buffer(text)
{
    size := StrPut(text, "UTF-8") - 1
    if size < 0
        size := 0
    buf := Buffer(size)
    if size > 0
        StrPut(text, buf, "UTF-8")
    return buf
}

; SHA-256 hex of UTF-8 bytes (must match Node crypto.createHash('sha256')).
Sha256HexUtf8(text)
{
    data := Utf8Buffer(text)
    hProv := 0
    hHash := 0
    ; PROV_RSA_AES = 24, CRYPT_VERIFYCONTEXT = 0xF0000000, CALG_SHA_256 = 0x800c, HP_HASHVAL = 2
    if !DllCall("advapi32\CryptAcquireContextW", "Ptr*", &hProv, "Ptr", 0, "Ptr", 0, "UInt", 24, "UInt", 0xF0000000)
        return ""
    if !DllCall("advapi32\CryptCreateHash", "Ptr", hProv, "UInt", 0x800C, "Ptr", 0, "UInt", 0, "Ptr*", &hHash)
    {
        DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
        return ""
    }
    if !DllCall("advapi32\CryptHashData", "Ptr", hHash, "Ptr", data, "UInt", data.Size, "UInt", 0)
    {
        DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
        DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
        return ""
    }
    hashLen := 32
    hash := Buffer(32)
    ok := DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", hash, "UInt*", &hashLen, "UInt", 0)
    DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
    DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
    if !ok || hashLen != 32
        return ""
    hex := ""
    loop 32
        hex .= Format("{:02x}", NumGet(hash, A_Index - 1, "UChar"))
    return hex
}

DispatchCursorUri(actionPath)
{
    uri := "cursor://magshifter.mag-workflow-bridge/" actionPath
    launched := DllCall("shell32\ShellExecuteW", "Ptr", 0, "WStr", "open", "WStr", uri, "Ptr", 0, "Ptr", 0, "Int", 1, "Ptr")
    if launched <= 32
        Notify("Could not trigger Cursor (" actionPath ").")
}

LogTerClick(seq, seqBeforeRead, seqAfterRead, readSeqChanged, consumedSeq, decision, empty, reason)
{
    DiagLog("TER_CLICK`tevent=TER_CLICK`tseq=" seq "`tseqBeforeRead=" seqBeforeRead "`tseqAfterRead=" seqAfterRead "`treadSeqChanged=" readSeqChanged "`tconsumedSeq=" consumedSeq "`tdecision=" decision "`tempty=" empty "`treason=" reason "`tmode=paste-only")
}

; One-click TER: sequence + normalized content fingerprint guards (not user-intent proof).
TriggerFreshnessTerminal()
{
    global terminalConsumedSeq, lastConsumedTerminalFingerprint, TER_CLIP_OBS_LOGGING, diagConsumedTextFp
    ; Eligibility uses sequence captured BEFORE the clipboard read (existing semantics).
    seqBeforeRead := GetClipboardSequenceNumber()
    clipText := A_Clipboard
    seqAfterRead := GetClipboardSequenceNumber()
    readSeqChanged := (seqAfterRead != seqBeforeRead) ? 1 : 0
    seq := seqBeforeRead
    empty := Trim(clipText, " `t`r`n") = ""
    emptyFlag := empty ? 1 : 0
    reason := ""
    decision := "REFUSE"

    if empty
        reason := "empty"
    else if seq <= terminalConsumedSeq
        reason := "stale-sequence"
    else
    {
        payload := NormalizeTerminalPayload(clipText)
        fingerprint := Sha256HexUtf8(payload)
        if fingerprint = ""
            reason := "invalid-fingerprint"
        else if lastConsumedTerminalFingerprint != "" && fingerprint = lastConsumedTerminalFingerprint
            reason := "same-consumed-content"
        else
        {
            decision := "ALLOW"
            reason := "allow"
            ; One-use: consume sequence and product fingerprint before URI dispatch.
            terminalConsumedSeq := seq
            lastConsumedTerminalFingerprint := fingerprint
            if TER_CLIP_OBS_LOGGING
            {
                ; Diagnostic-only memory for later CLIP_OBS consumedState labels. Does not gate TER.
                diagConsumedTextFp := fingerprint
            }
        }
    }

    if TER_CLIP_OBS_LOGGING
        LogTerClick(seq, seqBeforeRead, seqAfterRead, readSeqChanged, terminalConsumedSeq, decision, emptyFlag, reason)

    if decision = "ALLOW"
    {
        DispatchCursorUri("terminal?fp=" fingerprint)
        return
    }

    if reason = "empty"
        Notify("Clipboard is empty.")
    else if reason = "invalid-fingerprint"
        Notify("Could not authorize terminal command.")
    else
        Notify("Copy a command first.")
}

TriggerCursorCommand(actionPath)
{
    if actionPath = "terminal"
    {
        TriggerFreshnessTerminal()
        return
    }
    if Trim(A_Clipboard, " `t`r`n") = ""
    {
        Notify("Clipboard is empty.")
        return
    }
    DispatchCursorUri(actionPath)
}

StatusBarSettingsPath()
{
    return EnvGet("LOCALAPPDATA") "\MAG-GPT-Cursor-Sync\settings.ini"
}

EnsureMagSettingsDir()
{
    dir := EnvGet("LOCALAPPDATA") "\MAG-GPT-Cursor-Sync"
    if !DirExist(dir)
        DirCreate(dir)
}

NormalizeStatusBarPosition(value)
{
    position := StrLower(Trim(value))
    if position = "left" || position = "center"
        return position
    return "center"
}

ReadStatusBarPosition()
{
    path := StatusBarSettingsPath()
    if !FileExist(path)
        return "center"
    return NormalizeStatusBarPosition(IniRead(path, "StatusBar", "Position", "center"))
}

WriteStatusBarPosition(position)
{
    EnsureMagSettingsDir()
    IniWrite(NormalizeStatusBarPosition(position), StatusBarSettingsPath(), "StatusBar", "Position")
}

UpdateStatusBarCheckmarks(position)
{
    global statusBarMenu
    statusBarMenu.Uncheck("Left")
    statusBarMenu.Uncheck("Center")
    if position = "left"
        statusBarMenu.Check("Left")
    else
        statusBarMenu.Check("Center")
}

SetStatusBarPosition(position)
{
    normalized := NormalizeStatusBarPosition(position)
    WriteStatusBarPosition(normalized)
    UpdateStatusBarCheckmarks(normalized)
    DispatchCursorUri("statusbar-" normalized)
}

NormalizeCursorModelsTelemetry(value)
{
    state := StrLower(Trim(value))
    if state = "enabled" || state = "disabled"
        return state
    return "disabled"
}

ReadCursorModelsTelemetry()
{
    path := StatusBarSettingsPath()
    if !FileExist(path)
        return "disabled"
    return NormalizeCursorModelsTelemetry(IniRead(path, "Telemetry", "CursorModels", "disabled"))
}

WriteCursorModelsTelemetry(state)
{
    EnsureMagSettingsDir()
    IniWrite(NormalizeCursorModelsTelemetry(state), StatusBarSettingsPath(), "Telemetry", "CursorModels")
}

UpdateCursorModelsTelemetryCheckmarks(state)
{
    global cursorModelsTelemetryMenu
    cursorModelsTelemetryMenu.Uncheck("Enabled")
    cursorModelsTelemetryMenu.Uncheck("Disabled")
    if state = "enabled"
        cursorModelsTelemetryMenu.Check("Enabled")
    else
        cursorModelsTelemetryMenu.Check("Disabled")
}

SetCursorModelsTelemetry(state)
{
    normalized := NormalizeCursorModelsTelemetry(state)
    WriteCursorModelsTelemetry(normalized)
    UpdateCursorModelsTelemetryCheckmarks(normalized)
}

InitCompanionBar()
{
    global companionGui, companionW, companionH
    ; WS_EX_NOACTIVATE (E0x08000000): do not steal ChatGPT focus on click.
    ; Do not use WS_EX_TRANSPARENT (E0x20) or TransColor: keyed pixels are
    ; HTTRANSPARENT and the click falls through to ChatGPT (Send/composer).
    companionGui := Gui("+AlwaysOnTop -Caption -Border +ToolWindow -SysMenu +E0x08000000")
    companionGui.BackColor := "F3F3F3"
    companionGui.MarginX := 0
    companionGui.MarginY := 0
    companionGui.SetFont("s9", "Segoe UI")
    ; CLEAR uses Text (not themed Button) so muted-red Background is reliable on Win11.
    clearBtn := companionGui.Add("Text", "x0 y0 w50 h28 Center 0x200 Border BackgroundB07A7A cF5F5F5", "CLEAR")
    ter := companionGui.Add("Button", "x+6 yp w46 h28", "TER")
    agt := companionGui.Add("Button", "x+6 yp w46 h28", "AGT")
    try clearBtn.ToolTip := "Reset TER state (recovery). Copy a command afterward."
    try ter.ToolTip := "Paste current clipboard into Cursor Terminal (press Enter to run)"
    try agt.ToolTip := "Send current clipboard to Cursor Agent"
    clearBtn.OnEvent("Click", ClearTerminalAuthorization)
    ter.OnEvent("Click", (*) => TriggerCursorCommand("terminal"))
    agt.OnEvent("Click", (*) => TriggerCursorCommand("agent"))
    companionGui.Show("Hide")
    companionGui.GetPos(,, &companionW, &companionH)
}

HideCompanion()
{
    global companionVisible, companionGui, companionLastX, companionLastY
    if companionVisible
    {
        companionGui.Hide()
        companionVisible := false
    }
    companionLastX := ""
    companionLastY := ""
}

HideEverything()
{
    global companionTarget, lastWinX, lastWinY, lastWinW, lastWinH, stableTicks
    HideCompanion()
    companionTarget := 0
    lastWinX := ""
    lastWinY := ""
    lastWinW := ""
    lastWinH := ""
    stableTicks := 0
}

IsMagGui(hwnd)
{
    global companionGui
    return hwnd = companionGui.Hwnd
}

ShowCompanionAt(hwnd)
{
    global companionGui, companionW, companionH, companionVisible, companionLastX, companionLastY
    WinGetPos(&cx, &cy, &cw, &ch, hwnd)
    GetWorkAreaForPoint(cx + cw // 2, cy + ch // 2, &workL, &workT, &workR, &workB)
    rightGap := 72
    bottomGap := Max(148, Min(176, ch // 6))
    x := cx + cw - companionW - rightGap
    y := cy + ch - companionH - bottomGap
    x := Max(cx + 8, Min(x, cx + cw - companionW - 8))
    y := Max(cy + 8, Min(y, cy + ch - companionH - 8))
    x := Max(workL, Min(x, workR - companionW))
    y := Max(workT, Min(y, workB - companionH))
    if !companionVisible || companionLastX != x || companionLastY != y
    {
        companionGui.Show("NA x" x " y" y)
        companionLastX := x
        companionLastY := y
    }
    companionVisible := true
}

GetWorkAreaForPoint(px, py, &workL, &workT, &workR, &workB)
{
    loop MonitorGetCount()
    {
        MonitorGet(A_Index, &ml, &mt, &mr, &mb)
        if px >= ml && px < mr && py >= mt && py < mb
        {
            MonitorGetWorkArea(A_Index, &workL, &workT, &workR, &workB)
            return
        }
    }
    MonitorGetWorkArea(MonitorGetPrimary(), &workL, &workT, &workR, &workB)
}

UpdateCompanionBar()
{
    global actionBarEnabled, companionTarget, lastWinX, lastWinY, lastWinW, lastWinH, stableTicks
    if !actionBarEnabled
    {
        HideEverything()
        return
    }

    if !WinExist("ahk_exe ChatGPT.exe")
    {
        HideEverything()
        return
    }

    active := WinExist("A")
    chatgpt := WinActive("ahk_exe ChatGPT.exe")
    if chatgpt
        companionTarget := DllCall("user32\GetAncestor", "ptr", chatgpt, "uint", 2, "ptr") || chatgpt
    else if !IsMagGui(active) || !companionTarget || !WinExist(companionTarget)
    {
        HideEverything()
        return
    }

    WinGetPos(&cx, &cy, &cw, &ch, companionTarget)
    if lastWinX = ""
    {
        lastWinX := cx
        lastWinY := cy
        lastWinW := cw
        lastWinH := ch
        stableTicks := 3
        ShowCompanionAt(companionTarget)
        return
    }
    if cx != lastWinX || cy != lastWinY || cw != lastWinW || ch != lastWinH
    {
        lastWinX := cx
        lastWinY := cy
        lastWinW := cw
        lastWinH := ch
        stableTicks := 0
        HideCompanion()
        return
    }
    if stableTicks < 3
    {
        stableTicks += 1
        HideCompanion()
        return
    }
    ShowCompanionAt(companionTarget)
}

ToggleActionBar(*)
{
    global actionBarEnabled
    actionBarEnabled := !actionBarEnabled
    if actionBarEnabled
        A_TrayMenu.Check("ChatGPT action bar")
    else
    {
        A_TrayMenu.Uncheck("ChatGPT action bar")
        HideEverything()
    }
}

StartupShortcutPath()
{
    return A_Startup "\MAG Workflow Bridge.lnk"
}

StartupIsEnabled()
{
    return FileExist(StartupShortcutPath()) ? true : false
}

InitTray()
{
    global statusBarMenu, cursorModelsTelemetryMenu
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Cursor Agent", (*) => TriggerCursorCommand("agent"))
    A_TrayMenu.Add("Cursor Terminal", (*) => TriggerCursorCommand("terminal"))
    A_TrayMenu.Add("Send to ChatGPT`tCtrl+Alt+Shift+G", (*) => DispatchCursorUri("sendtogpt"))
    A_TrayMenu.Add("CLEAR TER", ClearTerminalAuthorization)
    A_TrayMenu.Add()
    A_TrayMenu.Add("ChatGPT action bar", ToggleActionBar)
    A_TrayMenu.Check("ChatGPT action bar")
    A_TrayMenu.Add()
    statusBarMenu := Menu()
    statusBarMenu.Add("Left", (*) => SetStatusBarPosition("left"))
    statusBarMenu.Add("Center", (*) => SetStatusBarPosition("center"))
    A_TrayMenu.Add("Status Bar Position", statusBarMenu)
    UpdateStatusBarCheckmarks(ReadStatusBarPosition())
    cursorModelsTelemetryMenu := Menu()
    cursorModelsTelemetryMenu.Add("Enabled", (*) => SetCursorModelsTelemetry("enabled"))
    cursorModelsTelemetryMenu.Add("Disabled", (*) => SetCursorModelsTelemetry("disabled"))
    A_TrayMenu.Add("Cursor Models Telemetry", cursorModelsTelemetryMenu)
    UpdateCursorModelsTelemetryCheckmarks(ReadCursorModelsTelemetry())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Enable startup", EnableStartup)
    A_TrayMenu.Add("Disable startup", DisableStartup)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    RefreshTray()
}

RefreshTray()
{
    if StartupIsEnabled()
    {
        A_TrayMenu.Disable("Enable startup")
        A_TrayMenu.Enable("Disable startup")
    }
    else
    {
        A_TrayMenu.Enable("Enable startup")
        A_TrayMenu.Disable("Disable startup")
    }
}

EnableStartup(*)
{
    linkPath := StartupShortcutPath()
    SplitPath A_LineFile, , &bridgeDir
    args := '"' A_LineFile '"'
    FileCreateShortcut(A_AhkPath, linkPath, bridgeDir, args, "[MAG] GPT|Cursor|Sync")
    RefreshTray()
    Notify("Startup enabled.")
}

DisableStartup(*)
{
    linkPath := StartupShortcutPath()
    if FileExist(linkPath)
        FileDelete linkPath
    RefreshTray()
    Notify("Startup disabled.")
}

Notify(message)
{
    ToolTip message
    SetTimer () => ToolTip(), -1500
}
