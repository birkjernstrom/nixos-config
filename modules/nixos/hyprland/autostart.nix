{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      exec = [
        "pgrep waybar || waybar &"
      ];
    };
  };
}
