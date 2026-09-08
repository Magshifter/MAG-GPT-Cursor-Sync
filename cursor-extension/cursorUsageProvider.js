const fs = require("fs");
const https = require("https");
const path = require("path");
const { createRequire } = require("module");

const USAGE_HOST = "api2.cursor.sh";
const USAGE_PATH = "/aiserver.v1.DashboardService/GetCurrentPeriodUsage";
const USAGE_TIMEOUT_MS = 5000;
const ACCESS_TOKEN_KEY = "cursorAuth/accessToken";

/**
 * Match Cursor UI percentage display:
 * values in (0, 1) become 1; otherwise round and clamp to 0..100.
 * @param {number} value
 * @returns {number | null}
 */
function normalizeCursorModelsPercent(value) {
	if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
		return null;
	}
	if (value > 0 && value < 1) {
		return 1;
	}
	return Math.round(Math.min(Math.max(value, 0), 100));
}

function getStateDbPath() {
	const appData = process.env.APPDATA || "";
	if (!appData) {
		return null;
	}
	return path.join(appData, "Cursor", "User", "globalStorage", "state.vscdb");
}

/**
 * Load Cursor's bundled @vscode/sqlite3 from the running app root.
 * Avoids adding extension dependencies.
 * @param {string} appRoot
 */
function loadSqlite3(appRoot) {
	if (!appRoot || typeof appRoot !== "string") {
		throw new Error("Cursor app root is unavailable.");
	}
	const packageJson = path.join(appRoot, "package.json");
	if (!fs.existsSync(packageJson)) {
		throw new Error("Cursor app package.json was not found.");
	}
	const requireFromApp = createRequire(packageJson);
	return requireFromApp("@vscode/sqlite3");
}

/**
 * Read the Cursor access token from local ItemTable, then close the DB.
 * The token is returned only for an immediate HTTPS call and must not be logged.
 * @param {string} appRoot
 * @returns {Promise<string | null>}
 */
function readAccessToken(appRoot) {
	const dbPath = getStateDbPath();
	if (!dbPath || !fs.existsSync(dbPath)) {
		return Promise.resolve(null);
	}

	let sqlite3;
	try {
		sqlite3 = loadSqlite3(appRoot);
	} catch {
		return Promise.resolve(null);
	}

	return new Promise((resolve) => {
		let settled = false;
		const finish = (value) => {
			if (settled) {
				return;
			}
			settled = true;
			resolve(value);
		};

		const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (openError) => {
			if (openError) {
				finish(null);
				return;
			}

			try {
				db.configure("busyTimeout", 3000);
			} catch {
				// Older bindings may not support configure; continue.
			}

			db.get(
				"SELECT value AS value FROM ItemTable WHERE key = ? LIMIT 1",
				[ACCESS_TOKEN_KEY],
				(queryError, row) => {
					db.close(() => {
						if (queryError || !row || row.value == null) {
							finish(null);
							return;
						}
						const token = Buffer.isBuffer(row.value)
							? row.value.toString("utf8")
							: String(row.value);
						finish(token && token.length >= 20 ? token : null);
					});
				}
			);
		});

		db.on("error", () => {
			try {
				db.close(() => finish(null));
			} catch {
				finish(null);
			}
		});
	});
}

/**
 * Bounded POST to the Cursor-owned usage endpoint proven by U1.
 * @param {string} accessToken
 * @returns {Promise<object>}
 */
function fetchCurrentPeriodUsage(accessToken) {
	return new Promise((resolve, reject) => {
		const request = https.request(
			{
				hostname: USAGE_HOST,
				path: USAGE_PATH,
				method: "POST",
				timeout: USAGE_TIMEOUT_MS,
				headers: {
					"Content-Type": "application/json",
					"Connect-Protocol-Version": "1",
					Authorization: `Bearer ${accessToken}`,
					"Content-Length": Buffer.byteLength("{}"),
				},
			},
			(response) => {
				const chunks = [];
				response.on("data", (chunk) => {
					chunks.push(chunk);
				});
				response.on("end", () => {
					const body = Buffer.concat(chunks).toString("utf8");
					if (response.statusCode !== 200) {
						reject(new Error("Usage request failed."));
						return;
					}
					try {
						resolve(JSON.parse(body));
					} catch {
						reject(new Error("Usage response was not valid JSON."));
					}
				});
			}
		);

		request.on("timeout", () => {
			request.destroy(new Error("Usage request timed out."));
		});
		request.on("error", (error) => {
			reject(error instanceof Error ? error : new Error(String(error)));
		});
		request.write("{}");
		request.end();
	});
}

/**
 * Isolated Cursor Models percentage provider.
 * @param {string} appRoot vscode.env.appRoot for the running Cursor install
 * @returns {Promise<number | null>} integer percent, or null when unavailable
 */
async function getCursorModelsPercentage(appRoot) {
	let accessToken = null;
	try {
		accessToken = await readAccessToken(appRoot);
		if (!accessToken) {
			return null;
		}

		const payload = await fetchCurrentPeriodUsage(accessToken);
		accessToken = null;

		const planUsage = payload && typeof payload === "object" ? payload.planUsage : null;
		if (!planUsage || typeof planUsage !== "object") {
			return null;
		}

		return normalizeCursorModelsPercent(planUsage.autoPercentUsed);
	} catch {
		return null;
	} finally {
		accessToken = null;
	}
}

module.exports = {
	USAGE_HOST,
	USAGE_PATH,
	USAGE_TIMEOUT_MS,
	getCursorModelsPercentage,
	normalizeCursorModelsPercent,
};
