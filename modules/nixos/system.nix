{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts
    ./stylix.nix
    ./hyprland/system.nix
  ];
}
