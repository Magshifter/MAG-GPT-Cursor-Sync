const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { spawn } = require("child_process");
const vscode = require("vscode");
const { getCursorModelsPercentage } = require("./cursorUsageProvider");

const SEND_TO_CHATGPT = "magWorkflowBridge.sendToChatGPT";
const SEND_LAST_TERMINAL_OUTPUT_TO_CHATGPT = "magWorkflowBridge.sendLastTerminalOutputToChatGPT";
const SEND_LAST_2_TERMINAL_OUTPUTS_TO_CHATGPT = "magWorkflowBridge.sendLast2TerminalOutputsToChatGPT";
const SEND_LAST_3_TERMINAL_OUTPUTS_TO_CHATGPT = "magWorkflowBridge.sendLast3TerminalOutputsToChatGPT";
const SEND_TO_AGENT = "magWorkflowBridge.sendToCursorAgent";
const SEND_TO_TERMINAL = "magWorkflowBridge.sendToCursorTerminal";
const COPY_LAST_COMMAND_AND_OUTPUT = "workbench.action.terminal.copyLastCommandAndLastCommandOutput";
const STATUS_BAR_POSITION_KEY = "magWorkflowBridge.statusBarPosition";
const DEFAULT_STATUS_BAR_POSITION = "center";
const MAG_STATUS_BAR_FOREGROUND_DARK = "#F0F0F0";
const MAG_STATUS_BAR_FOREGROUND_LIGHT = "#141414";
const MAG_SETTINGS_DIR_NAME = "MAG-GPT-Cursor-Sync";
const CURSOR_MODELS_TELEMETRY_FOOTER_RE = /\n*Cursor Models After: (?:\d+%|unavailable)\s*$/u;
const TERMINAL_FINGERPRINT_RE = /^[a-f0-9]{64}$/i;
const TER_GPT_CAPTURE_WAIT_MS = 2000;

const STATUS_BAR_LAYOUTS = {
	left: {
		alignment: vscode.StatusBarAlignment.Left,
		priorities: [10004, 10003, 10002, 10001],
	},
	center: {
		alignment: vscode.StatusBarAlignment.Left,
		priorities: [4, 3, 2, 1],
	},
};

const MAG_STATUS_BAR_SPECS = [
	{
		text: "TER → GPT",
		tooltip: "Send last terminal command + output to ChatGPT",
		command: SEND_LAST_TERMINAL_OUTPUT_TO_CHATGPT,
	},
	{
		text: "2",
		tooltip: "Send last 2 terminal commands + output to ChatGPT",
		command: SEND_LAST_2_TERMINAL_OUTPUTS_TO_CHATGPT,
	},
	{
		text: "3",
		tooltip: "Send last 3 terminal commands + output to ChatGPT",
		command: SEND_LAST_3_TERMINAL_OUTPUTS_TO_CHATGPT,
	},
	{
		text: "AGT → GPT",
		tooltip: "Send clipboard to ChatGPT",
		command: SEND_TO_CHATGPT,
	},
];

/** @type {Map<object, { commandLine: string, output: string, exitCode: number | undefined }[]>} */
const terminalHistory = new Map();

/** @type {Map<object, { terminal: object, chunks: string[], streamDone: Promise<void> }>} */
const pendingExecutions = new Map();

/** @type {import("vscode").StatusBarItem[]} */
let magStatusBarItems = [];

