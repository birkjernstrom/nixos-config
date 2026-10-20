import { createHash } from "node:crypto";
import { lstatSync, readFileSync, realpathSync } from "node:fs";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { homedir } from "node:os";
import { executable, safeInspection, scanShell, shellRisks } from "./shell.js";

export type Action = "allow" | "ask" | "deny";
export type Profile = "balanced" | "strict";
export const RULES = [
	"secrets.read", "secrets.modify", "secrets.search", "permissions.modify",
	"filesystem.delete", "filesystem.overwrite", "filesystem.outside-project",
	"git.discard-changes", "git.push", "host.privileged", "host.modify",
	"network.request", "network.upload", "code.execute", "code.download-and-execute",
	"external.mutate", "shell.dynamic", "shell.unclassified", "tools.unknown",
] as const;
export type Rule = typeof RULES[number];
export type Exception = { id: string; operation: Rule; paths: string[]; action: Action };
export type Policy = {
	version: 1;
	profile?: Profile;
	rules?: Partial<Record<Rule, Action>>;
	tools?: Record<string, Action>;
	sensitiveNames?: string[];
	sensitivePaths?: string[];
	exceptions?: Exception[];
};
export type Effective = {
	profile: Profile;
	rules: Record<Rule, Action>;
	tools: Record<string, Action>;
	sources: Record<string, string>;
	sensitiveNames: string[];
	sensitivePaths: string[];
	exceptions: (Exception & { source: string; base: string })[];
};
export type Match = { rule: string; action: Action; source: string };
export type Decision = { action: Action; matches: Match[]; summary: string; targets: string[] };
export type Paths = { root: string; agentDir: string; global: string; project: string; trust: string; protected: string[] };
const actions = new Set(["allow", "ask", "deny"]);
const rank: Record<Action, number> = { allow: 0, ask: 1, deny: 2 };

function object(value: unknown): value is Record<string, unknown> {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}
function keys(value: Record<string, unknown>, allowed: readonly string[]) {
	for (const key of Object.keys(value)) if (!allowed.includes(key)) throw new Error(`Unknown policy field: ${key}`);
}
function strings(value: unknown): value is string[] {
	return Array.isArray(value) && value.every((item) => typeof item === "string" && item.length > 0);
}
export function parsePolicy(text: string): Policy {
	if (text.length > 65536) throw new Error("Policy exceeds 64 KiB");
	const value: unknown = JSON.parse(text);
	if (!object(value)) throw new Error("Policy must be an object");
	keys(value, ["version", "profile", "rules", "tools", "sensitiveNames", "sensitivePaths", "exceptions"]);
	if (value.version !== 1) throw new Error("Policy version must be 1");
	if (value.profile !== undefined && value.profile !== "balanced" && value.profile !== "strict") throw new Error("Unknown permission profile");
	for (const field of ["rules", "tools"] as const) {
		if (value[field] === undefined) continue;
		if (!object(value[field])) throw new Error(`${field} must be an object`);
		for (const [name, action] of Object.entries(value[field])) {
			if ((field === "rules" && !(RULES as readonly string[]).includes(name)) || !actions.has(action as string) || !name || ["__proto__", "prototype", "constructor"].includes(name)) throw new Error(`Invalid ${field} entry: ${name}`);
		}
	}
	for (const field of ["sensitiveNames", "sensitivePaths"] as const) {
		if (value[field] !== undefined && !strings(value[field])) throw new Error(`${field} must contain nonempty strings`);
	}
	if ((value.sensitiveNames as string[] | undefined)?.some((name) => name.includes("/") || /[?\[\]{}]/.test(name))) throw new Error("sensitiveNames supports basenames with * wildcards only");
	if (value.exceptions !== undefined) {
		if (!Array.isArray(value.exceptions)) throw new Error("exceptions must be an array");
		const ids = new Set<string>();
		for (const entry of value.exceptions) {
			if (!object(entry)) throw new Error("Invalid exception");
			keys(entry, ["id", "operation", "paths", "action"]);
			if (typeof entry.id !== "string" || !entry.id || ids.has(entry.id) || !(RULES as readonly unknown[]).includes(entry.operation) ||
				!actions.has(entry.action as string) || !strings(entry.paths) || !entry.paths.length || entry.paths.some((path) => /[*?\[\]{}]/.test(path))) throw new Error("Invalid or duplicate exception");
			ids.add(entry.id);
		}
	}
	return value as Policy;
}

export function readOptional(path: string): string | undefined {
	try {
		if (lstatSync(path).isDirectory()) throw new Error(`Expected a file: ${path}`);
		return readFileSync(path, "utf8");
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") {
			try { lstatSync(path); } catch { return undefined; }
		}
		throw error;
	}
}

