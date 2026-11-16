{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) bind mod exec;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprshot
    ];

    wayland.windowManager.hyprland.settings = {
      bind = [
        # Screenshots with hyprshot
        (bind "Screen capture: Screenshot screen" "F11" (exec "hyprshot -m output"))
        (bind "Screen capture: Screenshot window" (mod "F11") (exec "hyprshot -m window"))
        (bind "Screen capture: Screenshot region" (mod "SHIFT + S") (exec "hyprshot -m region"))
      ];
    };
  };
}