function delay(ms) {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

function findAutoHotkey() {
	const programFiles = process.env.ProgramFiles || "C:\\Program Files";
	const localAppData = process.env.LOCALAPPDATA || "";
	const candidates = [
		path.join(programFiles, "AutoHotkey", "v2", "AutoHotkey64.exe"),
		path.join(programFiles, "AutoHotkey", "AutoHotkey64.exe"),
		path.join(localAppData, "Programs", "AutoHotkey", "v2", "AutoHotkey64.exe"),
	];
	return candidates.find((candidate) => fs.existsSync(candidate));
}

function runHelper(ahkPath, helperPath) {
	return new Promise((resolve, reject) => {
		const child = spawn(ahkPath, [helperPath], {
			windowsHide: true,
			stdio: "ignore",
		});
		const timer = setTimeout(() => {
			child.kill();
			reject(new Error("The helper timed out."));
		}, 5000);
		child.on("error", (error) => {
			clearTimeout(timer);
			reject(error);
		});
		child.on("exit", (code) => {
			clearTimeout(timer);
			resolve(code === null ? 1 : code);
		});
	});
}

/**
 * Smallest safe cleanup of terminal formatting/control sequences for ChatGPT text.
 * Preserves human-readable output and line breaks; does not reinterpret command semantics.
 */
function normalizeTerminalOutput(text) {
	return String(text || "")
		.replace(/\u001b\][^\u0007\u001b]*(?:\u0007|\u001b\\)/g, "")
		.replace(/\u001b\[[0-9;?]*[ -\/]*[@-~]/g, "")
		.replace(/\u001b[@-Z\\-_]/g, "")
		.replace(/\u0000/g, "")
		.replace(/\r\n/g, "\n")
		.replace(/\r/g, "\n");
}

function getHistory(terminal) {
	return terminalHistory.get(terminal) || [];
}

function pushCompletedExecution(terminal, entry) {
	const history = terminalHistory.get(terminal) || [];
	history.push(entry);
	while (history.length > 3) {
		history.shift();
	}
	terminalHistory.set(terminal, history);
}

function formatExecutionsMessage(entries) {
	return entries
		.map((entry, index) => {
			const command = entry.commandLine || "";
			const output = entry.output || "";
			return `Command ${index + 1}:\n${command}\n\nOutput:\n${output}`;
		})
		.join("\n\n");
}

function formatLastExecutionPayload(entry) {
	const command = entry.commandLine || "";
	const output = entry.output || "";
	return `${command}\n${output}`;
}

function hasPendingCaptureForTerminal(terminal) {
	for (const pending of pendingExecutions.values()) {
		if (pending.terminal === terminal) {
			return true;
		}
	}
	return false;
}

async function waitUntilNoPendingCaptureForTerminal(terminal, timeoutMs) {
	const deadline = Date.now() + timeoutMs;
	while (hasPendingCaptureForTerminal(terminal)) {
		if (Date.now() >= deadline) {
			return false;
		}
		await delay(50);
	}
	return true;
}

function beginShellExecutionCapture(event) {
	const terminal = event.terminal;
	const execution = event.execution;
	const chunks = [];
	const stream = execution.read();
	const streamDone = (async () => {
		try {
			for await (const data of stream) {
				chunks.push(data);
			}
		} catch {
			// Capture must not interfere with normal terminal execution.
		}
	})();

	pendingExecutions.set(execution, {
		terminal,
		chunks,
		streamDone,
	});
}

async function completeShellExecutionCapture(event) {
	const terminal = event.terminal;
	const execution = event.execution;
	const pending = pendingExecutions.get(execution);
	if (!pending) {
		return;
	}

	try {
		await pending.streamDone;

		const commandLine =
			(execution.commandLine && typeof execution.commandLine.value === "string"
				? execution.commandLine.value
				: "") || "";
		// Empty/whitespace Shell Integration executions must not consume history slots.
		if (commandLine.trim() === "") {
			return;
		}
		const output = normalizeTerminalOutput(pending.chunks.join(""));
		const exitCode = typeof event.exitCode === "number" ? event.exitCode : undefined;

		pushCompletedExecution(terminal, {
			commandLine,
			output,
			exitCode,
		});
	} catch {
		// Incomplete streams are not stored as completed history.
	} finally {
		pendingExecutions.delete(execution);
	}
}

function clearTerminalState(terminal) {
	terminalHistory.delete(terminal);
	for (const [execution, pending] of pendingExecutions.entries()) {
		if (pending.terminal === terminal) {
			pendingExecutions.delete(execution);
		}
	}
}

function getMagSettingsPath() {
	const localAppData = process.env.LOCALAPPDATA || "";
	if (!localAppData) {
		return null;
	}
	return path.join(localAppData, MAG_SETTINGS_DIR_NAME, "settings.ini");
}

/**
 * Read [Telemetry] CursorModels from the MAG settings.ini used by the tray.
 * Missing or invalid values default to disabled.
 * @returns {boolean}
 */
function isCursorModelsTelemetryEnabled() {
	const settingsPath = getMagSettingsPath();
	if (!settingsPath || !fs.existsSync(settingsPath)) {
		return false;
	}

	try {
		const text = fs.readFileSync(settingsPath, "utf8");
		const sectionMatch = text.match(/\[Telemetry\]([\s\S]*?)(?=\n\[|$)/i);
		if (!sectionMatch) {
			return false;
		}
		const valueMatch = sectionMatch[1].match(/^\s*CursorModels\s*=\s*(.+)\s*$/im);
		if (!valueMatch) {
			return false;
		}
		return String(valueMatch[1]).trim().toLowerCase() === "enabled";
	} catch {
		return false;
	}
}

function stripCursorModelsTelemetryFooter(text) {
	return String(text || "").replace(CURSOR_MODELS_TELEMETRY_FOOTER_RE, "");
}

/**
 * When enabled, append a single Cursor Models footer to the current clipboard.
 * Usage failure leaves the original clipboard unchanged and never blocks send.
 */
async function maybeAppendCursorModelsTelemetry() {
	if (!isCursorModelsTelemetryEnabled()) {
		return;
	}

	let percent = null;
	try {
		percent = await getCursorModelsPercentage(vscode.env.appRoot);
	} catch {
		percent = null;
	}

	if (percent === null) {
		return;
	}

	const original = await vscode.env.clipboard.readText();
	const base = stripCursorModelsTelemetryFooter(original).replace(/\s+$/u, "");
	const payload = base
		? `${base}\n\nCursor Models After: ${percent}%`
		: `Cursor Models After: ${percent}%`;
	await vscode.env.clipboard.writeText(payload);
}

/**
 * @param {import("vscode").ExtensionContext} context
 * @param {{ appendCursorModelsTelemetry?: boolean }} [options]
 */
async function sendToChatGPT(context, options = {}) {
	const appendCursorModelsTelemetry = options.appendCursorModelsTelemetry === true;

	if (appendCursorModelsTelemetry) {
		try {
			await maybeAppendCursorModelsTelemetry();
		} catch {
			// Telemetry must never block AGT → GPT.
		}
	}

	const ahkPath = findAutoHotkey();
	if (!ahkPath) {
		void vscode.window.showWarningMessage("AutoHotkey v2 was not found. Install it, then try again.");
		return;
	}

	const helperPath = path.join(context.extensionPath, "helper.ahk");
	if (!fs.existsSync(helperPath)) {
		void vscode.window.showWarningMessage("[MAG] GPT|Cursor|Sync helper.ahk is missing.");
		return;
	}

	try {
		const code = await runHelper(ahkPath, helperPath);
		if (code === 2) {
			void vscode.window.showWarningMessage("ChatGPT is not running.");
		} else if (code === 3) {
			void vscode.window.showWarningMessage("Could not activate ChatGPT.");
		} else if (code !== 0) {
			void vscode.window.showWarningMessage("ChatGPT paste did not complete.");
		}
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		void vscode.window.showWarningMessage(message);
	}
}

async function sendLastTerminalOutputToChatGPT(context) {
	const terminal = vscode.window.activeTerminal;
	if (!terminal) {
		void vscode.window.showWarningMessage("No Cursor integrated terminal is active.");
		return;
	}

	terminal.show(false);

	const hadPendingCapture = hasPendingCaptureForTerminal(terminal);
	if (hadPendingCapture) {
		const settled = await waitUntilNoPendingCaptureForTerminal(terminal, TER_GPT_CAPTURE_WAIT_MS);
		if (!settled) {
			void vscode.window.showWarningMessage(
				"Latest terminal command is still being captured. Try TER → GPT again."
			);
			return;
		}
	}

	const history = getHistory(terminal);
	if (history.length > 0) {
		const payload = formatLastExecutionPayload(history[history.length - 1]);
		await vscode.env.clipboard.writeText(payload);
		await sendToChatGPT(context);
		return;
	}

	if (hadPendingCapture) {
		void vscode.window.showWarningMessage(
			"Could not obtain last terminal command and output. Try TER → GPT again."
		);
		return;
	}

	// Sentinel so we never send pre-existing clipboard if the terminal copy fails.
	const marker = `__MAG_WF_BRIDGE_TERM_${Date.now()}__`;
	await vscode.env.clipboard.writeText(marker);

	try {
		await vscode.commands.executeCommand(COPY_LAST_COMMAND_AND_OUTPUT);
	} catch (error) {
		await vscode.env.clipboard.writeText("");
		void vscode.window.showWarningMessage("Could not copy last terminal command and output.");
		return;
	}

	const text = await vscode.env.clipboard.readText();
	if (!text || text === marker) {
		await vscode.env.clipboard.writeText("");
		void vscode.window.showWarningMessage(
			"Could not obtain last terminal command and output. Shell integration may be unavailable."
		);
		return;
	}

	await sendToChatGPT(context);
}

async function sendLastNTerminalOutputsToChatGPT(context, count) {
	const terminal = vscode.window.activeTerminal;
	if (!terminal) {
		void vscode.window.showWarningMessage("No Cursor integrated terminal is active.");
		return;
	}

	const history = getHistory(terminal);
	if (history.length < count) {
		void vscode.window.showWarningMessage(
			`Need ${count} completed terminal command(s) in the active Terminal. Captured: ${history.length}.`
		);
		return;
	}

	const entries = history.slice(-count);
	const message = formatExecutionsMessage(entries);
	await vscode.env.clipboard.writeText(message);
	await sendToChatGPT(context);
}

async function sendToCursorAgent(context) {
	const text = await vscode.env.clipboard.readText();
	if (!text) {
		void vscode.window.showWarningMessage("Clipboard is empty.");
		return;
	}

	const ahkPath = findAutoHotkey();
	if (!ahkPath) {
		void vscode.window.showWarningMessage("AutoHotkey v2 was not found. Install it, then try again.");
		return;
	}

	const helperPath = path.join(context.extensionPath, "agent-helper.ahk");
	if (!fs.existsSync(helperPath)) {
		void vscode.window.showWarningMessage("[MAG] GPT|Cursor|Sync agent-helper.ahk is missing.");
		return;
	}

	try {
		await vscode.commands.executeCommand("composer.focusComposer");
	} catch (error) {
		void vscode.window.showWarningMessage("Could not focus Cursor Agent (composer.focusComposer).");
		return;
	}

	await delay(200);
	try {
		const code = await runHelper(ahkPath, helperPath);
		if (code !== 0) {
			void vscode.window.showWarningMessage("Cursor Agent paste/submit did not complete.");
		}
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		void vscode.window.showWarningMessage(message);
	}
}

/**
 * Must match MAG-Workflow-Bridge.ahk NormalizeTerminalPayload().
 * @param {string} text
 * @returns {string}
 */
function normalizeTerminalPayload(text) {
	return String(text || "")
		.replace(/\r\n/g, "\n")
		.replace(/\r/g, "\n")
		.replace(/\n+$/u, "");
}

/**
 * Transient SHA-256 fingerprint of the payload that would be executed.
 * Must match MAG-Workflow-Bridge.ahk Sha256HexUtf8(NormalizeTerminalPayload(...)).
 * @param {string} text
 * @returns {string}
 */
function fingerprintTerminalPayload(text) {
	return crypto.createHash("sha256").update(normalizeTerminalPayload(text), "utf8").digest("hex");
}

/**
 * @param {import("vscode").Uri} uri
 * @returns {string | null}
 */
function parseTerminalFingerprint(uri) {
	const query = String(uri.query || "");
	if (!query) {
		return null;
	}
	try {
		const params = new URLSearchParams(query);
		const fp = params.get("fp");
		if (!fp || !TERMINAL_FINGERPRINT_RE.test(fp)) {
			return null;
		}
		return fp.toLowerCase();
	} catch {
		return null;
	}
}

/**
 * @param {{ requireFingerprint?: boolean, expectedFingerprint?: string | null, pasteOnly?: boolean }} [options]
 */
async function sendToCursorTerminal(options = {}) {
	const requireFingerprint = options.requireFingerprint === true;
	const pasteOnly = options.pasteOnly === true;
	const expectedFingerprint =
		typeof options.expectedFingerprint === "string" ? options.expectedFingerprint.toLowerCase() : null;

	if (requireFingerprint) {
		if (!expectedFingerprint || !TERMINAL_FINGERPRINT_RE.test(expectedFingerprint)) {
			void vscode.window.showWarningMessage(
				"Terminal execution was not authorized. Copy a command first."
			);
			return;
		}
	}

	const text = await vscode.env.clipboard.readText();
	if (!text) {
		void vscode.window.showWarningMessage("Clipboard is empty.");
		return;
	}

	const terminal = vscode.window.activeTerminal;
	if (!terminal) {
		void vscode.window.showWarningMessage("No Cursor integrated terminal is active.");
		return;
	}

	// Normalize newlines for the terminal API; keep internal blank lines.
	const payload = normalizeTerminalPayload(text);

	if (requireFingerprint) {
		const actualFingerprint = fingerprintTerminalPayload(text);
		if (actualFingerprint !== expectedFingerprint) {
			void vscode.window.showWarningMessage(
				"Clipboard changed before execution. Copy the command again."
			);
			return;
		}
	}

	terminal.show();
	// sendText addNewLine=true executes. Companion/tray URI and Command Palette both auto-execute.
	terminal.sendText(payload, !pasteOnly);
}

function normalizeStatusBarPosition(value) {
	if (value === "left" || value === "center") {
		return value;
	}
	return DEFAULT_STATUS_BAR_POSITION;
}

async function initializeStatusBarPosition(context) {
	const stored = context.globalState.get(STATUS_BAR_POSITION_KEY);
	const normalized = normalizeStatusBarPosition(stored);
	if (stored !== normalized) {
		await context.globalState.update(STATUS_BAR_POSITION_KEY, normalized);
	}
	createMagStatusBarItems(normalized);
}

function getMagStatusBarForegroundColor() {
	const kind = vscode.window.activeColorTheme.kind;
	if (kind === vscode.ColorThemeKind.Light || kind === vscode.ColorThemeKind.HighContrastLight) {
		return MAG_STATUS_BAR_FOREGROUND_LIGHT;
	}
	return MAG_STATUS_BAR_FOREGROUND_DARK;
}

function applyMagStatusBarForegroundColors() {
	const color = getMagStatusBarForegroundColor();
	for (const item of magStatusBarItems) {
		item.color = color;
	}
}

function disposeMagStatusBarItems() {
	for (const item of magStatusBarItems) {
		item.dispose();
	}
	magStatusBarItems = [];
}

function createMagStatusBarItems(position) {
	disposeMagStatusBarItems();
	const layout = STATUS_BAR_LAYOUTS[normalizeStatusBarPosition(position)];
	const color = getMagStatusBarForegroundColor();
	for (let index = 0; index < MAG_STATUS_BAR_SPECS.length; index += 1) {
		const spec = MAG_STATUS_BAR_SPECS[index];
		const item = vscode.window.createStatusBarItem(layout.alignment, layout.priorities[index]);
		item.text = spec.text;
		item.tooltip = spec.tooltip;
		item.color = color;
		item.command = spec.command;
		item.show();
		magStatusBarItems.push(item);
	}
}

async function applyStatusBarPosition(context, position) {
	const normalized = normalizeStatusBarPosition(position);
	await context.globalState.update(STATUS_BAR_POSITION_KEY, normalized);
	createMagStatusBarItems(normalized);
}

function handleExternalUri(context, uri) {
	const action = String(uri.path || "").replace(/^\/+|\/+$/g, "").toLowerCase();
	if (action === "agent") {
		return vscode.commands.executeCommand(SEND_TO_AGENT);
	}
	if (action === "terminal") {
		const expectedFingerprint = parseTerminalFingerprint(uri);
		return sendToCursorTerminal({
			requireFingerprint: true,
			expectedFingerprint,
			pasteOnly: false,
		});
	}
	if (action === "statusbar-left") {
		return applyStatusBarPosition(context, "left");
	}
	if (action === "statusbar-center") {
		return applyStatusBarPosition(context, "center");
	}
	if (action === "sendtogpt") {
		return sendToChatGPT(context, { appendCursorModelsTelemetry: true });
	}
	void vscode.window.showWarningMessage("[MAG] GPT|Cursor|Sync: unknown Cursor URI action.");
}

function activate(context) {
	void initializeStatusBarPosition(context);

	context.subscriptions.push(
		vscode.commands.registerCommand(SEND_TO_CHATGPT, () =>
			sendToChatGPT(context, { appendCursorModelsTelemetry: true })
		),
		vscode.commands.registerCommand(SEND_LAST_TERMINAL_OUTPUT_TO_CHATGPT, () =>
			sendLastTerminalOutputToChatGPT(context)
		),
		vscode.commands.registerCommand(SEND_LAST_2_TERMINAL_OUTPUTS_TO_CHATGPT, () =>
			sendLastNTerminalOutputsToChatGPT(context, 2)
		),
		vscode.commands.registerCommand(SEND_LAST_3_TERMINAL_OUTPUTS_TO_CHATGPT, () =>
			sendLastNTerminalOutputsToChatGPT(context, 3)
		),
		vscode.commands.registerCommand(SEND_TO_AGENT, () => sendToCursorAgent(context)),
		vscode.commands.registerCommand(SEND_TO_TERMINAL, () => sendToCursorTerminal()),
		vscode.window.registerUriHandler({ handleUri: (uri) => handleExternalUri(context, uri) }),
		{ dispose: disposeMagStatusBarItems },
		vscode.window.onDidChangeActiveColorTheme(() => {
			applyMagStatusBarForegroundColors();
		}),
		vscode.window.onDidStartTerminalShellExecution((event) => {
			beginShellExecutionCapture(event);
		}),
		vscode.window.onDidEndTerminalShellExecution((event) => {
			void completeShellExecutionCapture(event);
		}),
		vscode.window.onDidCloseTerminal((terminal) => {
			clearTerminalState(terminal);
		})
	);
}

function deactivate() {}

module.exports = {
	activate,
	deactivate,
};