export function canonical(path: string): string {
	const absolute = resolve(path);
	try { lstatSync(absolute); } catch (error) {
		if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
		const parent = dirname(absolute);
		if (parent === absolute) throw error;
		return join(canonical(parent), basename(absolute));
	}
	return realpathSync(absolute);
}
export function expand(path: string, base: string): string {
	return resolve(base, path === "~" ? homedir() : path.startsWith("~/") ? join(homedir(), path.slice(2)) : path);
}
export function within(path: string, parent: string): boolean {
	const rel = relative(parent, path);
	return rel === "" || (!rel.startsWith(`..${sep}`) && rel !== ".." && !isAbsolute(rel));
}
export function projectRoot(cwd: string): string {
	let current = canonical(cwd);
	let local: string | undefined;
	while (true) {
		if (readableEntry(join(current, ".git"))) return current;
		if (!local && readableEntry(join(current, ".pi"))) local = current;
		const parent = dirname(current);
		if (parent === current) return local ?? canonical(cwd);
		current = parent;
	}
}
function readableEntry(path: string): boolean {
	try { lstatSync(path); return true; } catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
		throw error;
	}
}
export function digest(value: unknown): string {
	return createHash("sha256").update(stable(value)).digest("hex");
}
export function stable(value: unknown): string {
	if (Array.isArray(value)) return `[${value.map(stable).join(",")}]`;
	if (object(value)) return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stable(value[key])}`).join(",")}}`;
	return JSON.stringify(value) ?? "null";
}

export function mergePolicy(layers: { policy: Policy; source: string; base: string }[]): Effective {
	const rules = Object.fromEntries(RULES.map((rule) => [rule, rule === "shell.unclassified" ? "allow" : "ask"])) as Record<Rule, Action>;
	const result: Effective = {
		profile: "balanced", rules, tools: Object.create(null),
		sources: Object.fromEntries(RULES.map((rule) => [rule, "built-in"])),
		sensitiveNames: [".env", ".env.*", "*.pem", "*.key", ".npmrc", ".pypirc", ".netrc", "id_rsa*", "id_ed25519*"],
		sensitivePaths: ["~/.ssh", "~/.aws", "~/.azure", "~/.gnupg", "~/.kube", "~/.config/gcloud", "~/.config/gh", "~/.password-store"].map((path) => canonical(expand(path, homedir()))),
		exceptions: [],
	};
	const explicit = new Set<string>();
	for (const { policy, source, base } of layers) {
		if (policy.profile) result.profile = policy.profile;
		for (const [rule, action] of Object.entries(policy.rules ?? {})) {
			result.rules[rule as Rule] = action; result.sources[rule] = source; explicit.add(rule);
		}
		for (const [tool, action] of Object.entries(policy.tools ?? {})) {
			result.tools[tool] = action; result.sources[`tool:${tool}`] = source;
		}
		result.sensitiveNames.push(...policy.sensitiveNames ?? []);
		result.sensitivePaths.push(...(policy.sensitivePaths ?? []).map((path) => canonical(expand(path, base))));
		for (const entry of policy.exceptions ?? []) {
			result.exceptions = result.exceptions.filter((old) => old.id !== entry.id);
			result.exceptions.push({ ...entry, source, base });
		}
	}
	if (result.profile === "strict" && !explicit.has("shell.unclassified")) {
		result.rules["shell.unclassified"] = "ask"; result.sources["shell.unclassified"] = "strict profile";
	}
	return result;
}

function namedSensitive(path: string, policy: Effective): boolean {
	return path.split(sep).some((part) => policy.sensitiveNames.some((pattern) =>
		new RegExp(`^${pattern.split("*").map((p) => p.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join(".*")}$`).test(part)));
}
function pathVariants(path: string, cwd: string): string[] {
	const requested = expand(path, cwd);
	return [requested, canonical(requested)];
}
function secret(path: string, policy: Effective, paths: Paths): boolean {
	return namedSensitive(path, policy) || policy.sensitivePaths.some((parent) => within(path, parent)) ||
		["auth.json", "models.json", "mcp.json"].some((name) => within(path, canonical(join(paths.agentDir, name))));
}
function protectedPath(path: string, paths: Paths): boolean {
	return paths.protected.some((item) => within(path, expand(item, paths.root)) || within(path, canonical(expand(item, paths.root)))) ||
		path.split(sep).some((part) => ["AGENTS.md", "AGENTS.MD", "AGENTS.override.md", "CLAUDE.md", "CLAUDE.MD", ".git", ".agents"].includes(part)) ||
		path.includes(`${sep}.pi${sep}`) ||
		[".bashrc", ".bash_profile", ".profile", ".zshrc"].includes(basename(path));
}

