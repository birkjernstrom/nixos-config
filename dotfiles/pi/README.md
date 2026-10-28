# Pi extensions and skills

## Live development links

`modules/shared/programming/pi.nix` currently sets `livePiSources = true`. Home Manager installs directory symlinks resolving to:

```text
~/.pi/agent/extensions → ~/.nixos-config/dotfiles/pi/extensions
~/.pi/agent/skills     → ~/.nixos-config/dotfiles/pi/skills
```

After initial activation, editing or adding extensions and skills needs only `/reload`, not a rebuild or sudo. Do not also load them with `-e` or `--skill`. The repository must remain at `~/.nixos-config`. Pi's `AGENTS.md` and the Pi package remain Nix-managed and still need the usual deployment workflow.

These links use the live working tree, including uncommitted and untracked files. Broken edits can fail on reload. Nix generation rollbacks do not restore the repository contents. Extensions that write runtime state relative to their source directory may now write into the repository; prefer storing that state outside the source tree.

### One-time migration

Build the new configuration first. Before switching, back up the existing resource directories, since Home Manager cannot replace nonempty real directories with its directory symlinks. On the current XPS host, after reviewing/staging the intended changes:

```sh
nixos-rebuild build --flake "$HOME/.nixos-config#xps" --no-update-lock-file
```

Only after that succeeds, in your own terminal:

```sh
backup="$(mktemp -d "$HOME/.pi/agent/resources-before-live.XXXXXX")"
for name in extensions skills; do
  path="$HOME/.pi/agent/$name"
  if [ -d "$path" ] && [ ! -L "$path" ]; then
    mv "$path" "$backup/$name" || break
  fi
done
printf 'Previous Pi resources saved in %s\n' "$backup"
```

Check the move succeeded for both directories before switching:

```sh
sudo nixos-rebuild switch --flake "$HOME/.nixos-config#xps" --no-update-lock-file
```

Keep the backup: it preserves old logs and any manually installed resources. If switching fails, inspect its state before restoring anything; do not restore the backup over newly installed directory links. After success, verify both destinations with `readlink -f`, then run `/reload` in Pi.

### Return to Nix-store sources later

Set `livePiSources = false` in `modules/shared/programming/pi.nix`, stage any new source files, and rebuild/switch. The same resource directories will then point into the Nix store. Subsequent source edits require another rebuild/switch and reload.

## Ask user

`extensions/ask-user.ts` registers the `ask_user` tool. Its prompt guideline tells the model to use the tool when it needs clarification or a decision, instead of asking in ordinary response text. This is model guidance, not automatic detection of every question in a response.

Questions appear in a focused panel in Pi's editor area, with the question and suggested answers above the answer editor. The normal prompt draft is left untouched. Related questions are presented one at a time; cancelling returns any completed answers and marks the rest unanswered.

| Key | Action |
| --- | --- |
| j / k or Down / Up | Navigate suggestions, including “Write my own answer” |
| Enter | Select a suggestion, or submit a nonempty written answer |
| Tab | Switch between suggestions and the answer editor; retain the draft |
| Shift+Enter | Insert a newline in the answer editor |
| Ctrl+G | Edit the answer in an external editor; from choices, seed it with the selected suggestion |
| Esc | Return from editing to choices, or cancel when already in choices; free-form-only questions cancel directly |

`j` and `k` navigate only while choosing an option; in the answer editor they type normally.

The external-editor shortcut and editor keys follow Pi's keybindings. The table lists their defaults. Saving and closing the external editor returns to the panel for review; it does not submit the answer automatically.

External-editor resolution is Pi's `externalEditor` setting, then `$VISUAL`, then `$EDITOR`, then Pi's platform fallback. For Neovim, set `EDITOR=nvim` (and ensure `VISUAL` does not override it), or set `"externalEditor": "nvim"` in `~/.pi/agent/settings.json`. Pi's editor command parser supports a command plus space-separated arguments; use a wrapper script for complex shell commands.

### Try without rebuilding

From this repository:

```sh
pi -e ./dotfiles/pi/extensions/ask-user.ts
```

To try it, ask Pi: “Demo the ask_user tool with a few example questions, including choices and a free-form answer.” No slash command is registered. Answers are returned to the model as normal tool results.

### Persistent installation

`modules/shared/programming/pi.nix` installs the resource directories when the AI tools option is enabled. Follow the live-link migration above for initial activation. Once the live links are installed, extension and skill edits need only `/reload`. With `livePiSources = false`, include new files in Git and rebuild/switch for each update. Do not also load the file with `-e` once it is installed globally.

No npm dependencies or compilation step are needed: the extension uses Pi's host-provided packages. The panel requires TUI mode; in other modes, the tool returns an error instructing the model to ask in plain text.

### Tests

The test runner takes the installed Pi package directory as its argument. For the current Nix package layout:

```sh
pi_root="$(dirname "$(readlink -f "$(command -v pi)")")/../lib/node_modules/pi-monorepo"
node dotfiles/pi/tests/ask-user.mjs "$pi_root"
```

Tests exercise the registered tool using Pi's real editor component and a simulated TUI, including launching a temporary external-editor process. They do not replace a manual visual check with your terminal and Neovim.
