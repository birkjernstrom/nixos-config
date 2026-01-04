{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.languages.typescript;
in
{
  options.userSettings.programming.languages.typescript.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Typescript programming environment.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs_20
      pnpm
    ];

    programs = {};
  };
}
