import { chmodSync, mkdirSync, renameSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { askQuestions, displayText } from "../lib/questions.js";
import {
	canonical, digest, evaluate, mergePolicy, parsePolicy, projectRoot, readOptional, RULES, stable,
	type Action, type Decision, type Effective, type Paths, type Policy, type Profile,
} from "./policy.js";

type State = {
	id: string;
	paths: Paths;
	profile?: Profile;
	rules: Record<string, Action>;
	approvals: Set<string>;
	project?: { signature: string; accepted: boolean };
	last?: Decision;
	queue: Promise<unknown>;
};
type Store = { current?: State };
const key = Symbol.for("birk.pi.permissions.v1");
const processState = globalThis as typeof globalThis & { [key: symbol]: Store };
const store = processState[key] ??= {};

function stateFor(ctx: ExtensionContext): State {
	const agentDir = canonical(getAgentDir());
	const id = `${agentDir}:${ctx.sessionManager.getSessionId()}`;
	if (store.current?.id === id) return store.current;
	const root = projectRoot(ctx.cwd);
	const global = join(agentDir, "permissions.json");
	const project = join(root, ".pi", "permissions.json");
	const trust = join(agentDir, "permission-trust.json");
	const source = fileURLToPath(import.meta.url);
	const paths = {
		root, agentDir, global, project, trust,
		protected: [global, project, trust, join(agentDir, "extensions"), join(agentDir, "settings.json"),
			join(agentDir, "trust.json"), join(dirname(source), ".."), join(dirname(source), "..", "..", "permissions.json")],
	};
	return store.current = { id, paths, rules: Object.create(null), approvals: new Set(), queue: Promise.resolve() };
}

function locked<T>(state: State, fn: () => Promise<T>): Promise<T> {
	const task = state.queue.then(fn);
	state.queue = task.catch(() => undefined);
	return task;
}

async function choose(ctx: ExtensionContext, question: string, options: string[]): Promise<string | undefined> {
	const result = await askQuestions(ctx, [{ question: displayText(question), options }], ctx.signal, undefined, true);
	return !result.cancelled && !result.answers[0]?.custom ? result.answers[0]?.answer : undefined;
}

type Trust = { version: 1; projects: Record<string, { root: string; signature: string }> };
function readTrust(path: string): Trust {
	const raw = readOptional(path);
	if (raw === undefined) return { version: 1, projects: Object.create(null) };
	const parsed = JSON.parse(raw);
	if (parsed?.version !== 1 || !parsed.projects || typeof parsed.projects !== "object" || Array.isArray(parsed.projects) ||
		Object.values(parsed.projects).some((entry: any) => typeof entry?.root !== "string" || typeof entry?.signature !== "string")) throw new Error("Invalid permission trust store");
	return parsed;
}
function remember(paths: Paths, signature: string) {
	const trust = readTrust(paths.trust);
	trust.projects[digest(paths.root)] = { root: paths.root, signature };
	mkdirSync(dirname(paths.trust), { recursive: true, mode: 0o700 });
	const temp = `${paths.trust}.${randomUUID()}.tmp`;
	writeFileSync(temp, `${JSON.stringify(trust, null, 2)}\n`, { mode: 0o600, flag: "wx" });
	renameSync(temp, paths.trust);
	chmodSync(paths.trust, 0o600);
}

function policyInputs(paths: Paths) {
	const globalRaw = readOptional(paths.global);
	const projectRaw = readOptional(paths.project);
	return {
		global: globalRaw === undefined ? undefined : parsePolicy(globalRaw),
		project: projectRaw === undefined ? undefined : parsePolicy(projectRaw),
		signature: digest({ root: paths.root, path: canonical(paths.project), content: projectRaw }),
		revision: digest({ globalRaw, projectRaw, globalPath: canonical(paths.global), projectPath: canonical(paths.project) }),
	};
}

function projectSummary(project: Policy, global: Effective): string {
	const lines: string[] = [];
	if (project.profile) lines.push(`profile: ${global.profile} → ${project.profile}${global.profile === "strict" && project.profile === "balanced" ? " (relaxation)" : ""}`);
	const rank = { allow: 0, ask: 1, deny: 2 };
	for (const [rule, action] of Object.entries(project.rules ?? {})) {
		const previous = global.rules[rule as keyof typeof global.rules];
		lines.push(`${rule}: ${previous} → ${action}${rank[action] < rank[previous] ? " (relaxation)" : ""}`);
	}
	for (const [tool, action] of Object.entries(project.tools ?? {})) lines.push(`tool ${tool}: ${action}`);
	for (const exception of project.exceptions ?? []) lines.push(`exception ${exception.id}: ${exception.operation} ${exception.action} [${exception.paths.join(", ")}]`);
	if (project.sensitiveNames?.length) lines.push(`add sensitive names: ${project.sensitiveNames.join(", ")}`);
	if (project.sensitivePaths?.length) lines.push(`add sensitive paths: ${project.sensitivePaths.join(", ")}`);
	return lines.join("\n") || "No overrides";
}

async function loadPolicy(state: State, ctx: ExtensionContext): Promise<{ policy: Effective; revision: string }> {
	const inputs = policyInputs(state.paths);
	const globalLayers = inputs.global ? [{ policy: inputs.global, source: "global", base: state.paths.root }] : [];
	const layers = [...globalLayers];
	if (inputs.project) {
		if (state.project?.signature !== inputs.signature) {
			const saved = readTrust(state.paths.trust).projects[digest(state.paths.root)];
			let accepted = saved?.root === state.paths.root && saved.signature === inputs.signature;
			if (!accepted) {
				const summary = projectSummary(inputs.project, mergePolicy(globalLayers));
				const choice = await choose(ctx,
					`Trust project permission overrides?\n\nProject: ${state.paths.root}\nPolicy: ${state.paths.project}\nSHA-256: ${inputs.signature}\n\n${summary}\n\nOverrides can weaken global protections. Trust applies only to this policy revision.`,
					["Ignore project overrides", "Trust for this session", "Trust and remember"]);
				accepted = choice === "Trust for this session" || choice === "Trust and remember";
				if (policyInputs(state.paths).revision !== inputs.revision) throw new Error("Policy changed during trust approval; retry after reviewing it");
				if (choice === "Trust and remember") remember(state.paths, inputs.signature);
			}
			state.project = { signature: inputs.signature, accepted };
		}
		if (state.project.accepted) layers.push({ policy: inputs.project, source: "project", base: state.paths.root });
	}
	const session: Policy = { version: 1, rules: state.rules };
	if (state.profile) session.profile = state.profile;
	layers.push({ policy: session, source: "session", base: state.paths.root });
	return { policy: mergePolicy(layers), revision: digest({ disk: inputs.revision, session, project: state.project }) };
}

function unchanged(state: State, revision: string): boolean {
	const inputs = policyInputs(state.paths);
	const session: Policy = { version: 1, rules: state.rules };
	if (state.profile) session.profile = state.profile;
	return revision === digest({ disk: inputs.revision, session, project: state.project });
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (event, ctx) => {
		try {
			if (event.reason !== "reload") store.current = undefined;
			const state = stateFor(ctx);
			await locked(state, async () => {
				const { policy } = await loadPolicy(state, ctx);
				ctx.ui.setStatus("permissions", `Permissions: ${policy.profile}`);
			});
		} catch (error) {
			ctx.ui.setStatus("permissions", "Permissions: CONFIG ERROR");
			ctx.ui.notify(`Permissions fail closed: ${displayText(String(error))}`, "error");
		}
	});

	pi.on("tool_call", async (event, ctx) => {
		try {
			const state = stateFor(ctx);
			const input = stable(event.input);
			return await locked(state, async () => {
				if (ctx.signal?.aborted || store.current !== state) return { block: true, reason: "Permission request cancelled" };
				const { policy, revision } = await loadPolicy(state, ctx);
				const decision = evaluate(event.toolName, event.input, ctx.cwd, state.paths, policy);
				state.last = decision;
				if (decision.action === "deny") return { block: true, reason: `Denied by permission policy: ${decision.matches.filter((m) => m.action === "deny").map((m) => m.rule).join(", ")}` };
				const approvalKey = digest({ tool: event.toolName, input, cwd: canonical(ctx.cwd), revision, decision });
				if (decision.action === "allow" || state.approvals.has(approvalKey)) {
					if (!unchanged(state, revision) || stable(event.input) !== input) return { block: true, reason: "Policy or tool input changed; retry" };
					return;
				}
				if (ctx.mode !== "tui") return { block: true, reason: "Permission requires approval in the interactive Pi TUI" };
				const reasons = decision.matches.filter((m) => m.action !== "allow").map((m) => `${m.rule} (${m.source}: ${m.action})`).join("\n");
				const detail = event.toolName === "bash" ? decision.summary : `${event.toolName}\n${JSON.stringify(event.input, null, 2)}`;
				const choice = await choose(ctx,
					`Working directory: ${ctx.cwd}\n\n${reasons}\n\n${detail}\n\nApproval trusts any code invoked; this guard is not a sandbox.`,
					["Deny", "Allow this exact operation once", "Allow this exact operation for this session"]);
				if (ctx.signal?.aborted || store.current !== state || stable(event.input) !== input || !unchanged(state, revision) || stable(evaluate(event.toolName, event.input, ctx.cwd, state.paths, policy)) !== stable(decision)) return { block: true, reason: "Permission request, input, paths, or policy changed; retry" };
				if (choice !== "Allow this exact operation once" && choice !== "Allow this exact operation for this session") return { block: true, reason: "Operation not approved" };
				if (choice === "Allow this exact operation for this session") state.approvals.add(approvalKey);
			});
		} catch (error) {
			return { block: true, reason: `Permissions fail closed: ${displayText(String(error))}` };
		}
	});

	pi.registerCommand("permissions", {
		description: "Inspect permissions; profile balanced|strict; set RULE allow|ask|deny; reset-session; trust-project; explain",
		handler: async (args, ctx) => {
			try {
				const state = stateFor(ctx);
				await locked(state, async () => {
					const words = args.trim().split(/\s+/).filter(Boolean);
					if (words[0] === "reset-session" && words.length === 1) {
						state.rules = Object.create(null); state.profile = undefined; state.approvals.clear(); state.last = undefined;
					} else if (words[0] === "profile" && words.length === 2 && ["balanced", "strict"].includes(words[1])) {
						state.profile = words[1] as Profile; state.approvals.clear();
					} else if (words[0] === "set" && words.length === 3 && (RULES as readonly string[]).includes(words[1]) && ["allow", "ask", "deny"].includes(words[2])) {
						state.rules[words[1]] = words[2] as Action; state.approvals.clear();
					} else if (words[0] === "trust-project" && words.length === 1) {
						state.project = undefined;
					} else if (words[0] === "explain" && words.length === 1) {
						const last = state.last;
						ctx.ui.notify(last ? displayText(`${last.action}: ${last.summary}\n${last.matches.map((m) => `${m.rule}: ${m.action} (${m.source})`).join("\n")}`) : "No tool decision yet", "info");
						return;
					} else if (words.length) throw new Error("Usage: /permissions [explain | profile balanced|strict | set RULE allow|ask|deny | reset-session | trust-project]");
					const { policy } = await loadPolicy(state, ctx);
					ctx.ui.setStatus("permissions", `Permissions: ${policy.profile}`);
					ctx.ui.notify(displayText([
						`Profile: ${policy.profile} (guard only; not a sandbox)`, `Root: ${state.paths.root}`,
						`Global: ${state.paths.global}`, `Project: ${state.paths.project} (${state.project?.accepted ? "trusted" : "ignored/absent"})`,
						`Exact session approvals: ${state.approvals.size}`,
						...RULES.map((rule) => `${rule}: ${policy.rules[rule]} (${policy.sources[rule]})`),
						...Object.entries(policy.tools).map(([tool, action]) => `tool ${tool}: ${action} (${policy.sources[`tool:${tool}`]})`),
						...policy.exceptions.map((entry) => `exception ${entry.id}: ${entry.operation} ${entry.action} [${entry.paths.join(", ")}] (${entry.source})`),
					].join("\n")), "info");
				});
			} catch (error) { ctx.ui.notify(displayText(String(error)), "error"); }
		},
	});
}
