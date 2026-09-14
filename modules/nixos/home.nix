{ config, lib, pkgs, ... }:

{
  imports = [
    ./hyprland/home.nix
    ./noctalia/home.nix
    ./quickshell
    ./webapps.nix
    ./mako.nix
  ];
}
