{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprlock
    ];

    wayland.windowManager.hyprland.settings = {
      bind = [
        # Lock screen with hyprlock
        "$mainMod SHIFT, Q, exec, hyprlock"
      ];
    };
  };
}
