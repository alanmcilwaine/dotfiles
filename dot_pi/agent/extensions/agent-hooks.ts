/**
 * Runs the shared agent hooks in ~/.agents/hooks, so Pi behaves like the other
 * harnesses: the project's personal instructions go into every run, and the
 * project's checks run before the agent may finish.
 *
 * All logic lives in the hook scripts. This file only translates Pi's events.
 */

import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOOKS_DIR = join(homedir(), ".agents", "hooks");
const EXIT_BLOCK = 2;

interface HookResult {
	code: number | null;
	stdout: string;
	stderr: string;
}

function runHook(name: string, cwd: string, sessionId: string): Promise<HookResult> {
	return new Promise((resolve, reject) => {
		const child = spawn(join(HOOKS_DIR, name), { stdio: ["pipe", "pipe", "pipe"] });
		let stdout = "";
		let stderr = "";
		child.stdout.on("data", (chunk) => {
			stdout += chunk;
		});
		child.stderr.on("data", (chunk) => {
			stderr += chunk;
		});
		child.on("error", reject);
		child.on("close", (code) => resolve({ code, stdout, stderr }));
		child.stdin.end(JSON.stringify({ cwd, session_id: sessionId }));
	});
}

export default function agentHooks(pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		const result = await runHook("session-start", ctx.cwd, ctx.sessionManager.getSessionId());
		if (result.code !== 0) {
			throw new Error(`session-start hook failed: ${result.stderr.trim()}`);
		}

		const instructions = result.stdout.trim();
		if (instructions) {
			event.systemPromptOptions.sections.project_overlay = instructions;
		} else {
			delete event.systemPromptOptions.sections.project_overlay;
		}
	});

	pi.on("agent_before_settle", async (event, ctx) => {
		if (event.outcome !== "completed") return;

		const result = await runHook("stop-gate", ctx.cwd, ctx.sessionManager.getSessionId());
		if (result.code === EXIT_BLOCK) {
			return {
				entries: [
					...event.entries,
					{ type: "custom_message", customType: "stop-gate", content: result.stderr.trim(), display: true },
				],
				continue: true,
			};
		}
		if (result.code !== 0) {
			throw new Error(`stop-gate hook failed: ${result.stderr.trim()}`);
		}

		// The gate prints a JSON systemMessage when it gives up after repeated failures.
		const notice = result.stdout.trim();
		if (notice && ctx.hasUI) {
			ctx.ui.notify(JSON.parse(notice).systemMessage, "warning");
		}
	});
}
