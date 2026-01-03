{ ... }:

{
  imports = [
    ./core.nix
    ./sops.nix
    ./dotfiles.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./nvim

    ./programming
    ./scripts

    # Move to NixOS specific later
    ./hyprland
  ];
}
