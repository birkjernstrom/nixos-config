{ config, pkgs, lib, ... }:

with lib; let
  feat = config.features.programming.typescript;
in
{
  options.features.programming.typescript.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Typescript programming environment.";
  };

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      nodejs_20
      pnpm
    ];

    programs = {};
  };
}
