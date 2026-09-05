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
        (bind "F11" (exec "hyprshot -m output"))                # Full screen
        (bind (mod "F11") (exec "hyprshot -m window"))          # Active window
        (bind (mod "SHIFT + S") (exec "hyprshot -m region"))    # Region selection
      ];
    };
  };
}
