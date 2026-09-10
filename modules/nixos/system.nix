{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts
    ./nix.nix
    ./stylix.nix
    ./hyprland/system.nix
    ./primo.nix
    ./clamav.nix
    ./tailscale.nix
  ];
}
