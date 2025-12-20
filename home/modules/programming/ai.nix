{ config, pkgs, lib, ... }:

with lib; let
  feat = config.features.programming.ai;
in
{
  options.features.programming.ai.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable AI tools (claude-code, opencode).";
  };

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      claude-code
      opencode
    ];
  };
}
