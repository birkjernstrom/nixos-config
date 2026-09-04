{ config, lib, pkgs, ... }:

{
  imports = [
    ./hyprland/home.nix
    ./quickshell
    ./mako.nix
  ];
}
