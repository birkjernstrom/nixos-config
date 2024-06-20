{ pkgs, ... }:

with pkgs; [
  # Terminal
  zsh
  bat
  fzf
  zoxide
  starship
  tmux
  ripgrep
  sesh

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
