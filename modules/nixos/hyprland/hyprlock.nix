{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprlock
    ];

    # Disable Stylix auto-styling for hyprlock
    stylix.targets.hyprlock.enable = false;

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 0;
        };

        background = [{
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }];

        # Minimal input field only - Vesper colors
        input-field = [{
          size = "250, 40";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.15;
          dots_center = true;
          outer_color = "rgb(232323)";      # base02 - selection
          inner_color = "rgb(1a1a1a)";      # base01 - elevated bg
          font_color = "rgb(a0a0a0)";       # base05 - muted fg
          fade_on_empty = false;
          placeholder_text = "";
          hide_input = false;
          check_color = "rgb(ffc799)";      # base09 - orange accent
          fail_color = "rgb(ff8080)";       # base08 - red
          fail_text = "";
          capslock_color = "rgb(ffc799)";   # base09 - orange accent
          position = "0, 0";
          halign = "center";
          valign = "center";
        }];
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        # Lock screen with hyprlock
        "$mainMod SHIFT, Q, exec, hyprlock"
      ];
    };
  };
}
