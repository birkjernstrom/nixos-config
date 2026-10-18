# LocalSend module (system-level)
# Installs via homebrew on Darwin, via the NixOS module on NixOS (opens TCP/UDP 53317)
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  localsendEnabled = settings.user.apps.localsend.enable or false;
in
{
  config = if isDarwin then {
    homebrew.casks = lib.mkIf localsendEnabled [ "localsend" ];
  } else {
    programs.localsend.enable = localsendEnabled;
  };
}
