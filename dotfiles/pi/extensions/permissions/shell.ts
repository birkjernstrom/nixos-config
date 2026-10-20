import { basename } from "node:path";

export type Shell = { commands: string[][]; words: string[]; complex: boolean; redirects: boolean; simple: boolean };

export function scanShell(input: string): Shell {
	const commands: string[][] = [];
	const words: string[] = [];
	let command: string[] = [];
	let word = "";
	let started = false;
	let quote = "";
	let complex = false;
	let redirects = false;
	let separators = false;
	function flushWord() {
		if (started) { command.push(word); words.push(word); word = ""; started = false; }
	}
	function flushCommand() { flushWord(); if (command.length) commands.push(command); command = []; }
	for (let i = 0; i < input.length; i++) {
		const c = input[i];
		if (c === "\\" && quote !== "'") {
			const next = input[++i];
			if (next === undefined) { complex = true; break; }
			if (next !== "\n") { word += next; started = true; }
			continue;
		}
		if (quote) {
			if (c === quote) quote = "";
			else { word += c; if (quote === '"' && /[$`]/.test(c)) complex = true; }
			continue;
		}
		if (c === "'" || c === '"') { quote = c; started = true; continue; }
		if (c === "#" && !started) {
			while (i < input.length && input[i] !== "\n") i++;
			flushCommand(); separators = true; continue;
		}
		if (/[\s]/.test(c)) {
			if (c === "\n") { flushCommand(); separators = true; } else flushWord();
			continue;
		}
		if (/[;&|()<>]/.test(c)) {
			flushCommand(); separators = true;
			if (/[<>]/.test(c)) redirects = true;
			if (/[()]/.test(c) || (c === "&" && input[i + 1] !== "&" && input[i - 1] !== "&")) complex = true;
			continue;
		}
		if (/[$`*?{}\[\]~]/.test(c)) complex = true;
		word += c; started = true;
	}
	if (quote) complex = true;
	flushCommand();
	if (commands.some((args) => args.some((arg) => /^(?:if|then|else|fi|for|while|until|do|done|case|esac|function|!|\[\[)$/.test(arg)))) complex = true;
	return { commands, words, complex, redirects, simple: !complex && !redirects && !separators && commands.length === 1 };
}

export function executable(args: string[]): { name: string; args: string[] } {
	let index = 0;
	while (/^[A-Za-z_][A-Za-z_0-9]*=/.test(args[index] ?? "")) index++;
	while (["command", "builtin", "exec", "nohup", "time"].includes(args[index] ?? "")) {
		index++;
		while (args[index]?.startsWith("-")) index++;
	}
	return { name: basename(args[index] ?? ""), args: args.slice(index + 1) };
}

export function safeInspection(shell: Shell): boolean {
	if (shell.complex || shell.redirects || !shell.commands.length) return false;
	return shell.commands.every((words) => {
		const command = executable(words);
		if (words[0] !== command.name) return false;
		if (["pwd", "whoami"].includes(command.name)) return command.args.every((arg) => /^-[LP]+$/.test(arg));
		if (["ls", "stat", "wc", "head", "tail", "cat", "readlink", "realpath"].includes(command.name)) return true;
		if (command.name !== "git") return false;
		return ["status", "diff", "log", "show", "ls-files", "rev-parse"].includes(command.args[0]) &&
			!command.args.some((arg) => /^(?:-c|--config|--exec-path|--output|--ext-diff|--textconv|--no-index|--open-files-in-pager)/.test(arg));
	});
}

export function shellRisks(shell: Shell, raw: string): Set<string> {
	const risks = new Set<string>();
	const add = (rule: string) => risks.add(rule);
	if (shell.complex) add("shell.dynamic");
	if (shell.redirects) add("filesystem.overwrite");
	const commands = shell.commands.flatMap((words) => {
		const name = executable(words).name;
		return ["sudo", "doas", "env", "xargs", "timeout", "nice", "setsid", "find"].includes(name)
			? words.map((_, index) => words.slice(index)) : [words];
	});
	for (const words of commands) {
		const { name, args } = executable(words);
		const all = args.join(" ");
		if (["rm", "rmdir", "unlink", "shred"].includes(name) || (name === "find" && args.some((a) => /^-(delete|exec|execdir|ok|okdir)$/.test(a))) ||
			(name === "rsync" && args.some((a) => a.startsWith("--delete")))) add("filesystem.delete");
		if (["dd", "truncate", "tee", "cp", "mv", "install", "touch", "ln", "patch", "apply_patch", "tar", "bsdtar", "unzip", "zip", "7z", "7za", "unrar", "cpio", "gzip", "gunzip", "bzip2", "bunzip2", "xz", "unxz"].includes(name) || (name === "sed" && args.some((a) => /^(-[a-zA-Z]*i|--in-place)/.test(a)))) add("filesystem.overwrite");
		if (["sudo", "su", "doas", "pkexec"].includes(name)) add("host.privileged");
		if (/^(?:chmod|chown|chgrp|mount|umount|systemctl|loginctl|shutdown|reboot|poweroff|kill|killall|pkill|iptables|nft|ufw|fdisk|sfdisk|parted|wipefs|mkfs(?:\..*)?|mkswap|swapon|crontab)$/.test(name)) add("host.modify");
		if (["env", "printenv", "set", "export", "declare"].includes(name)) add("secrets.read");
		if (["grep", "rg", "ag", "ack"].includes(name)) add("secrets.search");
		if (name === "git") {
			if (/\b(reset|clean|restore|checkout|switch|rebase|reflog|gc|rm|mv|read-tree|update-ref|update-index|filter-branch|filter-repo)\b/.test(all) ||
				(/\b(?:branch|tag)\b/.test(all) && /(?:^|\s)(?:-[a-zA-Z]*[dD]|--delete|--force)(?:\s|$)/.test(all)) || /\bstash\s+(drop|clear)\b/.test(all)) add("git.discard-changes");
			if (/\bpush\b/.test(all)) add("git.push");
			if (!["status", "diff", "log", "show", "ls-files", "rev-parse", "branch", "tag", "remote"].includes(args[0])) add("code.execute");
			if (/\b(config|remote|submodule|fetch|pull|clone|commit|apply|am|merge|cherry-pick)\b/.test(all) || args.some((a) => /^(?:-c|--exec-path|--ext-diff|--textconv)/.test(a))) add("code.execute");
		}
		if (["curl", "wget", "http", "https", "ssh", "scp", "sftp", "rsync", "nc", "ncat", "netcat", "socat"].includes(name)) add("network.request");
		if (["scp", "sftp", "rsync", "nc", "ncat", "netcat", "socat"].includes(name) ||
			(name === "curl" && args.some((a) => /^(?:-[a-zA-Z]*[dFTX]|--(?:data|form|upload|request|json|url-query))/.test(a))) ||
			(name === "wget" && args.some((a) => /^--(?:post|method|body)/.test(a)))) add("network.upload");
		if (/^(?:bash|sh|zsh|fish|dash|eval|source|\.|python[\d.]*|node|nodejs|deno|bun|ruby|perl|php|lua|awk|gawk|sed|ed|ex|vim|nvim|emacs|xargs|env|npm|npx|pnpm|yarn|pip[\d.]*|uv|poetry|make|gmake|just|task|cargo|go|nix|nix-shell|nix-build|direnv|docker|podman)$/.test(name) ||
			words[0]?.includes("/") || args.some((a) => /^--(?:exec|pre|pre-glob)(?:=|$)/.test(a))) add("code.execute");
		if (["gh", "glab", "aws", "gcloud", "az", "kubectl", "helm", "terraform", "tofu", "ansible", "psql", "mysql", "sqlite3", "redis-cli", "mongosh", "vercel", "fly", "wrangler", "nixos-rebuild", "home-manager"].includes(name)) add("external.mutate");
	}
	if (/\b(?:curl|wget)\b[\s\S]*(?:\||<\()[\s\S]*\b(?:sh|bash|python|node)\b/.test(raw)) add("code.download-and-execute");
	return risks;
}
