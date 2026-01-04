{ config, lib, pkgs, ... }:

{
  imports = [
    ./stylix.nix
    ./hyprland/system.nix
  ];
}
