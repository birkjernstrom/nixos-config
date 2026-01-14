# Slack app module (system-level)
# Installs via homebrew on Darwin, via nixpkgs on NixOS with hyprland keybinding
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  slackEnabled = settings.user.apps.slack.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then {
    # Darwin: install via homebrew cask
    homebrew.casks = lib.mkIf slackEnabled [ "slack" ];
  } else {
    # NixOS/Linux: install via home-manager
    home-manager.users.${username} = lib.mkIf slackEnabled {
      home.packages = [ pkgs.slack ];

      # Add hyprland keybinding (Super+S to launch Slack)
      wayland.windowManager.hyprland.settings.bind = [
        "SUPER, S, exec, slack"
      ];
    };
  };
}
