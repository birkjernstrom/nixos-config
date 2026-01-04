{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.tools;
in
{
  options.userSettings.programming.tools.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable development tools (lazydocker, redis).";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      lazydocker
    ];
  };
}
