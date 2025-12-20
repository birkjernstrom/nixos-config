{ config, pkgs, lib, ... }:

with lib; let
  feat = config.features.programming.tools;
in
{
  options.features.programming.tools.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable development tools (lazydocker, redis).";
  };

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      lazydocker
    ];
  };
}
