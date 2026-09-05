{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) bind mod exec;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprlock
    ];

    # Colours come from Stylix. Only the wallpaper is opted out of, so the
    # lock screen keeps its blurred screenshot background.
    stylix.targets.hyprlock.image.enable = false;

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 0;
        };

        background = {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        };

        # Minimal input field - geometry only
        input-field = {
          size = "250, 40";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.15;
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "";
          hide_input = false;
          fail_text = "";
          position = "0, 0";
          halign = "center";
          valign = "center";
        };
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        # Lock screen with hyprlock
        (bind (mod "SHIFT + Q") (exec "hyprlock"))
      ];
    };
  };
}
