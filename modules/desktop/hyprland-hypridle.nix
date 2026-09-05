# hypridle: dim, lock and blank the screen on a timer.
#
# The `hl.*` helpers come from modules/desktop/_hypr.nix, which is a plain
# function rather than a module - import-tree skips it because of the `_`.
{ lib, ... }:

let
  hypr = import ./_hypr.nix { inherit lib; };
in
{
  flake.modules.homeManager.desktop = { config, pkgs, ... }: {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          # Dim screen after 2.5 minutes
          {
            timeout = 150;
            on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
            on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
          # Lock screen after 5 minutes
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          # Turn off screen after 5.5 minutes
          {
            timeout = 330;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          # Suspend after 30 minutes
          {
            timeout = 1800;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
