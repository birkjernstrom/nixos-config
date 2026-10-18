# Pi extensions

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

Run `/ask-user-demo`. The demo does not send its answers to the model. To test the model integration, ask Pi to ask you a clarification question using `ask_user`.

### Persistent installation

`modules/shared/programming/pi.nix` installs the extension at `~/.pi/agent/extensions/ask-user.ts` when the AI tools option is enabled. Include the new files in Git before a Git-flake-based rebuild, then activate your usual Nix/Home Manager configuration and run `/reload` or restart Pi. Do not also load the file with `-e` once it is installed globally.

No npm dependencies or compilation step are needed: the extension uses Pi's host-provided packages. The panel requires TUI mode; in other modes, the tool returns an error instructing the model to ask in plain text.

### Tests

The test runner takes the installed Pi package directory as its argument. For the current Nix package layout:

```sh
pi_root="$(dirname "$(readlink -f "$(command -v pi)")")/../lib/node_modules/pi-monorepo"
node dotfiles/pi/tests/ask-user.mjs "$pi_root"
```

Tests exercise the registered tool using Pi's real editor component and a simulated TUI, including launching a temporary external-editor process. They do not replace a manual visual check with your terminal and Neovim.
