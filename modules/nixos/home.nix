{ config, lib, pkgs, ... }:

{
  imports = [
    ./hyprland/home.nix
    ./wofi.nix
    ./waybar.nix
    ./mako.nix
  ];

  # Disable Stylix nvf theming - we use our own theme configuration
  stylix.targets.nvf.enable = false;
}
