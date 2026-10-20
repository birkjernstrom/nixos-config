# Pi permissions

A global, pre-execution confirmation guard for model-issued tools, including nested calls through Pi's `ctx.executeTool()`. It shares the `ask_user` panel but does not depend on the model remembering to call that tool. It is **not a sandbox**.

## Installation

`modules/shared/programming/pi.nix` installs:

```text
~/.pi/agent/extensions       → dotfiles/pi/extensions
~/.pi/agent/permissions.json → dotfiles/pi/permissions.json
```

The actual symlink targets follow the module's `livePiSources` setting. With live sources enabled, code and global policy edits are used without a rebuild after initial installation. Extension changes require `/reload`; policy files are checked before each tool call.

If `~/.pi/agent/extensions` is still a real directory, follow the backup/build/switch migration in [README.md](README.md#one-time-migration). Do not overwrite that directory: it may contain other extensions or logs. Adding the managed global policy requires a Home Manager activation; back up any existing unmanaged `permissions.json` first.

Before installation, try both extensions from this repository:

```sh
pi -e ./dotfiles/pi/extensions/ask-user.ts -e ./dotfiles/pi/extensions/permissions/index.ts
```

Do not load a second copy of an extension already installed globally. The permissions extension can run without `ask-user.ts` because they import a shared panel. With no global policy file, built-in defaults match the checked-in balanced configuration. `-e` loads the guard into that Pi process; it does not retrofit an already-running agent.

## Defaults

Routine project file reads/edits and ordinary inspections are allowed. Confirmation is required for:

| Rule | Coverage |
| --- | --- |
| `secrets.read` | Sensitive paths/names, environment dumps, agent credential/config files |
| `secrets.modify` | Recognized shell mutations or file-tool writes to sensitive paths |
| `secrets.search` | Content searches through `grep`, `rg`, `ag`, `ack`, or Pi's `grep` tool |
| `permissions.modify` | Policy files, trust records, extension sources, `.pi` files, agent instructions, Git internals, common shell startup files |
| `filesystem.delete` | `rm`, `rmdir`, `unlink`, `shred`, `find` execution/deletion, `rsync --delete` |
| `filesystem.overwrite` | Shell redirection, copying/moving, `dd`, `truncate`, `tee`, in-place `sed`, links, patches, `touch`, archive/compression tools |
| `filesystem.outside-project` | File-tool paths and recognized shell path arguments outside the fixed root |
| `git.discard-changes` | Reset, clean, restore, checkout/switch, rebase, Git file removal/moves, branch/tag/stash deletion, index/ref rewrites and maintenance |
| `git.push` | Pushes, including force pushes |
| `host.privileged` | `sudo`, `su`, `doas`, `pkexec` |
| `host.modify` | Permissions, ownership, services, mounts, disks, firewall, process killing, shutdown |
| `network.request` | Common network clients, SSH, file transfer, raw socket tools |
| `network.upload` | Recognized uploads, non-GET requests, file transfers, raw socket tools |
| `code.execute` | Interpreters, scripts, package managers, build tools, containers, Git operations that can invoke hooks/code |
| `code.download-and-execute` | Recognized download-to-interpreter pipelines |
| `external.mutate` | Cloud, deployment, database and infrastructure CLIs, NixOS/Home Manager activation tools |
| `shell.dynamic` | Expansions, globs, substitutions, grouping/background execution, unsupported control syntax |
| `shell.unclassified` | Commands outside the small inspection subset: **allow in balanced, ask in strict** |
| `tools.unknown` | Other tools, including MCP and orchestration tools, unless explicitly configured |

`ask_user` is allowed unless explicitly restricted by a tool rule.

Names protected by default: `.env`, `.env.*`, `*.pem`, `*.key`, `.npmrc`, `.pypirc`, `.netrc`, `id_rsa*`, `id_ed25519*`, including matching ancestor directory names. `.env.example` is intentionally included; use a narrow exception if appropriate.

Default protected credential directories include `~/.ssh`, `~/.aws`, `~/.azure`, `~/.gnupg`, `~/.kube`, `~/.config/gcloud`, `~/.config/gh`, and `~/.password-store`. Agent `auth.json`, `models.json`, and `mcp.json` are sensitive too.

Unrestricted searches ask because they can return secret contents without explicitly naming the secret file. Repeated exact searches can be approved for the session. Prefer narrowing the search or intentionally changing `secrets.search` rather than treating an ignored `.env` as a guarantee.

## Approval panel

The panel shows the working directory, matching rules and policy sources, then the command or tool arguments. Large details scroll with **PgUp/PgDn**. Choices are:

1. **Deny** (initial selection)
2. **Allow this exact operation once**
3. **Allow this exact operation for this session**

Use `j`/`k` or arrows, then Enter. Escape or Ctrl+C denies. Approval panels have no custom-answer or external-editor escape hatch. Ordinary `ask_user` panels keep those features. Both kinds of panel share a queue; concurrent tools cannot place overlapping dialogs on screen.

Session grants are bound to the tool name, exact arguments, canonical working directory, policy revision, matched rules and resolved path targets. Changing the command, input, recognized target, or policy invalidates them. Pending approvals are rejected if input, policy, or resolved targets change while the panel is open.

This does **not** bind approvals to all files a script might execute or read. Approving `npm test` again after changing a test still trusts the command's current code. A one-time grant authorizes one tool invocation, not a program's individual filesystem/network operations.

In RPC, print and JSON modes, operations requiring interactive approval are blocked. Policy-allowed operations still work. Policy-denied operations cannot be approved in the panel. Invalid policy/configuration blocks tools with an error; fix the file manually or inspect the error with `/permissions`.

## Configuration

Global policy: `<agent-dir>/permissions.json`, normally `~/.pi/agent/permissions.json`. Pi's `PI_CODING_AGENT_DIR` is respected.

Project policy: `<project-root>/.pi/permissions.json`.

The project root is fixed when entering a session: nearest ancestor with `.git`, otherwise nearest ancestor with `.pi`, otherwise the starting directory. A Bash `cd` does not change which policy is selected. In a Git repository, a nested `.pi` does not replace the Git-root policy.

Example project policy:

```json
{
  "version": 1,
  "rules": {
    "git.push": "deny",
    "secrets.search": "allow"
  },
  "sensitiveNames": ["credentials.json", "*.secret"],
  "sensitivePaths": ["./private"],
  "exceptions": [
    {
      "id": "generated-build-cleanup",
      "operation": "filesystem.delete",
      "paths": ["./build", "./dist"],
      "action": "allow"
    }
  ]
}
```

All fields except `version` are optional. Unknown fields/rules, invalid actions, unsupported versions and malformed exceptions are errors, not ignored configuration. Policies are limited to 64 KiB.

### Project trust

Project policy is parsed but **not applied** until approved. The panel lists overrides, the canonical project path, the policy path and a hash. Choices are ignore, trust for this session, or trust and remember.

Remembered decisions live in `<agent-dir>/permission-trust.json`, outside the repository, with file mode `0600`. Trust binds to the canonical root, resolved policy path, and exact file contents. Even a whitespace edit requires renewed approval. An ignored policy is not prompted again during the same session unless it changes or you run `/permissions trust-project`.

Headless runs ignore overrides that lack remembered approval. A malformed project policy still fails closed, even if its last revision was ignored.

This is separate from Pi's built-in `/trust`: Pi project trust can load executable extensions; permission-policy trust approves one data-only policy revision. Trusting a project extension gives that extension the ability to bypass this guard. Do not grant Pi project trust to executable resources you do not trust.

### Precedence

Layers apply in order:

1. Built-in defaults
2. Global policy
3. Approved project policy
4. User-issued session settings

Named rules and tool rules replace earlier values. A trusted project can therefore change a global `deny` to `ask` or `allow`; an untrusted project cannot. Exception IDs are replaced explicitly by a later layer. Sensitive-name/path lists are additive, including built-in defaults.

Within the resulting policy, all matching rules apply: `deny` wins over `ask`, and `ask` wins over `allow`. A tool-level `allow` does not bypass built-in path/command checks. For example, allowing `git.push` alone can still leave a `code.execute` approval for Git's hooks; the panel lists every matching reason. For otherwise unknown tools, an explicit tool rule replaces the generic `tools.unknown` ask, but cannot bypass a `tools.unknown: deny` rule.

`profile: "strict"` changes the default for `shell.unclassified` to `ask`. An explicit `shell.unclassified` rule overrides that default. Switching profiles does not undo other explicit rules, so do not set that rule to `allow` if you expect a later strict profile to tighten it.

### Paths and exceptions

Policy paths are relative to the fixed project root, including global-policy paths. `~/` paths are expanded. `sensitiveNames` matches basenames and supports only `*` wildcards; `sensitivePaths` protects literal directories and their descendants.

Exceptions have an ID, an operation, a list of literal paths, and an action. They are intentionally limited:

- Paths must exactly match every target, not a parent directory or glob.
- Targets must be inside the project and have no symlink aliasing.
- A `deny` rule cannot be relaxed by an exception in the same effective policy.
- Exceptions do not bypass unrelated risks, such as secret access or shell redirection.
- Bash deletion exceptions work only for a single literal `rm` command with recognized flags, no wrappers, expansions, chaining, or redirection.
- File-tool exceptions can apply to `secrets.read`, `secrets.modify`, and `filesystem.outside-project`, but the in-project constraint means exceptions do not grant arbitrary external file access. `permissions.modify` always requires its own rule/approval.
- Other shell effects have no path exceptions; approve the exact invocation or change the named rule explicitly.

Tool rules are keyed by exact tool name:

```json
{
  "version": 1,
  "tools": {
    "my_read_only_tool": "allow",
    "my_deploy_tool": "deny"
  }
}
```

Only add an allow rule after reviewing what the tool does. Tool annotations are not treated as verified safety guarantees.

## Session commands

```text
/permissions
/permissions explain
/permissions profile strict
/permissions profile balanced
/permissions set git.push deny
/permissions set secrets.search allow
/permissions reset-session
/permissions trust-project
```

`/permissions` shows the effective policy and its sources. `explain` reports the last decision. Settings commands are user slash commands, not model-callable tools. They change only this process's active session. `reset-session` clears session rules, profile and exact-operation grants; it does not revoke remembered project trust.

Session state survives `/reload` within the same process, but clears when switching/new/forking sessions. Returning to an old session does not restore its old grants. Restarting Pi also clears session grants. No approval payloads or secret values are written to an audit log or session entry by this extension. Pi itself can record normal tool inputs/results in its transcript.

## Security limits

The Bash analyzer is a dependency-free, conservative lexer for a limited shell subset, not a complete Bash AST or a proof of behavior. It recognizes quoting, escaped characters, separators, redirection and common risk patterns, and asks on dynamic/unsupported syntax. Some harmless commands will prompt. Balanced mode deliberately permits unclassified commands; strict mode asks instead.

The inspection subset includes `pwd`, `whoami`, `ls`, `stat`, `wc`, `head`, `tail`, `cat`, `readlink`, `realpath`, and selected Git inspections. It assumes trusted executable resolution and Git configuration. Git config, hooks, aliases, external diff programs, executable replacement, startup environment, opaque scripts, uncommon clients and application-specific flags can defeat command classification. `code.execute` approval is broad trust in whatever code the invoked program executes.

Paths are checked lexically and through existing symlinks, including existing parents of new files. This does not prevent hard-link aliases, changes after the final check, or other filesystem races. Shell arguments are inspected conservatively as possible paths; they are not full data-flow analysis. A `cd` chain is not interpreted to resolve later relative arguments against the new directory.

The guard does not cover Pi's own startup/context-file reads, arbitrary filesystem/process activity inside extensions, remote services, separate agents that do not inherit the guard, or user-issued `!`/`!!` shell commands. Those remain explicit manual actions. Other trusted extensions may mutate tool input after the check or replace execution entirely. Disabling/removing the extension disables the guard.

Most importantly, allowing a build/test/script can read `.env`, use inherited credentials, change policies, or contact the network without another tool event. A strict secret boundary requires OS-level filesystem isolation, restricted environment variables, network controls, and careful treatment of agent credentials. Prefer isolating the entire agent when working on hostile repositories. No automatic unsandboxed fallback should be added to a future sandbox integration.

## Tests

```sh
pi_root="$(dirname "$(readlink -f "$(command -v pi)")")/../lib/node_modules/pi-monorepo"
node dotfiles/pi/tests/ask-user.mjs "$pi_root"
node dotfiles/pi/tests/permissions.mjs "$pi_root"
```

Tests use the installed Pi packages and simulated TUI input; no dangerous shell commands in the test cases are executed. Coverage includes validation, rule precedence, command variants, symlinks, exact exceptions, trust/hash changes, cancellation, headless mode, session switching/reload, concurrent approvals and long/narrow permission panels. A real-terminal visual check remains useful.

## Background

- [OWASP prompt injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)
- [OWASP excessive agency](https://genai.owasp.org/llmrisk/llm062025-excessive-agency/)
- [Claude Code security](https://code.claude.com/docs/en/security)
- [Claude Code sandboxing](https://code.claude.com/docs/en/sandboxing)
- [OpenAI shell tools](https://developers.openai.com/api/docs/guides/tools-shell)
- Installed Pi `docs/extensions.md`, `docs/security.md`, `docs/configuration.md`, and `docs/containerization.md`
