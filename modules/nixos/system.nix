{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts
    ./nix.nix
    ./stylix.nix
    ./hyprland/system.nix
    ./noctalia
    ./primo.nix
    ./clamav.nix
    ./tailscale.nix
  ];
}
