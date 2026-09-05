{ config, lib, pkgs, ... }:

{
  imports = [
    ./core.nix
    ./sops/home.nix
    ./dotfiles.nix
    ./zsh.nix
    ./git.nix
    ./jj.nix
    ./tmux.nix
    ./nvim
    ./programming
    ./scripts
    ./options.nix
  ];
}
