import type { ExtensionAPI, ProjectTrustEventResult } from "@earendil-works/pi-coding-agent";

const TRUSTED_OWNERS = new Set(["birkjernstrom", "polarsource"]);

export function githubOwner(url: string): string | undefined {
	const value = url.trim();
	const scp = value.match(/^(?:[^@/:\s]+@)?github\.com:([^/:\s]+)\/[^/\s]+?\/?$/i);
	if (scp) return scp[1].toLowerCase();
	try {
		const parsed = new URL(value);
		if (parsed.hostname.toLowerCase() !== "github.com") return undefined;
		const parts = parsed.pathname.split("/").filter(Boolean);
		return parts.length === 2 ? decodeURIComponent(parts[0]).toLowerCase() : undefined;
	} catch {
		return undefined;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("project_trust", async (event): Promise<ProjectTrustEventResult> => {
		try {
			const result = await pi.exec("git", ["remote", "get-url", "--all", "origin"], { cwd: event.cwd, timeout: 5000 });
			const urls = result.code === 0 ? result.stdout.split(/\r?\n/).filter((line) => line.trim()) : [];
			if (urls.length && urls.every((url) => TRUSTED_OWNERS.has(githubOwner(url) ?? ""))) {
				return { trusted: "yes", remember: true };
			}
		} catch {}
		return { trusted: "undecided" };
	});
}
