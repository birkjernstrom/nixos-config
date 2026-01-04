{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprshot
    ];

    wayland.windowManager.hyprland.settings = {
      bind = [
        # Screenshots with hyprshot
        ", F11, exec, hyprshot -m output"           # Full screen
        "$mainMod, F11, exec, hyprshot -m window"   # Active window
        "$mainMod SHIFT, S, exec, hyprshot -m region" # Region selection
      ];
    };
  };
}
