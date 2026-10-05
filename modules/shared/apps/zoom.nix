# Zoom app module (system-level)
# Linux only: Darwin installs via homebrew cask in modules/darwin/homebrew.nix.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  zoomEnabled = settings.user.apps.zoom.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then { } else {
    home-manager.users.${username} = lib.mkIf zoomEnabled {
      home.packages = [ pkgs.zoom-us ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/zoommtg" = "Zoom.desktop";
          "x-scheme-handler/zoomus" = "Zoom.desktop";
        };
      };
    };
  };
}
