{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts.nix
    ./stylix.nix
    ./hyprland/system.nix
  ];
}
