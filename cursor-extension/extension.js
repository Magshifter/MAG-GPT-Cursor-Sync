const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const vscode = require("vscode");

const SEND_TO_CHATGPT = "magWorkflowBridge.sendToChatGPT";
const SEND_TO_AGENT = "magWorkflowBridge.sendToCursorAgent";
const SEND_TO_TERMINAL = "magWorkflowBridge.sendToCursorTerminal";

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

function hasAmbiguousMultiline(text) {
	const normalized = text.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
	const trimmed = normalized.replace(/\n+$/u, "");
	return trimmed.includes("\n");
}

async function sendToChatGPT(context) {
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

async function sendToCursorTerminal() {
	const text = await vscode.env.clipboard.readText();
	if (!text) {
		void vscode.window.showWarningMessage("Clipboard is empty.");
		return;
	}

	if (hasAmbiguousMultiline(text)) {
		void vscode.window.showWarningMessage(
			"Clipboard has multiple lines. [MAG] GPT|Cursor|Sync did not execute it in the Cursor terminal."
		);
		return;
	}

	const terminal = vscode.window.activeTerminal;
	if (!terminal) {
		void vscode.window.showWarningMessage("No Cursor integrated terminal is active.");
		return;
	}

	terminal.show();
	terminal.sendText(text.replace(/\r\n/g, "\n").replace(/\r/g, "\n").replace(/\n+$/u, ""), true);
}

function handleExternalUri(uri) {
	const action = String(uri.path || "").replace(/^\/+|\/+$/g, "").toLowerCase();
	if (action === "agent") {
		return vscode.commands.executeCommand(SEND_TO_AGENT);
	}
	if (action === "terminal") {
		return vscode.commands.executeCommand(SEND_TO_TERMINAL);
	}
	void vscode.window.showWarningMessage("[MAG] GPT|Cursor|Sync: unknown Cursor URI action.");
}

function activate(context) {
	const item = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
	item.text = "→ ChatGPT";
	item.tooltip = "Send clipboard to ChatGPT";
	item.color = "#89D185";
	item.command = SEND_TO_CHATGPT;
	item.show();
	context.subscriptions.push(item);

	context.subscriptions.push(
		vscode.commands.registerCommand(SEND_TO_CHATGPT, () => sendToChatGPT(context)),
		vscode.commands.registerCommand(SEND_TO_AGENT, () => sendToCursorAgent(context)),
		vscode.commands.registerCommand(SEND_TO_TERMINAL, () => sendToCursorTerminal()),
		vscode.window.registerUriHandler({ handleUri: handleExternalUri })
	);
}

function deactivate() {}

module.exports = {
	activate,
	deactivate,
};
