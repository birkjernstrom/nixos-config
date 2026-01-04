{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.ai;
in
{
  options.userSettings.programming.ai.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable AI tools (claude-code, opencode).";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
      opencode
    ];
  };
}
