# Cursor app module (system-level)
# Linux only.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  cursorEnabled = settings.user.apps.cursor.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then { } else {
    home-manager.users.${username} = lib.mkIf cursorEnabled {
      home.packages = [ pkgs.code-cursor ];
    };
  };
}