export function evaluate(tool: string, input: Record<string, unknown>, cwd: string, paths: Paths, policy: Effective): Decision {
	const matches: Match[] = [];
	const resolvedTargets = new Set<string>();
	const add = (rule: Rule, targets?: string[]) => {
		let action = policy.rules[rule];
		let source = policy.sources[rule];
		const exceptions = targets?.length ? policy.exceptions.filter((entry) => entry.operation === rule && targets.every((target) =>
			entry.paths.some((path) => {
				const expected = expand(path, entry.base);
				return expected === resolve(target) && canonical(expected) === expected && within(expected, paths.root);
			}))) : [];
		if (action !== "deny" && exceptions?.length) {
			const exceptionRank = Math.max(...exceptions.map((entry) => rank[entry.action]));
			const entry = exceptions.find((item) => rank[item.action] === exceptionRank)!;
			action = entry.action; source = `${entry.source} exception:${entry.id}`;
		}
		if (!matches.some((match) => match.rule === rule && match.action === action && match.source === source)) matches.push({ rule, action, source });
	};
	const fileCheck = (path: string, write: boolean, exceptions = true) => {
		const variants = pathVariants(path, cwd);
		for (const variant of variants) resolvedTargets.add(variant);
		if (variants.some((path) => secret(path, policy, paths))) add(write ? "secrets.modify" : "secrets.read", exceptions ? variants : undefined);
		if (write && variants.some((path) => protectedPath(path, paths))) add("permissions.modify");
		if (variants.some((path) => !within(path, paths.root))) add("filesystem.outside-project", exceptions ? variants : undefined);
	};
	let summary = tool;
	if (["read", "write", "edit", "grep", "find", "ls"].includes(tool)) {
		const path = typeof input.path === "string" ? input.path : ".";
		fileCheck(path, tool === "write" || tool === "edit");
		if (tool === "grep") add("secrets.search");
		summary = `${tool} ${path}`;
	} else if (tool === "bash") {
		if (typeof input.command !== "string") throw new Error("Missing Bash command");
		const shell = scanShell(input.command);
		const risks = shellRisks(shell, input.command);
		let deleteTargets: string[] | undefined;
		if (shell.simple) {
			const { name, args } = executable(shell.commands[0]);
			if (name === "rm" && shell.commands[0][0] === "rm" && args.every((arg) => !arg.startsWith("-") || /^(?:-[rfviIdP]+|--recursive|--force|--verbose|--interactive(?:=\w+)?|--)$/.test(arg))) {
				deleteTargets = args.filter((arg) => !arg.startsWith("-")).map((arg) => expand(arg, cwd));
			}
		}
		for (const risk of risks) add(risk as Rule, risk === "filesystem.delete" ? deleteTargets : undefined);
		if (!safeInspection(shell)) add("shell.unclassified");
		const write = [...risks].some((risk) => ["filesystem.delete", "filesystem.overwrite", "host.modify"].includes(risk));
		for (const word of shell.words) {
			if (!word || /^(?:https?|ssh|git):\/\//.test(word)) continue;
			let value = word;
			if (word.includes("=") && !word.startsWith("/")) value = word.slice(word.indexOf("=") + 1);
			else if (word.startsWith("-")) continue;
			if (/^[\w~^.-]+:/.test(value)) value = value.slice(value.indexOf(":") + 1);
			if (value) {
				fileCheck(value, false, false);
				if (write) fileCheck(value, true, false);
			}
		}
		if (/\b(?:auth|models|mcp)\.json\b|\.pi\/agent/.test(input.command)) add(write ? "secrets.modify" : "secrets.read");
		summary = input.command;
	} else if (tool !== "ask_user") add("tools.unknown");
	if (Object.hasOwn(policy.tools, tool)) matches.push({ rule: `tool:${tool}`, action: policy.tools[tool], source: policy.sources[`tool:${tool}`] });
	if (Object.hasOwn(policy.tools, tool) && tool !== "bash" && !["read", "write", "edit", "grep", "find", "ls", "ask_user"].includes(tool)) {
		const index = matches.findIndex((match) => match.rule === "tools.unknown");
		if (index >= 0 && policy.rules["tools.unknown"] !== "deny") matches.splice(index, 1);
	}
	const action = matches.reduce<Action>((result, match) => rank[match.action] > rank[result] ? match.action : result, "allow");
	return { action, matches, summary, targets: [...resolvedTargets].sort() };
}
