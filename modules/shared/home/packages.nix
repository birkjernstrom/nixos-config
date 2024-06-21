{ pkgs, ... }:

with pkgs;
let customShellScripts = import ../../../sh { inherit pkgs; }; in
customShellScripts ++ [
  # Terminal
  zsh
  bat
  fzf
  zoxide
  starship
  ripgrep
  sesh

  # Tmux
  tmux
  tmuxp

  # Development
  neovim
  git
  delta  # Git diff
  gh    # GitHub CLI

  # Node
  nodejs_20
  corepack  # To install pnpm as needed etc

  # Python
  pyenv
  poetry
]
