# Foliate app module (system-level)
# Linux only: nixpkgs has no Darwin build.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  foliateEnabled = settings.user.apps.foliate.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then { } else {
    home-manager.users.${username} = lib.mkIf foliateEnabled {
      home.packages = [ pkgs.foliate ];
    };
  };
}
