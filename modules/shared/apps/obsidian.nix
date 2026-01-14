# Obsidian app module (system-level)
# Installs via homebrew on Darwin, via nixpkgs on NixOS
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  obsidianEnabled = settings.user.apps.obsidian.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then {
    # Darwin: install via homebrew cask
    homebrew.casks = lib.mkIf obsidianEnabled [ "obsidian" ];
  } else {
    # NixOS/Linux: install via home-manager
    home-manager.users.${username} = lib.mkIf obsidianEnabled {
      home.packages = [ pkgs.obsidian ];

      # Add hyprland keybinding (Super+O to launch Obsidian)
      wayland.windowManager.hyprland.settings.bind = [
        "SUPER, O, exec, obsidian"
      ];
    };
  };
}
