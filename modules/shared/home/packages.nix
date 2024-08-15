{ pkgs, nixpkgs-stable, ... }:

with pkgs;
let
  customShellScripts = import ../../../sh { inherit pkgs; };
in
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
  gh    # GitHub CLI
  lazydocker

  # Node
  nodejs_20
  corepack  # To install pnpm as needed etc

  # Python
  pyenv
  poetry
  python313
]
++
(with nixpkgs-stable;
[
  # Disable short-term due to nix issues with delta
  # delta # Git diff
])
