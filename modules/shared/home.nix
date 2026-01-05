{ config, lib, pkgs, ... }:

{
  imports = [
    ./core.nix
    ./sops/home.nix
    ./dotfiles.nix
    ./ghostty.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./nvim
    ./programming
    ./scripts
  ];
}
