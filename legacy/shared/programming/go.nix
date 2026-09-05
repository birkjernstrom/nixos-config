{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.languages.go;
in
{
  options.userSettings.programming.languages.go.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Go programming environment.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      go
    ];

    programs = {};
  };
}
