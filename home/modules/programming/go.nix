{ config, pkgs, lib, ... }:

with lib; let
  feat = config.features.programming.go;
in
{
  options.features.programming.go.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Go programming environment.";
  };

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      go
    ];

    programs = {};
  };
}
