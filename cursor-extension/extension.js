const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const vscode = require("vscode");

const COMMAND_ID = "magWorkflowBridge.sendToChatGPT";

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
			reject(new Error("The ChatGPT paste helper timed out."));
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

async function sendToChatGPT(context) {
	const ahkPath = findAutoHotkey();
	if (!ahkPath) {
		void vscode.window.showWarningMessage("AutoHotkey v2 was not found. Install it, then try again.");
		return;
	}

	const helperPath = path.join(context.extensionPath, "helper.ahk");
	if (!fs.existsSync(helperPath)) {
		void vscode.window.showWarningMessage("MAG Workflow Bridge helper.ahk is missing.");
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

function activate(context) {
	const item = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
	item.text = "→ ChatGPT";
	item.tooltip = "Send clipboard to ChatGPT";
	item.color = "#89D185";
	item.command = COMMAND_ID;
	item.show();
	context.subscriptions.push(item);

	context.subscriptions.push(
		vscode.commands.registerCommand(COMMAND_ID, () => sendToChatGPT(context))
	);
}

function deactivate() {}

module.exports = {
	activate,
	deactivate,
};
