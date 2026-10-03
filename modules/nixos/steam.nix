{ config, lib, ... }:

with lib; let
  cfg = config.systemSettings.steam;
in
{
  options.systemSettings.steam.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Steam";
  };

  config = mkIf cfg.enable {
    programs.steam.enable = true;
  };
}
