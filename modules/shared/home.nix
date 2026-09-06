{ config, lib, pkgs, ... }:

{
  imports = [
    ./core.nix
    ./sops/home.nix
    ./dotfiles.nix
    ./zsh.nix
    ./git.nix
    ./jj.nix
    ./try.nix
    ./tmux.nix
    ./nvim
    ./programming
    ./scripts
    ./options.nix
  ];
}
