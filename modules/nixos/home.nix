{ config, lib, pkgs, ... }:

{
  imports = [
    ./hyprland/home.nix
    ./quickshell
    ./webapps.nix
    ./mako.nix
  ];
}
