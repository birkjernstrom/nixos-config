{ config, lib, pkgs, ... }:

{
  imports = [
    ./hyprland/home.nix
    ./wofi.nix
    ./waybar.nix
    ./mako.nix
  ];
}
