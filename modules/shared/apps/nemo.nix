# Nemo app module (system-level)
# Linux only. Also answers org.freedesktop.FileManager1, so "Show in folder"
# works without Nautilus.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  nemoEnabled = settings.user.apps.nemo.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then { } else {
    home-manager.users.${username} = lib.mkIf nemoEnabled {
      home.packages = [ pkgs.nemo-with-extensions ];

      dconf.settings."org/cinnamon/desktop/applications/terminal".exec = "ghostty";
    };
  };
}
