{ config, lib, ... }:

with lib; let
  feat = config.features.hyprland;
in
{
  config = mkIf feat.enable {
    wayland.windowManager.hyprland.settings = {
      exec = [
        "pgrep waybar || waybar &"
      ];
    };
  };
}
