# Todoist app module (system-level)
# Installs via homebrew on Darwin, via nixpkgs on NixOS with hyprland keybinding
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  todoistEnabled = settings.user.apps.todoist.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then {
    # Darwin: install via homebrew cask
    homebrew.casks = lib.mkIf todoistEnabled [ "todoist" ];
  } else {
    # NixOS/Linux: install via home-manager
    home-manager.users.${username} = lib.mkIf todoistEnabled {
      home.packages = [ pkgs.todoist-electron ];

      # Add hyprland keybinding (Super+T to launch Todoist)
      wayland.windowManager.hyprland.settings.bind = [
        "SUPER, T, exec, todoist-electron"
      ];
    };
  };
}
