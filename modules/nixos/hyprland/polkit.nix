{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    services.hyprpolkitagent.enable = true;
  };
}
