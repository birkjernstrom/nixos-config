{ pkgs, ... }:

with pkgs; [
  # Terminal
  zsh
  bat
  fzf
  zoxide
  starship

  # Development
  neovim
  git
  delta  # Git diff

  # Python
  pyenv
  poetry
]
