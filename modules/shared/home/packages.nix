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

  # Development
  neovim
  git
  delta  # Git diff
  gh    # GitHub CLI

  # Node
  nodejs_20

  # Python
  pyenv
  poetry
]
