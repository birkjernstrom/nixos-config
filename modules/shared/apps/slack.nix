# Slack app module (system-level)
# Installs via homebrew on Darwin, via nixpkgs on NixOS with hyprland keybinding
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  slackEnabled = settings.user.apps.slack.enable or false;
  username = settings.user.name;
  hypr = import ../../nixos/hyprland/lib.nix { inherit lib; };
  inherit (hypr) bind exec;
in
{
  config = if isDarwin then {
    # Darwin: install via homebrew cask
    homebrew.casks = lib.mkIf slackEnabled [ "slack" ];
  } else {
    # NixOS/Linux: install via home-manager
    home-manager.users.${username} = lib.mkIf slackEnabled {
      home.packages = [ pkgs.slack ];

      # slack:// links (e.g. the sign-in redirect from the browser).
      xdg.mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/slack" = "slack.desktop";
      };

      # Add hyprland keybinding (Super+S to launch Slack)
      wayland.windowManager.hyprland.settings.bind = [
        (bind "SUPER + S" (exec "slack"))
      ];
    };
  };
}
